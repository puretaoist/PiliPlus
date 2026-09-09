import 'dart:convert';

import 'package:PiliPlus/common/constants.dart';
import 'package:PiliPlus/grpc/bilibili/app/playerunite/v1/playerunite.pb.dart'
    as pu;
import 'package:PiliPlus/grpc/bilibili/metadata.pb.dart';
import 'package:PiliPlus/grpc/bilibili/metadata/device.pb.dart';
import 'package:PiliPlus/grpc/bilibili/playershared.pb.dart' as ps;
import 'package:PiliPlus/grpc/grpc_req.dart';
import 'package:PiliPlus/grpc/url.dart';
import 'package:PiliPlus/http/browser_ua.dart';
import 'package:PiliPlus/http/init.dart';
import 'package:PiliPlus/http/loading_state.dart';
import 'package:PiliPlus/models/common/account_type.dart';
import 'package:PiliPlus/models/common/video/audio_quality.dart';
import 'package:PiliPlus/models/common/video/video_quality.dart';
import 'package:PiliPlus/models/video/play/url.dart';
import 'package:PiliPlus/utils/accounts.dart';
import 'package:PiliPlus/utils/login_utils.dart';
import 'package:dio/dio.dart' show Options;
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
          // 与 bbspace 下载路径一致（4048 含 4K/HDR/8K/AV1 格式）
          fnval: 4048,
          download: 0,
          forceHost: 1, // 让服务端下发 https 流地址（明文 http 在 Android 9+ 会被拦截）
          preferCodecType: switch (preferCodec) {
            1 => ps.CodeType.CODE264,
            3 => ps.CodeType.CODEAV1,
            _ => ps.CodeType.CODE265,
          },
          // 对应 bbspace 的「需要4k」开关（试看流）
          isNeedTrial: needTrial,
        ),
        bvid: bvid ?? '',
        spmid: 'united.player-video-detail.0.0',
        fromSpmid: 'tm.recommend.0.0',
        fromScene: 'normal',
        playCtrl: ps.PlayCtrl.PLAY_CTRL_DEFAULT,
        extraContent: const {
          'short_edge': '1080',
          'long_edge': '1920',
        }.entries,
      ),
      pu.PlayViewUniteReply.fromBuffer,
      headers: await _phoneAppHeaders(),
    );

    switch (res) {
      case Success(:final response):
        return _toPlayUrlModel(response);
      case Error():
        return res;
      case Loading():
        return res;
    }
  }

  static String? _remoteBuvid;

  /// 取服务端下发的 buvid（本地生成的 buvid 服务端可能不认识）
  static Future<String> _buvid() async {
    if (_remoteBuvid != null) {
      return _remoteBuvid!;
    }
    try {
      final res = await Request().get(
        'https://api.bilibili.com/x/web-frontend/getbuvid',
        options: Options(
          headers: {
            'user-agent': BrowserUa.mob,
            'referer': 'https://www.bilibili.com',
          },
        ),
      );
      if (res.data?['data']?['buvid'] case final String buvid
          when buvid.isNotEmpty) {
        return _remoteBuvid = buvid;
      }
    } catch (_) {}
    return _remoteBuvid = LoginUtils.buvid;
  }

  /// 官方手机版（android）的客户端身份头。
  /// PiliPlus 默认用 HD/电视版身份（android_hd、appId 5），
  /// 两者的画质档位授权不同；这里按手机版身份请求（bbspace 默认也是手机版）。
  static Future<Map<String, String>> _phoneAppHeaders() async {
    const build = 8620300;
    const channel = '360';
    final buvid = await _buvid();
    final accessKey = Accounts.get(AccountType.main).accessKey;
    return {
      'app-key': 'android64',
      'user-agent': Constants.userAgentApp,
      'buvid': buvid,
      'x-bili-device-bin': base64Encode(
        Device(
          appId: 1,
          build: build,
          buvid: buvid,
          mobiApp: 'android',
          platform: 'android',
          channel: channel,
          brand: 'android',
          model: 'android',
          osver: '15',
          versionName: '8.62.0',
        ).writeToBuffer(),
      ),
      'x-bili-metadata-bin': base64Encode(
        Metadata(
          accessKey: accessKey,
          mobiApp: 'android',
          device: 'android',
          build: build,
          channel: channel,
          buvid: buvid,
          platform: 'android',
        ).writeToBuffer(),
      ),
    };
  }

  /// 把 PlayViewUniteReply 映射成 web 接口同构的 PlayUrlModel，
  /// 下游（画质选择、播放器、下载）无需改动
  static LoadingState<PlayUrlModel> _toPlayUrlModel(
    pu.PlayViewUniteReply reply,
  ) {
    final vod = reply.vodInfo;

    // 同一画质可能有多条流（不同编码），按画质分组
    final grouped = <int, List<ps.Stream>>{};
    for (final stream in vod.streamList) {
      final info = stream.streamInfo;
      if (info.quality <= 0 ||
          !_qualityKnown(info.quality) ||
          _dashOf(stream) == null) {
        continue;
      }
      grouped.putIfAbsent(info.quality, () => []).add(stream);
    }
    if (grouped.isEmpty) {
      final total = vod.streamList.length;
      final dashCount = vod.streamList.where((s) => s.hasDashVideo()).length;
      final multiCount =
          vod.streamList.where((s) => s.hasMultiDashVideo()).length;
      return Error(
        '取流失败：服务端返回 $total 条流（dash=$dashCount, multi=$multiCount）',
      );
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
        final dash = _dashOf(stream)!;
        final codec = _codecString(dash.codecid);
        codecs.add(codec);
        videos.add(
          VideoItem(
            id: quality,
            baseUrl: _https(dash.baseUrl),
            backupUrl: dash.backupUrl.map(_https).toList(),
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

    final model = PlayUrlModel(
      quality: vod.quality > 0 ? vod.quality : videos.first.id,
      timeLength: vod.timelength.toInt(),
      acceptQuality: qualities,
      acceptDesc: descriptions,
      videoCodecid: vod.videoCodecid,
      dash: Dash(video: videos, audio: audios.isEmpty ? null : audios),
      supportFormats: formats,
    );
    return Success(model);
  }

  // 明文 http 在 Android 9+ 默认被拦截，统一升级为 https
  static String _https(String url) =>
      url.startsWith('http://') ? 'https://${url.substring(7)}' : url;

  /// 高画质流可能放在 multiDashVideo 里（app 接口对 HDR/8K 等会这样返回），
  /// 取其中第一条可用的 dash 流
  static ps.DashVideo? _dashOf(ps.Stream stream) {
    if (stream.hasDashVideo() && stream.dashVideo.baseUrl.isNotEmpty) {
      return stream.dashVideo;
    }
    if (stream.hasMultiDashVideo()) {
      for (final dash in stream.multiDashVideo.dashVideos) {
        if (dash.baseUrl.isNotEmpty) {
          return dash;
        }
      }
    }
    return null;
  }

  static AudioItem? _toAudio(ps.DashItem item) {
    if (item.baseUrl.isEmpty || !_audioKnown(item.id)) {
      return null;
    }
    return AudioItem.fromJson({
      'id': item.id,
      'baseUrl': _https(item.baseUrl),
      'backupUrl': item.backupUrl.map(_https).toList(),
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
