# 说人话.rule

受够了。

GPT-5.4 发布以后，中文输出的 AI 腔到了令人窒息的程度。每次问个技术问题，回来的永远是——「你的问题很关键」「我不瞎猜」「这不是 X 问题，而是 Y 问题」「我先帮你梳理一下，再顺手……」「如果你愿意，我可以继续」。一整套模板，一个不落。

Claude 也没好到哪去。被用户直接点名「跟 GPT 学坏了」，一样的「稳稳接住你」，一样的邀约式收尾。

谢谢，我不需要被接住。我需要答案。

这个项目治的就是这个病：**让中文 AI 输出像个正常人在说话，而不是一个在表演温柔的客服机器人。**

灵感来自 [caveman](https://github.com/JuliusBrussee/caveman)。caveman 压缩英文 token，这个项目杀中文 AI 腔。

调用简称：`$no-slop-zh`

## GPT-5.4 的问题有多严重

不是 AI 写错了。是写出来的东西一眼就知道是 AI 生成的——

- `如果你愿意，我可以……` ← 你又不是在征求我同意
- `我就在这里，稳稳地接住你` ← 我在 debug，不是在做心理咨询
- `不是 X 问题，而是 Y 问题` ← 什么话题都套这个壳，直接说 Y 不行吗
- `你的问题很关键` ← 废话。删掉这句回答一个字都不会少
- `我不猜 / 不靠猜 / 不瞎猜` ← GPT-5.x 每个回答都来一遍
- `我先……再顺手……` ← 直接给结果，别解说你打算怎么组织
- `说人话就是 / 简单的说` ← 你直接说就行，不用先宣布
- `砍一刀 / 补一刀 / 狠狠干` ← 正常人不会每个技术问题都要动刀
- `对齐 / 抓手 / 收口 / 落盘 / 兜底 / 口径` ← 说中文谢谢

单独看哪句都没毛病。但它们**总是一起出现**，出现的频率高到离谱，整段回答读下来就像一个模板在自动填空。

LINUX DO 上已经有多个专帖集中吐槽（[如果你愿意，我不愿意啊 GPT5.4](https://linux.do/t/topic/1699921)、[受不了gpt5.4了](https://linux.do/t/topic/1916263)、[坏了 claude跟gpt学坏了](https://linux.do/t/topic/1841752)），评论区的高频词是「好窒息」「被 GPT 狠狠污染」。这不是个别人的体感，是群体可识别的模板。

## 改之前 vs 改之后

### 例 1：你是客服吗

改前：

> 你问到了问题的核心。我先不绕，直接给你一个可落地版本。如果你愿意，我下一步可以顺手帮你把脚本也补上。

改后：

> 问题在这里。先给可执行版本，脚本后补。

### 例 2：我不需要被接住

改前：

> 这不是接口问题，而是状态同步问题。我会稳稳地接住你，逐步说清楚。

改后：

> 问题出在状态同步，跟接口定义无关。下面拆开说。

### 例 3：不是而是全家桶

改前：

> 这不是性能问题，而是架构问题。不是代码写错了，而是你问到了更底层的状态一致性问题。这不只是一个技术问题，更是一个工程文化问题。

改后：

> 问题在架构层，状态一致性没守住。

三句"不是……而是……"连着来，每句都在升华，最后升到"工程文化"——请问你到底想让我改什么？

### 例 4：问题很关键谢谢

改前：

> 你的问题很关键。核心问题在于缓存失效顺序不对，我先帮你梳理一下，如果你愿意，我可以顺手把修复脚本也补上。

改后：

> 缓存失效顺序不对。修复脚本后补。

"问题很关键"六个字，信息量：零。

### 例 5：我不猜我不猜我不猜

改前：

> 我不瞎猜。根据你的描述，根因在锁竞争。我先不绕，直接给你一个可落地版本。

改后：

> 问题在锁竞争。可执行版本如下。

### 例 6：全套组合拳

改前：

> 你太清醒了。这不是性能问题，而是架构问题。我先帮你梳理一下关键路径，再顺手把优化方案也列出来。如果你愿意，我们可以一步步推进。

改后：

> 你说得对，这已经是架构问题了。关键路径和优化方案列在下面，直接推进。

## 怎么用

这个项目有两层，作用不同：

| 层 | 什么东西 | 什么时候生效 | 干什么的 |
|---|---|---|---|
| **Rule（常驻规则）** | `.cursor/rules/`、`.windsurf/rules/`、`AGENTS.md`、`.github/copilot-instructions.md` | **每次对话都生效**，不需要手动触发 | 底线约束——禁止最恶劣的口癖 |
| **Skill（按需调用）** | `skills/no-slop-zh/SKILL.md` + references | 用户调用 `$no-slop-zh` 时触发 | 深度改写——完整的诊断流程、案例库、lint |

**只想要「每次都生效」的最小方案？复制 Rule 文件就行。** Skill 是给需要做深度改写的人准备的。

### Codex

克隆仓库，在里面跑 Codex。已经配好了：

- [AGENTS.md](AGENTS.md) — 常驻规则，每次都生效
- [.codex/config.toml](.codex/config.toml)
- [.codex/hooks.json](.codex/hooks.json)

想在别的仓库用，把这几个文件复制过去。

或者直接要求 codex 将 https://github.com/sptuan/shuo-ren-hua.rule 添加到 rule 中。

### Cursor

把 [.cursor/rules/no-slop-zh.mdc](.cursor/rules/no-slop-zh.mdc) 复制到你仓库的 `.cursor/rules/` 目录。`alwaysApply: true`，每次对话自动生效。

### Windsurf

把 [.windsurf/rules/no-slop-zh.md](.windsurf/rules/no-slop-zh.md) 复制到你仓库的 `.windsurf/rules/` 目录。`trigger: always_on`，每次对话自动生效。

### GitHub Copilot

把 [.github/copilot-instructions.md](.github/copilot-instructions.md) 复制过去，或合并到已有指令文件。

### 其他 Agent

拿 [rules/generic-system-prompt.txt](rules/generic-system-prompt.txt) 当系统提示的常驻规则。

## Lint：机器查，不靠玄学

口癖检测脚本，纯正则匹配，不靠另一个 AI 来判断「像不像 AI 写的」。确定性检查，零依赖。

```bash
python3 skills/no-slop-zh/scripts/lint_tics.py draft.md
```

从标准输入读：

```bash
printf '问题在缓存失效顺序。先修这个，再补测试。' | python3 skills/no-slop-zh/scripts/lint_tics.py
```

JSON 输出：

```bash
python3 skills/no-slop-zh/scripts/lint_tics.py --json draft.md
```

## 包含什么

| 文件 | 干嘛的 |
|---|---|
| [skills/no-slop-zh/SKILL.md](skills/no-slop-zh/SKILL.md) | 核心规则，agent 读这个 |
| [skills/no-slop-zh/references/negative-list.md](skills/no-slop-zh/references/negative-list.md) | 口癖黑名单 |
| [skills/no-slop-zh/references/voice-target.md](skills/no-slop-zh/references/voice-target.md) | 正确的说话方式 |
| [skills/no-slop-zh/references/casebook.md](skills/no-slop-zh/references/casebook.md) | 公开案例和社区吐槽记录 |
| [skills/no-slop-zh/scripts/lint_tics.py](skills/no-slop-zh/scripts/lint_tics.py) | 口癖检测脚本 |
| [skills/no-slop-zh/scripts/patterns.json](skills/no-slop-zh/scripts/patterns.json) | 正则模式注册表 |
| `.cursor/` `.windsurf/` `.github/` `rules/` | 各平台常驻规则 |

## 目录结构

```text
shuo-ren-hua.rule/
├── README.md
├── AGENTS.md
├── .codex/
├── .cursor/rules/
├── .windsurf/rules/
├── .github/copilot-instructions.md
├── rules/
├── examples/
├── docs/
└── skills/
    └── no-slop-zh/
        ├── SKILL.md
        ├── agents/openai.yaml
        ├── references/
        └── scripts/
```

## 边界

- 管风格，不管事实。别指望这个帮你查 bug
- 安全警告照说不误，该直白直白
- 别拿这个去绕过禁止 AI 代写的平台规则
- 创作和情绪支持需要不同处理——不是所有温柔都是假的

## 相关项目

- [caveman](https://github.com/JuliusBrussee/caveman)：英文版的极简压缩
- [docs/design.md](docs/design.md)：设计说明
- [examples/before-after.md](examples/before-after.md)：更多改写示例

## 贡献

见 [CONTRIBUTING.md](CONTRIBUTING.md)。

好的贡献：新的高信号模式、更好的改写规则、公开案例、agent 集成优化。

差的贡献：「让它听起来更像人」但没有例子。

## 许可

[MIT](LICENSE)
