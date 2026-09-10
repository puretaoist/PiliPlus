# 变更日志

本文件记录本 fork（puretaoist/PiliPlus）相对上游 bggRGjQaUbCoE/PiliPlus 的改动。

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

### 待真机验证

- 归因心跳接口返回 `code` 是否为 0（验证签名与参数）
- 内容偏好写接口的 `action` 取值（当前按 1=保存 / 2=恢复默认 实现）
- 弹幕节流 / 全屏 60Hz 的功耗改善幅度
