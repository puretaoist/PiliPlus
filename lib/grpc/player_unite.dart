import 'package:PiliPlus/grpc/bilibili/app/playerunite/v1/playerunite.pb.dart'
    as pu;
import 'package:PiliPlus/grpc/bilibili/playershared.pb.dart' as ps;
import 'package:PiliPlus/grpc/grpc_req.dart';
import 'package:PiliPlus/grpc/url.dart';
import 'package:PiliPlus/http/loading_state.dart';
import 'package:PiliPlus/models/common/video/audio_quality.dart';
import 'package:PiliPlus/models/common/video/video_quality.dart';
import 'package:PiliPlus/models/video/play/url.dart';
import 'package:fixnum/fixnum.dart';

/// app 端 gRPC 取流（PlayViewUnite）
///
/// 与 web 取流（VideoHttp.videoUrl）的差别：请求体里可带 VideoVod.isNeedTrial，
/// 服务端按试看策略下发高画质流；返回的每条流仍带 needVip/needLogin 标记，
/// 最终能不能播由服务端返回的 URL 决定。
abstract final class PlayerUniteGrpc {
  static Future<LoadingState<PlayUrlModel>> playViewUnite({
    required int aid,
    required int cid,
    required int qn,
    bool needTrial = false,
    int preferCodec = 2, // 1=AVC, 2=HEVC, 3=AV1
    String? bvid,
  }) async {
    final res = await GrpcReq.request(
      GrpcUrl.playViewUnite,
      pu.PlayViewUniteReq(
        vod: ps.VideoVod(
          aid: Int64(aid),
          cid: Int64(cid),
          qn: Int64(qn),
          fnver: 0,
          fnval: 4048,
          download: 0,
          fourk: true,
          preferCodecType: switch (preferCodec) {
            1 => ps.CodeType.CODE264,
            3 => ps.CodeType.CODEAV1,
            _ => ps.CodeType.CODE265,
          },
          isNeedTrial: needTrial,
        ),
        bvid: bvid ?? '',
        spmid: 'main.ugc-video-detail.0.0',
        fromSpmid: 'main.ugc-video-detail.0.0',
        fromScene: '0',
        playCtrl: ps.PlayCtrl.PLAY_CTRL_DEFAULT,
        extraContent: const {
          'short_edge': '1080',
          'long_edge': '1920',
        }.entries,
      ),
      pu.PlayViewUniteReply.fromBuffer,
    );

    switch (res) {
      case Success(:final response):
        final model = _toPlayUrlModel(response);
        return model == null
            ? const Error('取流失败：没有可用的视频流')
            : Success(model);
      case Error():
        return res;
      case Loading():
        return res;
    }
  }

  /// 把 PlayViewUniteReply 映射成 web 接口同构的 PlayUrlModel，
  /// 下游（画质选择、播放器、下载）无需改动
  static PlayUrlModel? _toPlayUrlModel(pu.PlayViewUniteReply reply) {
    final vod = reply.vodInfo;

    // 同一画质可能有多条流（不同编码），按画质分组
    final grouped = <int, List<ps.Stream>>{};
    for (final stream in vod.streamList) {
      final info = stream.streamInfo;
      if (info.quality <= 0 ||
          stream.dashVideo.baseUrl.isEmpty ||
          !_qualityKnown(info.quality)) {
        continue;
      }
      grouped.putIfAbsent(info.quality, () => []).add(stream);
    }
    if (grouped.isEmpty) {
      return null;
    }

    // findAvailableVideoQuality 依赖“高画质在前”的顺序
    final qualities = grouped.keys.toList()..sort((a, b) => b.compareTo(a));
    final videos = <VideoItem>[];
    final formats = <FormatItem>[];
    final descriptions = <String>[];
    for (final quality in qualities) {
      final streams = grouped[quality]!;
      final info = streams.first.streamInfo;
      final codecs = <String>{};
      for (final stream in streams) {
        final dash = stream.dashVideo;
        final codec = _codecString(dash.codecid);
        codecs.add(codec);
        videos.add(
          VideoItem(
            id: quality,
            baseUrl: dash.baseUrl,
            backupUrl: dash.backupUrl,
            bandWidth: dash.bandwidth,
            mimeType: 'video/mp4',
            codecs: codec,
            width: dash.width,
            height: dash.height,
            frameRate: dash.frameRate,
            codecid: dash.codecid,
            quality: VideoQuality.fromCode(quality),
          ),
        );
      }
      final desc = info.newDescription.isNotEmpty
          ? info.newDescription
          : info.description;
      descriptions.add(desc);
      formats.add(
        FormatItem(
          quality: quality,
          format: info.format,
          newDesc: desc,
          displayDesc: info.displayDesc,
          codecs: codecs.toList(),
        ),
      );
    }

    final audios = <AudioItem>[];
    for (final item in vod.dashAudio) {
      final audio = _toAudio(item);
      if (audio != null) {
        audios.add(audio);
      }
    }
    if (vod.hasDolby() && vod.dolby.type != ps.DolbyItem_Type.NONE) {
      for (final item in vod.dolby.audio) {
        final audio = _toAudio(item);
        if (audio != null) {
          audios.add(audio);
        }
      }
    }
    if (vod.hasLossLessItem() &&
        vod.lossLessItem.isLosslessAudio &&
        vod.lossLessItem.hasAudio()) {
      final audio = _toAudio(vod.lossLessItem.audio);
      if (audio != null) {
        audios.add(audio);
      }
    }

    return PlayUrlModel(
      quality: vod.quality > 0 ? vod.quality : videos.first.id,
      timeLength: vod.timelength.toInt(),
      acceptQuality: qualities,
      acceptDesc: descriptions,
      videoCodecid: vod.videoCodecid,
      dash: Dash(video: videos, audio: audios.isEmpty ? null : audios),
      supportFormats: formats,
    );
  }

  static AudioItem? _toAudio(ps.DashItem item) {
    if (item.baseUrl.isEmpty || !_audioKnown(item.id)) {
      return null;
    }
    return AudioItem.fromJson({
      'id': item.id,
      'baseUrl': item.baseUrl,
      'backupUrl': item.backupUrl,
      'bandwidth': item.bandwidth,
      'codecid': item.codecid,
    });
  }

  // VideoQuality/AudioQuality 的 fromCode 对未知取值会抛异常，先过滤
  static bool _qualityKnown(int code) =>
      VideoQuality.values.any((e) => e.code == code);

  static bool _audioKnown(int code) =>
      AudioQuality.values.any((e) => e.code == code);

  static String _codecString(int codecid) => switch (codecid) {
    7 => 'avc1',
    12 => 'hev1',
    13 => 'av01',
    14 => 'dvh1',
    _ => 'hev1',
  };
}
