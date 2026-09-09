// This is a generated file - do not edit.
//
// Generated from bilibili/app/playerunite/v1/playerunite.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:async' as $async;
import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;
import 'package:protobuf/well_known_types/google/protobuf/any.pb.dart' as $1;

import '../../../playershared.pb.dart' as $0;
import 'playerunite.pbenum.dart';

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

export 'playerunite.pbenum.dart';

/// 统一播放页请求。
class PlayViewUniteReq extends $pb.GeneratedMessage {
  factory PlayViewUniteReq({
    $0.VideoVod? vod,
    $core.String? spmid,
    $core.String? fromSpmid,
    $core.Iterable<$core.MapEntry<$core.String, $core.String>>? extraContent,
    $core.String? bvid,
    $core.String? adExtra,
    $0.Fragment? fragment,
    $core.String? fromScene,
    $0.PlayCtrl? playCtrl,
  }) {
    final result = create();
    if (vod != null) result.vod = vod;
    if (spmid != null) result.spmid = spmid;
    if (fromSpmid != null) result.fromSpmid = fromSpmid;
    if (extraContent != null) result.extraContent.addEntries(extraContent);
    if (bvid != null) result.bvid = bvid;
    if (adExtra != null) result.adExtra = adExtra;
    if (fragment != null) result.fragment = fragment;
    if (fromScene != null) result.fromScene = fromScene;
    if (playCtrl != null) result.playCtrl = playCtrl;
    return result;
  }

  PlayViewUniteReq._();

