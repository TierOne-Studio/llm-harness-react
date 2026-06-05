#!/usr/bin/env bash
# run-acceptance.sh — acceptance tests for the project-agnostic React harness.
#
# Validates the SHIPPED template tree (skills + agents + instructions.md + ruler.toml)
# directly — it does NOT require `ruler apply` to have run. This is the package's own
# regression gate: it proves the harness stays structurally sound AND free of coupling
# to any specific project (no "velocity" project names, no hardcoded ADR citations,
# no project-specific auth/route-guard symbols leaking into the generic skills/agents).
#
# Run from anywhere:  bash <path>/template/.ruler/tests/run-acceptance.sh
# In the package repo: bash template/.ruler/tests/run-acceptance.sh

set -uo pipefail

# RULER_DIR = the .ruler/ tree this script ships inside (tests/ is one level down).
RULER_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SKILLS="$RULER_DIR/skills"
AGENTS="$RULER_DIR/agents"
INSTRUCTIONS="$RULER_DIR/instructions.md"

for tool in bash grep awk sed find wc; do
  if ! command -v "$tool" >/dev/null 2>&1; then
    echo "PRE-FAIL: required tool '$tool' not found on PATH" >&2
    exit 2
  fi
done

PASS=0
FAIL=0
FAILED_TESTS=""

assert_true() {
  local name="$1" cmd="$2"
  if eval "$cmd" >/dev/null 2>&1; then
    echo "PASS: $name"; PASS=$((PASS+1))
  else
    echo "FAIL: $name (command failed: $cmd)"
    FAIL=$((FAIL+1)); FAILED_TESTS="$FAILED_TESTS $name"
  fi
}

# The canonical skills shipped by this harness.
SKILL_LIST="accessibility ai-ui-patterns async-error-handling bug-investigation bundle-size \
code-simplifier compound-pattern cross-repo-workspace cyclomatic-complexity decision-rules \
design-review documentation-and-adrs failure-mode-analysis frontend-security git-workflow \
hoc-pattern hooks-pattern js-performance-patterns meta-skill-hygiene mixin-pattern \
module-pattern plan-mode playwright-best-practices presentational-container-pattern \
provider-pattern proxy-pattern pushback-templates react-2026 react-composition-2026 \
react-data-fetching react-forms react-patterns react-performance react-render-optimization \
react-routing react-state-management react-testing render-props-pattern repo-conventions \
rlm-explore shadcn tailwind-v4-shadcn tdd-workflow typescript-advanced-types vite vitest"

AGENT_LIST="architect-reviewer code-reviewer qa-validator security-reviewer lessons-curator"

# ---------------------------------------------------------------------------
echo "=== T1: Structure — instructions, ruler config, every skill + agent present ==="
assert_true "T1: instructions.md exists" "test -f '$INSTRUCTIONS'"
assert_true "T1: ruler.toml exists" "test -f '$RULER_DIR/ruler.toml'"
for s in $SKILL_LIST; do
  assert_true "T1: skill '$s' has SKILL.md" "test -f '$SKILLS/$s/SKILL.md'"
done
for a in $AGENT_LIST; do
  assert_true "T1: agent '$a' exists" "test -f '$AGENTS/$a.md'"
done

# ---------------------------------------------------------------------------
echo
echo "=== T2: Project-agnostic — NO coupling to any specific project (the headline) ==="
SEARCH_PATHS="$SKILLS $AGENTS $INSTRUCTIONS"
assert_true "T2: no 'spa-velocity' / 'api-velocity' references" \
  "! grep -rniE 'spa-velocity|api-velocity' $SEARCH_PATHS"
assert_true "T2: no project-specific token-contract symbol (localStorage.bearer_token)" \
  "! grep -rnE 'bearer_token' $SEARCH_PATHS"
# Numbered ADR citations must not appear as real citations. Allowed: generic placeholders
# (<repo-a>/<repo-b>), illustrative markers (ADR-00X), and the cross-repo counter-example.
assert_true "T2: no hardcoded numbered ADR citations (only generic/illustrative allowed)" \
  "! grep -rnE 'ADR-0[0-9][0-9]' $SEARCH_PATHS | grep -vE 'repo-a|repo-b|illustrative|substitute|ambiguous in workspace|ADR-00[XY]'"
assert_true "T2: no 'in this repo, X already exists / established pattern here' assertions" \
  "! grep -rniE 'already in this repo|established pattern (in this repo|here)|tokens in this repo' $SEARCH_PATHS"

# ---------------------------------------------------------------------------
echo
echo "=== T3: instructions.md structure (priority profile P0..P9, generic title) ==="
assert_true "T3: title is generic (not '(spa-velocity)')" \
  "! grep -qE '^# .*\\(spa-velocity\\)' '$INSTRUCTIONS'"
