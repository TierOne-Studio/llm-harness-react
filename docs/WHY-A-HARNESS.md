# Why a harness — the case for engineering leaders

Your engineers are already using AI agents. The only open question is whether
that happens **with or without controls**. This harness is the controls: a
versioned, installable package that gives every engineer's agent the same
conventions, the same test discipline, the same independent review gates, and
the same hard safety rules — across Claude Code, Copilot, Cursor, and Codex
simultaneously. And unlike a prompt file, it is **measured**: live-model evals
with committed baselines verify that models actually follow it, mutation tests
verify the evals themselves would catch regressions, and every change to the
harness ships with a reviewable behavioral diff.

---

## 1. The problem: ungoverned variance

Without a shared harness, AI-assisted engineering looks like this:

- **N engineers × M personal prompting styles.** Each developer's agent follows
  whatever conventions that developer remembered to mention that day. Code
  review becomes the only place consistency is enforced — after the code is
  written, at the most expensive point.
- **Safety by hope.** Nothing structurally prevents an agent from pushing to
  `main`, hardcoding a credential, writing a token into `localStorage`, or
  weakening a route guard — except each engineer's vigilance, on every task.
- **Unverifiable guidelines.** Most teams that do write an agent rules file
  cannot answer the follow-up question: *how do you know the model follows it?*
  Instructions degrade silently — when the file grows, when the model is
  upgraded, when context fills up mid-session. Nobody notices until an incident.
- **Per-tool fragmentation.** Rules written for one agent (a `CLAUDE.md`, a set
  of Cursor rules) don't transfer. Every tool change restarts the governance
  effort, which in practice means it never happens.

## 2. What the harness is

