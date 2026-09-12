import 'dart:convert';
import 'dart:io';

import 'package:PiliPlus/common/constants.dart';
import 'package:PiliPlus/grpc/bilibili/main/community/reply/v1.pb.dart'
    show ReplyInfo;
import 'package:PiliPlus/http/api.dart';
import 'package:PiliPlus/http/browser_ua.dart';
import 'package:PiliPlus/utils/bili_report_sign.dart';
import 'package:PiliPlus/utils/diag_log.dart';
import 'package:PiliPlus/http/init.dart';
import 'package:PiliPlus/http/loading_state.dart';
import 'package:PiliPlus/http/login.dart';
import 'package:PiliPlus/models/common/account_type.dart';
import 'package:PiliPlus/models/common/video/video_type.dart';
import 'package:PiliPlus/models/common/video_report_context.dart';
import 'package:PiliPlus/utils/app_sign.dart';
import 'package:PiliPlus/models/home/rcmd/result.dart';
import 'package:PiliPlus/models/model_hot_video_item.dart';
import 'package:PiliPlus/models/model_rec_video_item.dart';
import 'package:PiliPlus/models/pgc_lcf.dart';
import 'package:PiliPlus/models/video/play/url.dart';
import 'package:PiliPlus/models_new/pgc/pgc_rank/pgc_rank_item_model.dart';
import 'package:PiliPlus/models_new/popular/popular_precious/data.dart';
import 'package:PiliPlus/models_new/popular/popular_series_list/list.dart';
import 'package:PiliPlus/models_new/popular/popular_series_one/data.dart';
import 'package:PiliPlus/models_new/triple/pgc_triple.dart';
import 'package:PiliPlus/models_new/triple/ugc_triple.dart';
import 'package:PiliPlus/models_new/video/video_ai_conclusion/data.dart';
import 'package:PiliPlus/models_new/video/video_detail/data.dart';
import 'package:PiliPlus/models_new/video/video_note_list/data.dart';
import 'package:PiliPlus/models_new/video/video_play_info/data.dart';
import 'package:PiliPlus/models_new/video/video_relation/data.dart';
import 'package:PiliPlus/models_new/video/video_shot/data.dart';
import 'package:PiliPlus/utils/accounts.dart';
import 'package:PiliPlus/utils/extension/string_ext.dart';
import 'package:PiliPlus/utils/global_data.dart';
import 'package:PiliPlus/utils/id_utils.dart';
import 'package:PiliPlus/utils/recommend_filter.dart';
import 'package:PiliPlus/utils/request_utils.dart';
import 'package:PiliPlus/utils/storage.dart';
import 'package:PiliPlus/utils/storage_pref.dart';
import 'package:PiliPlus/utils/subtitle_utils.dart';
import 'package:PiliPlus/utils/utils.dart';
import 'package:PiliPlus/utils/wbi_sign.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show compute;
import 'package:protobuf/protobuf.dart';

/// view层根据 status 判断渲染逻辑
abstract final class VideoHttp {
  static RegExp zoneRegExp = RegExp(Pref.banWordForZone, caseSensitive: false);
  static bool enableFilter = zoneRegExp.pattern.isNotEmpty;

  static String? _deviceModel;
  // 官方 app 会带上真实机型，这里同样带上（取不到就退回 android）
  static Future<String> _deviceName() async {
    if (_deviceModel != null) return _deviceModel!;
    try {
      _deviceModel = Platform.isAndroid
          ? (await DeviceInfoPlugin().androidInfo).model
          : Platform.operatingSystem;
    } catch (_) {
      _deviceModel = 'android';
    }
    return _deviceModel!;
  }

  // 首页推荐视频
  static Future<LoadingState<List<RcmdVideoItemModel>>> rcmdVideoList({
    required int ps,
    required int freshIdx,
  }) async {
    final res = await Request().get(
      Api.recommendListWeb,
      queryParameters: await WbiSign.makSign({
        'version': 1,
        'feed_version': 'V8',
        'homepage_ver': 1,
        'ps': ps,
        'fresh_idx': freshIdx,
        'brush': freshIdx,
        'fresh_type': 4,
      }),
    );
    if (res.data['code'] == 0) {
      List<RcmdVideoItemModel> list = <RcmdVideoItemModel>[];
      for (final i in res.data['data']['item']) {
        //过滤掉live与ad，以及拉黑用户
        if (i['goto'] == 'av' &&
            (i['owner'] != null &&
                !GlobalData().blackMids.contains(i['owner']['mid']))) {
          RcmdVideoItemModel videoItem = RcmdVideoItemModel.fromJson(i);
          if (!RecommendFilter.filter(videoItem)) {
            list.add(videoItem);
          }
        }
      }
      return Success(list);
    } else {
      return Error(res.data['message']);
    }
  }

