#!/usr/bin/env python3
"""Read the Mac ZIP's version over bounded HTTP byte ranges."""

import io
import re
import sys
import urllib.error
import urllib.request
import zipfile

BLOCK_SIZE = 1024 * 1024
MAX_TRANSFER = 64 * 1024 * 1024
MAX_ASSEMBLY = 64 * 1024 * 1024
VERSION_PATTERN = re.compile(rb"sim version:\s*([0-9]+\.[0-9]+[a-z]*)")


class RangeError(Exception):
    pass


class RangeReader(io.RawIOBase):
    """A seekable, size-limited HTTP reader for zipfile's random access."""

    def __init__(self, url):
        super().__init__()
        self.url = url
        self.pos = 0
        self.size = None
        self.validator = None
        self.cache_start = 0
        self.cache = b""
        self.transferred = 0
        self._fetch(0, 0)

    def _fetch(self, start, end):
        headers = {"Range": f"bytes={start}-{end}", "Accept-Encoding": "identity"}
        if self.validator:
            headers["If-Range"] = self.validator
        request = urllib.request.Request(self.url, headers=headers)
        try:
            with urllib.request.urlopen(request, timeout=30) as response:
                if response.status != 206:
                    raise RangeError(f"server did not honor byte ranges (HTTP {response.status})")
                content_range = response.headers.get("Content-Range", "")
                match = re.fullmatch(r"bytes (\d+)-(\d+)/(\d+)", content_range)
                if not match:
                    raise RangeError("server returned an invalid Content-Range")
                first, last, total = map(int, match.groups())
                if first != start or last != min(end, total - 1) or first > last:
                    raise RangeError("server returned an unexpected byte range")
                if self.size is not None and total != self.size:
                    raise RangeError("archive size changed during inspection")
                validator = response.headers.get("ETag") or response.headers.get("Last-Modified")
                if self.validator and validator != self.validator:
                    raise RangeError("archive changed during inspection")
                if not self.validator:
                    self.validator = validator
                expected = last - first + 1
                if self.transferred + expected > MAX_TRANSFER:
                    raise RangeError("archive inspection exceeded the transfer limit")
                data = response.read(expected + 1)
                if len(data) != expected:
                    raise RangeError("server returned an incomplete byte range")
                self.transferred += len(data)
                self.size = total
                self.cache_start = first
                self.cache = data
        except (OSError, urllib.error.URLError) as error:
            raise RangeError(str(error)) from error

    def readable(self):
        return True

    def seekable(self):
        return True

    def tell(self):
        return self.pos

    def seek(self, offset, whence=io.SEEK_SET):
        if whence == io.SEEK_SET:
            target = offset
        elif whence == io.SEEK_CUR:
            target = self.pos + offset
        elif whence == io.SEEK_END:
            target = self.size + offset
        else:
            raise ValueError("invalid seek origin")
        if target < 0:
            raise ValueError("negative seek position")
        self.pos = target
        return self.pos

    def read(self, size=-1):
        if size is None or size < 0:
            size = self.size - self.pos
        size = min(size, max(0, self.size - self.pos))
        chunks = []
        while size:
            if not self.cache_start <= self.pos < self.cache_start + len(self.cache):
                start = (self.pos // BLOCK_SIZE) * BLOCK_SIZE
                self._fetch(start, min(start + BLOCK_SIZE - 1, self.size - 1))
            offset = self.pos - self.cache_start
            chunk = self.cache[offset : offset + size]
            chunks.append(chunk)
            self.pos += len(chunk)
            size -= len(chunk)
        return b"".join(chunks)


def probe(url):
    with RangeReader(url) as remote, zipfile.ZipFile(remote) as archive:
        matches = [entry for entry in archive.infolist() if entry.filename.endswith("/Assembly-CSharp.dll")]
        if len(matches) != 1:
            raise RangeError("archive must contain exactly one Assembly-CSharp.dll")
        entry = matches[0]
        if entry.file_size > MAX_ASSEMBLY or entry.compress_size > MAX_TRANSFER:
            raise RangeError("version-bearing assembly is too large to inspect")
        binary = archive.read(entry).replace(b"\x00", b"")
        match = VERSION_PATTERN.search(binary)
        if not match:
            raise RangeError("binary does not contain a sim version")
        version = match.group(1).decode("ascii")
        if not entry.filename.startswith(f"{version}_Mac/OPTCGSim.app/"):
            raise RangeError("bundle path does not match the binary version")
        return version, remote.transferred


def main():
    if len(sys.argv) != 2:
        sys.exit("Usage: probe-optcgsim.py <archive-url>")
    try:
        version, transferred = probe(sys.argv[1])
    except (RangeError, zipfile.BadZipFile, NotImplementedError, OSError) as error:
        sys.exit(f"Error: could not inspect Mac archive by range: {error}")
    print(f"{version}\t{transferred}")


if __name__ == "__main__":
    main()
