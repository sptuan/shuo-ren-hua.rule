#!/usr/bin/env bash
# Codex Stop 钩子：每个 turn 结束时跑 lint。
# 命中 hard 口癖就返回 decision=block + reason，让 Codex 把 reason 作为新 prompt
# 触发模型重写。这是 Phase C 输出清扫——规则没拦住的留给确定性脚本。

set -e

input=$(cat)

# 防止无限循环。如果本轮已经被 Stop 钩子继续过，就放过去。
already_continued=$(echo "$input" | jq -r '.stop_hook_active // false' 2>/dev/null || echo "false")
if [ "$already_continued" = "true" ]; then
  echo '{}'
  exit 0
fi

# 拿到 assistant 最后一条消息。Codex Stop 事件直接给。
response=$(echo "$input" | jq -r '.last_assistant_message // empty' 2>/dev/null || echo "")
if [ -z "$response" ] || [ "$response" = "null" ]; then
  echo '{}'
  exit 0
fi

# 找 lint 脚本。优先 git root，回退 cwd 相对路径。
LINT_SCRIPT=""
if git_root=$(git rev-parse --show-toplevel 2>/dev/null); then
  candidate="$git_root/skills/no-slop-zh/scripts/lint_tics.py"
  if [ -f "$candidate" ]; then
    LINT_SCRIPT="$candidate"
  fi
fi
if [ -z "$LINT_SCRIPT" ] && [ -f "skills/no-slop-zh/scripts/lint_tics.py" ]; then
  LINT_SCRIPT="skills/no-slop-zh/scripts/lint_tics.py"
fi

# 找不到 lint 脚本就 fail open。
if [ -z "$LINT_SCRIPT" ]; then
  echo '{}'
  exit 0
fi

# python3 / jq 缺失也 fail open。
if ! command -v python3 >/dev/null 2>&1 || ! command -v jq >/dev/null 2>&1; then
  echo '{}'
  exit 0
fi

result=$(echo "$response" | python3 "$LINT_SCRIPT" --json 2>/dev/null || echo "")
if [ -z "$result" ]; then
  echo '{}'
  exit 0
fi

hard_count=$(echo "$result" | jq -r '.summary.counts.hard // 0' 2>/dev/null || echo 0)

# 没命中 hard 就放过，soft 不拦截。
if [ "$hard_count" -eq 0 ]; then
  echo '{}'
  exit 0
fi

# 列出命中的口癖
matches=$(echo "$result" | jq -r '
  .hits | map(select(.severity == "hard")) | .[:8] |
  map("- " + .category + "：" + .match) | join("\n")
' 2>/dev/null)

# decision=block 在 Stop 事件里不是真的 block，而是触发继续。
# Codex 会把 reason 作为新 user prompt 发给模型，让模型重写。
cat <<EOF
{
  "decision": "block",
  "reason": "你刚才的回复命中了 ${hard_count} 处硬口癖。重写包含这些表达的段落，不要解释，不要道歉，直接给修改后的版本：\n${matches}\n\n禁止：不是X而是Y、稳稳接住你、如果你愿意、问得好、原因很直接、目的很明确、我不猜。"
}
EOF
exit 0
