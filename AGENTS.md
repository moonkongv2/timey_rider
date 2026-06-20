## Working Style
- Keep changes minimal.
- Do not do unrelated refactors.
- Search first to understand the structure before editing.
- Run tests or lint within a practical scope after changes.
- If tests fail, clearly report the cause and scope.

## Editing Rules
- Preserve existing function and class style as much as possible.
- Prefer targeted edits over full-file rewrites.
- Add new dependencies only when clearly necessary.

## Review Loop Shortcuts
- If the user says `code-review-loop`, read `CODEX_REVIEW_LOOP.md` and follow that protocol for a code review loop.
- If the user says `agy-code-review-loop` or `codex-code-review-loop`, read `CODEX_REVIEW_LOOP.md` and follow that protocol for a code review loop with the selected reviewer.
- If the user says `plan-review-loop`, read `CODEX_REVIEW_LOOP.md` and follow that protocol for a plan review loop.
- If the user says `agy-plan-review-loop` or `codex-plan-review-loop`, read `CODEX_REVIEW_LOOP.md` and follow that protocol for a plan review loop with the selected reviewer.
- Do not read or apply `CODEX_REVIEW_LOOP.md` for unrelated implementation, debugging, explanation, or commit requests.

## Communication
- Briefly summarize what changed, why it changed, and how it was verified.
- After each implementation task, explicitly list the app areas or flows the user should manually check.
