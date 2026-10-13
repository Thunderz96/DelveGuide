#!/usr/bin/env python3
"""CI-only text checks over every tracked .lua file.

Two independent checks, selected by the first argument:

  colors   FATAL. Malformed "|c" colour escapes (see COLOUR CHECK below).
  secrets  WARNING ONLY. Heuristic hunt for secret values (UnitName/UnitGUID/
           aura fields) compared or table-indexed outside a pcall.

Run from anywhere inside the checkout; file discovery uses `git ls-files`.
"""
import os
import re
import subprocess
import sys

REPO = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), os.pardir))


def tracked_lua():
    out = subprocess.run(
        ["git", "ls-files", "*.lua"],
        cwd=REPO, capture_output=True, text=True, check=True,
    ).stdout
    return [p for p in out.splitlines() if p.strip()]


def read_lines(rel):
    with open(os.path.join(REPO, rel), encoding="utf-8", errors="replace") as fh:
        return fh.read().splitlines()


# --------------------------------------------------------------------------
# COLOUR CHECK
#
# A WoW colour escape is "|c" plus EXACTLY eight hex digits (AARRGGBB). A ninth
# digit is swallowed as part of the code and the extra characters render as
# literal text -- the v1.11.x bug where "|cFFAAAAAAAAWidget tier filter" showed
# up in Settings as the literal string "AAWidget tier filter" (fixed in 82575e2).
#
# The obvious pattern the maintainer used to hunt that bug by hand --
# |c[0-9A-Fa-f]{9,} -- is NOT usable as a build gate. Colour codes are almost
# always followed by display text, and a-f/A-F are letters, so any string that
# starts with a hex letter extends the run:
#
#     |cFF00BFFFDelve       -> run "FF00BFFFDe"    (10 hex) -- perfectly valid
#     |cFF888888Effective   -> run "FF888888Effec" (13 hex) -- perfectly valid
#
# The current tree has 60+ such benign hits, so neither ">=9" nor ">=10"
# consecutive hex digits can be fatal without failing on day one. Run length
# alone genuinely cannot separate "|cFFAAAAAAAAWidget" from "|cFF00BFFFDelve" --
# they are the same shape.
#
# What DOES separate them is the alphabet. A mistyped code repeats the code's
# own digits, so the whole run is drawn from a tiny alphabet; a code followed by
# a word pulls in several distinct characters:
#
#     FFAAAAAAAA     -> {F, A}                 = 2 distinct  -> the real bug
#     FF00BFFFDe     -> {F, 0, B, D, E}        = 5 distinct  -> text
#     FF888888Effec  -> {F, 8, E, C}           = 4 distinct  -> text
#
# So: FATAL when the maximal hex run after "|c" is >= 10 characters AND uses at
# most 2 distinct hex characters (case-insensitively). That catches the exact
# doubled-code typo that shipped, and produces zero hits on the current tree.
#
# It is deliberately narrow: a run like "|cFF00BFFF0Delve" (one stray digit from
# a different alphabet) would slip through. Every >=9 run is therefore counted
# and printed as an informational line so a wider pattern is one edit away if a
# different shape of this bug ever ships.
# --------------------------------------------------------------------------
COLOUR_RE = re.compile(r"\|c([0-9A-Fa-f]+)")


def check_colors(paths=None):
    failures, informational = [], 0
    for rel in paths or tracked_lua():
        for n, line in enumerate(read_lines(rel), 1):
            for m in COLOUR_RE.finditer(line):
                run = m.group(1)
                if len(run) < 9:
                    continue
                informational += 1
                if len(run) >= 10 and len(set(run.upper())) <= 2:
                    failures.append((rel, n, run, line.strip()))

    print(f"|c escapes with 9+ hex characters (mostly benign, code + text): {informational}")
    if not failures:
        print("No malformed |c colour codes.")
        return 0

    print(f"\n!! {len(failures)} malformed |c colour code(s) -- |c takes EXACTLY 8 hex digits:")
    for rel, n, run, line in failures:
        print(f"   {rel}:{n}: |c{run}  ({len(run)} hex digits, should be 8)")
        print(f"      {line}")
    return 1