  // app 推荐接口的 idx 是续推游标（刷新传列表首条的 idx、加载更多传末条的 idx），不是页码
  static Future<LoadingState<List<RcmdVideoItemAppModel>>> rcmdVideoListApp({
    required int idx,
    required int flush,
    required bool pull,
  }) async {
    final isCold = idx == 0;
    final params = {
      'build': 2001100,
      'c_locale': 'zh_CN',
      'channel': 'master',
      // column/qn/player_extra_content/video_mode 等对齐 bbspace 的实测参数：
      // column=4 会拉到质量偏差的内容池，qn=32 声明成 480P 也会影响服务端筛选
      'column': 2,
      'column_timestamp': 0,
      'device': 'pad',
      'device_name': await _deviceName(),
      'device_type': 0,
      'disable_rcmd': 0,
      'flush': flush,
      'fnval': 976,
      'fnver': 0,
      'force_host': 2, //使用https
      'fourk': 1,
      'guidance': 0,
      'https_url_req': 0,
      'idx': idx,
      'inline_danmu': 2,
      'inline_sound': 1,
      'interest_id': 0,
      // 会话上下文：冷启动且已登录=2、未登录=1、非冷启动=0
      'login_event': isCold ? (Accounts.main.isLogin ? 2 : 1) : 0,
      'mobi_app': 'android_hd',
      'network': 'wifi',
      'open_event': isCold ? 'cold' : 'hot',
      'platform': 'android',
      'player_extra_content': '{"short_edge":"1080","long_edge":"1920"}',
      'player_net': 1,
      'pull': pull ? 'true' : 'false',
      'qn': 80,
      'qn_policy': 0,
      'recsys_mode': 0,
      's_locale': 'zh_CN',
      'splash_id': '',
      'statistics': Constants.statistics,
      'video_mode': 1,
      'voice_balance': 1,
    };
    final res = await Request().get(
      Api.recommendListApp,
      queryParameters: params,
      options: Options(
        headers: {
          'buvid': LoginHttp.buvid,
          'fp_local': '1111111111111111111111111111111111111111111111111111111111111111',
          'fp_remote': '1111111111111111111111111111111111111111111111111111111111111111',
          'session_id': '11111111',
          'env': 'prod',
          'app-key': 'android_hd',
          'User-Agent': Constants.userAgent,
          'x-bili-trace-id': Constants.traceId,
          'x-bili-aurora-eid': '',
          'x-bili-aurora-zone': '',
          'bili-http-engine': 'cronet',
        },
      ),
    );
    if (res.data['code'] == 0) {
      final data = res.data['data'];
      final items = data is Map ? data['items'] : null;
      if (items is! List || items.isEmpty) {
        // code=0 但列表为空：多为服务端风控/参数问题，带上结构信息便于定位
        return Error('推荐列表为空（items=${items.runtimeType}）');
      }
      final list = <RcmdVideoItemAppModel>[];
      try {
        for (final i in items.whereType<Map>()) {
          // 屏蔽推广和拉黑用户
          if (i['card_goto'] != 'ad_av' &&
              i['card_goto'] != 'ad_web_s' &&
              i['ad_info'] == null &&
              i['can_play'] == 1 &&
              (i['args'] != null &&
                  !GlobalData().blackMids.contains(i['args']['up_id']))) {
            if (enableFilter &&
                i['args']?['tname'] != null &&
                zoneRegExp.hasMatch(i['args']['tname'])) {
              continue;
            }
            RcmdVideoItemAppModel videoItem = RcmdVideoItemAppModel.fromJson(
              i.cast<String, dynamic>(),
            );
            if (!RecommendFilter.filter(videoItem)) {
              list.add(videoItem);
            }
          }
        }
      } catch (e) {
        // 单条脏数据/结构变化不应让首页崩溃，转成可见错误
        return Error('推荐解析异常: $e');
      }
      return Success(list);
    } else {
      return Error(res.data['message']);
    }
  }

  // 最热视频
  static Future<LoadingState<List<HotVideoItemModel>>> hotVideoList({
    required int pn,
    required int ps,
  }) async {
    final res = await Request().get(
      Api.hotList,
      queryParameters: {'pn': pn, 'ps': ps},
    );
    if (res.data['code'] == 0) {
      List<HotVideoItemModel> list = <HotVideoItemModel>[];
      for (final i in res.data['data']['list']) {
        if (!GlobalData().blackMids.contains(i['owner']['mid']) &&
            !RecommendFilter.filterTitle(i['title']) &&
            !RecommendFilter.filterLikeRatio(
              i['stat']['like'],
              i['stat']['view'],
            )) {
          if (enableFilter &&
              i['tname'] != null &&
              zoneRegExp.hasMatch(i['tname'])) {
            continue;
          }
          list.add(HotVideoItemModel.fromJson(i));
        }
      }
      return Success(list);
    } else {
      return Error(res.data['message']);
    }
  }

  // 视频流
  @pragma('vm:notify-debugger-on-exception')
  static Future<LoadingState<PlayUrlModel>> videoUrl({
    int? avid,
    String? bvid,
    required int cid,
    required int qn,
    dynamic epid,
    dynamic seasonId,
    required bool tryLook,
    required VideoType videoType,
    String? language,
    bool voiceBalance = false,
  }) async {
    final dmImgStr = Utils.base64EncodeRandomString(16, 64);
    final dmCoverImgStr = Utils.base64EncodeRandomString(32, 128);
    final params = await WbiSign.makSign({
      'avid': ?avid,
      'bvid': ?bvid,
      'ep_id': ?epid,
      'season_id': ?seasonId,
      'cid': cid,
      'qn': qn,
      // 获取所有格式的视频
      'fnval': 4048,
      'fourk': 1,
      'fnver': 0,
      'voice_balance': voiceBalance ? 1 : 0,
      'gaia_source': 'pre-load',
      'isGaiaAvoided': true,
      'web_location': 1315873,
      // 免登录查看1080p
      if (tryLook) 'try_look': 1,
      'dm_img_list': '[]',
      'dm_img_str': dmImgStr,
      'dm_cover_img_str': dmCoverImgStr,
      'dm_img_inter': '{"ds":[],"wh":[0,0,0],"of":[0,0,0]}',
      'cur_language': ?language,
    });

    try {
      final res = await Request().get(videoType.api, queryParameters: params);

      if (res.data['code'] == 0) {
        late PlayUrlModel data;
        switch (videoType) {
          case .ugc:
            data = PlayUrlModel.fromJson(res.data['data']);

          case .pgc:
            final result = res.data['result'];
            data = PlayUrlModel.fromJson(result['video_info'])
              ..lastPlayTime =
                  result['play_view_business_info']?['user_status']?['watch_progress']?['current_watch_progress'];

          case .pugv:
            final result = res.data['data'];
            data = PlayUrlModel.fromJson(result)
              ..lastPlayTime =
                  result['play_view_business_info']?['user_status']?['watch_progress']?['current_watch_progress'];
        }
        return Success(data);
      } else if (epid != null && videoType == .ugc) {
        return await videoUrl(
          avid: avid,
          bvid: bvid,
          cid: cid,
          qn: qn,
          epid: epid,
          seasonId: seasonId,
          tryLook: tryLook,
          videoType: .pgc,
        );
      }
      return Error(_parseVideoErr(res.data['code'], res.data['message']));
    } catch (e, s) {
      return Error('$e\n\n$s');
    }
  }

  static String _parseVideoErr(int? code, String? msg) {
    return switch (code) {
      -404 => '视频不存在或已被删除',
      87008 => '当前视频可能是专属视频，可能需包月充电观看($msg})',
      _ => '错误($code): $msg',
    };
  }

