#!/usr/bin/env python3
"""
Tests for aggregate_rankings.py.

    python -m unittest discover -s tools
    python tools/test_aggregate.py

Every fixture here is SYNTHETIC. The real responses.csv carries contributor
handles typed by strangers into a public form; it is gitignored and must never
end up in a test file, a fixture or a commit. Handles below are "player_a" and
friends, and the delve and variant names are invented.

The numbers are chosen so the grades are checkable by hand. Five variants are
graded, at 600 / 1000 / 1000 / 1000 / 1400 seconds, so the global median variant
-- the yardstick every grade is a ratio to -- is exactly 1000s. That puts the
band edges at 820 / 930 / 1080 / 1190 / 1370, and makes 600 an S, 1000 a B and
1400 an F. A 1000s variant sits 70s from its nearest edge, which is the lever
the hysteresis tests pull: --hysteresis 30 lets it move, --hysteresis 100 holds
it.
"""

import io
import os
import re
import sys
import csv
import shutil
import tempfile
import unittest
import contextlib

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import aggregate_rankings as agg   # noqa: E402


# --- fixture -----------------------------------------------------------------

# (delve, variant, tier, seconds, runs) sent by every baseline player.
SEGMENTS = [
    ("Alpha Delve", "Quick Route", 10, 600, 1),
    ("Alpha Delve", "Slow Route", 10, 1400, 1),
    ("Alpha Delve", "Shared Route", 10, 1000, 1),
    ("Beta Delve", "Middle Route", 10, 1000, 1),
    ("Beta Delve", "Shared Route", 10, 1000, 1),
]

# Only three players ever run this one, so it stays under the 4-player floor.
THIN = ("Beta Delve", "Thin Route", 10, 900, 2)

BASELINE = ["player_a", "player_b", "player_c", "player_d", "player_e"]

DATA_LUA = """\
-- ============================================================
-- test fixture
-- ============================================================
DelveGuideData = {}

DelveGuideData.delves = {
    -- ── Alpha Delve ─────────────────────
    { name="Alpha Delve", zone="Zone A", variant="Quick Route",     ranking="S", mountable=true,  hasBug=false, isBestRoute=true , medianSec=590, players=4 },  -- 9m 50s, 4 players
    { name="Alpha Delve", zone="Zone A", variant="Slow Route",      ranking="F", mountable=false, hasBug=true,  isBestRoute=false, medianSec=1450, players=4 },  -- 24m 10s, 4 players
    { name="Alpha Delve", zone="Zone A", variant="Shared Route",    ranking="A", mountable=true,  hasBug=true,  isBestRoute=false, medianSec=910, players=6 },  -- 15m 10s, 6 players
    { name="Alpha Delve", zone="Zone A", variant="Untouched Route", ranking="C", mountable=true,  hasBug=false, isBestRoute=false, medianSec=1100, players=5 },  -- 18m 20s, 5 players
    -- ── Beta Delve ──────────────────────
    { name="Beta Delve",  zone="Zone B", variant="Middle Route",    ranking="A", mountable=false, hasBug=false, isBestRoute=true , medianSec=915, players=7 },  -- 15m 15s, 7 players
    { name="Beta Delve",  zone="Zone B", variant="Shared Route",    ranking="F", mountable=true,  hasBug=true,  isBestRoute=false, medianSec=1500, players=4 },  -- 25m 00s, 4 players
    { name="Beta Delve",  zone="Zone B", variant="Thin Route",      ranking="?", mountable=false, hasBug=false, isBestRoute=false },
}

DelveGuideData.contributors = { "player_a", "player_b" }
"""


def read(path, mode="r"):
    kw = {} if "b" in mode else {"encoding": "utf-8", "newline": ""}
    with io.open(path, mode, **kw) as fh:
        return fh.read()


def code(segments):
    return "DG1;" + ";".join(f"{d}~{v}~{t}~{s}~{n}" for d, v, t, s, n in segments)


def bump(segments, delta):
    """Same variants, different times -- a player who has re-run everything."""
    return [(d, v, t, s + delta, n) for d, v, t, s, n in segments]


