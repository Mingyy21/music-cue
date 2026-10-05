# 情境音乐任务卡（music.cue）

跑在 OctoSense 上的小程序（OctoScript / Splash）。你说一句当下情境的话，它生成一张播放任务卡：
情境 + 时长 + 渐入/稳定/收尾三段 + 每段一句理由。你点头后卡片全程跟随。

**我们不做播放器，只做播放任务的组织与状态跟进。**

---

## 快速开始

前置：已装好 [OctoSense App Hub](https://github.com/OctoSense-org/OctoSense-App-Hub)
并通过 `octo doctor` 校验（本项目在 Windows / card-host 环境实测通过）。

```bash
export OCTO_HUB="<App-Hub>/target/release/hub.exe"          # Windows 上是 hub.exe
export OCTO_CARD_HOST="<App-Hub>/target/release/card-host.exe"
export OCTOSENSE_APP_HUB="<App-Hub>"

cd <OctoScript-App-Design-Flow>
python tools/octo doctor                              # 6/6 全绿
python tools/octo run <app>/bundle --port 8141 --hidden --detach
python tools/octo shot 8141 <app>/bundle/screenshots/01-main.png
python tools/octo check <app>/bundle                 # 应为 PASSED
curl -s 127.0.0.1:8141/quit                          # 停止
```

交互端点（用于自动化测试）：

| 端点 | 用途 |
|---|---|
| `GET /snap` | 组件树 JSON（根节点 `ty="Splash"` 需过滤） |
| `GET /click?x=&y=&wait=` | 点击 |
| `GET /t?t=<urlencoded>` | 输入文本 |
| `GET /quit` | 停止 |

> Windows 注意：`tools/octo` 的 `find_binary()` 只找裸名、不试 `.exe`。
> 把 `target/release` 加进用户 PATH 可绕过（`shutil.which` 会试 PATHEXT）。

---

## 怎么用

1. 在输入框说一句话，例如「晚上想专注」「早上通勤 45 分钟」「听点歌」
2. 场景词没识别到时，它会问一次「现在在做什么？」——**只问一次，不连环追问**
3. 拿到卡片后点「开始播放」
4. 播放中可以「跳过」或「收藏」，每次都会**立刻换一首同风格的**
5. 随时点「结束」，下次打开会提示续播
6. 输入页点「我的音乐」查看收藏过的曲目与收藏时间

支持的场景：**专注**（默认 90 分钟）、**通勤**（默认 30 分钟）。
显式说时长会覆盖默认值（例：「专注 45 分钟」）。超过 5 的数字才会被识别为时长。

---

## 它到底做了什么

四个专职模块，由一个状态机按顺序调度（平台当前没有 shell 真正运行多 Agent，
`model.complete` 在 card-host 返回 no service，所以不是四个独立 AI 进程）：

| 模块 | 性质 | 输入 → 输出 |
|---|---|---|
| 感知 perceive | 纯代码，不调 AI | 原话 + 时间 + 历史 → 情境包（四类关键词） |
| 决策 decide | 唯一调 AI 的口子（默认关闭） | 情境包 → 意图标签（情境/情绪/时长/置信度/理由） |
| 编排 orchestrate | 纯代码，本地映射表 | 意图标签 → 三段任务卡 + 每段理由 + 选曲 |
| 守护 guardian | 纯本地，贯穿全程 | 异常信号 → 兜底动作 + 界面文案 |

**两条闭环**：

- 模糊回环：只追问一次；时间取系统值，天气默认室内，状态默认中性，都不主动问
- 偏好回流：跳过/收藏写入本地偏好 → 下次选曲时加权（收藏 +1.0/次，跳过 -1.5/次，
  同一首跳过 2 次进黑名单）

---

## 能力边界（请先读这一段）

- **不播放音频。** 进度条是本地按三段时长**模拟推进**的，卡片底部固定标注这一点。
- **不接入版权曲库。** 曲库是编译期常量，内置 24 个**真实歌曲名**仅用于演示任务卡结构，
  不存储、不传输任何音频内容。
- **完全本地。** 只申请 `storage` 能力，不申请网络权限，不接第三方服务。
- **不登录。** 登录归宿主。

---

## 隐私政策

**本应用不收集、上传或共享任何用户数据。**

所有偏好设置（包括收藏记录、跳过记录、播放历史）仅保存在设备本地的应用私有空间内，
不存在任何形式的网络传输。

本应用未申请网络权限，不接入任何第三方服务，不含第三方统计与广告 SDK。

用户可通过卸载应用彻底删除全部本地数据。

---

## 数据存储

| 文件 | 路径 | 内容 |
|---|---|---|
| 偏好 | `accounts/device/preference.json` | 收藏（含时间戳）、跳过、播放历史 |
| 待续播 | `accounts/device/pending.json` | 播放中进度快照，播完即删 |
| 事件日志 | `accounts/device/events.jsonl` | skip / fav / finish / quit 逐行追加 |

`preference.json` 结构（v2）：

```json
{
  "version": 2,
  "tags": {
    "scenes": ["focus", "commute"],
    "favTracks": [{ "ref": "f-r1", "ts": 1696400000 }],
    "skippedTracks": []
  },
  "history": [{ "ts": 1696400000, "scene": "focus", "durationMin": 90, "cardId": "c1696400000" }]
}
```

容量上限：收藏 200、跳过 200、历史 50。超量在启动时自动裁剪（保留最新的）。

v1 格式（`favTracks` 为字符串数组）会在启动时自动迁移为 v2，行为幂等。

---

## 测试

```bash
export OCTO_HUB=... OCTO_CARD_HOST=... OCTOSENSE_APP_HUB=...
cd apps
python test_all.py        # 115 条断言，约 70 秒
```

单阶段：

```bash
python test_stage0.py     # 基线确认
python test_stage1.py     # 中文可用性 + 界面中文化
python test_stage2.py     # 演示观感（曲名 / 进度条 / 免责标注）
python test_stage3.py     # 偏好数据 v2（结构 / 权重 / 迁移 / 脏数据 / 裁剪）
python test_stage4.py     # 我的音乐（列表 / 排序 / 失效 ref / 渲染上限）
python shots.py           # 重新截商店图
```

测试全部基于真实运行：通过 `/snap` 读组件树、`/click` 驱动交互、断言界面文本与
`preference.json` 的实际内容，并检查运行日志中无 `[E]` 错误。

---

## 已知限制

| 限制 | 说明 |
|---|---|
| 单次会话时长 | 极长会话（如 4 小时以上）会逼近 20M 指令预算（20M/会话）。计时器间隔 5 秒是为规避这一点；如需支持更长会话，需再降频 |
| 「4 小时」解析不出来 | 时长提取只取第一个数字且要求 ≥ 5，「4 小时」会回落到默认 90 分钟；「240 分钟」可用 |
| 曲名 | 24 首真实歌名硬编码在 `main.splash` 的 `DEMO` 常量里；改曲库只需改 `title`，`ref` 不要动（打分与黑名单依赖它） |
| 场景粒度 | 初赛只做 focus / commute 两场景 |
| 视觉风格 | 目前单一配色。三套风格（暗色沉浸 / 浅色温柔 / 编辑部排版）留待后续 |

---

## 发布者

纯爱云烟口香糖三人音乐公司
