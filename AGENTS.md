# AGENTS.md — Ladder

Instructions for any AI agent working in this repository.

Read `SPEC.md` before proposing anything. `decisions.md` records why
things are the way they are, with dates; treat it as binding. If a
request conflicts with either file, say so instead of silently
complying.

---

## What this is

Ladder computes, deterministically, what a person is missing to reach
the next level of a published competency framework, and uses an LLM only
to write a narrative about a gap the model did not compute.

It is **not** a performance evaluation, a rating, a readiness verdict,
or an activity tracker. This is not a naming preference — the whole
architecture exists to keep it that way.

---

## Stack and layout

```
ladder/
├── AGENTS.md
├── SPEC.md
├── decisions.md
├── README.md
├── api/       Rails 7+ API-only, SQLite, Minitest
└── client/    Vite + React
```

Two servers in development: Rails on `:3000`, Vite on `:5173`, with
Vite proxying `/api` to Rails.

```bash
cd api    && bin/rails s          # :3000
cd client && npm run dev          # :5173
cd api    && bin/rails test       # all tests
cd api    && bin/rails db:seed    # reset demo data
```

**Do not add gems or npm packages without asking.** The dependency list
is part of the design.

---

## The four rules that cannot be broken

These map to the safety concerns in `decisions.md`. A change that
violates one of these is wrong even if it passes tests and the user
asked for it — flag it instead.

**1. The system never decides a person's level.**
`Person#level_position` is human input. No service, job, callback, or
controller may write it except the one explicit manual endpoint. Never
add logic that infers, suggests, or auto-advances a level.

**2. The LLM never decides anything.**
Its response schema has no field for level, readiness, score, or
recommendation-to-promote — and none may be added. It receives an
already-computed gap and returns prose. If the model returns anything
that fails validation, fall back to the deterministic template.

**3. Visibility is resolved before data is loaded or serialized.**
`VisibilityResolver` runs first, always. Never filter in the serializer,
never filter in React, never load a full record and hide fields in the
view. The LLM payload is built from the already-filtered set, never from
the raw record.

**4. No endpoint compares people.**
No rankings, no percentiles, no team averages, no "above/below" of any
kind. A viewer may only ever reach their own data or that of a direct
report. Anything else returns **404**, never 403 — a 403 confirms the
record exists.

---

## Where logic lives

- **Service objects** (`app/services/`) own business logic:
  `GapCalculator`, `VisibilityResolver`, `NarrativeGenerator`. These are
  plain Ruby, no HTTP, no session, no Rails magic — so they are trivially
  testable.
- **Models** own associations, validations, and scopes. No business
  rules.
- **Controllers** parse params, call one service, render. Thin.
- **React** renders. It owns no business logic, no permission logic, and
  no derived state that the API should have computed.

If a rule from `SPEC.md` §5 or §6 ends up in a controller, a serializer,
or a component, that is a bug.

---

## How to work with Santiago

**Plan before code.** For each sprint, state: goal, scope, out of scope,
and how it will be validated. Wait for approval before writing code.

**One sprint at a time.** Follow the sprint order in `SPEC.md` §10. The
deterministic core and its tests come before any UI, and the LLM layer
comes second to last. Do not jump ahead because something seems quick.

**Small diffs.** Santiago reviews every diff and will push back on at
least one thing per sprint. Make that easy: no drive-by refactors, no
reformatting untouched files, no files that were not in the plan.

**Tests come with the code, not after.** For `GapCalculator` and
`VisibilityResolver`, write the test first. The acceptance criteria in
`SPEC.md` §9 are the list; each one is a test.