class Fixture(unittest.TestCase):
    """A temp dir holding a synthetic responses.csv and a synthetic data file."""

    def setUp(self):
        self.dir = tempfile.mkdtemp(prefix="dg_test_")
        self.addCleanup(shutil.rmtree, self.dir, True)
        self.lua = os.path.join(self.dir, "DelveGuide_Data.lua")
        self.write_lua(DATA_LUA)
        self.csv = os.path.join(self.dir, "responses.csv")
        self.write_csv()

    def write_lua(self, text, newline="\n"):
        with io.open(self.lua, "w", encoding="utf-8", newline="") as fh:
            fh.write(text.replace("\n", newline))

    def write_csv(self, extra=()):
        """extra: (handle, code_cell) rows appended after the baseline five."""
        rows = [["Timestamp", "Submission code", "Handle", "Spare", "Feedback"]]
        for i, handle in enumerate(BASELINE):
            segs = list(SEGMENTS) + ([THIN] if i < 3 else [])
            rows.append([f"2026-09-0{i + 1} 10:00:00", code(segs), handle, "", "nice addon"])
        for handle, cell in extra:
            rows.append(["2026-09-09 10:00:00", cell, handle, "", ""])
        with io.open(self.csv, "w", encoding="utf-8", newline="") as fh:
            csv.writer(fh).writerows(rows)

    def run_tool(self, *argv):
        buf = io.StringIO()
        saved = sys.argv
        sys.argv = ["aggregate_rankings.py", self.csv, "--min-tier", "8",
                    "--published", self.lua] + list(argv)
        try:
            with contextlib.redirect_stdout(buf):
                agg.main()
        finally:
            sys.argv = saved
        return buf.getvalue()

    # -- helpers --------------------------------------------------------------

    FIELDS = re.compile(r'(\w+)=("[^"]*"|[\w.]+)')

    def rows_of(self, text):
        """{(delve, variant): (fields dict, whole line)} for a delves block."""
        found = {}
        for line in text.split("\n"):
            stripped = line.strip()
            if not stripped.startswith("{"):
                continue
            fields = dict(self.FIELDS.findall(stripped.split("},")[0]))
            if "name" in fields and "variant" in fields:
                found[(fields["name"].strip('"'), fields["variant"].strip('"'))] = (fields, line)
        return found

    def written(self):
        return self.rows_of(read(self.lua))

    def grade(self, delve, variant):
        return self.written()[(delve, variant)][0]["ranking"].strip('"')

    def players(self, delve, variant):
        return int(self.written()[(delve, variant)][0]["players"])


# --- 1.1 dedup on identity ---------------------------------------------------

class TestDedup(Fixture):

    def test_baseline_counts_five_players(self):
        self.run_tool("--write")
        self.assertEqual(self.players("Alpha Delve", "Quick Route"), 5)

    def test_resubmission_by_the_same_handle_counts_once(self):
        """The regression this whole change exists for.

        player_f submits, re-runs everything, and submits again. Both codes
        carry the same variants at DIFFERENT times, so they share no exact
        (delve, variant, avg_sec) entry at all -- the old overlap rule saw two
        strangers and counted one human twice.
        """
        self.write_csv(extra=[("player_f", code(SEGMENTS)),
                              ("player_f", code(bump(SEGMENTS, 5)))])
        out = self.run_tool("--write")
        self.assertEqual(self.players("Alpha Delve", "Quick Route"), 6)
        self.assertIn("1 by handle (exact)", out)

    def test_handle_match_ignores_case(self):
        self.write_csv(extra=[("Player_F", code(SEGMENTS)),
                              ("player_f", code(bump(SEGMENTS, 5)))])
        self.run_tool("--write")
        self.assertEqual(self.players("Alpha Delve", "Quick Route"), 6)

    def test_distinct_handles_with_identical_times_both_count(self):
        """Two people who happen to have run the same variants at the same pace
        are two players. The old rule superseded one of them."""
        self.write_csv(extra=[("player_f", code(SEGMENTS)),
                              ("player_g", code(SEGMENTS))])
        self.run_tool("--write")
        self.assertEqual(self.players("Alpha Delve", "Quick Route"), 7)

    def test_blank_handles_fall_back_to_entry_overlap(self):
        """No identity to key on, so the old heuristic is all there is."""
        self.write_csv(extra=[("", code(SEGMENTS)), ("", code(SEGMENTS))])
        out = self.run_tool("--write")
        self.assertEqual(self.players("Alpha Delve", "Quick Route"), 6)
        self.assertIn("by entry overlap", out)

    def test_prefixless_paste_is_salvaged_and_counted(self):
        """A player pasted a partial selection and lost the "DG1;" prefix."""
        raw = code(SEGMENTS)[len("DG1;"):]
        self.write_csv(extra=[("player_f", raw)])
        out = self.run_tool("--write")
        self.assertIn("no DG1; prefix", out)
        self.assertEqual(self.players("Alpha Delve", "Quick Route"), 6)