  factory PlayViewUniteReq.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory PlayViewUniteReq.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PlayViewUniteReq',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'bilibili.app.playerunite.v1'),
      createEmptyInstance: create)
    ..aOM<$0.VideoVod>(1, _omitFieldNames ? '' : 'vod',
        subBuilder: $0.VideoVod.create)
    ..aOS(2, _omitFieldNames ? '' : 'spmid')
    ..aOS(3, _omitFieldNames ? '' : 'fromSpmid', protoName: 'fromSpmid')
    ..m<$core.String, $core.String>(4, _omitFieldNames ? '' : 'extraContent',
        protoName: 'extraContent',
        entryClassName: 'PlayViewUniteReq.ExtraContentEntry',
        keyFieldType: $pb.PbFieldType.OS,
        valueFieldType: $pb.PbFieldType.OS,
        packageName: const $pb.PackageName('bilibili.app.playerunite.v1'))
    ..aOS(5, _omitFieldNames ? '' : 'bvid')
    ..aOS(6, _omitFieldNames ? '' : 'adExtra', protoName: 'adExtra')
    ..aOM<$0.Fragment>(7, _omitFieldNames ? '' : 'fragment',
        subBuilder: $0.Fragment.create)
    ..aOS(8, _omitFieldNames ? '' : 'fromScene', protoName: 'fromScene')
    ..aE<$0.PlayCtrl>(9, _omitFieldNames ? '' : 'playCtrl',
        protoName: 'playCtrl', enumValues: $0.PlayCtrl.values)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PlayViewUniteReq clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PlayViewUniteReq copyWith(void Function(PlayViewUniteReq) updates) =>
      super.copyWith((message) => updates(message as PlayViewUniteReq))
          as PlayViewUniteReq;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static PlayViewUniteReq create() => PlayViewUniteReq._();
  @$core.override
  PlayViewUniteReq createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static PlayViewUniteReq getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<PlayViewUniteReq>(create);
  static PlayViewUniteReq? _defaultInstance;

  /// 点播标识与播放能力参数。
  @$pb.TagNumber(1)
  $0.VideoVod get vod => $_getN(0);
  @$pb.TagNumber(1)
  set vod($0.VideoVod value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasVod() => $_has(0);
  @$pb.TagNumber(1)
  void clearVod() => $_clearField(1);
  @$pb.TagNumber(1)
  $0.VideoVod ensureVod() => $_ensure(0);

  /// 当前页面或请求的 SPM 标识。
  @$pb.TagNumber(2)
  $core.String get spmid => $_getSZ(1);
  @$pb.TagNumber(2)
  set spmid($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasSpmid() => $_has(1);
  @$pb.TagNumber(2)
  void clearSpmid() => $_clearField(2);

  /// 来源页的 SPM 标识。
  @$pb.TagNumber(3)
  $core.String get fromSpmid => $_getSZ(2);
  @$pb.TagNumber(3)
  set fromSpmid($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasFromSpmid() => $_has(2);
  @$pb.TagNumber(3)
  void clearFromSpmid() => $_clearField(3);

  /// 场景相关的附加参数。
  @$pb.TagNumber(4)
  $pb.PbMap<$core.String, $core.String> get extraContent => $_getMap(3);

  /// 目标稿件的 BVID。
  @$pb.TagNumber(5)
  $core.String get bvid => $_getSZ(4);
  @$pb.TagNumber(5)
  set bvid($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasBvid() => $_has(4);
  @$pb.TagNumber(5)
  void clearBvid() => $_clearField(5);

  /// 广告相关的透传扩展串。
  @$pb.TagNumber(6)
  $core.String get adExtra => $_getSZ(5);
  @$pb.TagNumber(6)
  set adExtra($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasAdExtra() => $_has(5);
  @$pb.TagNumber(6)
  void clearAdExtra() => $_clearField(6);

  /// 分片播放上下文。
  @$pb.TagNumber(7)
  $0.Fragment get fragment => $_getN(6);
  @$pb.TagNumber(7)
  set fragment($0.Fragment value) => $_setField(7, value);
  @$pb.TagNumber(7)
  $core.bool hasFragment() => $_has(6);
  @$pb.TagNumber(7)
  void clearFragment() => $_clearField(7);
  @$pb.TagNumber(7)
  $0.Fragment ensureFragment() => $_ensure(6);

  /// 请求来源场景。
  @$pb.TagNumber(8)
  $core.String get fromScene => $_getSZ(7);
  @$pb.TagNumber(8)
  set fromScene($core.String value) => $_setString(7, value);
  @$pb.TagNumber(8)
  $core.bool hasFromScene() => $_has(7);
  @$pb.TagNumber(8)
  void clearFromScene() => $_clearField(8);

  /// 播放控制模式。
  @$pb.TagNumber(9)
  $0.PlayCtrl get playCtrl => $_getN(8);
  @$pb.TagNumber(9)
  set playCtrl($0.PlayCtrl value) => $_setField(9, value);
  @$pb.TagNumber(9)
  $core.bool hasPlayCtrl() => $_has(8);
  @$pb.TagNumber(9)
  void clearPlayCtrl() => $_clearField(9);
}

/// 统一播放页响应。
class PlayViewUniteReply extends $pb.GeneratedMessage {
  factory PlayViewUniteReply({
    $0.VodInfo? vodInfo,
    $0.PlayArcConf? playArcConf,
    $0.PlayDeviceConf? playDeviceConf,
    $0.Event? event,
    $1.Any? supplement,
    $0.PlayArc? playArc,
    $0.QnTrialInfo? qnTrialInfo,
    $0.History? history,
    $0.ViewInfo? viewInfo,
    $0.FragmentVideo? fragmentVideo,
    $0.VideoCtrl? videoCtrl,
  }) {
    final result = create();
    if (vodInfo != null) result.vodInfo = vodInfo;
    if (playArcConf != null) result.playArcConf = playArcConf;
    if (playDeviceConf != null) result.playDeviceConf = playDeviceConf;
    if (event != null) result.event = event;
    if (supplement != null) result.supplement = supplement;
    if (playArc != null) result.playArc = playArc;
    if (qnTrialInfo != null) result.qnTrialInfo = qnTrialInfo;
    if (history != null) result.history = history;
    if (viewInfo != null) result.viewInfo = viewInfo;
    if (fragmentVideo != null) result.fragmentVideo = fragmentVideo;
    if (videoCtrl != null) result.videoCtrl = videoCtrl;
    return result;
  }

  PlayViewUniteReply._();

  factory PlayViewUniteReply.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory PlayViewUniteReply.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PlayViewUniteReply',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'bilibili.app.playerunite.v1'),
      createEmptyInstance: create)
    ..aOM<$0.VodInfo>(1, _omitFieldNames ? '' : 'vodInfo',
        protoName: 'vodInfo', subBuilder: $0.VodInfo.create)
    ..aOM<$0.PlayArcConf>(2, _omitFieldNames ? '' : 'playArcConf',
        protoName: 'playArcConf', subBuilder: $0.PlayArcConf.create)
    ..aOM<$0.PlayDeviceConf>(3, _omitFieldNames ? '' : 'playDeviceConf',
        protoName: 'playDeviceConf', subBuilder: $0.PlayDeviceConf.create)
    ..aOM<$0.Event>(4, _omitFieldNames ? '' : 'event',
        subBuilder: $0.Event.create)
    ..aOM<$1.Any>(5, _omitFieldNames ? '' : 'supplement',
        subBuilder: $1.Any.create)
    ..aOM<$0.PlayArc>(6, _omitFieldNames ? '' : 'playArc',
        protoName: 'playArc', subBuilder: $0.PlayArc.create)
    ..aOM<$0.QnTrialInfo>(7, _omitFieldNames ? '' : 'qnTrialInfo',
        protoName: 'qnTrialInfo', subBuilder: $0.QnTrialInfo.create)
    ..aOM<$0.History>(8, _omitFieldNames ? '' : 'history',
        subBuilder: $0.History.create)
    ..aOM<$0.ViewInfo>(9, _omitFieldNames ? '' : 'viewInfo',
        protoName: 'viewInfo', subBuilder: $0.ViewInfo.create)
    ..aOM<$0.FragmentVideo>(10, _omitFieldNames ? '' : 'fragmentVideo',
        protoName: 'fragmentVideo', subBuilder: $0.FragmentVideo.create)
    ..aOM<$0.VideoCtrl>(11, _omitFieldNames ? '' : 'videoCtrl',
        protoName: 'videoCtrl', subBuilder: $0.VideoCtrl.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PlayViewUniteReply clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PlayViewUniteReply copyWith(void Function(PlayViewUniteReply) updates) =>
      super.copyWith((message) => updates(message as PlayViewUniteReply))
          as PlayViewUniteReply;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static PlayViewUniteReply create() => PlayViewUniteReply._();
  @$core.override
  PlayViewUniteReply createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static PlayViewUniteReply getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<PlayViewUniteReply>(create);
  static PlayViewUniteReply? _defaultInstance;

  /// 视频与音频资源信息。
  @$pb.TagNumber(1)
  $0.VodInfo get vodInfo => $_getN(0);
  @$pb.TagNumber(1)
  set vodInfo($0.VodInfo value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasVodInfo() => $_has(0);
  @$pb.TagNumber(1)
  void clearVodInfo() => $_clearField(1);
  @$pb.TagNumber(1)
  $0.VodInfo ensureVodInfo() => $_ensure(0);

  /// 稿件维度的能力与配置。
  @$pb.TagNumber(2)
  $0.PlayArcConf get playArcConf => $_getN(1);
  @$pb.TagNumber(2)
  set playArcConf($0.PlayArcConf value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasPlayArcConf() => $_has(1);
  @$pb.TagNumber(2)
  void clearPlayArcConf() => $_clearField(2);
  @$pb.TagNumber(2)
  $0.PlayArcConf ensurePlayArcConf() => $_ensure(1);

  /// 设备维度的能力与配置。
  @$pb.TagNumber(3)
  $0.PlayDeviceConf get playDeviceConf => $_getN(2);
  @$pb.TagNumber(3)
  set playDeviceConf($0.PlayDeviceConf value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasPlayDeviceConf() => $_has(2);
  @$pb.TagNumber(3)
  void clearPlayDeviceConf() => $_clearField(3);
  @$pb.TagNumber(3)
  $0.PlayDeviceConf ensurePlayDeviceConf() => $_ensure(2);

  /// 播放事件与提示。
  @$pb.TagNumber(4)
  $0.Event get event => $_getN(3);
  @$pb.TagNumber(4)
  set event($0.Event value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasEvent() => $_has(3);
  @$pb.TagNumber(4)
  void clearEvent() => $_clearField(4);
  @$pb.TagNumber(4)
  $0.Event ensureEvent() => $_ensure(3);

  /// 额外扩展数据，具体类型暂未继续细分。
  @$pb.TagNumber(5)
  $1.Any get supplement => $_getN(4);
  @$pb.TagNumber(5)
  set supplement($1.Any value) => $_setField(5, value);
  @$pb.TagNumber(5)
  $core.bool hasSupplement() => $_has(4);
  @$pb.TagNumber(5)
  void clearSupplement() => $_clearField(5);
  @$pb.TagNumber(5)
  $1.Any ensureSupplement() => $_ensure(4);

  /// 当前播放稿件的基础信息。
  @$pb.TagNumber(6)
  $0.PlayArc get playArc => $_getN(5);
  @$pb.TagNumber(6)
  set playArc($0.PlayArc value) => $_setField(6, value);
  @$pb.TagNumber(6)
  $core.bool hasPlayArc() => $_has(5);
  @$pb.TagNumber(6)
  void clearPlayArc() => $_clearField(6);
  @$pb.TagNumber(6)
  $0.PlayArc ensurePlayArc() => $_ensure(5);

  /// 试看清晰度相关信息。
  @$pb.TagNumber(7)
  $0.QnTrialInfo get qnTrialInfo => $_getN(6);
  @$pb.TagNumber(7)
  set qnTrialInfo($0.QnTrialInfo value) => $_setField(7, value);
  @$pb.TagNumber(7)
  $core.bool hasQnTrialInfo() => $_has(6);
  @$pb.TagNumber(7)
  void clearQnTrialInfo() => $_clearField(7);
  @$pb.TagNumber(7)
  $0.QnTrialInfo ensureQnTrialInfo() => $_ensure(6);

  /// 播放历史信息。
  @$pb.TagNumber(8)
  $0.History get history => $_getN(7);
  @$pb.TagNumber(8)
  set history($0.History value) => $_setField(8, value);
  @$pb.TagNumber(8)
  $core.bool hasHistory() => $_has(7);
  @$pb.TagNumber(8)
  void clearHistory() => $_clearField(8);
  @$pb.TagNumber(8)
  $0.History ensureHistory() => $_ensure(7);

  /// 页面提示与弹窗聚合信息。
  @$pb.TagNumber(9)
  $0.ViewInfo get viewInfo => $_getN(8);
  @$pb.TagNumber(9)
  set viewInfo($0.ViewInfo value) => $_setField(9, value);
  @$pb.TagNumber(9)
  $core.bool hasViewInfo() => $_has(8);
  @$pb.TagNumber(9)
  void clearViewInfo() => $_clearField(9);
  @$pb.TagNumber(9)
  $0.ViewInfo ensureViewInfo() => $_ensure(8);

  /// 分片视频资源。
  @$pb.TagNumber(10)
  $0.FragmentVideo get fragmentVideo => $_getN(9);
  @$pb.TagNumber(10)
  set fragmentVideo($0.FragmentVideo value) => $_setField(10, value);
  @$pb.TagNumber(10)
  $core.bool hasFragmentVideo() => $_has(9);
  @$pb.TagNumber(10)
  void clearFragmentVideo() => $_clearField(10);
  @$pb.TagNumber(10)
  $0.FragmentVideo ensureFragmentVideo() => $_ensure(9);

  /// 清晰度控制与增强配置。
  @$pb.TagNumber(11)
  $0.VideoCtrl get videoCtrl => $_getN(10);
  @$pb.TagNumber(11)
  set videoCtrl($0.VideoCtrl value) => $_setField(11, value);
  @$pb.TagNumber(11)
  $core.bool hasVideoCtrl() => $_has(10);
  @$pb.TagNumber(11)
  void clearVideoCtrl() => $_clearField(11);
  @$pb.TagNumber(11)
  $0.VideoCtrl ensureVideoCtrl() => $_ensure(10);
}

/// 半屏频道或设置请求。
class PlayHalfChannelsReq extends $pb.GeneratedMessage {
  factory PlayHalfChannelsReq({
    $fixnum.Int64? aid,
    $fixnum.Int64? cid,
    $core.Iterable<$core.MapEntry<$core.String, $core.String>>? extraContent,
    $core.String? fromScene,
    ResourceType? resourceType,
  }) {
    final result = create();
    if (aid != null) result.aid = aid;
    if (cid != null) result.cid = cid;
    if (extraContent != null) result.extraContent.addEntries(extraContent);
    if (fromScene != null) result.fromScene = fromScene;
    if (resourceType != null) result.resourceType = resourceType;
    return result;
  }

  PlayHalfChannelsReq._();

  factory PlayHalfChannelsReq.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory PlayHalfChannelsReq.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PlayHalfChannelsReq',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'bilibili.app.playerunite.v1'),
      createEmptyInstance: create)
    ..aInt64(1, _omitFieldNames ? '' : 'aid')
    ..aInt64(2, _omitFieldNames ? '' : 'cid')
    ..m<$core.String, $core.String>(3, _omitFieldNames ? '' : 'extraContent',
        protoName: 'extraContent',
        entryClassName: 'PlayHalfChannelsReq.ExtraContentEntry',
        keyFieldType: $pb.PbFieldType.OS,
        valueFieldType: $pb.PbFieldType.OS,
        packageName: const $pb.PackageName('bilibili.app.playerunite.v1'))
    ..aOS(4, _omitFieldNames ? '' : 'fromScene', protoName: 'fromScene')
    ..aE<ResourceType>(5, _omitFieldNames ? '' : 'resourceType',
        protoName: 'resourceType', enumValues: ResourceType.values)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PlayHalfChannelsReq clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PlayHalfChannelsReq copyWith(void Function(PlayHalfChannelsReq) updates) =>
      super.copyWith((message) => updates(message as PlayHalfChannelsReq))
          as PlayHalfChannelsReq;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static PlayHalfChannelsReq create() => PlayHalfChannelsReq._();
  @$core.override
  PlayHalfChannelsReq createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static PlayHalfChannelsReq getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<PlayHalfChannelsReq>(create);
  static PlayHalfChannelsReq? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get aid => $_getI64(0);
  @$pb.TagNumber(1)
  set aid($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasAid() => $_has(0);
  @$pb.TagNumber(1)
  void clearAid() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get cid => $_getI64(1);
  @$pb.TagNumber(2)
  set cid($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasCid() => $_has(1);
  @$pb.TagNumber(2)
  void clearCid() => $_clearField(2);

  @$pb.TagNumber(3)
  $pb.PbMap<$core.String, $core.String> get extraContent => $_getMap(2);

  @$pb.TagNumber(4)
  $core.String get fromScene => $_getSZ(3);
  @$pb.TagNumber(4)
  set fromScene($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasFromScene() => $_has(3);
  @$pb.TagNumber(4)
  void clearFromScene() => $_clearField(4);

  @$pb.TagNumber(5)
  ResourceType get resourceType => $_getN(4);
  @$pb.TagNumber(5)
  set resourceType(ResourceType value) => $_setField(5, value);
  @$pb.TagNumber(5)
  $core.bool hasResourceType() => $_has(4);
  @$pb.TagNumber(5)
  void clearResourceType() => $_clearField(5);
}

/// 半屏频道或设置分组响应。
class PlayHalfChannelsReply extends $pb.GeneratedMessage {
  factory PlayHalfChannelsReply({
    $core.Iterable<$0.SettingGroup>? groups,
  }) {
    final result = create();
    if (groups != null) result.groups.addAll(groups);
    return result;
  }

  PlayHalfChannelsReply._();

  factory PlayHalfChannelsReply.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory PlayHalfChannelsReply.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PlayHalfChannelsReply',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'bilibili.app.playerunite.v1'),
      createEmptyInstance: create)
    ..pPM<$0.SettingGroup>(1, _omitFieldNames ? '' : 'groups',
        subBuilder: $0.SettingGroup.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PlayHalfChannelsReply clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PlayHalfChannelsReply copyWith(
          void Function(PlayHalfChannelsReply) updates) =>
      super.copyWith((message) => updates(message as PlayHalfChannelsReply))
          as PlayHalfChannelsReply;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static PlayHalfChannelsReply create() => PlayHalfChannelsReply._();
  @$core.override
  PlayHalfChannelsReply createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static PlayHalfChannelsReply getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<PlayHalfChannelsReply>(create);
  static PlayHalfChannelsReply? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<$0.SettingGroup> get groups => $_getList(0);
}

/// 播放补充信息请求。
class PlayAdditionReq extends $pb.GeneratedMessage {
  factory PlayAdditionReq() => create();

  PlayAdditionReq._();

  factory PlayAdditionReq.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory PlayAdditionReq.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PlayAdditionReq',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'bilibili.app.playerunite.v1'),
      createEmptyInstance: create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PlayAdditionReq clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PlayAdditionReq copyWith(void Function(PlayAdditionReq) updates) =>
      super.copyWith((message) => updates(message as PlayAdditionReq))
          as PlayAdditionReq;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static PlayAdditionReq create() => PlayAdditionReq._();
  @$core.override
  PlayAdditionReq createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static PlayAdditionReq getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<PlayAdditionReq>(create);
  static PlayAdditionReq? _defaultInstance;
}

/// 播放补充信息响应。
class PlayAdditionReply extends $pb.GeneratedMessage {
  factory PlayAdditionReply({
    UgcViewInfoMaterial? ugcViewInfoMaterial,
  }) {
    final result = create();
    if (ugcViewInfoMaterial != null)
      result.ugcViewInfoMaterial = ugcViewInfoMaterial;
    return result;
  }

  PlayAdditionReply._();

  factory PlayAdditionReply.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory PlayAdditionReply.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PlayAdditionReply',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'bilibili.app.playerunite.v1'),
      createEmptyInstance: create)
    ..aOM<UgcViewInfoMaterial>(1, _omitFieldNames ? '' : 'ugcViewInfoMaterial',
        protoName: 'ugcViewInfoMaterial',
        subBuilder: UgcViewInfoMaterial.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PlayAdditionReply clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PlayAdditionReply copyWith(void Function(PlayAdditionReply) updates) =>
      super.copyWith((message) => updates(message as PlayAdditionReply))
          as PlayAdditionReply;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static PlayAdditionReply create() => PlayAdditionReply._();
  @$core.override
  PlayAdditionReply createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static PlayAdditionReply getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<PlayAdditionReply>(create);
  static PlayAdditionReply? _defaultInstance;

  @$pb.TagNumber(1)
  UgcViewInfoMaterial get ugcViewInfoMaterial => $_getN(0);
  @$pb.TagNumber(1)
  set ugcViewInfoMaterial(UgcViewInfoMaterial value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasUgcViewInfoMaterial() => $_has(0);
  @$pb.TagNumber(1)
  void clearUgcViewInfoMaterial() => $_clearField(1);
  @$pb.TagNumber(1)
  UgcViewInfoMaterial ensureUgcViewInfoMaterial() => $_ensure(0);
}

/// 播放补充接口返回的 UGC 按钮与描述素材。
class UgcViewInfoMaterial extends $pb.GeneratedMessage {
  factory UgcViewInfoMaterial({
    $core.String? title,
    $core.String? btnText,
    $core.String? btnUrl,
    $core.int? btnJumpType,
    $core.String? descText,
    $core.String? descUrl,
    $core.Iterable<$core.MapEntry<$core.String, $core.String>>? track,
  }) {
    final result = create();
    if (title != null) result.title = title;
    if (btnText != null) result.btnText = btnText;
    if (btnUrl != null) result.btnUrl = btnUrl;
    if (btnJumpType != null) result.btnJumpType = btnJumpType;
    if (descText != null) result.descText = descText;
    if (descUrl != null) result.descUrl = descUrl;
    if (track != null) result.track.addEntries(track);
    return result;
  }

  UgcViewInfoMaterial._();

  factory UgcViewInfoMaterial.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory UgcViewInfoMaterial.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'UgcViewInfoMaterial',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'bilibili.app.playerunite.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'title')
    ..aOS(2, _omitFieldNames ? '' : 'btnText', protoName: 'btnText')
    ..aOS(3, _omitFieldNames ? '' : 'btnUrl', protoName: 'btnUrl')
    ..aI(4, _omitFieldNames ? '' : 'btnJumpType', protoName: 'btnJumpType')
    ..aOS(5, _omitFieldNames ? '' : 'descText', protoName: 'descText')
    ..aOS(6, _omitFieldNames ? '' : 'descUrl', protoName: 'descUrl')
    ..m<$core.String, $core.String>(7, _omitFieldNames ? '' : 'track',
        entryClassName: 'UgcViewInfoMaterial.TrackEntry',
        keyFieldType: $pb.PbFieldType.OS,
        valueFieldType: $pb.PbFieldType.OS,
        packageName: const $pb.PackageName('bilibili.app.playerunite.v1'))
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UgcViewInfoMaterial clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UgcViewInfoMaterial copyWith(void Function(UgcViewInfoMaterial) updates) =>
      super.copyWith((message) => updates(message as UgcViewInfoMaterial))
          as UgcViewInfoMaterial;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static UgcViewInfoMaterial create() => UgcViewInfoMaterial._();
  @$core.override
  UgcViewInfoMaterial createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static UgcViewInfoMaterial getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<UgcViewInfoMaterial>(create);
  static UgcViewInfoMaterial? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get title => $_getSZ(0);
  @$pb.TagNumber(1)
  set title($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasTitle() => $_has(0);
  @$pb.TagNumber(1)
  void clearTitle() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get btnText => $_getSZ(1);
  @$pb.TagNumber(2)
  set btnText($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasBtnText() => $_has(1);
  @$pb.TagNumber(2)
  void clearBtnText() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get btnUrl => $_getSZ(2);
  @$pb.TagNumber(3)
  set btnUrl($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasBtnUrl() => $_has(2);
  @$pb.TagNumber(3)
  void clearBtnUrl() => $_clearField(3);

  /// 这里先保留为 int32，暂未恢复出专门枚举。
  @$pb.TagNumber(4)
  $core.int get btnJumpType => $_getIZ(3);
  @$pb.TagNumber(4)
  set btnJumpType($core.int value) => $_setSignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasBtnJumpType() => $_has(3);
  @$pb.TagNumber(4)
  void clearBtnJumpType() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get descText => $_getSZ(4);
  @$pb.TagNumber(5)
  set descText($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasDescText() => $_has(4);
  @$pb.TagNumber(5)
  void clearDescText() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.String get descUrl => $_getSZ(5);
  @$pb.TagNumber(6)
  set descUrl($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasDescUrl() => $_has(5);
  @$pb.TagNumber(6)
  void clearDescUrl() => $_clearField(6);

  @$pb.TagNumber(7)
  $pb.PbMap<$core.String, $core.String> get track => $_getMap(6);
}

/// 当前包下的播放器 RPC 服务。
class PlayerApi {
  final $pb.RpcClient _client;

  PlayerApi(this._client);

  $async.Future<PlayViewUniteReply> playViewUnite(
          $pb.ClientContext? ctx, PlayViewUniteReq request) =>
      _client.invoke<PlayViewUniteReply>(
          ctx, 'Player', 'PlayViewUnite', request, PlayViewUniteReply());
  $async.Future<PlayHalfChannelsReply> playHalfChannels(
          $pb.ClientContext? ctx, PlayHalfChannelsReq request) =>
      _client.invoke<PlayHalfChannelsReply>(
          ctx, 'Player', 'PlayHalfChannels', request, PlayHalfChannelsReply());
  $async.Future<PlayAdditionReply> playAddition(
          $pb.ClientContext? ctx, PlayAdditionReq request) =>
      _client.invoke<PlayAdditionReply>(
          ctx, 'Player', 'PlayAddition', request, PlayAdditionReply());
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
