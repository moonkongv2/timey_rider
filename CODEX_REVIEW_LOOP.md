# Codex Review Loop Protocol

## Purpose
Use a newly launched reviewer agent only as a reviewer. The primary Codex keeps responsibility for implementation decisions, code changes, verification, and final reporting.

The reviewer agent is a helper, not an implementer.

## Roles

### Primary Codex
- Reads this protocol before starting a review loop.
- Summarizes the task, implemented changes, design intent, and constraints for the reviewer.
- Runs the selected reviewer agent with a review-only prompt.
- Saves every loop artifact under `codex_reviews/`.
- Reads the reviewer output and classifies each finding.
- Applies only findings judged valid and in scope.
- Runs relevant formatting, analysis, and tests.
- Reports accepted, rejected, and blocked findings to the user.

### Reviewer Agent
- Reviews only the current scope provided by the primary Codex.
- Does not modify files.
- Does not run broad refactors.
- Focuses on correctness, regressions, edge cases, missing tests, and mismatches with the stated task.
- Ignores style-only preferences, unrelated existing issues, and broad architectural suggestions unless they directly affect correctness.

## Reviewer Selection
Default reviewer:
- `codex`

Available reviewers:
- `codex`: run a newly launched Codex reviewer.
- `agy`: run Antigravity through `/Users/moonkong/.local/bin/agy --print --sandbox`.

Reviewer selection shortcuts:
- `code-review-loop N [scope]`: use the default `codex` reviewer.
- `agy-code-review-loop N [scope]`: use the `agy` reviewer.
- `codex-code-review-loop N [scope]`: explicitly use the `codex` reviewer.
- `plan-review-loop N <plan>`: use the default `codex` reviewer.
- `agy-plan-review-loop N <plan>`: use the `agy` reviewer.
- `codex-plan-review-loop N <plan>`: explicitly use the `codex` reviewer.

Do not use `agy --dangerously-skip-permissions` for review loops unless the user explicitly asks for it.

## Loop Inputs
- Loop count: provided by the user.
- Review scope: current git diff unless the user specifies another scope.
- Artifact directory: `codex_reviews/`.
- Review files:
  - `codex_reviews/loop_N_prompt.md`
  - `codex_reviews/loop_N_review.md`
  - `codex_reviews/loop_N_decision.md`
  - `codex_reviews/loop_N_verification.txt`
  - `codex_reviews/summary.md`

## Invocation Shortcuts
The primary Codex should read and apply this protocol only when the user explicitly asks for a review loop or uses one of the shortcuts below. Do not apply this protocol to unrelated implementation, debugging, explanation, or commit requests.

### `code-review-loop N [scope]`
Run a code review loop using this protocol.

Defaults:
- Review mode: code diff review.
- Loop count: `N`.
- Scope: current git diff unless `[scope]` is provided.
- Reviewer: selected reviewer agent, reviewer only.
- Artifacts: `codex_reviews/`.
- Apply valid findings to code.
- Run relevant verification.
- Do not commit unless the user explicitly asks.

Examples:
- `code-review-loop 1`
- `code-review-loop 2`
- `code-review-loop 1 lib/screens/result_screen.dart`
- `agy-code-review-loop 1`
- `codex-code-review-loop 1 lib/screens/result_screen.dart`

### `plan-review-loop N <plan>`
Run a plan review loop using this protocol.

Defaults:
- Review mode: plan review.
- Loop count: `N`.
- Scope: provided plan file or pasted plan text.
- Reviewer: selected reviewer agent, reviewer only.
- Artifacts: `codex_reviews/`.
- Apply valid findings to the plan only.
- Do not modify implementation code.
- Do not commit unless the user explicitly asks.

Examples:
- `plan-review-loop 1 docs/feature_plan.md`
- `plan-review-loop 2 docs/timer_result_plan.md`
- `plan-review-loop 1` followed by pasted plan text
- `agy-plan-review-loop 1 docs/feature_plan.md`
- `codex-plan-review-loop 1` followed by pasted plan text

## Primary Codex Loop Steps
For each loop `N`:

1. Inspect the current git diff and relevant context.
2. Write the exact reviewer prompt to `codex_reviews/loop_N_prompt.md`.
3. Run the selected newly launched reviewer agent using that prompt.
4. Save the raw reviewer output to `codex_reviews/loop_N_review.md`.
5. Read the review output.
6. Classify each finding as:
   - `accepted`
   - `rejected`
   - `needs-user-decision`
7. Write the classification and rationale to `codex_reviews/loop_N_decision.md`.
8. Apply only `accepted` findings.
9. Run relevant verification.
10. Save verification output or summary to `codex_reviews/loop_N_verification.txt`.
11. Update `codex_reviews/summary.md`.
12. Continue until the requested loop count is reached or a stop condition applies.

## Reviewer Commands
Use the selected reviewer command to produce `codex_reviews/loop_N_review.md`.

Codex reviewer:

```sh
codex exec --ephemeral -s read-only -C /Users/moonkong/dev/timey_rider -o codex_reviews/loop_N_review.md - < codex_reviews/loop_N_prompt.md
```

Antigravity reviewer:

```sh
/Users/moonkong/.local/bin/agy --print --sandbox --print-timeout 10m "$(cat codex_reviews/loop_N_prompt.md)" > codex_reviews/loop_N_review.md
```

## Reviewer Prompt Template
The primary Codex should fill in the placeholders before each loop and save the final prompt verbatim.

```text
Review the current git diff only.

You are a reviewer only. Do not modify files.

Task context:
{task_context}

Implemented changes:
{implemented_changes}

Design intent and constraints:
{design_constraints}

Review focus:
- correctness bugs
- behavioral regressions
- edge cases
- missing or broken tests
- mismatches with the stated task context

Do not focus on:
- broad refactors
- style-only preferences
- unrelated existing issues
- changes outside the current diff

Return:
- findings first, ordered by severity
- file and line references when possible
- clear rationale for each finding
- "No actionable findings" if nothing should be changed
```

## Decision Log Template
Use this format for `codex_reviews/loop_N_decision.md`.

```markdown
# Review Loop N Decision Log

## Summary
- Findings reported: 0
- Accepted: 0
- Rejected: 0
- Needs user decision: 0

## Finding 1
Status: accepted | rejected | needs-user-decision
Reviewer severity: high | medium | low | unspecified

Reviewer claim:
- ...

Primary Codex decision:
- ...

Changes made:
- ...

Verification:
- ...
```

## Verification Guidance
Run the smallest useful verification set for the actual change.

Prefer:
- Format changed files.
- Analyze changed files or the package when practical.
- Run targeted tests for touched behavior.
- Run broader tests only when the change is risky or user requested it.

If a verification command fails for an unrelated existing issue, record:
- command
- failure summary
- why it appears unrelated
- whether changed files were verified separately

## Stop Conditions
Stop the loop early and report to the user when:
- The requested loop count is reached.
- The reviewer reports no actionable findings.
- A finding requires a product, UX, or scope decision from the user.
- Verification fails for a reason that blocks safe continuation.
- The reviewer repeatedly reports the same rejected finding.
- The reviewer attempts to act as an implementer instead of a reviewer.

## Artifact Policy
- Review loop artifacts are for auditability.
- Do not include `codex_reviews/` in commits unless the user explicitly asks.
- Do not let reviewer output override primary Codex judgment.
- Do not apply reviewer suggestions that conflict with user instructions.

## User-Facing Report
At the end of the requested loops, report:
- loop count completed
- accepted findings and changes made
- rejected findings and reasons
- findings needing user decision
- verification results
- uncommitted review artifacts, if any