# --- forward compatibility ---------------------------------------------------

class TestUnknownSections(Fixture):

    def test_a_code_with_a_lab_section_still_parses_every_run(self):
        """2.0.0 clients append a |LAB; section of Labyrinth chamber timings.

        This tool does not rank Labyrinths, so the section is ignored -- but it
        must not cost the LAST run segment, which is what splitting on
        "|MISSING;" alone did: "...~1|LAB" is not an integer count, so the
        segment was dropped and that player's fastest variant vanished.
        """
        raw = code(SEGMENTS) + "|LAB;12345~Chamber of Rites~11~300;12346~Halazzi's Lair~11~420"
        parsed = list(agg.parse_code(raw))
        self.assertEqual(len(parsed), len(SEGMENTS))
        self.assertIn(("Alpha Delve", "Shared Route", 10, 1000, 1), parsed)
        self.assertEqual(list(agg.parse_missing(raw)), [])

        # ...and it survives the whole pipeline, MISSING section included.
        raw2 = raw.replace("|LAB;", "|MISSING;Gamma Delve~frFR~Voie Inconnue|LAB;", 1)
        self.write_csv(extra=[("player_f", raw2)])
        self.run_tool("--write")
        self.assertEqual(self.players("Alpha Delve", "Quick Route"), 6)


# --- player floor ------------------------------------------------------------

class TestPlayerFloor(Fixture):

    def test_variant_below_the_floor_is_withheld_and_its_row_untouched(self):
        before = read(self.lua)
        out = self.run_tool("--write")
        self.assertIn("Thin Route", out.split("variant(s) withheld")[1])
        self.assertEqual(self.grade("Beta Delve", "Thin Route"), "?")
        self.assertIn(self.written()[("Beta Delve", "Thin Route")][1],
                      before)   # the row came through byte-for-byte

    def test_lowering_the_floor_grades_it(self):
        self.run_tool("--write", "--min-submitters", "3")
        self.assertNotEqual(self.grade("Beta Delve", "Thin Route"), "?")


# --- 1.3 / 1.4 hysteresis ----------------------------------------------------

class TestHysteresis(Fixture):

    def test_active_by_default_and_reported(self):
        self.assertIn("Hysteresis ACTIVE", self.run_tool())

    def test_single_band_move_is_held_and_marked(self):
        # Middle Route is published A, measures B, and sits 70s from the edge.
        out = self.run_tool("--write", "--hysteresis", "100")
        self.assertEqual(self.grade("Beta Delve", "Middle Route"), "A")
        self.assertIn("-- HELD (would be B)",
                      self.written()[("Beta Delve", "Middle Route")][1])
        self.assertIn("HELD by hysteresis", out)

    def test_a_clear_move_is_not_held(self):
        # Same row, but 70s is now well past the 30s default.
        self.run_tool("--write", "--hysteresis", "30")
        self.assertEqual(self.grade("Beta Delve", "Middle Route"), "B")

    def test_multi_band_collapse_is_never_held(self):
        """Beta/Shared Route is published F and measures B -- three bands. A hold
        would be self-perpetuating, because the held letter is what gets written
        back and read as the next run's baseline."""
        self.run_tool("--write", "--hysteresis", "100")
        self.assertEqual(self.grade("Beta Delve", "Shared Route"), "B")
        self.assertNotIn("HELD", self.written()[("Beta Delve", "Shared Route")][1])

    def test_shared_variant_name_is_keyed_per_delve(self):
        """Both delves have a variant called "Shared Route" at the same time.
        Alpha's is published A (adjacent -> held); Beta's is published F (three
        bands -> not held). Keyed on the variant name alone, one published grade
        would decide both rows."""
        self.run_tool("--write", "--hysteresis", "100")
        self.assertEqual(self.grade("Alpha Delve", "Shared Route"), "A")
        self.assertEqual(self.grade("Beta Delve", "Shared Route"), "B")


