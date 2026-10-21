# 变更日志

本文件记录本 fork（puretaoist/PiliPlus）相对上游 bggRGjQaUbCoE/PiliPlus 的改动。

## 2026-10-21 修复：「不感兴趣」未登录/未指定推荐账号时点不了

**现象**：首页卡片「我不想看」点任何理由都提示「请退出账号后重新登录」，
即使已经登录。原因是 `lib/http/video.dart` 里有一道硬门槛：

```dart
if (Accounts.get(AccountType.recommend).accessKey.isNullOrEmpty) {
  return const Error('请退出账号后重新登录');
}
```

`AccountType.recommend` 只有在「账号模式」里显式指定过推荐账号才有值，
否则落到 `AnonymousAccount`（`accessKey` 恒为 `null`）→ 永远提交不了。
这道门槛来自上游 `8daf603fd`，不是本 fork 引入的。

**为什么可以放心去掉**：
1. 官方 App 自己就是可选的 —— `pegasus/request/f.java` 里
   `if (strA != null) map.put("access_key", strA);`，缺失照样发请求；
2. `AccountManager.onRequest` 已经统一处理：**有 accessKey 就附加并签名，
   没有就只补 `appkey`/`ts`/`sign`**，业务层再拦一道纯属重复；
3. 实测匿名（无 `access_key`）+ 完整参数集返回 `code=0`；
4. 签名与否都验证过：不签名/签名、有无 `access_key`、假 `access_key`
   四种组合全部 `code=0`，所以去掉门槛不会引入 -400。

**同时修掉的两个隐患**（都会导致「提交成功但反馈没用」）：

- **`old_pegasus=1` 之前没带**。官方 `pegasus/api/D.java` 的 `b(...)` 必带此项，
  缺失时接口仍返回 `code=0`，但归因会退化。
- **`mid`/`rid`/`tag_id` 之前无条件下发**（`rid` 传的还是 `item.aid`，官方取
  `args.rid`）。官方写法是**仅当 `> 0` 才带** —— 传 `0` 等于明确告诉服务端
  「这个 UP 不存在」，比不传更糟。

**关键发现：`reason_id` 才是反馈是否生效的开关**

这一点做了严格的对照实验（同 buvid、同页面、随机对半分 UP，投一半留一半，
各 4 个 buvid × 40 页）：

| 投喂内容 | 投喂组命中 | 对照组命中 | 结论 |
|---|---|---|---|
| `reason_id=4`（UP主级） | **0 / 3200 (0.00%)** | 42 / 3200 (1.31%) | 完全抑制，4/4 buvid 一致 |
| 不带 `reason_id` | 31 / 2720 (1.14%) | 40 / 2720 (1.47%) | 22%，噪声范围，等于没投 |

也就是说：**服务端对「不说话的不感兴趣」只是收下不办**。这正好是
`docs/regression-checklist.md` 里「`code=0` ≠ 写入成功」那条陷阱的又一个实例。
UI 侧本来就会传 `reason_id`（取自 `three_point_v2`），所以这条不需要改代码，
但记了诊断：万一调用方漏传，会写一条 `dislike.noReason`，**不阻断请求**。

**改动**：抽出纯函数 `VideoHttp.buildFeedDislikeParams(...)`（便于单测断言参数），
`feedDislike` / `feedDislikeCancel` 共用；删除两处 accessKey 门槛；
失败时补 `dislike.fail` / `dislike.cancelFail` 诊断日志。

**验证**：`flutter analyze` 40 issues / **0 error 0 warning**（与改动前一致，
新增代码零提示）；新增 `test/http/feed_dislike_test.dart` 5 个用例守护参数构造
（含「不下发 `access_key`」「`mid`/`rid`/`tag_id` 为 0 时不下发」）。

## 2026-10-21 新增：首页推荐重排（设置 → 推荐 → 推荐重排）

**为什么做**：实测发现服务端下发的首页主要是**热门库存池，不是画像**。
100 条采样里 60~73% 来自 `newuser` 池（`high_quality_newuser_ann_dssm_u2i_v2`
/ `newuser_u2u`），推荐理由 82/100 为空、其余全是「1万点赞」「5千点赞」这类
点赞数导向，没有一条是「因为你看了 X」。

更关键的反向证据：**两台全新设备之间** 20 条推荐有 12 条重合（Jaccard 42.86%），
而**同一设备连续两次**请求 0 条重合（0.00%）。方向完全反了 —— 若个性化生效，
同设备两次应高度重合。这说明个性化只做了很浅的一层叠加。

所以"补曝光上报"救不回推荐质量（原 P0 已降级为 P3），改为在客户端用**已有的、
零额外请求的**信号重排。

**做什么**（`lib/utils/rcmd_resort.dart`，纯函数 + 可单测）：

