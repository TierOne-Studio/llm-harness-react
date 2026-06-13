# Adoption playbook — pilot, measure, scale

**Audience:** the engineering leader or platform team running the rollout.
**Premise:** never adopt org-wide on faith. One repo, ~30 days, instrumented,
then a data-backed scale/stop decision. The harness's own philosophy — measured,
not believed — applies to adopting it too.

**Companions:** [WHY-A-HARNESS.md](WHY-A-HARNESS.md) (the case) ·
[ARCHITECTURE.md](ARCHITECTURE.md) (internals) · [README](../README.md) (install reference).

---

## The shape of the rollout

```mermaid
flowchart LR
    P0["<b>Phase 0</b><br/>Pick the pilot<br/>(½ day)"]
    P1["<b>Phase 1</b><br/>Install + customize<br/>(~1 day)"]
    P2["<b>Phase 2</b><br/>Run the pilot<br/>(30 days, instrumented)"]
    D{"Scale<br/>decision"}
    P3["<b>Phase 3</b><br/>Scale out<br/>(repo by repo)"]
    S["Steady state:<br/>update cadence +<br/>curation loop"]
    P0 --> P1 --> P2 --> D -->|metrics support it| P3 --> S
    D -->|they don't| STOP["Stop or narrow —<br/>you spent ~2 dev-days<br/>to find out"]
```

---

## Phase 0 — pick the pilot (half a day)

Choose **one repository** and **3–5 engineers** who already use AI agents daily.

Good pilot repo traits:
- A React SPA matching the harness's target shape (Vite + React + TypeScript,
  Vitest/Testing Library, Playwright e2e), actively developed — you want enough
  PRs in 30 days for the metrics to mean something (rule of thumb: ≥30 PRs).
- Has CI already; has at least some test culture (the harness *strengthens*
  test discipline; it can't bootstrap a culture war and a tooling change at once).
- Not your most politically sensitive codebase. Pick a team that opted in.

Capture the **baseline window now**, before anything changes: pull the last
30–60 days of the metrics in the framework below, so "before" isn't
reconstructed from memory later.

## Phase 1 — install and customize (~1 day for the first repo)

```bash
npx @tierone/llm-harness-react init   # copies the harness into ./.ruler
npm i -D @intellectronica/ruler
npx ruler apply                       # generates CLAUDE.md, AGENTS.md, copilot-instructions, …
```

Then the three customization steps that make it *yours* — in priority order:

1. **Fill in `repo-conventions`** (`.ruler/skills/repo-conventions/SKILL.md`).
   It ships as a fill-in skeleton covering the SPA's load-bearing choices:
   project layout, state-management tiers, routing and guards, forms, styling,
   auth and token storage, data fetching, the API-contract seam with your
   backend, testing. This is the highest-leverage hour of the whole rollout:
   it's the file every agent *and* every review subagent treats as "what's
   correct for this repo." A senior engineer on the pilot team should own it.
2. **Copy the enforcement templates** from the `quality-gates` skill into
   place: `templates/ci.yml` → `.github/workflows/`, `templates/pre-commit` →
   `.husky/` (husky + lint-staged), `templates/claude-settings.json` →
   `.claude/settings.json`. This is the deterministic layer — branch protection
   on `main`, typecheck/lint/test/e2e gates on every PR, agent-permission
   denies on push-to-main and prompts on git-write/deploy/dependency commands.
   **Don't skip this step**: the measured finding behind the harness design is
   that both model tiers drop the branch-creation approval pause on some votes,
   and the cost-floor model bends under "URGENT, skip the approval" pressure —
   exactly the command-shaped gates this settings file enforces no matter what
   the model decides.
3. **Decide your spec/ADR locations** if you don't have them (`docs/specs/`,
   `docs/decisions/`) — the spec-steward and reviewer agents will look for them.

Commit all of it. The harness travels with the repo: every engineer (and every
CI agent run) gets it on next pull, with nothing to install per-person.

## Phase 2 — run the pilot (30 days)

Let the team work normally. Three operating notes worth telling them up front:

- **The fast path exists.** Small, low-risk changes (≤2 files, single concern,
  no high-risk surface, no contract-type change, no new dependency — all five
  must hold) skip the review-agent fleet, declared as the first line of the
  change. If everything feels heavyweight, the path declarations are being
  ignored — that's a coaching moment, not a tooling failure.
- **Corrections are capture-able.** When an engineer corrects their agent
  ("stop doing X", "we discussed this"), the harness offers to convert that
  correction into a durable change (a skill edit, a convention line) —
  one proposed change, approval-gated. Encourage the team to say yes: this is
  how the harness adapts to your codebase instead of staying generic.
