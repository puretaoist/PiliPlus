# 变更日志

本文件记录本 fork（puretaoist/PiliPlus）相对上游 bggRGjQaUbCoE/PiliPlus 的改动。

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