1. `isFollowed`（服务端给的「已关注 / 新关注」）→ `+3.0` 提权
2. 本地 `watchProgress`（按 cid 存进度，用户真的点开过才写）：
   已看完 `−4.0`、看过一部分 `−1.0`
3. 相邻错开：与上一条同 UP `−4.0`、同分区 `−0.8`

**刻意不做**（都在代码注释里写明理由）：
- 不按播放量/点赞率排序（"爆款"不等于用户爱看；`RcmdStat` 本来就没有 like 字段）
- 不删除任何条目（只重排，条目变少会让首页刷空）
- 不新增持久化数据（不建画像、不加黑名单，避免隐私与迁移负担）
- 不设"每 UP 最多 N 条"硬上限（关注了就该看到，掰开即可，不减少总量）

**三个必须处理的坑**（都写了对应验证）：

1. **游标**：app 推荐 `idx` 在页内**递减**，`_cursor()` 原本读 `list.first/last.idx`。
   重排后首/末条不再是原始极值 → 回传错误游标会跳页或反复拿同一批。
   修法：`handleListResponse` 里**先把极值缓存到 `_idxNewest`/`_idxOldest`**，
   重排只影响展示顺序。
2. **「上次看到这里」标记**：`lastRefreshAt` 是位置索引。重排只作用于
   `[0, freshLength)`（本批新数据），拼接进来的旧内容一个字都不动，
   标记位置恰好等于 `freshLength`，因此不漂移。
3. **拼接顺序**：`enableSaveLastData` 会在新数据后拼上次内容；重排必须在
   拼接之后、且只覆盖新数据段，否则会把已经显示过的内容打乱。

**默认关闭**，需在设置里手动打开（`SettingBoxKey.rcmdResort`）。顺序无变化时
`computeOrder` 返回 null，调用方完全跳过写入 —— 没有可用信号时首页一个字都不动。

**验证**（本机 `flutter test` 被 `nativeapi` 的 MSVC 需求挡住，改用独立脚本）：
- `verify_rcmd_resort.dart` 算法 17/17：关注提权、看完沉底、看完边界（5 秒）、
  同 UP 相邻从 4 降到 ≤1、整批同 UP 不抖动、结果是 0..n-1 排列不丢条目
- `verify_rcmd_cursor.dart` 游标 9/9：重排前后极值不变
- `verify_rcmd_marker.dart` 标记 7/7：新数据仍在标记前、旧数据顺序未动
- `verify_rcmd_e2e.dart` 端到端 9/9：真实形态（UP 连发 6 条）下相邻同 UP 从 5 降到 0
- `flutter analyze` 40 条全 info、**0 error / 0 warning**（基线一致）

## 2026-10-18 上游同步 2.1.6 → 2.1.6.2（45 个提交）

**无冲突自动合并**（160 个文件，+4640/−2904），fork 的改动全部存活。

### 环境要求再次上调

| 项 | 之前 | 现在 |
|---|---|---|
| Flutter | 3.47.6 | **3.47.7** |
| material_ui | 1.5.0 | **1.6.0** |
| cupertino_ui | 1.1.1 | **1.1.2** |

`.fvmrc` 与 `pubspec.yaml` 都已由上游改成 3.47.7。本机 SDK 停在 3.47.6 时
`flutter pub get` 会直接报 `Because PiliPlus requires Flutter SDK version 3.47.7,
version solving failed`，进而让 `patch.ps1` 报 `material_ui package not found
in pub cache`（那个报错是假象，真因是版本解不出来，补丁脚本连包都没下载）。

### 依赖迁移（上游完成，fork 无需跟改）

- **`waterfall_flow` → `flutter_staggered_grid_view ^0.7.0`**：旧包已删除，
  仓库内无残留引用（`lib/utils/waterfall.dart` 等 9 个文件改用新包）
- **新增 `nativeapi ^0.5.2`**：用于桌面端窗口/几何计算
  （`lib/utils/desktop/window_controller.dart`、`calc_window_position.dart`、
  `lib/pages/main/view.dart`，以及 `lib/plugin/pl_player/controller.dart`
  的画中画窗口尺寸计算）
- `tray_manager` 0.5.1 → 0.8.0、`screen_retriever` 0.2.0 → 0.3.0
- 上游把 `window_manager` 迁移到 `lib/utils/desktop/`（`calc_window_position.dart`
  从 `lib/utils/` 移入）

### 本机测试跑不了的原因（不是代码问题）

`nativeapi` 带 native build hook（`cnativeapi` + `native_toolchain_c`），
在 Windows 上需要 MSVC：

```
No compiler set in BuildInput.cCompiler.cc.
Found no Visual Studio Locator in [...]
No Visual Studio installation found with the requested
Microsoft.VisualStudio.Component.VC.Tools.x86.x64 component.
Building native assets failed.
```

本机没装 VS Build Tools → `flutter test` 全部失败。CI 跑 Linux/macOS，不受影响。
**本机可用的验证只剩 `flutter analyze`**（40 条 info，0 error / 0 warning）。

