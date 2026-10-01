#!/usr/bin/env python3
"""Write RELEASE_NOTES.md: the top section of CHANGELOG.md and nothing else.

    python tools/release_notes.py            # regenerate RELEASE_NOTES.md
    python tools/release_notes.py --check    # exit 1 if it is out of date

.pkgmeta points the packager's manual-changelog at RELEASE_NOTES.md, so this
file is what CurseForge shows as a release's "Changes". Left to itself the
packager builds that text from every commit message since the previous tag --
for 2.0.0, 230 developer notes where players should get the release notes.
The whole CHANGELOG.md would also work, but it is 80 KB and grows with every
release; the one section is what a player updating wants to read.

Run it after editing the top CHANGELOG.md section, the release-date stamp
included. --check is part of the lint gate, so a release cannot be built from
a tree where the two disagree.
"""

import argparse
import os
import re
import sys

REPO = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), os.pardir))
SRC = os.path.join(REPO, "CHANGELOG.md")
OUT = os.path.join(REPO, "RELEASE_NOTES.md")


def top_section(changelog):
    """The first '## [version]' section, under a title line."""
    start = re.search(r"(?m)^## \[", changelog)
    if not start:
        sys.exit("CHANGELOG.md has no '## [version]' heading")
    rest = changelog[start.start():]
    following = re.search(r"(?m)^## \[", rest[1:])
    section = rest[:following.start() + 1] if following else rest
    return "# DelveGuide\n\n" + section.rstrip() + "\n"


def read(path):
    with open(path, encoding="utf-8") as f:   # universal newlines: CRLF reads as LF
        return f.read()


def main():
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("--check", action="store_true", help="verify only, write nothing")
    args = ap.parse_args()

    notes = top_section(read(SRC))
    heading = notes.split("\n")[2]
    if args.check:
        current = read(OUT) if os.path.exists(OUT) else ""
        if current != notes:
            print("RELEASE_NOTES.md does not match the top CHANGELOG.md section (%s)." % heading)
            print("Run: python tools/release_notes.py")
            return 1
        print("OK: RELEASE_NOTES.md is the %s section (%d characters)" % (heading, len(notes)))
        return 0
    with open(OUT, "w", encoding="utf-8", newline="\n") as f:
        f.write(notes)
    print("wrote RELEASE_NOTES.md -- %s, %d characters" % (heading, len(notes)))
    return 0


if __name__ == "__main__":
    sys.exit(main())