assert_true "T3: title names the framework (React)" "grep -qiE '^# .*React' '$INSTRUCTIONS'"
for p in "P0" "P3" "P5" "P8" "P9"; do
  assert_true "T3: has section $p" "grep -qE '## $p ' '$INSTRUCTIONS'"
done
assert_true "T3: uses MUST/SHOULD/MAY normative language" \
  "grep -q 'MUST' '$INSTRUCTIONS' && grep -q 'SHOULD' '$INSTRUCTIONS' && grep -q 'MAY' '$INSTRUCTIONS'"
assert_true "T3: has Skill Pointers table" "grep -qiE '## skill[ -]pointers' '$INSTRUCTIONS'"
assert_true "T3: has Workflow chains table" "grep -qiE '## workflow chains' '$INSTRUCTIONS'"
assert_true "T3: P0 keeps the no-AI-attribution rule" \
  "grep -qiE 'Co-Authored-By: Claude|AI-attribution' '$INSTRUCTIONS'"

# ---------------------------------------------------------------------------
echo
echo "=== T4: Frontmatter well-formed (every skill + agent has name + description) ==="
for s in $SKILL_LIST; do
  f="$SKILLS/$s/SKILL.md"
  assert_true "T4: skill '$s' has name:" "grep -qE '^name:' '$f'"
  assert_true "T4: skill '$s' has description:" "grep -qE '^description:' '$f'"
done
for a in $AGENT_LIST; do
  f="$AGENTS/$a.md"
  assert_true "T4: agent '$a' has name:" "grep -qE '^name:' '$f'"
  assert_true "T4: agent '$a' has description:" "grep -qE '^description:' '$f'"
done

# ---------------------------------------------------------------------------
echo
echo "=== T5: Consumer-fill-in skeletons (repo-conventions, cross-repo-workspace) ==="
assert_true "T5: repo-conventions is a fill-in skeleton (has FILL IN placeholders)" \
  "grep -qi 'FILL IN' '$SKILLS/repo-conventions/SKILL.md'"
assert_true "T5: repo-conventions keeps the React section scaffold (state + routing + auth)" \
  "grep -qiE 'state' '$SKILLS/repo-conventions/SKILL.md' && grep -qiE 'rout' '$SKILLS/repo-conventions/SKILL.md' && grep -qiE 'auth' '$SKILLS/repo-conventions/SKILL.md'"
assert_true "T5: cross-repo-workspace is generic (repo-a/repo-b placeholders or FILL IN)" \
  "grep -qiE '<repo-a>|<repo-b>|FILL IN' '$SKILLS/cross-repo-workspace/SKILL.md'"

# ---------------------------------------------------------------------------
echo
echo "=== T6: Generic React knowledge retained ==="
assert_true "T6: react-patterns + react-state-management + react-routing present" \
  "test -f '$SKILLS/react-patterns/SKILL.md' && test -f '$SKILLS/react-state-management/SKILL.md' && test -f '$SKILLS/react-routing/SKILL.md'"
assert_true "T6: frontend-security keeps XSS + env-leak teaching" \
  "grep -qiE 'dangerouslySetInnerHTML|XSS' '$SKILLS/frontend-security/SKILL.md' && grep -qiE 'VITE_|env' '$SKILLS/frontend-security/SKILL.md'"
assert_true "T6: react-state-management keeps the four-layer model" \
  "grep -qiE 'four layer' '$SKILLS/react-state-management/SKILL.md'"
assert_true "T6: testing skills present (react-testing + playwright + vitest)" \
  "test -f '$SKILLS/react-testing/SKILL.md' && test -f '$SKILLS/playwright-best-practices/SKILL.md' && test -f '$SKILLS/vitest/SKILL.md'"

# ---------------------------------------------------------------------------
echo
echo "=== T7: Skill-pointer cross-reference integrity (named skills exist) ==="
for s in tdd-workflow design-review plan-mode repo-conventions react-patterns \
         react-state-management react-routing frontend-security decision-rules; do
  assert_true "T7: instructions.md references '$s' AND its skill dir exists" \
    "grep -q '$s' '$INSTRUCTIONS' && test -d '$SKILLS/$s'"
done

# ---------------------------------------------------------------------------
echo
echo "=== T8: No stray dev artifacts in the shipped template ==="
assert_true "T8: no *.bak files under .ruler/" "[ \$(find '$RULER_DIR' -name '*.bak' | wc -l) -eq 0 ]"

# ---------------------------------------------------------------------------
echo
echo "==========================="
echo "Acceptance results: $PASS passed, $FAIL failed"
if [ "$FAIL" -gt 0 ]; then
  echo "Failed:$FAILED_TESTS"
  exit 1
fi
exit 0
