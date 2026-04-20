#!/usr/bin/env bash
# 在 AI 每次回复后跑 lint。如果命中 hard 口癖，要求模型重写。
# 这是 Phase C 输出清扫：规则没拦住的留给确定性脚本。

set -e

input=$(cat)

# 提取 AI 最后一条响应。stop 事件的 payload 字段名以 cursor 实际为准，
# 这里同时尝试几种常见字段，取到非空就用。
response=$(echo "$input" | jq -r '
  .response // .agent_response // .last_message // .message //
  (.transcript[-1].content // empty)
' 2>/dev/null || echo "")

# 如果拿不到响应内容，fail open——不阻断对话。
if [ -z "$response" ]; then
  echo '{}'
  exit 0
fi

# 跑 lint。脚本路径相对项目根目录。
LINT_SCRIPT="skills/no-slop-zh/scripts/lint_tics.py"
if [ ! -f "$LINT_SCRIPT" ]; then
  echo '{}'
  exit 0
fi

result=$(echo "$response" | python3 "$LINT_SCRIPT" --json 2>/dev/null || echo "")
if [ -z "$result" ]; then
  echo '{}'
  exit 0
fi

hard_count=$(echo "$result" | jq -r '.summary.counts.hard // 0' 2>/dev/null || echo 0)

# 没命中 hard 就放过。soft 不拦截。
if [ "$hard_count" -eq 0 ]; then
  echo '{}'
  exit 0
fi

# 列出命中的口癖
matches=$(echo "$result" | jq -r '
  .hits | map(select(.severity == "hard")) | .[:8] |
  map("- " + .category + "：" + .match) | join("\n")
' 2>/dev/null)

cat <<EOF
{
  "followup_message": "你刚才的回复命中了 ${hard_count} 处硬口癖。重写包含这些表达的段落，不要解释，直接给修改后的版本：\n${matches}\n\n禁止使用：不是X而是Y、稳稳接住你、如果你愿意、问得好、原因很直接、目的很明确、我不猜。"
}
EOF
exit 0
