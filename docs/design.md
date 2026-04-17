# Design

This project has four layers.

## 1. Short Always-On Rules

These are the files under:

- `.codex/`
- `.cursor/rules/`
- `.windsurf/rules/`
- `.github/`
- `rules/`

They are intentionally short. They exist to change behavior from the first response in a session.

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