### fork 逻辑存活核查（逐条确认）

`mobileHeartBeat`（3）、`column_timestamp`、`login_event`、
`_writePlaybackProgress`（2）、`history.completed.early`、`hasSource`（2）、
`_initControllers`（3）、`class DiagLog`、`genSession`、`RecLabelAction`（2）
—— 命中数全部 ≥1，`rcmdVideoListApp` 的实测参数
（`device: pad` / `mobi_app: android_hd` / `column: 2` / `video_mode: 1` /
`voice_balance: 1` / `login_event` 冷热启动区分 / `flush` 走参数）逐项核对在位。

### 发布

首次全平台 Release：tag **`v2.1.6.2-fork1`**，一次 `workflow_dispatch` 触发
`build.yml` 的 5 个 job（Android + 通过 `uses:` 复用的 iOS / macOS /
Windows x64 / Linux x64）。签名 secret（`SIGN_KEYSTORE_BASE64`、
`KEYSTORE_PASSWORD`、`KEY_ALIAS`、`KEY_PASSWORD`）已配置。

## 2026-10-18 合并后回归：didPopNext 里 playerInit 空断言

真机日志 `piliplus_log_1792288847632.log`（b314cfe，10/06–10/18，87 条）里
7 次 `Null check operator`，其中 6 次是老的框架语义崩溃（`object.dart:6271`），
**第 7 次是上游合并引入的新回归、在我们自己的代码里**：

```
#0 VideoDetailController.playerInit (pages/video/controller.dart:750)
#1 _VideoDetailPageVState.didPopNext  (pages/video/view.dart:454)
```

**根因**：`didPopNext`（从子页面返回）里两条分支不对称 ——
`preInitPlayer` 那条检查了 `videoUrl != null`，而 `autoPlay` 那条没有。
若此时 `onReset` 已把 `videoUrl` 置空（换 P / 换视频还没取完流），
`playerInit` 会走到 `videoSource: videoUrl!` 并抛空断言。

**修复**（`dc1c06f66`）：给 `autoPlay` 分支补同样的判空，
并保留本地文件播放路径（`isFileSource` 本来就不需要 `videoUrl`）：

```dart
final hasSource = isFileSource || videoUrl != null;
if (autoPlay && hasSource) { playerInit(...); }
```

**同段日志的其余结论**

- `拦下误报的"已看完"` 触发 **9 次**，全部拦下（含 1754s/1743s、
  3458s/3419s 这类接近片尾的边界，说明只在真到位时才放行）
- 无 `heartbeat.fail` / `history.*.fail` —— 上游播放器大改（4 次
  `opt update PlaybackState` 等）**没有破坏上报链路**
- `grpc 非 0 状态 ... code=-304 msg=木有改动`（弹幕无变化）4 次，属业务码噪音
- 其余是网络类：`tls handshake -0x4e/-0x7280`、`ffurl_write 0xffffff99`、
  `Stream ends prematurely`、`Invalid OBU length`（AV1 解码）、DNS 失败
- `grpc 取流失败 ... 取流超时（10 秒无响应）` 3 次 —— 网络，已正确回退

## 2026-10 上游同步 2.1.3 → 2.1.6（125 个提交）

合并 `upstream/main`（`4ed5968f3` Release 2.1.6），291 个文件，**只有 2 个文件冲突**。

**上游带来的关键变化**

- **Flutter 3.47.2 → 3.47.6**（`366d6de18`）+ `.fvmrc` 同步；`material_ui` 解析到
  **1.5.0**（原 1.2.0）
- 依赖源换成上游的 fork：`media-kit`（`My-Responsitories` + `bggRGjQaUbCoE`）、
  `audio_session`(dev)、`font_awesome_flutter`、`cached_network_image_ce`、
  `flutter_inappwebview` 等；`file_picker ^13.1.0`
- 播放器大改：`refa player bar`、`opt set playback speed`、
  `skip to next/prev from audio session`、`opt update PlaybackState`（4 次）
- 新功能：离线合集/离线跳过、iOS 画中画、转发时回复、搜索全量、桌面 webview 等

**冲突解决（2 处，结论要留着）**

1. `lib/http/video.dart` —— 上游改了 app 推荐参数与过滤 API
   - **保留 fork 的实测参数**（`column_timestamp` / `device:pad` /
     `device_name` 动态获取 / `flush` 走参数 / `login_event` / `video_mode` /
     `voice_balance`）—— 这是归因心跳生效的前提，**别再被上游默认值覆盖**
   - **采纳上游的 `_filterAppRcmd` + `RecommendFilter.filterWithExempt`**
     （上游已把 `filter()` 改名，全仓无旧调用点）
   - **保留 fork 的 `try/catch`**（单条脏数据不该让首页空白）