- **Review-agent findings are free signal.** When a subagent blocks something a
  human reviewer would have caught later (or wouldn't have caught at all),
  note it — those become your best internal adoption stories.

### The metrics framework

Measure the same things before and during. Don't invent targets up front;
collect honestly and read the deltas.

| Metric | Source | What it tells you |
|---|---|---|
| PR cycle time (open → merge) | GitHub | Net velocity effect: does upstream ceremony pay for itself in fewer review rounds? |
| Human review rounds per PR | GitHub | The intended first-order effect: review agents catch issues pre-PR, so humans review cleaner diffs |
| Review findings by source (human / review agent / CI gate) | PR comments + pilot log | Where defects are being caught — the goal is the discovery point moving earlier |
| Defect escape rate (bugs traced to pilot-window PRs) | issue tracker | The quality effect, visible with ~30–60 days' lag |
| Revert / hotfix count | git history | Cheap proxy for escaped defects |
| Test coverage trend on changed files | CI | TDD discipline's footprint — expect this to move quickly |
| Gate events (blocked main-pushes, prompted git writes/deploys) | CI + permission logs | The risk layer working; each event is an incident that didn't happen |
| Engineer sentiment (1 short survey, week 4) | pilot team | Adoption is voluntary in practice; tools engineers resent get routed around |

A lightweight pilot log (a shared doc, one line per notable event: "security
reviewer caught a weakened route guard pre-PR") costs minutes and produces the
concrete examples the scale decision will actually turn on — aggregate numbers
persuade; specific caught-bugs convince.

### What's already measured for you

Your pilot measures **team-level** effects. The **harness-level** behavior is
measured upstream and committed in this package (`eval/baseline.json` +
`eval/history.jsonl`, June 2026, CLI backend) — you don't re-prove it:

- **Routing recall** (39 cases): Haiku-class 1.000 (false-positive rate 0.200,
  8/8 paraphrase stability); Sonnet-class 0.974 (0.545, 6/8).
- **Adherence** (25 cases, majority of 3 votes): Haiku-class 0.840 (safety
  10/13); Sonnet-class 0.920 (safety 11/13, ceremony 8/8).
- **Mutation kill rate** 6/6; **context decay** 1.000 → 0.833 at ~30k →
  0.833 at ~90k filler tokens.

The known soft spot in those numbers — models dropping the branch-creation
approval pause, the cost-floor model caving to manufactured urgency — is what
the Phase 1 step-2 gates exist for; the gate-events row above is where you
watch that layer earn its keep.

If you customize the harness materially (new skills, rewritten instructions)
and want to re-measure, the full suite runs from a checkout of the harness
repository (not your app repo):

```bash
npm test                # deterministic unit tests (CLI + merge engine)
npm run test:harness    # template acceptance + prompt simulations (no model calls)
npm run catalog         # regenerate the skill catalog after adding/editing skills
npm run catalog:check   # CI-style staleness check for the catalog
npm run eval            # live-model: routing + adherence (self-skips without credentials)
npm run eval:routing    # routing only
npm run eval:adherence  # adherence only
npm run eval:mutation   # would the suites catch a deleted gate? (kill rate)
npm run eval:decay      # gate adherence vs. context fill
```

See [EVALS.md](EVALS.md) for metric definitions, gating tolerances, and
re-baselining.

### The decision

At day 30: deltas on cycle time, review rounds, and escapes; the gate-event
count; the caught-findings log; sentiment. Three honest outcomes — scale,
extend the pilot (signal unclear), or stop. Total sunk cost of a stop: about
two developer-days plus a filled-in conventions file you keep anyway.

## Phase 3 — scale out

Repo-by-repo, in descending order of (activity × risk). Per repo it's Phase 1
again, faster: `init`, fill in that repo's `repo-conventions` (the only
genuinely per-repo work), copy the gates, apply. For the backend side of your
estate, the sibling [llm-harness-nest](https://github.com/TierOne-Studio/llm-harness-nest)
applies the same model to API repos — when a feature spans your SPA and its
API repo, the shipped `cross-repo-workspace` skill governs the coordination.
(Monorepos shipping frontend and backend together can use the upstream
[llm-harness-fullstack](https://github.com/TierOne-Studio/llm-harness-fullstack),
the union of the two.)

Two organizational decisions to make explicit at scale:

- **Ownership.** Name a harness owner (platform team or a senior IC per org).
  They review correction-driven skill proposals, decide what graduates from
  one repo's conventions into a shared customization, and run the update cadence.
- **Fork vs. track.** Default: track upstream (`update` performs a 3-way merge
  that preserves local edits; conflicts surface as standard git markers,
  `update --dry-run` works as a CI check, and `update --force` overwrites
  instead of merging when you explicitly want upstream's version). Fork only
  if your customizations diverge structurally — you then own the merge burden
  you just opted into.

## Steady state — the two loops

```mermaid
flowchart TB
    subgraph LOCAL["Per-repo improvement loop (continuous)"]
        C["Engineer corrects an agent"] --> CUR["Correction → ONE proposed<br/>harness change (approval-gated)"]
        CUR --> EDIT["repo's .ruler/ evolves"]
        EDIT --> GEN["ruler apply → all agents<br/>pick it up"]
    end
    subgraph UPSTREAM["Upstream tracking loop (e.g. quarterly)"]
        REL["New harness release<br/>(evals re-baselined, diff reviewable)"] --> UPD["npx @tierone/llm-harness-react update<br/>(3-way merge, local edits kept)"]
        UPD --> RES["resolve any conflict markers,<br/>re-run, ruler apply"]
    end
    EDIT -.->|patterns that prove out get<br/>proposed upstream| REL
```

- **Update cadence:** treat harness updates like dependency updates — a named
  owner, a regular cadence, and the release's eval-baseline diff as the review
  artifact ("what behavior changed in this version" is a committed, inspectable
  number, not a changelog adjective).
- **Curation cadence:** periodically review the accumulated corrections and
  review-agent meta-findings; promote the recurring ones into skills or
  conventions. This is how the harness compounds: every correction an engineer
  makes once stops being something every engineer must remember.

---

## Cost summary (honest)

| Item | Cost | Recurs? |
|---|---|---|
| First-repo install + conventions + gates | ~1 day (senior IC) | once |
| Each additional repo | ~2–4 hours | per repo |
| Pilot instrumentation + log | ~2 hours setup, minutes/week | pilot only |
| Per-change ceremony (full path) | minutes per feature; bounded by the fast path for small changes | continuous |
| Update merge (tracking upstream) | usually zero-conflict; conflicts are standard git markers | per release |
| Harness ownership | a few hours/month at steady state | continuous |

What you get for it is itemized — with the measured evidence — in
[WHY-A-HARNESS.md](WHY-A-HARNESS.md) §4–5.
