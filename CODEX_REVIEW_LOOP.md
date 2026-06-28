# Codex Review Loop Protocol

## Purpose
Use a newly launched reviewer agent only as a reviewer. The primary Codex keeps responsibility for implementation decisions, code or plan changes, verification, and final reporting.

The reviewer agent is a helper, not an implementer.

## Roles

### Primary Codex
- Reads this protocol before starting a review loop.
- Uses compact mode by default.
- Gives the reviewer only scoped diff or plan context needed for review.
- Reads the reviewer output and classifies each finding.
- Applies only findings judged valid and in scope.
- Runs the smallest useful verification.
- Reports compactly to the user.

### Reviewer Agent
- Reviews only the current scope provided by the primary Codex.
- Does not modify files.
- Does not run broad refactors.
- Focuses on correctness, regressions, edge cases, missing tests, and mismatches with the stated task.
- Ignores style-only preferences, unrelated existing issues, and broad architectural suggestions unless they directly affect correctness.
- Returns compact findings only.

## Reviewer Selection
Default reviewer:
- `codex`

Available reviewers:
- `codex`: run a newly launched Codex reviewer.
- `agy`: run Antigravity through `/Users/moonkong/.local/bin/agy --print --sandbox`.

Default compact shortcuts:
- `code-review-loop [N] [scope]`: use the default `codex` reviewer.
- `agy-code-review-loop [N] [scope]`: use the `agy` reviewer.
- `codex-code-review-loop [N] [scope]`: explicitly use the `codex` reviewer.
- `plan-review-loop [N] [plan]`: use the default `codex` reviewer.
- `agy-plan-review-loop [N] [plan]`: use the `agy` reviewer.
- `codex-plan-review-loop [N] [plan]`: explicitly use the `codex` reviewer.

Audit shortcuts:
- `audit-code-review-loop [N] [scope]`: use the default `codex` reviewer and preserve artifacts.
- `agy-audit-code-review-loop [N] [scope]`: use the `agy` reviewer and preserve artifacts.
- `codex-audit-code-review-loop [N] [scope]`: explicitly use the `codex` reviewer and preserve artifacts.
- `audit-plan-review-loop [N] [plan]`: use the default `codex` reviewer and preserve artifacts.
- `agy-audit-plan-review-loop [N] [plan]`: use the `agy` reviewer and preserve artifacts.
- `codex-audit-plan-review-loop [N] [plan]`: explicitly use the `codex` reviewer and preserve artifacts.

Do not use `agy --dangerously-skip-permissions` for review loops unless the user explicitly asks for it.

## Shortcut Parsing
- Default loop count: 1.
- If the first argument is a natural number, use it as the loop count.
- If the first argument is not a natural number, treat it as the scope or plan and use 1 loop.
- If scope is omitted for a code review, use the current git diff.
- If scope is provided, review only that scoped diff or file set.
- If plan is omitted for a plan review, use the pasted plan text when available.

Examples:
- `agy-code-review-loop`: 1 loop, current git diff.
- `agy-code-review-loop lib/screens/home_screen.dart`: 1 loop, scoped to that path.
- `agy-code-review-loop 2`: 2 loops, current git diff.
- `agy-code-review-loop 2 lib/screens/home_screen.dart`: 2 loops, scoped to that path.
- `codex-plan-review-loop docs/plan.md`: 1 loop, scoped to that plan file.

## Invocation Shortcuts
The primary Codex should read and apply this protocol only when the user explicitly asks for a review loop or uses one of the shortcuts below. Do not apply this protocol to unrelated implementation, debugging, explanation, or commit requests.

### Compact Code Review Shortcuts
Run a compact code review loop.

Defaults:
- Review mode: code diff review.
- Loop count: 1 unless provided.
- Scope: current git diff unless scope is provided.
- Reviewer: selected reviewer agent, reviewer only.
- Artifacts: none preserved by default.
- Apply valid findings to code.
- Run relevant verification.
- Do not commit unless the user explicitly asks.

Examples:
- `code-review-loop`
- `code-review-loop 2`
- `code-review-loop lib/screens/result_screen.dart`
- `agy-code-review-loop`
- `codex-code-review-loop lib/screens/result_screen.dart`

### Compact Plan Review Shortcuts
Run a compact plan review loop.

Defaults:
- Review mode: plan review.
- Loop count: 1 unless provided.
- Scope: provided plan file or pasted plan text.
- Reviewer: selected reviewer agent, reviewer only.
- Artifacts: none preserved by default.
- Apply valid findings to the plan only.
- Do not modify implementation code.
- Do not commit unless the user explicitly asks.

Examples:
- `plan-review-loop docs/feature_plan.md`
- `plan-review-loop 2 docs/timer_result_plan.md`
- `plan-review-loop` followed by pasted plan text
- `agy-plan-review-loop docs/feature_plan.md`
- `codex-plan-review-loop` followed by pasted plan text

### Audit Shortcuts
Run artifact-preserving review loops only when the user uses an `audit-*` shortcut.

Audit mode preserves:
- reviewer prompt
- raw reviewer output
- decision log
- verification summary
- final summary

Audit files:
- `codex_reviews/loop_N_prompt.md`
- `codex_reviews/loop_N_review.md`
- `codex_reviews/loop_N_decision.md`
- `codex_reviews/loop_N_verification.txt`
- `codex_reviews/summary.md`

Audit mode still applies token budget limits:
- Do not paste full files unnecessarily.
- Avoid broad repo inspection.
- Limit reviewer output to at most 5 findings.
- Keep verification logs summarized unless failure details are necessary.