2. `lib/pages/episode_panel/view.dart` —— 上游只把 `Future.delayed` 换成
   `Future.pause`，**并没有修**那个 RangeError
   - **保留 fork 的控制器重建修复**（`_initControllers` +
     `_tabIndex` / `_safeInitialTabIndex` 夹取），采纳上游的 `Future.pause` 写法

**补丁与本地环境**

- 合并后必须重打补丁（SDK 与 material_ui 都换版本了）。按 CI 流程本地验证：
  `patch.ps1 android` 在 **Flutter 3.47.6 + material_ui 1.5.0** 下
  **25 个 SDK 补丁 + 9 个 material 补丁全部应用成功**
- `patch.ps1` 在 **Windows 本地**直接跑会失败：android/ios/linux/macos 分支用
  `~/.pub-cache`，只有 windows 分支用 `$env:LOCALAPPDATA/Pub/Cache`（CI 的 Linux
  约定）。本机建一个 `~/.pub-cache` 目录联接指向真实缓存即可
- `patch.ps1` 开头会把**全局 git 身份**改成 `ci/example@example.com`，
  在开发者机器上跑完记得改回来
- 上游自 `d1d5c323c` 起使用 `Future.pause(...)`（6 处），仓库与依赖里均无定义
  —— 它是 **Flutter 3.47.6 的 API**，这也是本次必须升 SDK 的直接原因

**验证**：`flutter analyze` 39 条 info（与合并前一致，**0 error 0 warning**）；
`flutter test` **19/19 通过**；CI 构建 `b314cfe26` **success**（22.5 MB ×2）。

**遗留风险**：上游播放器大改与 fork 的上报分层（`send()` /
`_writePlaybackProgress`）落在同一文件（上游改了 395 行），编译通过但**行为只能
在真机确认** —— 重点看心跳/历史是否仍正常（日志里不该有 `heartbeat.fail`、
`history.*.fail`），以及倍速、上/下一个、进度条是否正常。

## 2026-09-22 时长对账：上报值是对的，播放器实测值不可靠（删掉误报日志）

装上 `47ccbd66d` 后的真机日志（`piliplus_log_1789993045198.log`，09/18~09/21）
里 `上报时长与播放器实测不一致` 报了 **12 次**，看着像"时长还是不对"。
于是把三方拉出来对账（脚本 `bilibili/check_duration3.py`：上报值 vs 播放器实测值
vs 公开接口的真实时长）：

| aid | 真实 | 上报(ctx) | 实测(播放器) |
|---|---|---|---|
| 116937984055032 | 1456s | **1455s** ✅ | 886s ❌ |
| 117060105408540 | 175s | **174s** ✅ | 1360s ❌ |
| 117282420294520 | 162s | **161s** ✅ | 1104s ❌ |
| 117274702775460 | 763s | **762s** ✅ | 193s ❌ |

**上报值 11/11 与真实一致**（差 1s 来自 `~/1000` 取整），
**播放器实测值 0/11 准确**（既偏小 886/1456，又偏大 1360/175 —— 疑似 EDL
播放列表加载不全，或残留了上一个视频的时长）。

结论与改动：

- `report.duration.mismatch` 属**误报**（拿不可信基线去比可信值），删除；
  取流模型的时长仍是权威来源
- 播放器实测值只在 `ctx.videoDuration <= 0`（gRPC 路径没给 timelength）时兜底，
  并按异常记 `report.duration.missing` / `report.duration.zero`

顺带确认本轮真机表现：`拦下误报的"已看完"` 触发 2 次并**正确拦下**
（其中一次正是"切视频后 completed 落到新 ctx"那种串场：播放器 27s/27s、
会话最大进度 0s/190s → 本次不报）；整段没有 `history.*` 失败，
**也没有再出现语义崩溃**（上一份日志 6 天 5 次，本段 3.5 天 0 次）。

## 2026-09-18 分集面板 index 越界崩溃（真机 RangeError）

真机日志（`piliplus_log_1789704124003.log`，09/16 22:26 连续三条）抓到分集面板崩溃：

```
RangeError (length): Invalid value: Not in inclusive range 0..5: 6
  #1 _IndicatorPainter.centerOf (material_ui/src/tabs.dart:604)   ← TabBar 指示器
  #2 _TabBarState._tabScrollOffset → _handleTabControllerTick
RangeError (length): Invalid value: Not in inclusive range 0..4: 5
  #1 _EpisodePanelState._buildBody (pages/episode_panel/view.dart)
RangeError (length): Invalid value: Not in inclusive range 0..4: 6
  #0 _EpisodePanelState.didUpdateWidget.jumpToCurrent (pages/episode_panel/view.dart)
```

