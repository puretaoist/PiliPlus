# 改动影响面审计清单

> 背景：2026-09-10 的三轮回归（首页空白、body 缺 appkey、历史断记）都源于
> "改了 A 没审计 A 承担的其他职责"。每次修改播放/上报/首页相关代码后，
> 过一遍本清单。

## 核心链路与验证方式

| # | 链路 | 涉及文件 | 验证方式 |
|---|---|---|---|
| 1 | 播放 → mobile 心跳归因 | `http/video.dart` `mobileHeartBeat`、`pl_player/controller.dart` `send()` | **本地脚本** `bilibili/hb_verify.py`（code=0）；真机日志 `mobileHeartBeat ok` |
| 2 | 播放 → 历史记录 | `http/video.dart` `reportHistory` | 看视频 1 分钟 → App 历史记录页出现；真机日志无报错 |
| 3 | 首页 → 推荐加载/刷新 | `pages/rcmd/controller.dart` `handleListResponse` | 首页首次加载 + 下拉刷新 + 连续刷新 3 次 |
| 4 | 4K/app 流探测 | `pages/video/controller.dart` `_probeGrpcStream` | 播放视频，日志无 "grpc stream unreachable"（有则回退 web，属预期） |
| 5 | 内容偏好读写 | `http/recommend_label.dart` | 设置页打开偏好页；保存后重进确认 |
| 6 | 弹幕渲染 | `scripts/danmaku_throttle.patch` | 开弹幕播放，肉眼确认流畅度 |

## 已知的"一改就坏"陷阱

1. **rcmd `handleListResponse` 里的 `dataList`**：运行时是
   `List<RcmdVideoItemXxx>`（泛型具体化）。对它 `addAll(Iterable<dynamic>)`
   （包括 `response.take(n)` 的返回值和任何 `List<dynamic>`）会触发集合类型
   检查抛异常 → 首页空白/刷新失败。**只能逐元素 add 或逐索引赋值**。
2. **心跳的 `appkey`**：必须同时出现在【签名计算】和【请求体】里。只参与签名
   会被服务端 -400（参数校验先于验签）。
3. **`Request()` 的全局拦截器**（AccountManager）会覆盖 headers、补 web
   referer、重算 sign。任何需要"干净 app 身份"的请求必须用独立 Dio
   （参考 `_heartbeatDio` 模式）。
4. **回退链路的副作用**：改"失败回退"逻辑前，先审计回退路径承担的所有职责
   （例：web 心跳回退曾兼职写历史记录）。
5. **material_ui 依赖升级**：pub get 下载干净副本会丢掉全部 9 个 material
   补丁 → 大量 error。升级后必须对新版本重新打补丁（CI 的 patch.ps1 已处理）。
6. **CI pub 缓存**：缓存会保存"已打补丁"的包。新增的 patch 步骤必须做幂等
   （`git apply --check --reverse` 已应用则跳过），参考 danmaku 段。

## 上报参数的权威来源（勿凭记忆修改）

- mobile 心跳：官方 APK 8.62 `tv.danmaku.biliplayerimpl.report.heartbeat.HeartbeatParams`
  （33 字段），反编译产物在 `bilibili/decompiled_rest/`
- 播放历史：`/x/v2/history/report`，参数对齐 bbspace `buildPlaybackHistoryParams`
- 签名：`md5(sorted(biliUrlEncode(k=v)) + appsec)`，**有单元测试守护**
  `test/utils/bili_report_sign_test.dart`（含官方验签期望值）

## 提交前检查（修改上述文件时）

- [ ] `flutter analyze` 0 error 0 warning
- [ ] `flutter test` 全绿
- [ ] 若改了心跳/历史参数：跑 `bilibili/hb_verify.py`（应 code=0）
- [ ] 若改了回退/失败路径：核对回退路径承担的职责是否都有替代
- [ ] 若改了 UI 可见行为：CHANGELOG.md 补一行
