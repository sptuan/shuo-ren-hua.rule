# Design

This project has five layers. Each layer fixes a different failure mode of the previous one.

See [why-it-fails.md](why-it-fails.md) for the research that motivated this design.

## 1. Short Always-On Rules

These are the files under:

- `.codex/`
- `.cursor/rules/`
- `.windsurf/rules/`
- `.github/`
- `rules/`

They are intentionally short. They list the **top 5 hard bans** plus a self-check instruction. Research shows 3-5 specific exclusions per prompt is the attention ceiling; more degrades quality. The rules exist to change behavior from the first response in a session.

## 2. Full Skill

The main logic lives in:

- `skills/no-slop-zh/SKILL.md`

That file defines:

- when the skill should trigger
- the workflow
- hard bans
- target style
- boundaries

## 3. References

Detailed content lives in:

- `references/negative-list.md`
- `references/voice-target.md`
- `references/casebook.md`
- `references/integration.md`

This keeps the core skill usable while preserving the evidence and deeper guidance.

## 4. Deterministic Lint

The linter is deliberately simple.

It does not ask another model whether a sentence “feels AI-generated”.

Instead, it checks a small registry of patterns and returns:

- match spans
- severity
- category
- rewrite advice

That makes the repo portable and cheap to use inside existing workflows.

## 5. Output-Time Hook

Files:

- `.codex/hooks.json` + `.codex/hooks/lint-response.sh` (Codex CLI v0.114+)
- `.cursor/hooks.json` + `.cursor/hooks/lint-response.sh` (Cursor)

The hook runs after every AI response. It pipes the response into `lint_tics.py --json`, and if `hard` count > 0:

- **Codex Stop event**: returns `{"decision":"block","reason":"..."}`. Codex treats `reason` as a new user prompt and continues the turn, effectively forcing a rewrite. The script checks `stop_hook_active` to avoid infinite loops.
- **Cursor stop event**: returns `{"followup_message":"..."}`. Same effect. `loop_limit: 2` caps automatic rewrites.

This is the most critical layer. Research shows that **prompt-level instructions cannot fully suppress patterns learned in RLHF**—the screenshot in the README shows GPT-5.4 acknowledging the rule and violating it in the next paragraph. The hook converts a probabilistic prompt into a deterministic gate.

Failure modes:

- `python3`, `jq`, or `git` missing → fail open (hook does nothing, conversation continues)
- Response field name varies between IDE versions → script tries multiple known field names
- Loop guard via `stop_hook_active` (Codex) or `loop_limit: 2` (Cursor) → at most one or two automatic rewrites per turn