**根因**：`EpisodePanel` 的 tab 控制器与每个 tab 的滚动控制器都是 `late final`，
只在 `initState` 按当时的 `widget.list.length` 建一次；而分集数据会在**同一个
State** 上变长变短（合集加载完从 1 个 tab 变成 N 个、切视频、番剧换季），
`widget.initialTabIndex` 又是父级按新列表算的 —— index 于是落到控制器列表之外，
连插件内部的 TabBar 指示器也一起越界。

**修复**：

- `_initControllers()` 抽出来，`initState` 与 `didUpdateWidget`（列表长度变化时）
  都调用；重建前 dispose 旧的 tab / 滚动控制器
- 所有取下标的地方统一夹到 `[0, list.length-1]`：新增 `_tabIndex`（当前 tab）
  与 `_safeInitialTabIndex`（父级给的初始 tab），替换 `_getCurrEpisodes`、
  `_animToTopOrBottom`、跳至当前、顺序/倒序按钮等 6 处
- `_getCurrEpisodes` 对空列表返回空，避免 `widget.list[0]` 越界

## 2026-09-14 没看完的视频被标成"已看完"（第二道拦截 + 构建身份可辨）

反馈"当前包下仍有没看完的视频被归为已看完"。先从日志确认在跑的到底是哪版：
`piliplus_log_1789361123441.log` 里直到 09/14 12:07 都还有 `mobileHeartBeat ok`、
`首页推荐拉取`、`心跳节流生效` 这些在 `7a6bebc9b` 就删掉的"成功日志" —— 说明
当时跑的是 `c71b94ea4`，**`history.completed.early` 拦截（`e1cdac31f`）根本不在包里**。

在此基础上把拦截做扎实（原来只有一个判据）：

- **① 播放器自证**：`duration - position <= 1s`（播放器实测值最可信；切视频后
  position 归零，这一条就能拦下把刚打开的视频标成已看完）
- **② 会话自证**：本次会话 `maxProgress` 到过片尾（拦 media_kit 的 `completed`
  事件落到**新的** `reportContext` 上那种串场）
- 两条都过不了就不报 `-1`：有可信进度就按实际进度上报，没有就**本次不报**
  （position 可能是上一个视频的，报什么都不对；周期心跳本来就在持续写进度）

顺带解决"这份日志是哪版跑出来的"这个反复踩的坑：

- CI 构建加 `--dart-define=pili.hash=$(git rev-parse --short HEAD)`，
  `BuildConfig.commitHash` 会进每条日志的 `customParameters` —— 以后拿到导出的
  日志一眼就能确认构建（**不传** `pili.time`，自构建版本靠 `buildTime == 0`
  跳过更新检查，这个行为要保留）

## 2026-09-12 历史进度不再更新（真机：看5分钟记00:15）—— 根因与修复

反馈："实际看了 5:00，记录却是 00:15，从历史记录再点进去从 00:15 开始。"

**根因**：fork 把上游写入观看进度的通道**降级成了兜底**。

- 上游 `bggRGjQaUbCoE/PiliPlus` 的 `makeHeartBeat` 里，`send()` 就是
  `VideoHttp.heartBeat(...)` —— 打 `/x/click-interface/web/heartbeat`，
  表单里的 `played_time` **就是进度秒数**（看完传 -1），并级联出历史记录进度；
  节流规则是 `playing` 进度每 +5s、`status` 每 +2s、`completed` 强制一次
- `c7e5fb0ea`（归因心跳）把 `send()` 换成了 mobile 心跳，
  `59081212b` 又加了 `/x/v2/history/report` 写历史，web 心跳只剩
  "手机心跳失败才回退" 的兜底 —— 于是它基本不再被调用，历史进度停更
- 日志能印证：`reportHistory failed -400` 刷了 514 行（APP 身份被拒），
  cookie 兜底返回 code=0 但**并不落库**（否则真机上进度不会停在 00:15），
  而 mobile 心跳本身"只做归因不写历史"，`2130fa9fd` 的注释也写明了这点
- 等于三条路里：APP 身份被拒、cookie 路径空转、只有被降级的 web 心跳真能写

**修复**：把两件事解耦，各走各的通道

- ① **写观看进度**：有 cookie 就每次 `send()` 都发 web 心跳
  `/x/click-interface/web/heartbeat`（上游通道，节流仍用上游的
  playing +5s / status +2s / completed 强制）；只有 access_key、没有 csrf 的
  账号才退到 `/x/v2/history/report`
- ② **归因心跳**：mobile 心跳保持 60s 一次，只做推荐归因，不再承担写历史
- 去掉了"手机心跳失败→回退 web 心跳""历史上报失败→回退 web 心跳"两条兜底链：
  web 心跳现在是每次都发的主通道，兜底逻辑反而会掩盖它没发这件事

上一节的两处加固（时长兜底、误报"已看完"拦截）保留，它们解决的是另一类症状。

## 2026-09-12 历史记录的时长/进度可信化