  // 视频信息 标题、简介
  static Future<LoadingState<VideoDetailData>> videoIntro({
    required String bvid,
  }) async {
    final res = await Request().get(
      Api.videoIntro,
      queryParameters: await WbiSign.makSign({'bvid': bvid}),
    );
    if (res.data['code'] == 0) {
      return Success(VideoDetailData.fromJson(res.data['data']));
    } else {
      return Error(res.data['message']);
    }
  }

  static Future<LoadingState<VideoRelation>> videoRelation({
    required String bvid,
  }) async {
    final res = await Request().get(
      Api.videoRelation,
      queryParameters: {'aid': IdUtils.bv2av(bvid), 'bvid': bvid},
    );
    if (res.data['code'] == 0) {
      return Success(VideoRelation.fromJson(res.data['data']));
    } else {
      return Error(res.data['message']);
    }
  }

  // 相关视频
  static Future<LoadingState<List<HotVideoItemModel>?>> relatedVideoList({
    required String bvid,
  }) async {
    final res = await Request().get(
      Api.relatedList,
      queryParameters: {'bvid': bvid},
    );
    if (res.data['code'] == 0) {
      final items = (res.data['data'] as List?)?.map(
        (i) => HotVideoItemModel.fromJson(i),
      );
      final list = RecommendFilter.applyFilterToRelatedVideos
          ? items?.where((i) => !RecommendFilter.filterAll(i)).toList()
          : items?.toList();
      return Success(list);
    } else {
      return Error(res.data['message']);
    }
  }

  // 获取点赞/投币/收藏状态 pgc
  static Future<LoadingState<PgcLCF>> pgcLikeCoinFav({
    required Object epId,
  }) async {
    final res = await Request().get(
      Api.pgcLikeCoinFav,
      queryParameters: {'ep_id': epId},
    );
    if (res.data['code'] == 0) {
      return Success(PgcLCF.fromJson(res.data['data']));
    } else {
      return Error(res.data['message']);
    }
  }

  // 投币
  static Future<LoadingState<void>> coinVideo({
    required String bvid,
    required int multiply,
    int selectLike = 0,
  }) async {
    final res = await Request().post(
      Api.coinVideo,
      data: {
        'aid': IdUtils.bv2av(bvid).toString(),
        // 'bvid': bvid,
        'multiply': multiply.toString(),
        'select_like': selectLike.toString(),
        // 'csrf': Accounts.main.csrf,
      },
      options: Options(contentType: Headers.formUrlEncodedContentType),
    );
    if (res.data['code'] == 0) {
      return const Success(null);
    } else {
      return Error(res.data['message']);
    }
  }

  // 一键三连 pgc
  static Future<LoadingState<PgcTriple>> pgcTriple({
    required Object epId,
    Object? seasonId,
  }) async {
    final res = await Request().post(
      Api.pgcTriple,
      data: {'ep_id': epId, 'csrf': Accounts.main.csrf},
      options: Options(
        contentType: Headers.formUrlEncodedContentType,
        headers: {
          'origin': 'https://www.bilibili.com',
          'referer':
              'https://www.bilibili.com/bangumi/play/${seasonId == null ? "ep$epId" : "ss$seasonId"}',
          'user-agent': BrowserUa.pc,
        },
      ),
    );
    if (res.data['code'] == 0) {
      return Success(PgcTriple.fromJson(res.data['data']));
    } else {
      return Error(res.data['message']);
    }
  }

  // 一键三连
  static Future<LoadingState<UgcTriple>> ugcTriple({
    required String bvid,
  }) async {
    final res = await Request().post(
      Api.ugcTriple,
      data: {
        'aid': IdUtils.bv2av(bvid),
        'eab_x': 2,
        'ramval': 0,
        'source': 'web_normal',
        'ga': 1,
        'csrf': Accounts.main.csrf,
        'spmid': '333.788.0.0',
        'statistics': '{"appId":100,"platform":5}',
      },
      options: Options(
        contentType: Headers.formUrlEncodedContentType,
        headers: {
          'origin': 'https://www.bilibili.com',
          'referer': 'https://www.bilibili.com/video/$bvid',
          'user-agent': BrowserUa.pc,
        },
      ),
    );
    if (res.data['code'] == 0) {
      return Success(UgcTriple.fromJson(res.data['data']));
    } else {
      return Error(res.data['message']);
    }
  }

  // （取消）点赞
  static Future<LoadingState<String>> likeVideo({
    required String bvid,
    required bool type,
  }) async {
    final res = await Request().post(
      Api.likeVideo,
      data: {'aid': IdUtils.bv2av(bvid).toString(), 'like': type ? '0' : '1'},
      options: Options(contentType: Headers.formUrlEncodedContentType),
    );
    if (res.data['code'] == 0) {
      return Success(res.data['data']['toast']);
    } else {
      return Error(res.data['message']);
    }
  }

  // （取消）点踩
  static Future<LoadingState<void>> dislikeVideo({
    required String bvid,
    required bool type,
  }) async {
    if (Accounts.main.accessKey.isNullOrEmpty) {
      return const Error('请退出账号后重新登录');
    }
    final res = await Request().post(
      Api.dislikeVideo,
      data: {
        'aid': IdUtils.bv2av(bvid).toString(),
        'dislike': type ? '0' : '1',
      },
      options: Options(contentType: Headers.formUrlEncodedContentType),
    );
    if (res.data is! String && res.data['code'] == 0) {
      return const Success(null);
    } else {
      return Error(res.data is String ? res.data : res.data['message']);
    }
  }

  // 推送不感兴趣反馈
  static Future<LoadingState<void>> feedDislike({
    required String goto,
    required int id,
    int? reasonId,
    int? feedbackId,
    int? mid,
    int? rid,
    int? tagId,
    String? trackId,
    String? reportData,
  }) async {
    if (Accounts.get(AccountType.recommend).accessKey.isNullOrEmpty) {
      return const Error('请退出账号后重新登录');
    }
    assert((reasonId != null) ^ (feedbackId != null));
    final res = await Request().get(
      Api.feedDislike,
      queryParameters: {
        'goto': goto,
        'id': id,
        'reason_id': ?reasonId,
        'feedback_id': ?feedbackId,
        // 官方 app 会带上这些定位字段，缺了服务端可能无法准确归因到 UP/分区
        'mid': ?mid,
        'rid': ?rid,
        'tag_id': ?tagId,
        'track_id': ?trackId,
        'report_data': ?reportData,
        'is_light_panel': 'false',
        'spmid': 'tm.recommend.0.0',
        'from_spmid': 'tm.recommend.0.0',
        'build': 1,
        'mobi_app': 'android',
      },
    );
    if (res.data['code'] == 0) {
      return const Success(null);
    } else {
      return Error(res.data['message']);
    }
  }

