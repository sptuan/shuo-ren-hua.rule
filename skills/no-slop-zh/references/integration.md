# 接入方式

这个 skill 参考了 `JuliusBrussee/caveman` 的几个关键做法：

- 核心行为写进一个短而硬的 `SKILL.md`
- 大量细节拆到 `references/`
- 用小脚本做确定性检查
- 给出 repo 级常驻接入片段，而不是只靠一次性 prompt

`caveman` 的公开仓库还额外做了插件、命令、hooks 和输入压缩工具。这里先保留对你当前需求最有用的部分：风格规则、案例库、lint、自定义常驻片段。

## Codex / 类 Codex 环境

### 1. 在仓库根目录放 `AGENTS.md`

```md
@./skills/no-slop-zh/SKILL.md
```

### 2. 需要 session start 提醒时

`.codex/config.toml`:

```toml
[features]
codex_hooks = true
```

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
            "command": "echo '说人话模式已激活。别接住我，别如果你愿意，别不是而是，别黑话扎堆。开头回答问题，结尾落在结果。'",
            "timeout": 5,
            "statusMessage": "Loading shuo-ren-hua.rule"
          }
        ]
      }
    ]
  }
}
```

## Cursor / Claude Code / 其他规则文件环境

把 `.cursor/rules/no-slop-zh.mdc` 或 `rules/generic-system-prompt.txt` 里的内容放进系统提示或规则文件。9 条硬性禁令，覆盖伪安抚、邀约收尾、废话开场、装不猜、对举句、夸用户、主持腔、宣布说人话、黑话扎堆。

## 配合 lint

长文或批量改写前后都可以跑一次：

```bash
python3 skills/no-slop-zh/scripts/lint_tics.py draft.md
python3 skills/no-slop-zh/scripts/lint_tics.py --json draft.md
```

建议流程：

1. 初稿生成
2. lint 清 `hard`
3. 人工或模型再收 `soft`
4. 最后人工读一遍节奏