反馈"历史记录的视频时长与真实的相悖"。先把上报值拿来对账：把日志里 8 条
`mobileHeartBeat` 的 `video_duration` 与公开的 `/x/web-interface/view`
逐分P真实时长比对（脚本 `bilibili/check_duration.py`），**8/8 一致**
（差值都是 -1s，来自 `timelength(ms) ~/ 1000` 的向下取整）：

```
aid 117233464379094  cid 41684437830  real 124s   reported 123s
aid 117133841336527  cid 41134588587  real 2102s  reported 2101s   … 全部一致
```

所以**上报的时长本身是对的**，对不上的更可能是历史记录角标里的"已看完"状态
（`pages/history/widgets/item.dart`：`progress == -1` 时角标显示"已看完"，
否则显示 `进度/时长`）。据此做两处加固：

- **时长兜底**：`VideoReportContext.videoDuration` 改为可变。取流模型
  （`PlayUrlModel.timeLength`）在 gRPC 路径上可能为 0，上报前用播放器实测
  时长（`durationInMilliseconds`）补齐；仍然拿不到就按异常记
  `report.duration.zero`，与实测值差 >2s 记 `report.duration.mismatch`
- **"已看完"必须名副其实**：`media_kit` 的 `completed` 事件在切视频/重新
  `open` 播放列表时也可能落到**新的** `reportContext` 上，把刚打开的视频报成
  "已看完"。现在用会话内最大进度兜一道：`maxProgress < videoDuration - 5s`
  就不允许标记看完，改为如实上报实际进度，并记 `history.completed.early`
  （宁可显示进度，也不要把没看完的标成已看完）

排查脚本 `bilibili/check_duration.py <日志或 grep 结果>` 可复用：它把日志里
上报的 `video_duration` 与真实时长逐条对账。

## 2026-09-12 全链路诊断日志 + 播放历史 -400 修复

真机日志（`piliplus_log_1789220265150.log`）统计出来的两类问题：

**1. 播放历史 APP 通道 100% 失败，且把日志刷爆**

- **514 次** `[DIAG] reportHistory failed ... {code: -400, message: 请求错误}`：
  `/x/v2/history/report` 的 access_key（APP）身份被恒定拒绝；同期心跳
  `mobileHeartBeat ok {code: 0}`（同一套 appkey/sign），说明不是签名问题，
  而是该接口对 app 身份的严格校验。整条日志因此涨到 700KB
- **0 次** cookie 通道失败（`reportHistory(cookie) failed` 一行都没有）：
  说明真正在记历史的一直是 cookie 回退路径
- 修复：**有 cookie（csrf）时优先走 cookie**（与 web 端一致），APP 方式退化为
  无 cookie 账号的兜底；任一条失败自动切另一条并把"可用通道"记进会话
  （不再每条上报都白跑一次注定失败的请求）；两条都失败才记日志
- 顺带补全 APP 方式的头（buvid / session_id / aurora / trace-id），与心跳对齐

**2. 日志刷屏 → 统一诊断日志出口 `lib/utils/diag_log.dart`**

- 原则：**只记出问题的事**。正常播放/正常读写不在日志里留任何行 ——
  排查时看到的每一行都应该是"有东西不对"，所以成功路径一律不写日志
- `DiagLog.log(key, msg)`：同一个 key 前 3 次逐条记，之后每 50 次记一条并带
  累计次数；`DiagLog.once()` 只记第一次（降级/回退/通道切换）
- 有单元测试守护节流行为（`test/utils/diag_log_test.dart`，含"100 次只落 5 行"）

**3. 给 fork 改过的每条链路补上"出问题才出声"的留痕**

| 链路 | 保留的日志（key，全部是异常/降级路径） |
|---|---|
| 4K/app 取流 | `grpc.unreachable`（探测不可达→回退 web）/ `grpc.error` / `grpc.probe.empty` / `grpc.probe.status` / `grpc.probe.err` / `grpc.parse.empty`（服务端没给可用档位） |
| gRPC 传输 | `grpc.transport.err`（断网/超时）/ `grpc.transport.fail` / `grpc.status`（非 0 状态码）/ `grpc.status.err` |
| 心跳 | `heartbeat.fail`（带参数快照）/ `heartbeat.webFallback` |
| 播放历史 | `history.cookie.fail/err`、`history.app.fail/err`（带完整参数）、`history.switch`（换通道）、`history.bothFailed`、`history.webFallback` |
| 首页推荐 | `rcmd.error`（含"保留旧数据 / 显示错误"的判定结果） |
| 内容偏好 | `uinterest.fail`、`uinterest.open.fail`、`uinterest.mng.fail`（带完整请求） |
| 功耗 | `power.hz.empty`（设备没有 ≤61Hz 档位，功能无法生效）/ `power.hz.err` |
| 更新检查 | `update.fail` / `update.err` |
| 日志导出 | `log.export.err` |

**4. 首轮日志验收（装包后）确认全绿，据此删掉了成功路径的日志**

