# How DelveGuide ranks delve variants

This is the spec. If the grades ever look wrong, start here.

## The pipeline

**1. The addon times your runs.**
`DelveGuide_HUD.lua` starts a timer when you enter a delve scenario and
`DelveGuide.lua` stops it on `SCENARIO_COMPLETED`. Each completed run is stored
per character with its delve, variant, tier and elapsed time.

**2. `/dg submit` builds a code.**
Format `DG1`, one segment per variant:

```
DG1;Parhelion Plaza~Bombing Run~11~731~4;The Darkway~Ogre Powered~10~880~2
        delve         variant   tier  sec  runs
```

**This is the single most important thing to understand:** the addon sends
**your average and your run count** — not your individual run times. A player
who ran a variant four times sends one number, already averaged. Nothing
downstream can see inside that average or recover the individual runs.

The code is a **complete snapshot** of that player's history, not an increment.
Submitting again resends everything.

**3. The player pastes it into the Google Form.** Handle is optional and only
used for the contributor credits on the Settings tab.

> **Screen handles before shipping them.** They are free text typed by strangers
> and get written verbatim into a Lua string literal that goes out to every user.
> A double quote or backslash breaks the file for everyone; `|cFFFF0000` lets a
> submitter colour or hide text on the Settings tab; and profanity, slurs,
> impersonation or advertising would ship under Thunderz's name.
>
> ```bash
> python tools/screen_handles.py tools/responses.csv --new-only
> ```
>
> It flags, it never decides — exit 1 means read the output. An unflagged handle
> is not "approved", it just did not trip a rule, so **always eyeball the NEW
> list**: no word list catches everything, and a determined submitter will pick
> something no list has.

**4. `aggregate_rankings.py` turns responses into grades.** In order:

| Step | Rule | Why |
|---|---|---|
| Drop resubmissions | A later code repeating ≥70% of an earlier one's exact entries supersedes it | Codes are full snapshots — counting both double-counts that player |
| Tier filter | Ignore any segment below **Tier 8** (`--min-tier 8`) | Times balloon at low tiers; mixing them is meaningless |
| Run floor | Variant needs **≥3 total runs** (`--min-runs`) | One clear is noise |
| Player floor | Variant needs **≥4 different submitters** (`--min-submitters`) | Stops one person grading a variant alone, and caps anyone at 1/4 of a grade |
| Aggregate | **Median** clear time, **one vote per player** (`--stat median --weight players`) | See below |
| Grade | Ratio to the **median** variant across all delves | S = clears in ~4/5 the time of a typical variant |

Grade thresholds live in `SUGGEST` at the top of the script: ≤0.82× the median
variant is S, ≤0.93× A, ≤1.08× B, ≤1.19× C, ≤1.37× D, slower is F.

