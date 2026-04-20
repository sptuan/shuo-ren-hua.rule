# 接入方式

这个 skill 参考了 `JuliusBrussee/caveman` 的几个关键做法：

- 核心行为写进一个短而硬的 `SKILL.md`
- 大量细节拆到 `references/`
- 用小脚本做确定性检查
- 给出 repo 级常驻接入片段，而不是只靠一次性 prompt

`caveman` 的公开仓库还额外做了插件、命令、hooks 和输入压缩工具。这里先保留对你当前需求最有用的部分：风格规则、案例库、lint、自定义常驻片段。

## Codex CLI

需要 v0.114+ 才有 hooks 支持。

### 1. 在仓库根目录放 `AGENTS.md`

```md
@./skills/no-slop-zh/SKILL.md
```

每次对话自动加载 SKILL。

### 2. 启用 hooks

`.codex/config.toml`:

```toml
[features]
codex_hooks = true
```

### 3. 注册 SessionStart + Stop 两个钩子

`.codex/hooks.json`:

```json
{
  "hooks": {
    "SessionStart": [
      {
        "matcher": "startup|resume",
        "hooks": [
          {
            "type": "command",
            "command": "echo '说人话模式已激活。别接住我，别如果你愿意，别不是而是，别黑话扎堆。'",
            "timeout": 5,
            "statusMessage": "Loading shuo-ren-hua.rule"
          }
        ]
      }
    ],
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "bash \"$(git rev-parse --show-toplevel 2>/dev/null || echo .)/.codex/hooks/lint-response.sh\"",
            "timeout": 15,
            "statusMessage": "Lint AI response for tics"
          }
        ]
      }
    ]
  }
}
```

### 4. 放好 lint 钩子脚本

`.codex/hooks/lint-response.sh` 见仓库里的实际文件。要点：

- 从 stdin 拿 `last_assistant_message`
- 跑 `skills/no-slop-zh/scripts/lint_tics.py --json`
- 命中 `hard` count > 0 就返回 `{"decision":"block","reason":"<重写指令>"}`
- 否则返回 `{}`
- `stop_hook_active=true` 时跳过，防止无限循环

`Stop` 事件里 `decision: "block"` 不是真的拒绝，是让 Codex 把 `reason` 当成新的 user prompt 发给模型——这就是自动让模型重写。

### 5. 依赖检查

```bash
command -v python3 && command -v jq && command -v git
```

任何一个缺失，钩子会 fail open（不阻塞对话，但 lint 也不跑）。

## Cursor

### 规则文件（前置硬禁令）

把 `.cursor/rules/no-slop-zh.mdc` 复制到目标仓库。`alwaysApply: true`，每次对话生效，列出 5 条 FORBIDDEN + 输出前自检指令。

### 输出后钩子（强烈推荐）

只放规则不够。模型会一边承认规则一边违反——这是模式坍塌的本质，prompt 改不动。所以加一个 `stop` 钩子：每次 AI 回复完跑 lint，命中 hard 就追加一条消息要求重写。

把 `.cursor/hooks.json` 和 `.cursor/hooks/lint-response.sh` 复制到目标仓库：

```bash
cp -r .cursor/hooks.json .cursor/hooks/ /your-project/.cursor/
chmod +x /your-project/.cursor/hooks/lint-response.sh
```

钩子做的事情：

1. 截获 AI 的最后一条回复
2. 跑 `lint_tics.py --json`
3. 如果 `hard` count > 0，返回 `followup_message` 列出命中的口癖，要求模型重写
4. 没命中就放过

依赖：`python3` 和 `jq` 在 PATH 里。缺任何一个，钩子 fail open，不阻塞对话。

`loop_limit: 2` 防止无限循环——最多重写两次还不行，就放过去（极少出现）。

## Claude Code / 其他规则文件环境

把 `rules/generic-system-prompt.txt` 内容放进系统提示。5 条 FORBIDDEN 加自检指令。

如果环境支持 stop / response 钩子，参考上面 Cursor 的钩子脚本，调整字段名即可。

## 配合 lint（手动场景）

长文或批量改写：

```bash
python3 skills/no-slop-zh/scripts/lint_tics.py draft.md
python3 skills/no-slop-zh/scripts/lint_tics.py --json draft.md
```

建议流程：

1. 初稿生成
2. lint 清 `hard`
3. 命中 hard 的段落整段重写，不要手动改一两个词
4. soft 看上下文判断
5. 人工读一遍节奏