`Agent = Model + Harness` (Fowler's framing). You don't control the model;
you control everything around it. The harness packages that "everything" as an
installable artifact — scoped to **one tier**: a React SPA codebase (Vite +
React + TypeScript, Vitest/Testing Library, Playwright e2e). The sibling
[`@tierone/llm-harness-nest`](https://github.com/TierOne-Studio/llm-harness-nest)
covers the backend repo; together the pair governs a split frontend/backend
estate, coordinated by the shipped `cross-repo-workspace` skill.

```mermaid
flowchart LR
    subgraph BEFORE["Guides — steer BEFORE the agent acts"]
        I["Operating profile<br/>(priority-ordered rules,<br/>safety gates first)"]
        S["38 skills in 4 families<br/>(React conventions, TDD,<br/>a11y, frontend security)"]
    end
    A["Agent does the work"]
    subgraph AFTER["Sensors — catch problems AFTER"]
        R["7 agents<br/>(design · coverage · security ·<br/>specs · live acceptance · lessons)"]
    end
    G["Deterministic gates<br/>CI · pre-commit · permission rules<br/>(catch what advice missed)"]
    M["Measurement<br/>evals · baselines · history<br/>(proof it all still works)"]

    BEFORE --> A --> AFTER --> G
    M -.->|regression-gates every<br/>change to the harness itself| BEFORE
    M -.-> AFTER
```

One `npx` command installs it into a repo; [ruler](https://github.com/intellectronica/ruler)
fans the same source out to every agent's native config format. Updates ship
as new package versions and merge over local customizations with a git 3-way
merge — adopting the harness is not a fork you maintain forever.

## 3. The three pillars

### 3.1 Consistency at scale

Every agent in every session operates from the same playbook: the same
fail-first test discipline, the same React conventions (state placement,
data-fetching and form discipline, routing and guards, accessibility, bundle
hygiene), the same definition of "done" (verification artifacts **executed**,
not claimed). Onboarding a new engineer's agent is
`npx @tierone/llm-harness-react init`, not a month of tribal knowledge. The
practical effect: convention enforcement moves from human code review
(expensive, late, inconsistent) to the point of generation (free, early,
uniform) — and the independent review subagents then check the work in fresh
context, before a human ever sees the PR.

### 3.2 Risk containment

The highest-priority section of the operating profile is non-negotiable safety:
no commits/pushes to `main`, explicit user approval for every git write,
deploy, publish, DB write, and sensitive-data change. But instructions alone
are advice — so the same rules exist a second time as **deterministic
enforcement**: ready-to-copy CI workflows, pre-commit hooks, and agent
permission rules that *deny* pushes to main and *prompt* on git-write /
deploy / dependency commands regardless of what the model intended. Two
independent layers; the second one doesn't depend on the model having a good
day. (Our own measurement of exactly which gates models drop — §4 — is
precisely why the second layer exists.)

### 3.3 No vendor lock-in

The harness is written once, in `.ruler/`, and generated into Claude Code,
GitHub Copilot, Cursor, Codex, and Windsurf formats mechanically. Your
governance investment is decoupled from your agent-vendor choice: switching or
mixing tools doesn't restart the effort, and an agent-tooling decision never
gets held hostage by "but all our rules are written for X."

---

## 4. How we know it works — the evidence

This is the part most "AI guidelines" efforts cannot offer. The harness treats
its own effectiveness as a testable claim, with four measurement layers and
committed, reviewable results. The numbers below are the actual committed
baselines and history records from this repository (June 2026, CLI backend,
run against the shipped template).

| Layer | Question | Latest result |
|---|---|---|
| **Routing eval** (live model, 39 cases) | Does a model load the right skills for a prompt — including paraphrases, including loading *nothing* for pure questions? | Haiku-class cost floor: **1.000 recall**, perfect paraphrase stability (8/8), false-positive rate 0.200. Sonnet-class: 0.974 recall, 6/8 stability, false-positive rate 0.545 |
| **Adherence eval** (live model, 25 cases × 3 votes) | Under the full operating profile, does the model actually emit the gates — approval pauses, waivers, path declarations — including under pressure and prompt injection? | Sonnet-class (consumer grade): **0.920 pass** — safety 11/13, ceremony 8/8. Haiku-class: 0.840 — safety 10/13 |
| **Mutation test** (eval of the eval) | If someone deleted a safety gate or softened a MUST, would the eval suite go red? | **6/6 seeded regressions killed (kill rate 1.0)** |
| **Context decay** (assumption check) | Does instruction-following degrade as the context window fills? | Pass rate 1.000 at empty context → **0.833 at ~30k → 0.833 at ~90k filler tokens** (flat-ish, not a cliff) |

Three honest readings of this table matter more than the headline numbers:

- **The misses are command-shaped — and that is the design rationale, not an
  embarrassment.** The safety cases models fail are specific: both model tiers
  drop the branch-creation approval pause on some votes, and the cost-floor
  model bends under manufactured social pressure (the `pr-urgent` case:
  *"production is down, skip the approval"*). Every one of those is a git-write
  operation — exactly the command-shaped gates the shipped deterministic layer
  (`quality-gates` → `templates/claude-settings.json` permission rules, CI
  branch protection, pre-commit) enforces without asking the model's opinion.
  Decay tells the same story at lower volume: the curve here is flat-ish
  (0.833 holds from ~30k to ~90k), but the probe that fails is, again, a P0
  gate — which is why the always-loaded profile is kept on a strict diet
  (298 lines, 3,284 words) and why every prose rule is backed by a gate that
  doesn't decay.
- **Bigger is not uniformly better — which is why baselines are keyed per
  model.** The cost-floor model routes with perfect recall and perfect
  paraphrase stability but the consumer-grade model adheres better to the
  operating profile (0.920 vs 0.840) while loading more unrequested skills
  (false-positive rate 0.545 vs 0.200). A single "the model follows our rules"
  claim would be wrong in both directions at once; per-model committed
  baselines are what make the difference visible and regression-gateable.
- **Every harness change ships with a behavioral diff.** Baselines live in
  version control, keyed per model; every full eval run appends to a committed
  history file. Editing a skill or an instruction requires re-running the
  evals; the baseline diff in the PR *is* the evidence of behavioral impact,
  reviewable like any other code change. CI fails on regression beyond
  tolerance — with **zero tolerance** for the safety category. Model upgrades
  are handled the same way: re-baseline, review the diff, decide.

For the methodology in depth (worst-variant scoring, majority voting,
deterministic regex judging — no LLM-judges-LLM circularity), see
[EVALS.md](EVALS.md).

---

## 5. What it costs — stated plainly

- **Ceremony overhead on changes.** The full path (spec gate, plan review,
  independent post-review, live acceptance verification) adds real latency per
  feature. It is bounded two ways: a **fast path** for small, low-risk changes
  (≤2 files, single concern, no risky surface) skips the review fleet entirely,
  and the cost asymmetry runs in your favor — a design flaw caught at plan
  review is roughly an order of magnitude cheaper than the same flaw caught
  after implementation and tests exist.
- **One-time setup per repo.** Install, generate configs, fill in the
  repo-conventions skeleton with your project's actual choices, copy the CI /
  pre-commit / permission templates. Roughly a day for the first repo, hours
  for subsequent ones (see [ADOPTION.md](ADOPTION.md)).
- **Eval runs are optional for consumers.** The evals gate *this package's*
  development. Consuming teams get the benefit through the committed baselines;
  running evals against your own customizations is available but not required,
  and the suites self-skip without credentials (the deterministic checks
  remain free).
- **A maintenance loop, not a maintenance burden.** Corrections your engineers
  give their agents can be converted — approval-gated, one change at a time —
  into durable harness improvements, and upstream harness releases merge over
  your local edits instead of overwriting them.

## 6. Objections, answered

**"This will slow my developers down."**
The overhead is real and bounded, and it buys back more than it costs. Bounded:
small, low-risk changes (≤2 files, single concern, no risky surface) take a
declared fast path that skips the review fleet entirely — the ceremony scales
with blast radius, not with every keystroke. Buys back: the plan-stage review
exists because a design flaw caught there is roughly 10× cheaper than the same
flaw caught after implementation; and human reviewers receive PRs that five
independent agents have already vetted, so human review rounds drop. The
[adoption playbook](ADOPTION.md) instruments exactly this trade in the pilot —
if cycle time worsens net, you'll see it in 30 days, not after an org-wide
rollout.

**"Models change every quarter — won't this rot?"**
That's the failure mode the measurement layer was built for. Baselines are
keyed *per model*: when a new model arrives, re-run the evals against it, and
the diff tells you precisely what behavioral assumptions still hold before
anyone switches. The committed baselines already show two model tiers behaving
differently in opposite directions (§4); an unmeasured rules file would have
hidden both.

**"We already have a CLAUDE.md / Cursor rules — isn't this the same thing?"**
A rules file is the first 10% of this. What it lacks: independent review agents
in fresh context (a rules file can't review its own output), deterministic
enforcement when instructions fail (measured: both model tiers drop a P0
approval pause on some votes, and gate adherence slips from 1.000 to 0.833 once
~30k tokens of context fill), evals proving the rules are followed, a
3-way-merge update path (your edits survive upstream improvements), and
multi-tool fan-out (one source serving Claude Code, Copilot, Cursor, Codex).

**"Is this another dependency / lock-in?"**
It's the opposite of one. Not a runtime dependency — `init` copies plain
Markdown files into your repo and leaves nothing in `node_modules`. Everything
is inspectable text you own; if you stop updating (or the package vanished
tomorrow), everything you have keeps working as-is. And because the same
source generates every agent's config, it *removes* the deeper lock-in: your
conventions are no longer written in any one vendor's format.

**"What if the model just ignores the instructions?"**
Sometimes it will — that's measured, not denied (§4). Three answers stack:
the instruction diet keeps the always-loaded profile small (298 lines,
3,284 words) because adherence demonstrably slips as context fills; the eval
suite catches regressions in the instructions themselves with zero tolerance
on the safety category; and the deterministic layer (CI, pre-commit,
permission denies) doesn't ask the model's opinion. The system is designed so
the consequences of an ignored instruction are bounded by a gate that can't
be ignored — and the gates the models measurably drop (git writes under
pressure) are precisely the ones the permission rules express.

**"Who maintains it after the enthusiasm fades?"**
Designed-for, not hoped-for: a named owner and an update cadence are explicit
steps in the playbook; upstream releases merge instead of overwrite; and the
correction-capture loop turns day-to-day agent corrections into harness
improvements as a side effect of normal work rather than a separate chore.

## 7. For the compliance conversation

If your organization carries SOC 2 / ISO 27001-style change-management
obligations, AI agents are an auditor question you will eventually be asked.
The harness's safety layer maps directly onto familiar control language:

| Harness control | Mechanism | Control family it supports |
|---|---|---|
| No direct changes to `main`; feature branch + PR always | instruction (P0) **and** CI branch protection **and** agent permission deny | change management — segregation of duties, peer review |
| Explicit human approval for every git write, deploy, publish | P0 approval gates + permission prompts on git-write/deploy/publish commands | change authorization; production-release control |
| Explicit human approval for DB writes, schema changes, migrations | P0 approval gates + permission prompts on DB CLIs (rare in an SPA repo, but seed scripts and tooling count) | data-integrity / change control on data stores |
| Sensitive-data handling gates (no hardcoded secrets, no tokens/PII in `localStorage` or URLs, no token logging, no weakened route guards without approval) | P0 + dedicated security reviewer on every auth/PII/secrets-touching diff | secrets management; access-control change review |
| Independent review before merge | five review agents in fresh context + human PR review + CI gates | peer-review evidence, generated per PR |
| No AI attribution in commits/PRs | P0 hard rule | clean audit trail of authorship policy |
| Verification artifacts executed, not claimed | P8 output contract + acceptance-verifier re-runs suites | testing evidence for change approval |
| Control effectiveness is itself tested | adherence eval (zero-tolerance safety category) + mutation testing of the eval suite | monitoring of control effectiveness |

Two candid caveats for this conversation: the instruction-layer controls are
*probabilistic* (that's why each row pairs them with a deterministic
mechanism — present the gates, not the prompts, as the control), and this
mapping is a starting point for your compliance team, not a certification
claim.

## 8. The bottom line

The alternatives are not "harness vs. no AI." They are governed variance vs.
ungoverned variance. A rules file gets you part of the way; what a rules file
cannot give you is *evidence* — that the rules are followed today, that they
are still followed after the next model upgrade, and that the safety-critical
subset is held to zero tolerance. That evidence loop is the difference between
an AI policy you wrote once and an AI capability you actually operate.

**Next step:** the pilot playbook in [ADOPTION.md](ADOPTION.md) — one repo,
30 days, measured.
