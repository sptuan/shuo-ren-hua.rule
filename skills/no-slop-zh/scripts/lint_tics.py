#!/usr/bin/env python3
"""Lint Chinese prose for common GPT/Claude-style filler and口癖."""

from __future__ import annotations

import argparse
import json
import re
import sys
from collections import Counter, defaultdict
from pathlib import Path


ROOT = Path(__file__).resolve().parent
PATTERNS_PATH = ROOT / "patterns.json"
SEVERITY_WEIGHT = {"hard": 3, "soft": 1}


def strip_code(text: str) -> str:
    text = re.sub(r"```.*?```", "", text, flags=re.S)
    text = re.sub(r"`[^`]*`", "", text)
    return text


def load_patterns() -> list[dict[str, str]]:
    return json.loads(PATTERNS_PATH.read_text(encoding="utf-8"))


def load_text(path: str | None) -> str:
    if path:
        return Path(path).read_text(encoding="utf-8")
    return sys.stdin.read()


def iter_matches(text: str, patterns: list[dict[str, str]]) -> list[dict[str, object]]:
    hits: list[dict[str, object]] = []
    cleaned = strip_code(text)
    for pattern in patterns:
        regex = re.compile(pattern["regex"])
        for match in regex.finditer(cleaned):
            hits.append(
                {
                    "id": pattern["id"],
                    "category": pattern["category"],
                    "severity": pattern["severity"],
                    "match": match.group(0),
                    "start": match.start(),
                    "end": match.end(),
                    "advice": pattern["advice"],
                }
            )
    return hits


def summarize(hits: list[dict[str, object]]) -> dict[str, object]:
    by_severity = Counter(hit["severity"] for hit in hits)
    by_category = Counter(hit["category"] for hit in hits)
    by_match = Counter(str(hit["match"]) for hit in hits)
    score = sum(SEVERITY_WEIGHT[str(hit["severity"])] for hit in hits)

    level = "low"
    if score >= 12 or by_severity["hard"] >= 3:
        level = "high"
    elif score >= 5 or by_severity["hard"] >= 1:
        level = "medium"

    advice_map: dict[str, list[str]] = defaultdict(list)
    for hit in hits:
        category = str(hit["category"])
        advice = str(hit["advice"])
        if advice not in advice_map[category]:
            advice_map[category].append(advice)

    return {
        "score": score,
        "level": level,
        "counts": {
            "total": len(hits),
            "hard": by_severity["hard"],
            "soft": by_severity["soft"],
        },
        "categories": dict(by_category.most_common()),
        "top_matches": dict(by_match.most_common(12)),
        "advice": dict(advice_map),
    }


def render_text(summary: dict[str, object], hits: list[dict[str, object]]) -> str:
    lines = [
        f"AI-tic score: {summary['score']} ({summary['level']})",
        (
            "Hits: "
            f"{summary['counts']['total']} total, "
            f"{summary['counts']['hard']} hard, "
            f"{summary['counts']['soft']} soft"
        ),
    ]

    categories = summary["categories"]
    if categories:
        lines.append("")
        lines.append("Categories:")
        for category, count in categories.items():
            lines.append(f"- {category}: {count}")

    if hits:
        lines.append("")
        lines.append("Matches:")
        for hit in hits[:20]:
            lines.append(
                f"- [{hit['severity']}] {hit['category']}: {hit['match']} "
                f"({hit['start']}..{hit['end']})"
            )

    advice = summary["advice"]
    if advice:
        lines.append("")
        lines.append("Advice:")
        for category, items in advice.items():
            for item in items:
                lines.append(f"- {category}: {item}")

    return "\n".join(lines)


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Lint Chinese text for common GPT/Claude-style口癖."
    )
    parser.add_argument("path", nargs="?", help="Optional path to a UTF-8 text file.")
    parser.add_argument("--json", action="store_true", help="Emit JSON output.")
    args = parser.parse_args()

    text = load_text(args.path)
    patterns = load_patterns()
    hits = iter_matches(text, patterns)
    summary = summarize(hits)

    if args.json:
        payload = {"summary": summary, "hits": hits}
        json.dump(payload, sys.stdout, ensure_ascii=False, indent=2)
        sys.stdout.write("\n")
        return 0

    sys.stdout.write(render_text(summary, hits))
    sys.stdout.write("\n")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