# --- 1.2 published path ------------------------------------------------------

class TestPublishedPath(Fixture):

    def test_default_is_resolved_next_to_the_script_not_the_cwd(self):
        expected = os.path.normpath(os.path.join(
            os.path.dirname(os.path.abspath(agg.__file__)), os.pardir,
            "DelveGuide_Data.lua"))
        self.assertEqual(agg.DEFAULT_PUBLISHED, expected)
        self.assertTrue(os.path.isabs(agg.DEFAULT_PUBLISHED))

    def test_missing_file_says_hysteresis_is_off_and_names_the_path(self):
        missing = os.path.join(self.dir, "nope", "DelveGuide_Data.lua")
        buf = io.StringIO()
        saved = sys.argv
        sys.argv = ["aggregate_rankings.py", self.csv, "--min-tier", "8",
                    "--published", missing]
        try:
            with contextlib.redirect_stdout(buf):
                agg.main()
        finally:
            sys.argv = saved
        out = buf.getvalue()
        self.assertIn("HYSTERESIS IS OFF", out)
        self.assertIn(os.path.abspath(missing), out)


# --- 1.5 round-tripping the block --------------------------------------------

class TestEmitter(Fixture):

    CURATED = ("zone", "mountable", "hasBug", "isBestRoute")

    def test_every_curated_field_survives_a_write(self):
        before = self.written()
        self.run_tool("--write")
        after = self.written()
        self.assertEqual(set(before), set(after))          # no row lost or invented
        for key, (fields, _line) in before.items():
            for name in self.CURATED:
                self.assertEqual(fields[name], after[key][0][name],
                                 f"{name} changed on {key}")

    def test_only_grade_median_and_players_move(self):
        before = self.written()
        self.run_tool("--write")
        after = self.written()
        moved = set()
        for key, (fields, _line) in before.items():
            other = after[key][0]
            moved |= {k for k in set(fields) | set(other) if fields.get(k) != other.get(k)}
        self.assertTrue(moved <= {"ranking", "medianSec", "players"}, moved)

    def test_everything_outside_the_block_is_byte_for_byte(self):
        raw = read(self.lua)
        self.run_tool("--write")
        new = read(self.lua)

        def split(text):
            i = text.index(agg.BLOCK_OPEN)
            j = text.index("\n}\n", i) + 2
            return text[:i], text[i:j], text[j:]

        old_pre, old_block, old_post = split(raw)
        new_pre, new_block, new_post = split(new)
        self.assertEqual(old_pre, new_pre)
        self.assertEqual(old_post, new_post)
        self.assertNotEqual(old_block, new_block)

    def test_comment_lines_inside_the_block_survive(self):
        raw = read(self.lua)
        self.run_tool("--write")
        new = read(self.lua)
        comments = lambda t: [l for l in t.split("\n") if l.strip().startswith("--")]
        self.assertEqual(comments(raw), comments(new))

    def test_crlf_line_endings_are_preserved(self):
        self.write_lua(DATA_LUA, newline="\r\n")
        raw = read(self.lua, "rb")
        self.run_tool("--write")
        new = read(self.lua, "rb")
        self.assertEqual(raw.count(b"\r\n"), new.count(b"\r\n"))
        self.assertEqual(new.count(b"\n"), new.count(b"\r\n"))   # no bare LF crept in

    def test_without_write_the_file_is_untouched(self):
        raw = read(self.lua, "rb")
        out = self.run_tool()
        self.assertEqual(raw, read(self.lua, "rb"))
        self.assertIn(agg.BLOCK_OPEN, out)                       # printed instead

    def test_a_variant_missing_from_the_table_is_appended_not_dropped(self):
        new_route = [("Alpha Delve", "Brand New Route", 10, 700, 1)]
        self.write_csv(extra=[(h + "_x", code(new_route)) for h in BASELINE])
        self.run_tool("--write")
        self.assertIn(("Alpha Delve", "Brand New Route"), self.written())

    def test_a_question_mark_row_gains_median_and_players_when_graded(self):
        self.run_tool("--write", "--min-submitters", "3")
        fields, line = self.written()[("Beta Delve", "Thin Route")]
        self.assertEqual(int(fields["medianSec"]), 900)
        self.assertEqual(int(fields["players"]), 3)
        self.assertIn("players=3", line)


if __name__ == "__main__":
    unittest.main()