# --------------------------------------------------------------------------
# SECRET-VALUE CHECK (warning only, never fails the build)
#
# In Midnight, UnitName/UnitGUID on a protected unit and some aura fields return
# SECRET values. Tainted code that compares or table-indexes one raises
# "attempt to compare ... (a secret string value)" -- GitHub #8, 215 errors in
# one raid report, because the fetch was inside a pcall but the comparison was
# not (see the comment above DelveGuide.OnTargetChanged).
#
# The heuristic: a trigger call whose line, or the line after it, contains a
# comparison or a table index, where that USE is not inside a pcall bubble.
#
# "Inside a pcall bubble" has to be tracked properly rather than by grepping for
# "pcall" nearby, because the #8 regression looked like this:
#
#     pcall(function() targetName = UnitName("target") end)   <- bubble closes here
#     if not targetName or targetName == "" then return end   <- OUTSIDE, raises
#
# A nearby-pcall test suppresses exactly the bug it is meant to catch. So a line
# opening "pcall(function()" without closing it on the same line opens a bubble
# that a leading "end)" closes; a self-contained one-line pcall protects only
# its own line. Verified against 5c7c3fc^ (flags it) and the current tree (silent).
#
# It is crude by design and cannot see across function boundaries, so it only
# ever WARNS. Silence a reviewed line with a "-- dg-secret-ok" marker on the
# trigger line or the one after it.
# --------------------------------------------------------------------------
TRIGGER_RE = re.compile(
    r"UnitName\s*\(|UnitGUID\s*\(|UnitAura\w*\s*\(|GetAuraData\w*\s*\(|GetPlayerAuraBySpellID\s*\("
)
USE_RE = re.compile(r"==|~=|(?<![-<>=])<(?!=)|(?<![-<>=])>(?!=)|\[")
PCALL_OPEN_RE = re.compile(r"pcall\s*\(\s*function")
PCALL_CLOSE_RE = re.compile(r"^\s*end\s*\)")
MARKER = "dg-secret-ok"


def pcall_bubbles(lines):
    """True for each line that sits inside a multi-line pcall(function() ... end)."""
    inside, depth = [], 0
    for line in lines:
        opens = 1 if (PCALL_OPEN_RE.search(line) and "end)" not in line.replace(" ", "")) else 0
        closes = 1 if (PCALL_CLOSE_RE.match(line) and depth > 0) else 0
        inside.append(depth > 0)
        depth += opens - closes
    return inside


def check_secrets(paths=None):
    hits = []
    for rel in paths or tracked_lua():
        lines = read_lines(rel)
        inside = pcall_bubbles(lines)
        for i, line in enumerate(lines):
            code = line.split("--", 1)[0]
            if not TRIGGER_RE.search(code):
                continue
            nxt = lines[i + 1] if i + 1 < len(lines) else ""
            if MARKER in line or MARKER in nxt:
                continue
            # A use is guarded only if its OWN line is inside a bubble, or it
            # shares a line with a self-contained pcall.
            same_ok = inside[i] or "pcall" in code
            next_ok = (i + 1 < len(lines) and inside[i + 1]) or "pcall" in nxt
            unguarded = (USE_RE.search(code) and not same_ok) or (
                USE_RE.search(nxt.split("--", 1)[0]) and not next_ok
            )
            if unguarded:
                hits.append((rel, i + 1, line.strip()))

    if not hits:
        print("No unguarded secret-value comparisons found.")
        return 0

    print(f"::warning::{len(hits)} possible unguarded secret-value use(s) -- review, "
          f"then add '-- {MARKER}' to silence a line")
    for rel, n, line in hits:
        print(f"::warning file={rel},line={n}::possible unguarded secret-value use: {line}")
        print(f"   {rel}:{n}: {line}")
    return 0  # warning only, never fails the build


if __name__ == "__main__":
    which = sys.argv[1] if len(sys.argv) > 1 else ""
    # Explicit paths are for spot-checking one file; CI passes none and the
    # check walks every tracked .lua.
    paths = sys.argv[2:] or None
    if which == "colors":
        sys.exit(check_colors(paths))
    if which == "secrets":
        sys.exit(check_secrets(paths))
    print(f"usage: {sys.argv[0]} colors|secrets [file ...]", file=sys.stderr)
    sys.exit(2)