装上新包后导出的 `piliplus_log_1789223730121.log`（22KB，旧日志是 721KB）里
22 行全是"正常"，其中关键三条：

- `uinterest/mng ok action=3` ×6、`action=6`、`action=7` → 内容偏好写接口在真机
  上真的生效了（删自选 / 恢复默认 / 批量加三种 action 全 code=0）
- `reportHistory(cookie) ok` 仅 1 行 → -400 刷屏消失，且没有再触发通道切换
- 没有任何 `Null check operator` → 页面崩溃修复有效

确认这些链路健康后，把它们的成功路径日志（`heartbeat.ok`、`history.*.ok`、
`grpc.ok`、`grpc.parse.ok`、`rcmd.mode/fetch/result/append`、`uinterest.open/more`、
`uinterest/mng ok`、`power.hz.pin/restore`、`update.skip/latest/available`、
日志导出成功）全部删除，`DiagLog.always()` 一并移除。现在正常使用下日志应当
**一行都不产生**。

**5. gRPC 传输层异常不再向上抛**

`GrpcReq.request` 约定返回 `LoadingState`，但传输异常（断网/超时/DNS）此前会
直接抛出，4K 取流的"失败→回退 web"分支根本走不到。现在统一转成
`Error('grpc 请求异常: ...')` 并记日志，回退逻辑得以生效。

**6. 又一轮日志复核（`piliplus_log_1789361123441.log`）去掉一类噪音**

gRPC `code > 0` 是业务码而不是故障：日志里出现的
`grpc 非 0 状态 ... code=12061 msg=UP主已关闭评论区` 属于正常交互结果、
UI 自己会提示，不该进诊断日志。现在业务码只在**取流链路**
（`GrpcUrl.playViewUnite`，fork 自己改的）才记，其余只在系统级失败
（无 code / code ≤ 0）时记。

## 2026-09-12 内容偏好管理（uinterest/mng）契约修正 + 页面崩溃修复

真机日志（`piliplus_log_*.log`）里抓到内容偏好页的三次 `Null check operator
used on a null value`，根因不是接口而是**页面 import 错了 Material**：

- 本 fork 的 `GetMaterialApp` 来自 `bggRGjQaUbCoE/getx.git`（dev 分支），该分支
  已改成 `import 'package:material_ui/material_ui.dart'` → 全 App 注册的是
  **material_ui 的 MaterialLocalizations**
- 内容偏好页此前 import 的是 `package:flutter/material.dart`（全 lib 仅此一处，
  另两处是 @docImport 注释），于是本页 `AppBar/BackButton` 与 `showDialog`
  去查 flutter 侧的 MaterialLocalizations → `Localizations.of` 返回 null
  → `!` 抛异常（日志栈：`_RecommendLabelPageState._backToDefault` →
  `new DialogRoute` → `MaterialLocalizations.of`）
- 修复：改为 `import 'package:material_ui/material_ui.dart'`，与其余 468 个文件一致

深入反编译官方 APK 8.62 的 `com.bilibili.pegasus.recommendlabel` 包后，发现
mng 写接口的字段编码与 action 语义此前都猜错了，导致"提交成功但偏好没变"：

- **字段编码**：`fixed_label` / `unfixed_label` 是**标签名用 "," 拼接的字符串**，
  不是 JSON 数组。官方 Kotlin 侧走 `Jt0.b.a(List<String>)` 拼接，服务端按逗号切分；
  旧实现发 `jsonEncode(list)`（`["动画","游戏"]`），服务端把它当成**一个**标签名，
  于是返回 code=0 却什么都没改
- **action 语义**（来自 `l0#c` 的 7 个调用点，此前只有 1/2 两个猜测值）：
  1=取消固定、2=删除固定标签、3=删除自选标签、4=自选升为固定、5=新增单个标签、
  6=恢复默认、7=批量新增（勾选后一次提交）。旧实现把 1 当成"保存修改"、
  把 2 当成"恢复默认"，两个都是错的
- **快照语义**：每次提交的是**变更后的全量快照**（变更后 is_fixed==1 的标签名 +
  变更后 is_fixed==0 的标签名 + 本次改动的标签名），不是增量
- 编辑页改为对齐官方：勾选/取消勾选 = 我的标签集合的增删；保存时**先逐个删除**
  （固定标签 action 2、自选标签 action 3，官方没有批量删除），**再一次批量新增**
  （action 7）；恢复默认走 action 6（两个列表都提交空且不带 changed_label）
- 接上编辑页的「更多标签」入口（`/x/v2/feed/uinterest/more`，此前 `uinterestMore()`
  是死代码）：底部弹层展示候选池，**默认全部勾选**、一个不勾则按钮置灰、
  文案全部用服务端下发的 title/subtitle/add_button/toast，候选为空时 toast
  "没有更多啦"，与官方 `BottomSheetContent` 的行为一致