**Why the median and not the fastest.** Grades were a ratio to the single fastest
variant until 1.9.2, which made the whole table hostage to one sample. Measured
across two consecutive pulls (73 → 84 responses) the fastest variant moved **51s**
while the median moved **17s**, and 15 variants gained a grade purely because the
yardstick got longer — nothing about them had changed. Re-anchoring gives an
identical grade distribution (S:4 A:6 B:12 C:8 D:2 F:1 either way) with **half the
churn: 18 → 9** changes across those same two pulls. Absolute bands ("S = under 12
minutes") would be perfectly stable but need retuning every season as gear
inflates — exactly how the Voidforge item-level thresholds ended up dead at
680/700/720. A median anchor rescales itself.

**5. Paste into `DelveGuideData.delves`.** `[Best]` marks the fastest variant of
each delve that has **≥7 runs**. Variants below the player floor are written as
`?`, **not** left holding a stale estimate — a gap invites data, a wrong grade
quietly misleads.

## Why median and not average

Clear time has a **hard floor and no ceiling**. You cannot clear faster than the
objectives allow, but an AFK, a wipe chain or a disconnect produces a 45-minute
"run" with nothing to cancel it out. The sample is right-skewed, so the mean
is the wrong estimator.

Measured on the 66-submission set (2026-08-22):

- **18 of 33 variants changed grade** depending only on mean vs median.
- *Academy Under Siege*: eight of ten players clear it in 8–15 minutes, but one
  submitter at **49m09s ×2** pulled the mean to 20m13s — shipping it as **F**
  instead of **D**.

**Dropping outliers was tested and is worse.** At 1.5×/2×/2.5×/3× median and by
IQR fence, **20 of 33 variants changed grade depending only on where the cutoff
sat** — that is more arbitrary than the choice of statistic, not less. Trimming
at 1.5× promoted *Calamitous*, the slowest variant in the game, to **S**,
because once you strip the tail the fastest survivor sets the grade. And it
cannot work in principle: `/dg submit` sends pre-averaged values, so trimming
only ever catches whole-player outliers, never the bad run buried inside
someone's four-run average.

The median needs no threshold and discards no data. It *is* outlier rejection,
with the cutoff chosen by the data instead of by us.

Run `--stat mean` to reproduce pre-1.8.8 grades for comparison.

## One vote per player

Each submitter counts **once**, no matter whether they ran a variant 1 time or
40. The grade is the median across players.

This replaced run-weighting in v1.8.8. Under the old scheme the median was
weighted by run count, so a player with 10 runs contributed 10 values — meaning
`--min-submitters` controlled *who got in, not how much weight they carried.*
Measured on the 66-submission set before the change:

- *Invasive Glow* had **15 players and 41 runs, but one player held 14 of them**
  — and their average **was** the grade.
- Worst single-player share was 43%. Nothing exceeded 50%, so nobody could
  quite set a grade alone — but that was luck, not a guarantee.
- In the pathological case (one player with 10 runs, two with 1 each) the heavy
  player holds **83%** of the weight and sets the grade outright.

The statistical objection: 10 runs by one person are not 10 independent samples
of "how long this takes a player." Same character, same gear, same route — they
are strongly correlated, closer to one sample than ten. This is
pseudo-replication, and run-weighting treats it as real information.

With one vote per player and a floor of N players, **no one can ever hold more
than 1/N of a grade** — 25% at the current floor of 4. That is a structural
guarantee, not a threshold that happens to hold today.

A per-player run cap (e.g. 3) was considered and rejected: with only 3 players
a cap of 3 still leaves someone at 60%, so it does not deliver the guarantee.

`--weight runs` restores the old behaviour for comparison.

## Why the floor is 4 and not 3

3 players already prevents a *majority* (33%), so the floor is about sample
quality rather than dominance. At 3, *Olds and Ends* scored **S** — the best
variant in the game — on three people's word. An inflated S on a new delve is
the most damaging error available, because players actively route to it.

Cost of each floor on the 2026-08-22 data:

| Min players | Variants graded | Max any 1 player |
|---|---|---|
| 3 | 33 | 33% |
| **4** | **30** | **25%** |
| 5 | 28 | 20% |
| 6 | 25 | 17% |

Raise it as submissions grow. 5 is the natural next step.

## Known gap: the per-player average

**This is the remaining hole.** `/dg submit` sends each player's *mean*, so an
outlier inside one player's own history is baked in before the aggregator ever
sees it, and nothing downstream can remove it.

Worked example — a player with ten runs, one of which was a 45-minute AFK:

| | |
|---|---|
| Their ten real runs | 12m00s, 12m15s, 11m40s, 12m40s, 12m25s, 11m50s, 12m10s, 12m30s, **45m00s**, 12m05s |
| Their true median | **12m12s** |
| What `/dg submit` sends | **15m27s** ← the mean |

One vote per player limits the *blast radius* (that distorted vote is one of
four or more, and the across-player median suppresses it), but the vote itself
is still wrong.

**The fix is addon-side:** have `GetVariantRunStats` in `DelveGuide.lua` take the
median of the per-variant `elapsed` values instead of `totSec / count`. The raw
per-run times are already in `DelveGuideDB.history` (account-wide, capped at 200
runs, each entry carrying `elapsed`, `variant` and `tierNum`), so this needs no
new data collection and improves every player's **next** submission immediately.

Bump the code prefix to `DG2` when doing it, so the aggregator can tell means
from medians and report the split — both will be in flight during rollout, and
silently blending them is exactly the class of bug this document exists to
prevent.

## Things that quietly break the data

- **Tier logged as 0** discards the run entirely at the `--min-tier 8` gate.
  Before v1.8.7, tier detection sat behind the `hudEnabled` check, so anyone
  with the HUD switched off submitted tier-0 runs. That was **442 of 1,312
  runs (34%)**, and 15 of 64 submissions were *entirely* tier 0.
- **Runs logged with no elapsed time** cannot be submitted at all. Before
  v1.8.7 a race between two `SCENARIO_COMPLETED` handlers destroyed the start
  time before the logger read it. Players hit by this never appear in the
  response data — the bug hides its own victims, so the affected population is
  always larger than the reports suggest.

Both are fixed, but any data pass drawn from before 2026-08-22 still carries
them.

## Running it

```bash
python tools/aggregate_rankings.py tools/responses.csv --min-tier 8
```

Defaults are `--min-runs 3 --min-submitters 4 --stat median --weight players`.
Output goes to
stdout: a per-delve ranked table, any variants withheld for too few players,
unidentified variant names reported by non-English clients, and a Lua snippet to
merge into `DelveGuideData.delves`.

`tools/responses.csv` and `tools/rankings.txt` are **gitignored** — they contain
contributor handles.