Do not include `codex_reviews/` in commits unless the user explicitly asks.

## Compact Mode Policy
- Compact mode is the default for all non-audit shortcuts.
- Default loop count: 1.
- Review only the current git diff or user-provided scope.
- Avoid broad repository inspection.
- Do not paste full file contents into reviewer prompts.
- Task context: max 5 bullets.
- Implemented changes: max 7 bullets.
- Design constraints: max 5 bullets.
- Reviewer output: max 3 actionable findings.
- No praise.
- No broad summary.
- No restatement of the task.
- If nothing should change, reviewer must return exactly: `No actionable findings.`
- Primary Codex classifies findings internally as accepted, rejected, or needs-user-decision.
- Do not write long decision logs in compact mode.
- Final user-facing report should be compact.

## Compact Artifact Policy
In compact mode, do not create persistent review-loop artifacts by default.

Do not create these files by default:
- `codex_reviews/loop_N_prompt.md`
- `codex_reviews/loop_N_review.md`
- `codex_reviews/loop_N_decision.md`
- `codex_reviews/loop_N_verification.txt`
- `codex_reviews/summary.md`

If a temporary file is required to invoke a reviewer command:
- Keep it compact.
- For `agy` compact reviews, prefer a short temporary prompt under `/private/tmp` and pass it with `$(cat /private/tmp/...)` to avoid shell quoting and argument parsing issues.
- Delete temporary compact-review prompt files after the review unless audit mode is requested.
- Do not preserve it unless needed.
- Do not create long prompt, review, decision, or summary artifacts.
- Only audit shortcuts should preserve artifacts under `codex_reviews/`.

Do not include `codex_reviews/` in commits unless the user explicitly asks.

## Primary Codex Loop Steps
For compact mode:

1. Determine loop count. If omitted, use 1.
2. Determine scope. If omitted, use current git diff.
3. Inspect only the scoped diff and minimal relevant context.
4. Prepare a compact reviewer prompt in memory or a temporary file only if needed.
5. Run the selected reviewer.
6. Read reviewer output.
7. If reviewer returns `No actionable findings.`, stop early.
8. Classify findings internally as accepted, rejected, or needs-user-decision.
9. Apply only accepted findings.
10. Run the smallest useful verification.
11. Report compactly to the user.

Do not write long decision logs in compact mode.

For audit mode, follow the same loop steps but preserve the prompt, raw review, decision log, verification summary, and final summary under `codex_reviews/`.

## Reviewer Commands
Use the selected reviewer command. In compact mode, capture output directly or through a compact temporary file only when needed. In audit mode, preserve output as `codex_reviews/loop_N_review.md`.

Codex reviewer:

```sh
codex exec --ephemeral -s read-only -C /Users/moonkong/dev/timey_rider -o codex_reviews/loop_N_review.md - < codex_reviews/loop_N_prompt.md
```

Antigravity reviewer:

```sh
/Users/moonkong/.local/bin/agy --sandbox --print "$(cat codex_reviews/loop_N_prompt.md)" --print-timeout 10m > codex_reviews/loop_N_review.md
```

For compact mode, the same command shape may be used with temporary prompt or output files instead of persistent `codex_reviews/` files. Keep hardcoded command paths unchanged unless the user explicitly asks.

If `agy` fails with log-file creation, language-server startup, localhost bind, or `operation not permitted` errors, rerun the same review command with escalated permissions. These failures can happen during normal `agy` CLI startup inside the sandbox and are not a reason to skip the requested review loop.

## Reviewer Prompt Template
The primary Codex should fill in the placeholders before each loop. Compact mode may keep the prompt in memory or a temporary file.

```text
Review only the provided diff and compact context.

You are a reviewer only. Do not modify files.

Task context:
{task_context_max_5_bullets}

Implemented changes:
{implemented_changes_max_7_bullets}

Design intent and constraints:
{design_constraints_max_5_bullets}

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
- changes outside the provided diff or scope

Return:
- at most 3 actionable findings
- no praise
- no general summary
- no restatement of the task
- each finding should be concise
- each finding should include severity, file/line when possible, issue, and suggested fix
- if nothing should change, return exactly: No actionable findings.

Do not inspect unrelated files unless a finding cannot be validated without them.
```

Audit mode may allow at most 5 actionable findings.

## Audit Decision Log Template
Use this format only for audit mode `codex_reviews/loop_N_decision.md`.

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

## Compact Stop Conditions
Stop the loop early and report to the user when:
- The requested loop count is reached.
- The reviewer returns `No actionable findings.`
- No accepted findings are found.
- Accepted findings do not cause actual code or plan changes.
- A finding requires a product, UX, or scope decision from the user.
- Verification fails for a reason that blocks safe continuation.
- The reviewer repeatedly reports the same rejected finding.
- The reviewer attempts to act as an implementer instead of a reviewer.

## Judgment Policy
- Do not let reviewer output override primary Codex judgment.
- Do not apply reviewer suggestions that conflict with user instructions.
- Do not apply reviewer suggestions that are outside the requested scope.

## Compact User-Facing Report
At the end of compact review loops, use this format and keep each section short:

```markdown
Reviewer:
Loops completed:
Findings:
Accepted changes:
Rejected findings:
Needs user decision:
Verification:
Notes:
```

Avoid long rationale unless needed for a blocking issue.

For audit mode, also mention preserved artifacts under `codex_reviews/`.