  // 推送不感兴趣取消
  static Future<LoadingState<void>> feedDislikeCancel({
    required String goto,
    required int id,
    int? reasonId,
    int? feedbackId,
    int? mid,
    int? rid,
    int? tagId,
    String? trackId,
    String? reportData,
  }) async {
    if (Accounts.get(AccountType.recommend).accessKey.isNullOrEmpty) {
      return const Error('请退出账号后重新登录');
    }
    final res = await Request().get(
      Api.feedDislikeCancel,
      queryParameters: {
        'goto': goto,
        'id': id,
        'reason_id': ?reasonId,
        'feedback_id': ?feedbackId,
        'mid': ?mid,
        'rid': ?rid,
        'tag_id': ?tagId,
        'track_id': ?trackId,
        'report_data': ?reportData,
        'is_light_panel': 'false',
        'spmid': 'tm.recommend.0.0',
        'from_spmid': 'tm.recommend.0.0',
        'build': 1,
        'mobi_app': 'android',
      },
    );
    if (res.data['code'] == 0) {
      return const Success(null);
    } else {
      return Error(res.data['message']);
    }
  }

  // 发表评论 replyAdd

  // type	num	评论区类型代码	必要	类型代码见表
  // oid	num	目标评论区id	必要
  // root	num	根评论rpid	非必要	二级评论以上使用
  // parent	num	父评论rpid	非必要	二级评论同根评论id 大于二级评论为要回复的评论id
  // message	str	发送评论内容	必要	最大1000字符
  // plat	num	发送平台标识	非必要	1：web端 2：安卓客户端  3：ios客户端  4：wp客户端
  static Future<LoadingState<ReplyInfo?>> replyAdd({
    required int type,
    required int oid,
    required String message,
    int? root,
    int? parent,
    List? pictures,
    bool syncToDynamic = false,
    Map<String, int>? atNameToMid,
  }) async {
    final data = {
      'type': type,
      'oid': oid,
      if (root != null && root != 0) 'root': root,
      if (parent != null && parent != 0) 'parent': parent,
      'message': message,
      if (atNameToMid?.isNotEmpty == true)
        'at_name_to_mid': jsonEncode(atNameToMid), // {"name":uid}
      if (pictures != null) 'pictures': jsonEncode(pictures),
      if (syncToDynamic) 'sync_to_dynamic': 1,
      'csrf': Accounts.main.csrf,
    };
    final res = await Request().post(
      Api.replyAdd,
      data: data,
      options: Options(contentType: Headers.formUrlEncodedContentType),
    );
    if (res.data['code'] == 0) {
      try {
        final replyInfo = RequestUtils.replyCast(res.data['data']['reply']);
        GStorage.reply?.put(
          replyInfo.id.toString(),
          (replyInfo.deepCopy()
                ..unknownFields.clear()
                ..clearTrackInfo())
              .writeToBuffer(),
        );
        return Success(replyInfo);
      } catch (e, s) {
        Utils.reportError(e, s);
        return const Success(null);
      }
    } else {
      return Error(res.data['message']);
    }
  }

  static Future<LoadingState<void>> replyDel({
    required int type, //replyType
    required int oid,
    required int rpid,
  }) async {
    final res = await Request().post(
      Api.replyDel,
      data: {
        'type': type, //type.index
        'oid': oid,
        'rpid': rpid,
        'csrf': Accounts.main.csrf,
      },
      options: Options(contentType: Headers.formUrlEncodedContentType),
    );
    if (res.data['code'] == 0) {
      GStorage.reply?.delete(rpid.toString());
      return const Success(null);
    } else {
      return const Error('请退出账号后重新登录');
    }
  }

  // 操作用户关系
  static Future<LoadingState<void>> relationMod({
    required int mid,
    required int act,
    required int reSrc,
  }) async {
    final res = await Request().post(
      Api.relationMod,
      queryParameters: {
        'statistics': '{"appId":100,"platform":5}',
        'x-bili-device-req-json':
            '{"platform":"web","device":"pc","spmid":"333.1387"}',
      },
      data: {
        'fid': mid,
        'act': act,
        're_src': reSrc,
        'gaia_source': 'web_main',
        'spmid': '333.1387',
        'extend_content': jsonEncode({
          "entity": "user",
          "entity_id": mid,
          'fp': BrowserUa.pc,
        }),
        'csrf': Accounts.main.csrf,
      },
      options: Options(
        contentType: Headers.formUrlEncodedContentType,
        headers: {
          'origin': 'https://space.bilibili.com',
          'referer': 'https://space.bilibili.com/$mid/dynamic',
          'user-agent': BrowserUa.pc,
        },
      ),
    );
    if (res.data['code'] == 0) {
      if (act == 5) {
        // block
        Pref.setBlackMid(mid);
      } else if (act == 6) {
        // unblock
        Pref.removeBlackMid(mid);
      }
      return const Success(null);
    } else {
      return Error(res.data['message']);
    }
  }

  static Future<void> roomEntryAction({required Object roomId}) {
    return Request().post(
      Api.roomEntryAction,
      queryParameters: {'csrf': Accounts.heartbeat.csrf},
      data: {'room_id': roomId, 'platform': 'pc'},
    );
  }

  static Future<void> historyReport({
    required Object aid,
    required Object type,
  }) {
    return Request().post(
      Api.historyReport,
      data: {'aid': aid, 'type': type, 'csrf': Accounts.heartbeat.csrf},
      options: Options(contentType: Headers.formUrlEncodedContentType),
    );
  }

  // 视频播放进度
  static Future<void> heartBeat({
    Object? aid,
    Object? bvid,
    required Object cid,
    required Object progress,
    Object? epid,
    Object? seasonId,
    Object? subType,
    required VideoType videoType,
  }) {
    final isPugv = videoType == VideoType.pugv;
    return Request().post(
      Api.heartBeat,
      data: {
        if (isPugv) 'aid': ?aid else 'bvid': ?bvid,
        'cid': cid,
        'epid': ?epid,
        'sid': ?seasonId,
        'type': videoType.type,
        'sub_type': ?subType,
        'played_time': progress,
        'csrf': Accounts.heartbeat.csrf,
      },
      options: Options(contentType: Headers.formUrlEncodedContentType),
    );
  }

