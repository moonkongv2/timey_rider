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
- Default review-loop shortcuts use compact mode: `code-review-loop`, `agy-code-review-loop`, `codex-code-review-loop`, `plan-review-loop`, `agy-plan-review-loop`, `codex-plan-review-loop`.
- Audit review-loop shortcuts preserve detailed artifacts: `audit-code-review-loop`, `agy-audit-code-review-loop`, `codex-audit-code-review-loop`, `audit-plan-review-loop`, `agy-audit-plan-review-loop`, `codex-audit-plan-review-loop`.
- If the loop count is omitted, default to 1 loop.
- Detailed review-loop behavior lives in `CODEX_REVIEW_LOOP.md`.
- Do not read or apply `CODEX_REVIEW_LOOP.md` for unrelated implementation, debugging, explanation, or commit requests.

## Communication
- Briefly summarize what changed, why it changed, and how it was verified.
- After each implementation task, explicitly list the app areas or flows the user should manually check.

## Localization
- When translating Korean phrases into English (or other languages), do not translate them literally. Instead, carefully review the context and translate the phrases so they sound natural and idiomatic to native speakers of the target language.
