# Contributing

## Scope

This repo is for Chinese style cleanup, not general prompt hacking.

Good contributions are concrete:

- a new high-signal pattern in `patterns.json`
- a better rewrite rule in `SKILL.md`
- a better target-style explanation in `references/voice-target.md`
- a public, dated example in `references/casebook.md`
- an integration improvement for a specific agent

Avoid vague contributions like “make it sound more human” without examples.

## Rules For New Patterns

When adding a pattern:

1. Prefer phrases that users consistently recognize as AI tics.
2. Avoid patterns that would hit ordinary Chinese too often.
3. Add `hard` only when the phrase is usually bad by default.
4. Add `soft` when the phrase can be valid in some contexts.
5. Add an actionable `advice` field. “Avoid this” is not enough.

## Evidence Standard

For `casebook.md`:

- use public sources
- include exact dates when possible
- link the primary release page for model versions
- separate what is verified from what is inferred

If a model/version name cannot be verified publicly, say that directly.

## Development

Basic checks:

```bash
python3 -m py_compile skills/no-slop-zh/scripts/lint_tics.py
printf '问题在缓存失效顺序。先修这个，再补测试。' | python3 skills/no-slop-zh/scripts/lint_tics.py
```

If you change patterns, test both:

- a clearly bad sample
- a clearly normal sample

The goal is fewer false positives, not just more matches.

## Style

- Default to ASCII in code and config unless Chinese is required
- Keep rule files short and forceful
- Keep references rich and evidence-based
- Keep README readable for people who have never seen this repo before
