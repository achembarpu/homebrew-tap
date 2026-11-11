#!/usr/bin/env python3
"""Test bounded ZIP inspection without external network access."""

import importlib.util
import io
import re
import sys
import unittest
import zipfile
from pathlib import Path
from unittest import mock

sys.dont_write_bytecode = True
spec = importlib.util.spec_from_file_location("probe_optcgsim", Path(__file__).with_name("probe-optcgsim.py"))
probe = importlib.util.module_from_spec(spec)
spec.loader.exec_module(probe)


class Response:
    def __init__(self, data, status, headers, requests):
        self.data = data
        self.status = status
        self.headers = headers
        self.requests = requests

    def __enter__(self):
        return self

    def __exit__(self, *_args):
        return False

    def read(self, amount):
        self.requests.append(amount)
        return self.data[:amount]


class RangeProbeTest(unittest.TestCase):
    def make_archive(self, folder="1.45a", binary="1.45a"):
        stream = io.BytesIO()
        with zipfile.ZipFile(stream, "w") as archive:
            archive.writestr("unrelated.bin", b"x" * (4 * 1024 * 1024))
            archive.writestr(
                f"{folder}_Mac/OPTCGSim.app/Contents/Assembly-CSharp.dll",
                f"sim version: {binary}".encode("utf-16le"),
                compress_type=zipfile.ZIP_DEFLATED,
            )
        return stream.getvalue()

    def server(self, archive, *, ignore_range=False, change_validator=False):
        reads = []
        requests = []

        def open_url(request, timeout):
            del timeout
            requests.append(request)
            if ignore_range:
                return Response(archive, 200, {}, reads)
            match = re.fullmatch(r"bytes=(\d+)-(\d+)", request.get_header("Range"))
            first, last = map(int, match.groups())
            last = min(last, len(archive) - 1)
            etag = '"changed"' if change_validator and len(requests) > 1 else '"original"'
            headers = {"Content-Range": f"bytes {first}-{last}/{len(archive)}", "ETag": etag}
            return Response(archive[first : last + 1], 206, headers, reads)

        return open_url, requests, reads

    def test_reads_version_without_downloading_archive(self):
        archive = self.make_archive()
        open_url, requests, reads = self.server(archive)
        with mock.patch.object(probe.urllib.request, "urlopen", open_url):
            version, transferred = probe.probe("https://example.test/archive.zip")
        self.assertEqual(version, "1.45a")
        self.assertLess(transferred, len(archive))
        self.assertLessEqual(transferred, 2 * probe.BLOCK_SIZE + 1)
        self.assertTrue(any(request.get_header("If-range") == '"original"' for request in requests))
        self.assertEqual(sum(reads), transferred + len(reads))

    def test_server_ignoring_range_does_not_stream_the_archive(self):
        open_url, _, reads = self.server(self.make_archive(), ignore_range=True)
        with mock.patch.object(probe.urllib.request, "urlopen", open_url):
            with self.assertRaises(probe.RangeError):
                probe.probe("https://example.test/archive.zip")
        self.assertEqual(reads, [])

    def test_changed_archive_is_rejected(self):
        open_url, _, _ = self.server(self.make_archive(), change_validator=True)
        with mock.patch.object(probe.urllib.request, "urlopen", open_url):
            with self.assertRaises(probe.RangeError):
                probe.probe("https://example.test/archive.zip")

    def test_bundle_version_must_match_binary(self):
        open_url, _, _ = self.server(self.make_archive(folder="1.45", binary="1.45a"))
        with mock.patch.object(probe.urllib.request, "urlopen", open_url):
            with self.assertRaises(probe.RangeError):
                probe.probe("https://example.test/archive.zip")


if __name__ == "__main__":
    unittest.main()