  /// 历史上报实际可用的身份通道（null = 本会话还没试出来）：
  /// true = cookie（web 身份），false = access_key（APP 身份）。
  /// 见 [reportHistory] 的注释：真机上 APP 通道对该接口恒定 -400
  static bool? _historyUseCookie;

  /// 心跳专用 Dio（绕开全局拦截器，见 mobileHeartBeat 注释）
  static Dio? _heartbeatDio;

  /// 手机版身份的签名：委托 BiliReportSign（算法与官方验签样例一致，
  /// 有单元测试守护 test/utils/bili_report_sign_test.dart）
  static String _mobileSign(Map<String, dynamic> params) =>
      BiliReportSign.sign(params);

  /// 心跳专用 UA：build/channel 与表单参数严格一致（对齐官方 8.62.0 形态）
  static const String _userAgentAppAndroid =
      'Mozilla/5.0 BiliDroid/8.62.0 (bbcallen@gmail.com) os/android '
      'model/android mobi_app/android build/8620300 channel/360 '
      'innerVer/8620300 osVer/15 network/2';

  /// 心跳专用 statistics：version 与 UA/build 保持一致（8.62.0）
  static const String _statisticsAppAndroid =
      '{"appId":1,"platform":3,"version":"8.62.0","abtest":""}';

  static const String _appKeyAndroid = BiliReportSign.appKeyAndroid;