**Save diagrams, don't let them live only in chat.** Whenever you produce
a Mermaid diagram (sequence, flow, or otherwise) to explain a sprint's
design, also save it as its own file under `docs/diagrams/`, named
`sX-short-description.md` (e.g. `s2-visibility-flow.md`), with the
Mermaid source in a ```mermaid fenced block. GitHub renders it natively
when the file is viewed there — no extra tooling needed. Mention the
new file path in the sprint summary so it doesn't go unnoticed.

**Explain the Rails you introduce.** Santiago has never used Rails —
this build is how he plans to learn it. When you first use a Rails idiom
(scopes, `has_many :through`, strong params, callbacks, concerns,
migrations, fixtures), add one sentence in the sprint summary saying
what it does and why it fits here. One sentence, not a tutorial, and
only the first time.

**Say when something is a bad idea.** If a request would break one of
the four rules, create scope creep, or not fit in the remaining time,
say so plainly and propose the smaller version.

**At the end of every sprint, list every command I should run to confirm
it actually worked** — not just the commands used to build it. Include
at least: a way to directly inspect the resulting state (not just
trust console output — e.g. open a DB GUI, query the actual rows, view
the actual file/response), any relevant tests, and a git status/diff
check for anything outside this sprint's scope. For each command, say
in one line what it shows me and why it matters for this sprint
specifically. Also, suggest good commit messages and practices for each commit.  Never commit automatically, I just wan't the information for guidance. 

**After every sprint**: State which files changed, what I should manually check before approving, any assumptions you made, and whether you deviated from SPEC.md.

---

## Git and PR workflow

This is practiced as if it shipped to Factorial, not simulated. Real
branches, real commits, real PRs on GitHub, real review before merge.
This is itself a stated goal of the project (`SPEC.md` §1b) — Santiago
has not worked collaborative, professional-grade git before, and this
repo is where that habit gets built. Do not shortcut it, and do not
skip it "to save time" without asking first.

**Branches, one per PR bundle, not one per sprint:**

| Branch | Covers |
|---|---|
| `sprint/s0-scaffold` | S0 |
| `sprint/s1-s2-core` | S1 + S2 — the deterministic core, the heart of the safety story |
| `sprint/s3-ui` | S3 |
| `sprint/s4-s5-ai-polish` | S4 + S5 |
| `sprint/s6-hr-stretch` | S6, only if reached |

Branch off `main`. Never commit directly to `main`.

**Commits are small and logical, not one dump per branch.** Use
Conventional Commits, in English:

```
feat: add core migrations for people, criteria, evidences, snapshots
feat: add self-referential manager association to Person
chore: add idempotent seed from Dropbox framework
docs: readme with framework attribution
test: add GapCalculator boundary cases A1-A5
```

One commit per coherent step within the branch's work, so the PR diff
tells a story instead of arriving as a single wall of code.

**Opening the PR:**

```bash
git push -u origin sprint/s0-scaffold
gh pr create --title "S0: scaffold" --body "..."
```

The PR description follows the same shape as the sprint plan Santiago
already approved: goal, scope, what's explicitly out of scope, how it
was validated. Copy it from the approved sprint plan rather than
rewriting it.

**Then stop.** Never merge a PR without Santiago's explicit approval.
He reviews the diff on GitHub (or via `gh pr diff`) and, per the
existing sprint discipline, flags at least one thing before it merges.
This is the review habit `SPEC.md` §1b exists to build — do not let it
become a formality that gets rubber-stamped.

**Merge:** squash merge once approved (`gh pr merge --squash`). Keeps
`main` readable as one commit per sprint bundle while the PR itself
preserves the full commit history for anyone reading it later.

**Never force-push. Never rewrite `main` history.**

**`.gitignore`:** set this up in the very first commit on `main`, before
any Rails or Node files exist, so nothing gets committed by accident on
S0:

```
# Rails
/api/config/master.key
/api/log/*
/api/tmp/*
/api/storage/*
!/api/storage/.keep
/api/db/*.sqlite3
/api/db/*.sqlite3-*

# Node
/client/node_modules/
/client/dist/

# OS
.DS_Store
```

`db/schema.rb` is **not** ignored — it's the readable source of truth
for the database structure and belongs in the diff.

---

## Conventions

**Language:** English everywhere — code, comments, UI, seed data. The
source framework is in English and translating it introduces drift in
the text that is the source of truth for the computation.

**Vocabulary — use:** gap, criterion, evidence, covered, uncorroborated,
next steps, snapshot, cycle.

**Vocabulary — never use, in code or UI:** evaluation, review, rating,
score, grade, readiness, performance, ranking. See D7 in
`decisions.md`.

**Tests:** Minitest, Rails default. Do not add RSpec.

**Migrations:** one migration per structural change, reversible.

**Seed:** `db/seeds.rb` must be idempotent — running it twice produces
the same state, not duplicates.

**Attribution:** the competency framework in the seed comes from the
publicly published Dropbox Engineering Career Framework. Every criterion
carries a `source` column, and the README credits and links the source.
Do not strip or paraphrase away that attribution.

---

## Scope discipline

This is a time-boxed build of roughly four to five hours. Out of scope,
deliberately, per `SPEC.md` §11: real auth, deploy, framework CRUD,
narrative evals, notifications, background jobs, cross-person aggregate
views, persistent audit log.

If time runs short, what gets cut is the progress chart and the HR
stretch — never the tests that prove the boundary.

