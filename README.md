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

## 为什么单靠 prompt 不够

研究的结论比直觉残酷：**模式坍塌发生在模型权重层面，prompt 只能小幅扰动概率，压不住几十个百分点的先验**。

具体数据：

- 负面指令在失败 case 里只能降低目标 token 概率 5.2 个百分点（成功 case 22.8）
- 单 prompt 里有效的硬禁令上限是 3-5 条，更多反而稀释注意力
- "Don't think of a pink elephant" 效应：列出禁止表达本身就在 prime 模型

模型自己也承认。有用户问 GPT-5.4「你的 rule 是否禁止你使用不是/而是句式」，它说「对，rule 禁了」，下一段就用「仓库里**不是**…这么简单，**它是**把…」——典型的"知道规则但生成时模式坍塌"。

完整分析见 [docs/why-it-fails.md](docs/why-it-fails.md)。

**结论：必须三层叠用，缺一不可。**

## 怎么用

| 层 | 什么东西 | 什么时候生效 | 干什么的 |
|---|---|---|---|
| **Rule（常驻规则）** | `.cursor/rules/`、`.windsurf/rules/`、`AGENTS.md`、`.github/copilot-instructions.md` | 每次对话都生效 | **前 5 条硬禁令** + 输出前自检指令 |
| **Skill（按需调用）** | `skills/no-slop-zh/SKILL.md` + references | 用户调用 `$no-slop-zh` 时触发 | 完整诊断流程、改写方法、场景调整 |
| **Hook（输出后兜底）** | `.cursor/hooks/lint-response.sh` | AI 每次回复完自动跑 | **跑 lint，命中 hard 强制重写** |

只用 Rule：能挡住明显的口癖，但模型仍会漏。
Rule + Hook：模型漏了，hook 让它重写一遍。这才是能真正生效的组合。
Rule + Hook + Skill：用户调用 `$no-slop-zh` 时进入深度改写模式。

### Codex

Codex CLI（v0.114+）支持 hooks。这个项目已经配好两个钩子：

- **SessionStart**：会话开始时打招呼
- **Stop**（关键）：每个 turn 结束时跑 lint，命中 hard 口癖就让 Codex 自动续一轮重写

需要的文件：

- [AGENTS.md](AGENTS.md) — 加载 SKILL，每次都生效
- [.codex/config.toml](.codex/config.toml) — 启用 `codex_hooks = true`
- [.codex/hooks.json](.codex/hooks.json) — 注册钩子
- [.codex/hooks/lint-response.sh](.codex/hooks/lint-response.sh) — 真正干活的脚本

#### 用法 1：直接克隆，在仓库里跑

```bash
git clone https://github.com/sptuan/shuo-ren-hua.rule
cd shuo-ren-hua.rule
codex
```

钩子自动生效。

#### 用法 2：拷到自己的项目

```bash
cp AGENTS.md /your-project/
cp -r .codex /your-project/
chmod +x /your-project/.codex/hooks/lint-response.sh

cp -r skills/no-slop-zh /your-project/skills/
```

钩子里的脚本通过 `git rev-parse --show-toplevel` 找 lint 路径，所以 `skills/no-slop-zh/scripts/lint_tics.py` 必须放在你的项目根下。

#### 用法 3：装到全局

把 `hooks.json` 和 `lint-response.sh` 放到 `~/.codex/`：

```bash
mkdir -p ~/.codex/hooks
cp .codex/hooks.json ~/.codex/hooks.json
cp .codex/hooks/lint-response.sh ~/.codex/hooks/
chmod +x ~/.codex/hooks/lint-response.sh
```

每个项目里再放 `skills/no-slop-zh/`。

#### 验证钩子在工作

跑一次 codex，让它故意写一段 AI 腔，看是否会被自动续一轮重写。或者直接测脚本：

```bash
echo '{"last_assistant_message":"你的问题很关键。这不是性能问题，而是架构问题。","stop_hook_active":false}' \
  | bash .codex/hooks/lint-response.sh
```

应该输出 `{"decision":"block","reason":"..."}`。如果输出 `{}`，钩子在 fail open（缺 python3 / jq 或找不到 lint 脚本）。

#### 依赖

- `python3`（lint 脚本是 Python）
- `jq`（解析 stdin JSON）
- `git`（定位脚本路径，可选）

任何一个缺失，钩子都会 fail open——不会阻塞对话，但 lint 也不会跑。

### Cursor

把 [.cursor/rules/no-slop-zh.mdc](.cursor/rules/no-slop-zh.mdc) 复制到你仓库的 `.cursor/rules/` 目录。`alwaysApply: true`，每次对话自动生效。

**强烈建议同时复制钩子配置**——这是这个项目能真正生效的关键：

```bash
cp -r .cursor/hooks.json .cursor/hooks/ /your-project/.cursor/
chmod +x /your-project/.cursor/hooks/lint-response.sh
```

钩子做什么：每次 AI 回复完，跑一遍 lint。命中 hard 口癖就自动追加一条消息要求重写。模型靠规则压不住的，靠 lint 兜底。

钩子需要 `python3` 和 `jq`。如果不在 PATH 里，钩子会 fail open（不阻塞对话）。

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
| [.codex/hooks/lint-response.sh](.codex/hooks/lint-response.sh) | Codex Stop 钩子，命中 hard 让 Codex 自动续一轮重写 |
| [.cursor/hooks/lint-response.sh](.cursor/hooks/lint-response.sh) | Cursor stop 钩子，命中 hard 强制重写 |
| [docs/why-it-fails.md](docs/why-it-fails.md) | 研究分析：为什么单靠 prompt 不够 |
| `.cursor/` `.windsurf/` `.github/` `rules/` | 各平台常驻规则 |

## 目录结构

```text
shuo-ren-hua.rule/
├── README.md
├── AGENTS.md
├── .codex/
│   ├── config.toml
│   ├── hooks.json          # SessionStart + Stop
│   └── hooks/lint-response.sh   # Codex 输出后兜底
├── .cursor/
│   ├── rules/
│   ├── hooks.json          # stop 事件
│   └── hooks/lint-response.sh   # Cursor 输出后兜底
├── .windsurf/rules/
├── .github/copilot-instructions.md
├── rules/
├── examples/
├── docs/
│   ├── design.md
│   └── why-it-fails.md     # 研究：为什么 prompt 不够
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
