import 'dart:math';

/// 一次播放会话的推荐归因上下文。
///
/// 由视频详情页在取流成功后挂到 `PlPlayerController.reportContext`，
/// 心跳（/x/report/heartbeat/mobile）读取并上报；切视频/进新页时重建。
/// 其中 trackId/reportData 来自首页 app 推荐的 item（track_id/report_data），
/// 是服务端做"该条推荐已被消费"归因与去重的关键。
class VideoReportContext {
  final int aid;
  final int cid;
  final String? bvid;
  final String? trackId;
  final String? reportData;

  /// 来源 spm：首页推荐流为 tm.recommend.0.0，其余来源留空
  final String from;
  final String fromSpmid;
  final String spmid;
  final int type;
  final int? subType;
  final int? epId;
  final int? seasonId;
  final int videoDuration;
  final int quality;

  /// 播放会话 id，会话内固定
  final String session;

  /// 会话开始的 unix 秒
  final int startTs;

  /// 会话内最大播放进度（秒）
  int maxProgress = 0;

  VideoReportContext({
    required this.aid,
    required this.cid,
    this.bvid,
    this.trackId,
    this.reportData,
    this.from = '',
    this.fromSpmid = '',
    this.spmid = 'united.player-video-detail.0.0',
    this.type = 3,
    this.subType,
    this.epId,
    this.seasonId,
    this.videoDuration = 0,
    this.quality = 0,
  }) : session = _genSession(),
       startTs = DateTime.now().millisecondsSinceEpoch ~/ 1000;

  void updateProgress(int progressSec) {
    if (progressSec > maxProgress) {
      maxProgress = progressSec;
    }
  }

  static final Random _random = Random();

  static String _genSession() {
    final sb = StringBuffer();
    for (var i = 0; i < 32; i++) {
      sb.write(_random.nextInt(16).toRadixString(16));
    }
    return sb.toString();
  }
}
