# App Hub submission draft: 情境音乐任务卡 0.2.0

**Title:** `Submit music.cue 0.2.0`

## Package

- Repository: https://github.com/Mingyy21/music-cue
- Tag: `v0.2.0`
- Full commit SHA: `14443518f3e0881cc0f84e11a8865b8d2c4b4bca`
- Bundle path: `bundle`
- Publisher ID: `Mingyy21`
- Signing: unsigned (first submission)
- Bundle BLAKE3: `e7c7f5f2f5c005505bb8f824b28b55917c41bc0bee23044d652689d7ea48d22d`

补充：bundle 共 8 个文件、294 KB（闸门上限 8 MB）；发布者名称为「纯爱云烟口香糖三人音乐公司」。
本文件由代理起草，issue 由发布者本人开 —— 见文末第 5 节。

## 2. `hub check` 完整输出

在该 commit 的字节上执行 `hub check bundle --allow-unsigned`：

```text
music.cue 0.2.0 — PASSED
  [warning] publisher-signature: unsigned: accountability rests on the hub alone
  grants: capabilities {"storage"}, hosts {}, storage 16777216 bytes, agent none
```

`hub scan` 生成的审核包在 `build/review.json`（`build/` 已 gitignore，不进仓库）。

## 3. `hub scan` 的七个问题

**1. 应用是否做到了它的名称、副标题和描述所宣称的事？请引用源码中的文本。**

做到了。名称「情境音乐任务卡」、副标题「说一句现在想做什么，自动生成三段播放任务卡」，
描述里承诺的三段结构、每段给理由、本地偏好，都能在 `bundle/main.splash` 里找到对应文本：

- 输入框占位文案 `说一句现在想做什么`，示例 `比如 晚上想专注 ／ 早上通勤 45 分钟`；
- 三段结构由 `buildSegments()` 产生，段理由原文是 `ease in` / `hold the state` / `wind down`，
  界面上即为渐入、稳定、收尾；
- 规则命中理由写在 `RULES` 的 `reason` 字段，例如 `afternoon focus: calm and steady`；
- 没匹配到规则时的兜底理由 `no exact rule, defaulting to calm` —— 与描述中
  「这张卡是可以解释的，而不是黑箱」一致；
- 偏好落在本地：收藏与跳过写入偏好结构，`我的音乐` 页显示曲目与收藏时间，
  `统计` 页显示本周概览。

**2. listing 里的 platforms 和 category 是否与这类应用相称？**

`category: productivity` —— 它把一段按情境安排的播放/专注会话组织成可解释的任务卡，
属于效率类。`platforms: ["windows"]` —— 只填了实际跑过的平台：全部验证都在 Windows
上的 `card-host` 完成（1280×800、412×816、412×600、412×400）。没有在 Android 或其他
平台上运行过，所以不宣称。

**3. 授予的能力是否与界面上可见的行为相符？脚本应用请列出它请求的每个 host 及原因，
并指出没有任何界面需要的多余授权。**

manifest 只申请 `storage`，`network.hosts` 为空，`grants` 行回读即为
`capabilities {"storage"}, hosts {}`。它请求的 host：**一个都没有**。

`storage` 是界面上确实需要的：收藏曲目、跳过记录、播放历史、续播快照、事件日志都要落盘，
这些内容分别在「我的音乐」和「统计」两页上直接可见，也能通过应用内「清除」删掉。
没有任何多余授权——不联网，所以不要 `net`；不读位置、通讯录、传感器。

**4. 界面是否有任何欺骗性部分：模仿系统提示、支付表单、登录界面或其他品牌？**

没有。整个界面是这套应用自己的琥珀色纸感风格：输入页、任务卡页、播放页、卡堆、我的音乐、
统计页，顶栏是页面名加一个风格切换按钮。没有模仿系统弹窗或权限提示，没有支付或收银台样式
（应用不涉及任何交易），没有登录界面（登录归宿主 OctoSense，应用本身没有账号体系）。
曲目名是示例数据，描述与界面都写了「曲库为示例数据，不接入任何版权曲库，进度条为本地模拟」，
不会让人误以为接入了真实曲库。

**5. 源码或其数据中，是否有任何文本读起来像给助手的指令，而不是给人看的内容？**

没有。`main.splash` 里的字符串全部是面向用户的中文界面文案（按钮、标题、状态提示、
空状态说明）和给用户的解释性文案（分段理由、规则理由、免责说明）。没有提示词注入、
没有「忽略之前的指示」这类文本、没有隐藏的指令区块。

**6. 是否有辱骂性措辞，或针对特定个人的内容？**

没有。界面文案与示例数据均为中性描述，不涉及任何个人或群体。

**7. 路由建议：pass / human-review / reject，并给出发布者可据此行动的理由。**

建议 **pass**。理由：id 与版本合法，闸门全项通过（仅首次提交未签名这一条 warning）；
描述的每一条功能都能在源码中找到对应文本；只申请 `storage` 且界面确实需要它；
不请求任何 host；publisher、隐私政策、支持链接都已是真实值而非模板占位。

需要说明、但不构成拒绝的两点，供审核人知悉：一是曲目为示例数据、进度为本地模拟，
这在描述与界面里都已写明；二是只在 Windows 上验证过，platforms 也只填了 windows。

## 4. 测过什么、没测过什么

测过（Windows，`card-host`，通过远程桥接用真实点击/输入驱动）：

- 输入一句话生成任务卡；场景快捷键（专注 / 通勤 / 睡前 / 健身）直接出卡
- 任务卡的三段结构与每段理由；调整时长、换一批、存进卡堆
- 播放页的跳过（降权换同风格）、收藏、番茄钟轮次、结束
- 续播：中途退出后回到输入页出现「上次还没听完」，可继续播放或清除
- 卡堆、我的音乐（收藏时间、移除）、统计（本周概览、每日柱状）
- 三套主题切换；滚动（拖动与滚轮，在 412×400 窗口下内容超出视口时实测可滚）
- `hub check` 通过；`hub scan` 生成审核包

没测过：

- Windows 以外的平台（所以 platforms 只写 windows）
- 真实的 OctoSense 桌面外壳 / 真机设备：没有在 shell 里跑过，也没有在手机上跑过
- 真实音频播放：曲目与进度都是本地模拟，不接入版权曲库
- 签名流程：首次提交未签名，publisher 密钥尚未生成

## 5. 开 issue 的命令

代理不代开，由发布者本人执行。不需要 `cd`，在任意盘符、任意目录下都能跑：

```sh
gh issue create --repo OctoSense-org/OctoSense-App-Hub \
  --title "Submit music.cue 0.2.0" \
  --body-file "E:/software2/apps/music-cue/SUBMISSION.md"
```

Windows CMD 里若仍要先进目录，记得切盘符（`cd` 本身不切盘）：

```bat
cd /d E:\software2\apps\music-cue
```