  /// 移动端心跳（/x/report/heartbeat/mobile），带推荐归因。
  ///
  /// [completed] 为 true 表示"会话结束立即上报"（退出/完成，跳过节流）。
  /// progress==-1 表示真正看完（played_time 取全长）；
  /// 退出时 progress 为实际进度，played_time 按实际值上报，
  /// 不要把"退出"误报成"看完整部"。
  static Future<bool> mobileHeartBeat(
    VideoReportContext ctx,
    int progress, {
    required bool completed,
  }) {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final total = (now - ctx.startTs).clamp(0, 1 << 30);
    final progressSec = progress < 0 ? ctx.videoDuration : progress;
    ctx.updateProgress(progressSec);
    ctx.lastReportTs = now;
    final account = Accounts.get(AccountType.main);
    final params = <String, dynamic>{
      'session': ctx.session,
      'mid': account.mid,
      'aid': ctx.aid,
      'cid': ctx.cid,
      'type': ctx.type,
      'sub_type': ctx.subType ?? 0,
      'quality': ctx.quality,
      'video_duration': ctx.videoDuration,
      'play_type': 1,
      'network_type': 1,
      'from': ctx.from,
      'from_spmid': ctx.fromSpmid,
      'spmid': ctx.spmid,
      'play_status': 0,
      'user_status': 0,
      'epid_status': '',
      'auto_play': 0,
      'play_mode': 1,
      'cur_language': '',
      'oaid': '',
      'is_auto_qn': 1,
      // 官方 HeartbeatParams 里这两个字段是"总是传"的（APK 8.62 反编译实证）：
      // perfer_type 默认空串；is_audio_play 1=音频播放 2=普通视频播放。
      // 缺失会被服务端判为参数错误（-400）
      'perfer_type': '',
      'is_audio_play': 2,
      // 官方会话级随机 8 位 hex；缺失会返回 -400 参数错误
      'polaris_action_id': ctx.polarisActionId,
      // 官方把 extra Map 的每个 entry 作为独立表单参数注入
      // （HeartbeatParams 构造末尾的 map 循环），而非 JSON 字符串；
      // 这里两种形式都给，兼容新旧
      'from_outer_spmid': ctx.fromSpmid,
      'extra': '{"from_outer_spmid":"${ctx.fromSpmid}"}',
      'track_id': ?ctx.trackId,
      'sid': ctx.seasonId ?? 0,
      'epid': ctx.epId ?? 0,
      'start_ts': ctx.startTs,
      'total_time': total,
      'paused_time': 0,
      'played_time': progressSec,
      'last_play_progress_time': progressSec,
      'max_play_progress_time': ctx.maxProgress,
      'actual_played_time': total,
      'list_play_time': 0,
      'miniplayer_play_time': 0,
      'build': 8620300,
      // app 公参对齐 bbspace BiliRestParamBuilder.app（缺 disable_rcmd/statistics
      // 会被判参数错误 -400；locale/channel 用官方取值）
      'c_locale': 'zh-Hans_CN',
      'channel': '360',
      'disable_rcmd': 0,
      'mobi_app': 'android',
      'platform': 'android',
      's_locale': 'zh-Hans_CN',
      'statistics': _statisticsAppAndroid,
      'ts': now,
      'access_key': ?account.accessKey,
    };
    // appkey 必须同时出现在请求体里（服务端先校验必需参数，缺它会直接返回
    // -400 而不会走到验签）—— 这也是真机持续 -400 的根因
    params['appkey'] = _appKeyAndroid;
    // 手机版身份的签名（appkey/appsec 必须与 mobi_app=android 匹配）
    params['sign'] = _mobileSign(params);
    // 必须用独立 Dio 而不是 Request()：全局拦截器（AccountManager）会给请求
    // 覆盖账号 headers、补 web referer、并移除 sign 重新签名 —— app 身份错乱
    // 触发风控（真机日志：连续 badResponse）。bbspace 的心跳同样是不带
    // cookie/referer 的干净 app 请求。
    return (_heartbeatDio ??= Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        // 4xx（如 412 风控）也保留响应体，供日志定位
        validateStatus: (status) => status != null,
      ),
    ))
        .post(
          // 正确 host 是 api.bilibili.com（bbspace BASE_URL_API 同源）；
          // 最初误写 app.bilibili.com 导致 404 page not found
          'https://api.bilibili.com/x/report/heartbeat/mobile',
          data: params,
          options: Options(
            contentType: Headers.formUrlEncodedContentType,
            headers: {
              // 与推荐接口/live 一致的头集合 + 修正 app-key 名称（官方 APP profile
              // 的 appKeyName 是 android64，不是 android —— 身份标识不匹配会被拒）
              'accept': '*/*',
              'app-key': 'android64',
              'bili-http-engine': 'cronet',
              'env': 'prod',
              'buvid': LoginHttp.buvid,
              'fp_local':
                  '1111111111111111111111111111111111111111111111111111111111111111',
              'fp_remote':
                  '1111111111111111111111111111111111111111111111111111111111111111',
              'session_id': '11111111',
              // UA 里的 build/channel 必须与表单参数一致（服务端会做一致性校验）：
              // 沿用 Constants.userAgentApp 会带上旧的 build/8430300 channel/master
              'user-agent': _userAgentAppAndroid,
              'x-bili-aurora-eid': '',
              'x-bili-aurora-zone': '',
              'x-bili-trace-id': Constants.traceId,
            },
          ),
        )
        .then((res) {
          final ok = res.data is Map && res.data['code'] == 0;
          // 只在失败时记：成功路径不写日志（正常播放不该产生任何诊断行）。
          // 失败要带参数快照 —— 参数类错误如 -400 没有快照就没法定位，凭据已剔除
          if (!ok) {
            final snapshot = Map.of(params)
              ..remove('access_key')
              ..remove('sign');
            DiagLog.log(
              'heartbeat.fail',
              'mobileHeartBeat failed http=${res.statusCode} aid=${ctx.aid} '
              'cid=${ctx.cid} type=${ctx.type} resp=${res.data} params=$snapshot',
            );
          }
          return ok;
        });
  }

  /// APP 播放历史上报（/x/v2/history/report）。
  /// mobile 心跳（/x/report/heartbeat/mobile）只做实时归因，**不写观看历史**；
  /// 历史必须单独上报本接口 —— 此前依赖"心跳失败→回退 web 心跳"顺带记录，
  /// 心跳打通后该回退不再触发，导致历史断记（真机反馈）。
  ///
  /// 认证双轨（真机日志实证）：
  /// - **cookie 方式**（`Request()` 自带 SESSDATA + csrf）：这条通道在真机上
  ///   一次都没失败过
  /// - **APP 方式**（表单 + appkey/sign + access_key）：对 `/x/v2/history/report`
  ///   恒定返回 `code=-400 请求错误`（一次运行 514 次，日志刷到 700KB）；同一套
  ///   appkey/sign 打心跳却是 code=0，说明是本接口对 app 身份的严格校验，不是签名问题
  ///
  /// 因此：**有 cookie 就走 cookie**（与 web 端一致），APP 方式退化为
  /// 无 cookie 账号（纯 access_key 登录）的兜底；任一条失败时自动切另一条，
  /// 并把"实际可用通道"记进会话，避免每条上报都白跑一次失败请求。
  static Future<bool> reportHistory({
    required VideoReportContext ctx,
    required int progress,
    required bool completed,
  }) async {
    final account = Accounts.get(AccountType.main);
    if (!account.isLogin) return false;
    final progressValue = completed ? -1 : progress.clamp(0, 1 << 30);

    final hasCookie = Accounts.heartbeat.csrf.isNotEmpty;
    // 会话内记住哪条通道可用（null = 还没试出来）
    final useCookie = _historyUseCookie ?? hasCookie;
    final ok = useCookie
        ? await _reportHistoryByCookie(ctx, progressValue)
        : await _reportHistoryByApp(ctx, progressValue);
    if (ok) return true;

    // 主通道失败：换另一条再试一次，成功则记住它
    final altCookie = !useCookie;
    final altOk = altCookie
        ? await _reportHistoryByCookie(ctx, progressValue)
        : await _reportHistoryByApp(ctx, progressValue);
    if (altOk) {
      _historyUseCookie = altCookie;
      DiagLog.once(
        'history.switch',
        'reportHistory 通道切换 → ${altCookie ? 'cookie' : 'app'}'
        '（原通道 ${useCookie ? 'cookie' : 'app'} 失败）',
      );
    } else {
      DiagLog.log(
        'history.bothFailed',
        'reportHistory 两条通道都失败 aid=${ctx.aid} cid=${ctx.cid} '
        'type=${ctx.type} sub=${ctx.subType} sid=${ctx.seasonId} '
        'epid=${ctx.epId} duration=${ctx.videoDuration} '
        'progress=$progressValue completed=$completed',
      );
    }
    return altOk;
  }

  /// cookie 身份的历史上报（web 端同一接口，Request() 自带 SESSDATA + csrf）
  static Future<bool> _reportHistoryByCookie(
    VideoReportContext ctx,
    int progressValue,
  ) {
    return Request()
        .post(
          'https://api.bilibili.com/x/v2/history/report',
          data: {
            'aid': ctx.aid,
            'cid': ctx.cid,
            'progress': progressValue,
            'type': ctx.type,
            'epid': ?ctx.epId,
            'sid': ?ctx.seasonId,
            'csrf': Accounts.heartbeat.csrf,
          },
          options: Options(contentType: Headers.formUrlEncodedContentType),
        )
        .then((res) {
          final ok = res.data is Map && res.data['code'] == 0;
          if (!ok) {
            DiagLog.log(
              'history.cookie.fail',
              'reportHistory(cookie) failed aid=${ctx.aid} cid=${ctx.cid} '
              'type=${ctx.type} sub=${ctx.subType} sid=${ctx.seasonId} '
              'epid=${ctx.epId} duration=${ctx.videoDuration} '
              'progress=$progressValue resp=${res.data}',
            );
          }
          return ok;
        })
        .catchError((Object e) {
          DiagLog.log(
            'history.cookie.err',
            'reportHistory(cookie) 异常 aid=${ctx.aid} cid=${ctx.cid}: $e',
          );
          return false;
        });
  }

  /// access_key 身份的历史上报（表单 + appkey/sign）。
  /// 真机上该接口对 app 身份返回 -400，保留作为无 cookie 账号的兜底
  static Future<bool> _reportHistoryByApp(
    VideoReportContext ctx,
    int progressValue,
  ) {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final accessKey = Accounts.get(AccountType.main).accessKey;
    final params = <String, dynamic>{
      'aid': ctx.aid,
      'cid': ctx.cid,
      'duration': ctx.videoDuration,
      'progress': progressValue,
      'type': ctx.type,
      'device_ts': now,
      'start_ts': ctx.startTs,
      'source': 'player-old',
      'scene': 'front',
      'sid': ctx.seasonId ?? 0,
      'epid': ctx.epId ?? 0,
      'sub_type': ctx.subType ?? 0,
      // 公参：本地实测缺 platform/build 等会被判 -400（bbspace 由
      // restClient 自动注入，这里需手动带全）
      'build': 8620300,
      'mobi_app': 'android',
      'platform': 'android',
      'c_locale': 'zh-Hans_CN',
      's_locale': 'zh-Hans_CN',
      'channel': '360',
      'disable_rcmd': 0,
      'statistics': _statisticsAppAndroid,
      'ts': now,
      'access_key': ?accessKey,
      'appkey': _appKeyAndroid,
    };
    params['sign'] = _mobileSign(params);
    return (_heartbeatDio ??= Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        validateStatus: (status) => status != null,
      ),
    ))
        .post(
          'https://api.bilibili.com/x/v2/history/report',
          data: params,
          options: Options(
            contentType: Headers.formUrlEncodedContentType,
            headers: {
              'accept': '*/*',
              'user-agent': _userAgentAppAndroid,
              'app-key': 'android64',
              'bili-http-engine': 'cronet',
              'env': 'prod',
              // 与心跳一致带上设备身份头：缺 buvid/session_id 时该接口更容易被风控拒
              'buvid': LoginHttp.buvid,
              'session_id': '11111111',
              'x-bili-aurora-eid': '',
              'x-bili-aurora-zone': '',
              'x-bili-trace-id': Constants.traceId,
            },
          ),
        )
        .then((res) {
          final ok = res.data is Map && res.data['code'] == 0;
          // 失败时把完整参数（除凭据）写进日志：-400 只能靠参数快照定位
          if (!ok) {
            final snapshot = Map.of(params)
              ..remove('access_key')
              ..remove('sign');
            DiagLog.log(
              'history.app.fail',
              'reportHistory(app) failed http=${res.statusCode} '
              'aid=${ctx.aid} cid=${ctx.cid} duration=${ctx.videoDuration} '
              'progress=$progressValue resp=${res.data} params=$snapshot',
            );
          }
          return ok;
        })
        .catchError((Object e) {
          DiagLog.log(
            'history.app.err',
            'reportHistory(app) 异常 aid=${ctx.aid} cid=${ctx.cid}: $e',
          );
          return false;
        });
  }

  static Future<void> medialistHistory({
    required int desc,
    required Object oid,
    required Object upperMid,
  }) {
    return Request().post(
      Api.mediaListHistory,
      data: {
        'desc': desc,
        'oid': oid,
        'upper_mid': upperMid,
        'csrf': Accounts.heartbeat.csrf,
      },
      options: Options(contentType: Headers.formUrlEncodedContentType),
    );
  }

  // 添加追番
  static Future<LoadingState<String>> pgcAdd({int? seasonId}) async {
    final res = await Request().post(
      Api.pgcAdd,
      data: {'season_id': seasonId, 'csrf': Accounts.main.csrf},
      options: Options(contentType: Headers.formUrlEncodedContentType),
    );
    if (res.data['code'] == 0) {
      return Success(res.data['result']['toast']);
    } else {
      return Error(res.data['message']);
    }
  }

  // 取消追番
  static Future<LoadingState<String>> pgcDel({int? seasonId}) async {
    final res = await Request().post(
      Api.pgcDel,
      data: {'season_id': seasonId, 'csrf': Accounts.main.csrf},
      options: Options(contentType: Headers.formUrlEncodedContentType),
    );
    if (res.data['code'] == 0) {
      return Success(res.data['result']['toast']);
    } else {
      return Error(res.data['message']);
    }
  }

  static Future<LoadingState<String>> pgcUpdate({
    required String seasonId,
    required int status,
  }) async {
    final res = await Request().post(
      Api.pgcUpdate,
      data: {
        'season_id': seasonId,
        'status': status,
        'csrf': Accounts.main.csrf,
      },
      options: Options(contentType: Headers.formUrlEncodedContentType),
    );
    if (res.data['code'] == 0) {
      return Success(res.data['result']['toast']);
    } else {
      return Error(res.data['message']);
    }
  }

  // 查看视频同时在看人数
  static Future<LoadingState<String>> onlineTotal({
    int? aid,
    String? bvid,
    required int cid,
  }) async {
    assert(aid != null || bvid != null);
    final res = await Request().get(
      Api.onlineTotal,
      queryParameters: {'aid': aid, 'bvid': bvid, 'cid': cid},
    );
    if (res.data['code'] == 0) {
      return Success(res.data['data']['total']);
    } else {
      return Error(res.data['message']);
    }
  }

  static Future<LoadingState<AiConclusionData>> aiConclusion({
    required String bvid,
    required int cid,
    int? upMid,
  }) async {
    final params = await WbiSign.makSign({
      'bvid': bvid,
      'cid': cid,
      'up_mid': ?upMid,
    });
    final res = await Request().get(Api.aiConclusion, queryParameters: params);
    final int? code = res.data['code'];
    if (code == 0) {
      final int? dataCode = res.data['data']?['code'];
      if (dataCode == 0) {
        return Success(AiConclusionData.fromJson(res.data['data']));
      } else {
        return Error(null, code: dataCode);
      }
    } else {
      return Error(res.data['message']);
    }
  }

  static Future<LoadingState<PlayInfoData>> playInfo({
    String? aid,
    String? bvid,
    required int cid,
    dynamic seasonId,
    dynamic epId,
  }) async {
    assert(aid != null || bvid != null);
    final res = await Request().get(
      Api.playInfo,
      queryParameters: await WbiSign.makSign({
        'aid': ?aid,
        'bvid': ?bvid,
        'cid': cid,
        'season_id': ?seasonId,
        'ep_id': ?epId,
      }),
    );
    if (res.data['code'] == 0) {
      return Success(PlayInfoData.fromJson(res.data['data']));
    } else {
      return Error(res.data['message']);
    }
  }

  static Future<String?> getSubtitles(
    String subtitleUrl, {
    SubtitleFormat format = .vtt,
  }) async {
    final res = await Request().get("https:$subtitleUrl");
    if (res.data?['body'] case List list) {
      switch (format) {
        case .json:
          throw UnimplementedError();
        case .vtt:
          return compute<List, String>(SubtitleUtils.json2Vtt, list);
        case .srt:
          return compute<List, String>(SubtitleUtils.json2Srt, list);
      }
    }
    return null;
  }

  static bool _canAddRank(Map i) {
    if (!GlobalData().blackMids.contains(i['owner']['mid']) &&
        !RecommendFilter.filterTitle(i['title']) &&
        !RecommendFilter.filterLikeRatio(
          i['stat']['like'],
          i['stat']['view'],
        )) {
      if (enableFilter &&
          i['tname'] != null &&
          zoneRegExp.hasMatch(i['tname'])) {
        return false;
      }
      return true;
    }
    return false;
  }

  // 视频排行
  static Future<LoadingState<List<HotVideoItemModel>>> getRankVideoList(
    int rid,
  ) async {
    final res = await Request().get(
      Api.getRankApi,
      queryParameters: await WbiSign.makSign({'rid': rid, 'type': 'all'}),
    );
    if (res.data['code'] == 0) {
      List<HotVideoItemModel> list = <HotVideoItemModel>[];
      for (final i in res.data['data']['list']) {
        if (_canAddRank(i)) {
          list.add(HotVideoItemModel.fromJson(i));
          // final List? others = i['others'];
          // if (others != null && others.isNotEmpty) {
          //   for (final j in others) {
          //     if (_canAddRank(j)) {
          //       list.add(HotVideoItemModel.fromJson(j));
          //     }
          //   }
          // }
        }
      }
      return Success(list);
    } else {
      return Error(res.data['message']);
    }
  }

  // pgc 排行
  static Future<LoadingState<List<PgcRankItemModel>?>> pgcRankList({
    int day = 3,
    required int seasonType,
  }) async {
    final res = await Request().get(
      Api.pgcRank,
      queryParameters: await WbiSign.makSign({
        'day': day,
        'season_type': seasonType,
      }),
    );
    if (res.data['code'] == 0) {
      return Success(
        (res.data['result']?['list'] as List?)
            ?.map((e) => PgcRankItemModel.fromJson(e))
            .toList(),
      );
    } else {
      return Error(res.data['message']);
    }
  }

  // pgc season 排行
  static Future<LoadingState<List<PgcRankItemModel>?>> pgcSeasonRankList({
    int day = 3,
    required int seasonType,
  }) async {
    final res = await Request().get(
      Api.pgcSeasonRank,
      queryParameters: await WbiSign.makSign({
        'day': day,
        'season_type': seasonType,
      }),
    );
    if (res.data['code'] == 0) {
      return Success(
        (res.data['data']?['list'] as List?)
            ?.map((e) => PgcRankItemModel.fromJson(e))
            .toList(),
      );
    } else {
      return Error(res.data['message']);
    }
  }

  static Future<LoadingState<VideoNoteData>> getVideoNoteList({
    dynamic oid,
    dynamic uperMid,
    required int page,
  }) async {
    final res = await Request().get(
      Api.archiveNoteList,
      queryParameters: {
        'csrf': Accounts.main.csrf,
        'oid': oid,
        'oid_type': 0,
        'pn': page,
        'ps': 10,
        'uper_mid': ?uperMid,
      },
    );
    if (res.data['code'] == 0) {
      return Success(VideoNoteData.fromJson(res.data['data']));
    } else {
      return Error(res.data['message']);
    }
  }

  static Future<LoadingState<List<PopularSeriesListItem>?>>
  popularSeriesList() async {
    final res = await Request().get(
      Api.popularSeriesList,
      queryParameters: await WbiSign.makSign({'web_location': 333.934}),
    );
    if (res.data['code'] == 0) {
      return Success(
        (res.data['data']?['list'] as List<dynamic>?)
            ?.map(
              (e) => PopularSeriesListItem.fromJson(e as Map<String, dynamic>),
            )
            .toList(),
      );
    } else {
      return Error(res.data['message']);
    }
  }

  static Future<LoadingState<PopularSeriesOneData>> popularSeriesOne({
    required int number,
  }) async {
    final res = await Request().get(
      Api.popularSeriesOne,
      queryParameters: await WbiSign.makSign({
        'number': number,
        'web_location': 333.934,
      }),
    );
    if (res.data['code'] == 0) {
      return Success(PopularSeriesOneData.fromJson(res.data['data']));
    } else {
      return Error(res.data['message']);
    }
  }

  static Future<LoadingState<PopularPreciousData>> popularPrecious({
    required int page,
  }) async {
    final res = await Request().get(
      Api.popularPrecious,
      queryParameters: await WbiSign.makSign({
        'page_size': 100,
        'page': page,
        'web_location': 333.934,
      }),
    );
    if (res.data['code'] == 0) {
      return Success(PopularPreciousData.fromJson(res.data['data']));
    } else {
      return Error(res.data['message']);
    }
  }

  static Future<LoadingState<PlayUrlModel>> tvPlayUrl({
    required int cid,
    required int objectId, // aid, epid
    required int playurlType, // ugc 1, pgc 2
    int? qn,
  }) async {
    final accessKey = Accounts.get(AccountType.video).accessKey;
    final params = {
      'access_key': ?accessKey,
      'actionKey': 'appkey',
      'cid': cid,
      'fourk': 1,
      'is_proj': 1,
      'mobile_access_key': ?accessKey,
      'object_id': objectId,
      'mobi_app': 'android',
      'platform': 'android',
      'playurl_type': playurlType,
      'protocol': 0,
      'qn': qn ?? 80,
    };
    AppSign.appSign(params);
    final res = await Request().get(Api.tvPlayUrl, queryParameters: params);
    if (res.data['code'] == 0) {
      return Success(PlayUrlModel.fromJson(res.data['data']));
    } else {
      return Error(res.data['message']);
    }
  }

  static Future<LoadingState<VideoShotData>> videoshot({
    required String bvid,
    required int cid,
  }) async {
    final res = await Request().get(
      Api.videoshot,
      queryParameters: {
        // 'aid': IdUtils.bv2av(_bvid),
        'bvid': bvid,
        'cid': cid,
        'index': 1,
      },
      options: Options(
        headers: {
          'user-agent': BrowserUa.pc,
          'referer': 'https://www.bilibili.com/video/$bvid',
        },
      ),
    );
    if (res.data['code'] == 0) {
      final data = VideoShotData.fromJson(res.data['data']);
      if (data.index.isNotEmpty) {
        return Success(data);
      } else {
        return const Error(null);
      }
    }
    return Error(res.data['message']);
  }
}
