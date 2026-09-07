#!/usr/bin/env python3
"""
Tests for extract_locale_phrases.py.

    python -m unittest discover -s tools
    python tools/test_extract_locale_phrases.py

Every fixture here is SYNTHETIC Lua written into a temporary directory that the
module is pointed at, so a test can never read, rewrite or delete a real addon
file -- extract_locale_phrases.py writes tools/locale_phrases.lua as a side
effect of a plain run, and that file is committed.

The three cases are the three ways the extractor can be wrong in a way nobody
would notice by reading its output: the same phrase written twice would ship two
CurseForge entries, an escaped quote would truncate a phrase mid-sentence, and
an L[variable] would silently ship no entry at all for a string a player reads.
"""

import io
import os
import sys
import shutil
import tempfile
import unittest
import contextlib

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import extract_locale_phrases as ex   # noqa: E402


class ExtractorCase(unittest.TestCase):
    """Points the module at a throwaway repo and writes .lua files into it."""

    def setUp(self):
        self.tmp = tempfile.mkdtemp(prefix="dg_l10n_")
        self.realRepo = ex.REPO
        ex.REPO = self.tmp
        os.makedirs(os.path.join(self.tmp, "tools"))

    def tearDown(self):
        ex.REPO = self.realRepo
        shutil.rmtree(self.tmp, ignore_errors=True)

    def write(self, name, body):
        with open(os.path.join(self.tmp, name), "w", encoding="utf-8", newline="\n") as fh:
            fh.write(body)

    def run_main(self, argv):
        """main() with stdout captured; returns (exit code, output)."""
        buf = io.StringIO()
        with contextlib.redirect_stdout(buf):
            rc = ex.main(argv)
        return rc, buf.getvalue()


class TestDedupe(ExtractorCase):

    def test_same_phrase_in_two_files_yields_one_entry(self):
        self.write("A.lua", 'f:SetText(L["Coffer Key"])\nprint(L["Coffer Key"])\n')
        self.write("B.lua", "g:SetText(L['Coffer Key'])\nh(L[\"Keys: %d/%d\"])\n")

        self.assertEqual(ex.extract(ex.lua_files()), ["Coffer Key", "Keys: %d/%d"])

    def test_output_is_sorted_and_one_line_per_phrase(self):
        self.write("A.lua", 'print(L["zebra"], L["apple"], L["apple"])\n')
        rc, _ = self.run_main([])
        self.assertEqual(rc, 0)

        with open(os.path.join(self.tmp, ex.OUT_REL), encoding="utf-8") as fh:
            lines = fh.read().splitlines()
        body = [ln for ln in lines if not ln.startswith("--")]
        self.assertEqual(body, ['L["apple"] = true', 'L["zebra"] = true'])
        self.assertIn("2 phrases", lines[1])

    def test_whole_line_comments_are_not_phrases(self):
        # DelveGuide_Locale.lua's header documents the policy with example
        # L["..."] lines; those must never reach the phrase list.
        self.write("A.lua", '-- wrap text as L["Some English text"].\nprint(L["real"])\n')
        self.assertEqual(ex.extract(ex.lua_files()), ["real"])


class TestEscapedQuote(ExtractorCase):

    def test_escaped_quote_survives_extraction_and_output(self):
        self.write("A.lua", 'print(L["Say \\"go\\" now"])\n')

        self.assertEqual(ex.extract(ex.lua_files()), ['Say "go" now'])

        rc, _ = self.run_main([])
        self.assertEqual(rc, 0)
        with open(os.path.join(self.tmp, ex.OUT_REL), encoding="utf-8") as fh:
            out = fh.read()
        self.assertIn('L["Say \\"go\\" now"] = true', out)

    def test_apostrophe_phrase_in_double_quotes(self):
        self.write("A.lua", 'print(L["Today\'s Active Delves:"])\n')
        self.assertEqual(ex.extract(ex.lua_files()), ["Today's Active Delves:"])


class TestCheckMode(ExtractorCase):

    def test_check_fails_on_L_indexed_by_a_variable(self):
        self.write("A.lua", 'print(L["fine"])\nlocal s = L[someVariable]\n')

        rc, out = self.run_main(["--check"])
        self.assertEqual(rc, 1)
        self.assertIn("A.lua:2", out)
        self.assertIn("FAIL", out)

    def test_check_passes_on_literals_only(self):
        self.write("A.lua", "print(L[\"fine\"], L['also fine'])\n")

        rc, out = self.run_main(["--check"])
        self.assertEqual(rc, 0)
        self.assertIn("OK", out)

    def test_check_writes_nothing(self):
        self.write("A.lua", 'print(L["fine"])\n')
        rc, _ = self.run_main(["--check"])
        self.assertEqual(rc, 0)
        self.assertFalse(os.path.exists(os.path.join(self.tmp, ex.OUT_REL)))

    def test_similarly_named_table_is_not_an_L_lookup(self):
        # STATE_LABEL[state] ends in "L[" but is not the locale table.
        self.write("A.lua", "local t = STATE_LABEL[state]\nprint(L[\"fine\"])\n")

        rc, _ = self.run_main(["--check"])
        self.assertEqual(rc, 0)

    def test_plain_run_refuses_to_write_when_check_would_fail(self):
        self.write("A.lua", "local s = L[someVariable]\n")

        rc, _ = self.run_main([])
        self.assertEqual(rc, 1)
        self.assertFalse(os.path.exists(os.path.join(self.tmp, ex.OUT_REL)))


if __name__ == "__main__":
    unittest.main()