- 顺带补齐 `back_to_default_window`（服务端下发的二次确认弹窗文案：title /
  subtitle / cancel_button / confirm_button / toast）
- 新增回归守护：`test/http/recommend_label_test.dart`（字段编码 + action 取值 +
  服务端字段解析）
- 新增真机之外的自证脚本 `bilibili/uinterest_verify.py`：
  `python uinterest_verify.py <access_key>` 只读打印当前偏好；
  加 `--write` 做一次**可回滚**的读写回环（新增 → 确认生效 → 删回）

## 2026-09-10 上游同步

- 合并上游 main（9730d29a8 → 32538c4d7，共 5 个提交：评论区 API 迁移、
  动态优化、依赖升级等），零冲突
- 依赖升级（上游 upgrade deps）：material_ui 1.1.1 → **1.2.0** ——
  升级会丢补丁，已对 1.2.0 重新应用全部 9 个 material 补丁（上游同步适配过）
- 本地脚本注意：material_ui 升级后需重新打补丁（见 apply_patches.ps1）

## 2026-09-09 ~ 2026-09-10

### 4K / 高清播放

- 修复 gRPC 取流探测：改用**不带拦截器的裸 Dio**（AccountManager 会给所有请求补 Referer，
  带 Referer 拉 app 流会被 CDN 403），探测失败静默回退 web 流
- 播放头对齐 bbspace：按流 URL 的 platform 选择 UA/Referer
- 探测**实际会播放的那个 URL**（`getCdnUrl` 选出的可能是 backupUrl，不是 `playUrls.first`），
  避免探测错对象导致误判不可用
- 探测并行化 + 超时收紧（8s→5s），最坏等待从 16s 降到 5s

### 首页推荐

- **移除**本地去重：实测服务端重推概率很低，本地记录的收益不抵复杂度（曾尝试
  删除式过滤与降权沉底，均因第三方客户端拿不到曝光上报、推荐池有限而问题多），
  改为专注把"归因上报"做对（见下）
- **修复首页空白**：请求失败不再被 `handleError` 静默吞掉（无旧数据时正常显示错误）
- 推荐解析加固：空列表 / 脏数据转为可见错误，不再让页面崩溃
- **归因心跳**：播放时上报 `/x/report/heartbeat/mobile`（正确 host 为
  `api.bilibili.com`，签名与表单传输编码严格一致），带 `track_id` /
  `report_flow_data` / `from_spmid`，让服务端知道"这条推荐被消费了"，
  从而服务端侧去重、更新画像 —— 这是改善推荐质量的正路
  - 按官方节奏节流（60s 一次），退出 / 完成时强制上报
  - 被拒时回退 web 心跳，保证进度与历史记录不丢
  - 失败写入可导出日志（含 HTTP 状态码与业务 code），便于定位
  - 修复"退出详情页被上报成看完整部"的语义 bug

### 内容偏好（uinterest）

- 新增「内容偏好调节」页面（设置 → 推荐设置）
- 读：`GET /x/v2/feed/uinterest`（我的标签 / 全部分区 / 近期偏好分布）
- 读：`GET /x/v2/feed/uinterest/more`
- 写：`POST /x/v2/feed/uinterest/mng`（保存修改 / 恢复默认）
- 接口契约逆向自官方客户端 `RecommendLabelApiService`（2026-09）

### 功耗

- **弹幕重绘节流到 60fps**：canvas_danmaku 的 `_tick` 每个 vsync 都全量重绘画布，
  高刷屏上功耗随刷新率线性上涨；加时间闸门后重绘减半，视觉无损
- **全屏时临时钉 ≤60Hz**（Android），退出全屏恢复用户设置

### 构建 / CI

- 新增 `lib/scripts/danmaku_throttle.patch`，接入 CI 的 `patch.ps1` 与本地 `apply_patches.ps1`
- 桌面端（Windows / Linux）构建无需改动：`lib/` 共享代码自动包含，
  补丁由各平台 workflow 的 Apply Patch 步骤完成，Flutter 版本由 pubspec 锁定在 3.47.2（补丁锚点）

### 日志

- 日志页面新增「导出日志」：把 `.pili_logs.json` 通过系统分享面板导出，便于反馈问题

### 真机验证结果

- ✅ **归因心跳已打通**：真机日志 `mobileHeartBeat ok http=200: {code: 0}`
  （参数表按官方 APK 8.62 的 `HeartbeatParams` 逐字段对齐；关键点是
  `appkey` 必须同时出现在请求体里，只用于签名会导致服务端 -400）
- ✅ 内容偏好写接口的 action 取值已校准（见 2026-09-12 一节：1/2 的猜测作废，
  正确语义为 2=删固定 / 3=删自选 / 6=恢复默认 / 7=批量新增）
- ⏳ 弹幕节流 / 全屏 60Hz 的功耗改善幅度待实测对比
