// This is a generated file - do not edit.
//
// Generated from bilibili/app/playerunite/v1/playerunite.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports
// ignore_for_file: unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

import 'package:protobuf/well_known_types/google/protobuf/any.pbjson.dart'
    as $1;

import '../../../playershared.pbjson.dart' as $0;

@$core.Deprecated('Use resourceTypeDescriptor instead')
const ResourceType$json = {
  '1': 'ResourceType',
  '2': [
    {'1': 'RESOURCE_TYPE_DEFAULT', '2': 0},
    {'1': 'RESOURCE_TYPE_OPUS', '2': 1},
  ],
};

/// Descriptor for `ResourceType`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List resourceTypeDescriptor = $convert.base64Decode(
    'CgxSZXNvdXJjZVR5cGUSGQoVUkVTT1VSQ0VfVFlQRV9ERUZBVUxUEAASFgoSUkVTT1VSQ0VfVF'
    'lQRV9PUFVTEAE=');

@$core.Deprecated('Use playViewUniteReqDescriptor instead')
const PlayViewUniteReq$json = {
  '1': 'PlayViewUniteReq',
  '2': [
    {
      '1': 'vod',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.bilibili.playershared.VideoVod',
      '10': 'vod'
    },
    {'1': 'spmid', '3': 2, '4': 1, '5': 9, '10': 'spmid'},
    {'1': 'fromSpmid', '3': 3, '4': 1, '5': 9, '10': 'fromSpmid'},
    {
      '1': 'extraContent',
      '3': 4,
      '4': 3,
      '5': 11,
      '6': '.bilibili.app.playerunite.v1.PlayViewUniteReq.ExtraContentEntry',
      '10': 'extraContent'
    },
    {'1': 'bvid', '3': 5, '4': 1, '5': 9, '10': 'bvid'},
    {'1': 'adExtra', '3': 6, '4': 1, '5': 9, '10': 'adExtra'},
    {
      '1': 'fragment',
      '3': 7,
      '4': 1,
      '5': 11,
      '6': '.bilibili.playershared.Fragment',
      '10': 'fragment'
    },
    {'1': 'fromScene', '3': 8, '4': 1, '5': 9, '10': 'fromScene'},
    {
      '1': 'playCtrl',
      '3': 9,
      '4': 1,
      '5': 14,
      '6': '.bilibili.playershared.PlayCtrl',
      '10': 'playCtrl'
    },
  ],
  '3': [PlayViewUniteReq_ExtraContentEntry$json],
};

@$core.Deprecated('Use playViewUniteReqDescriptor instead')
const PlayViewUniteReq_ExtraContentEntry$json = {
  '1': 'ExtraContentEntry',
  '2': [
    {'1': 'key', '3': 1, '4': 1, '5': 9, '10': 'key'},
    {'1': 'value', '3': 2, '4': 1, '5': 9, '10': 'value'},
  ],
  '7': {'7': true},
};

/// Descriptor for `PlayViewUniteReq`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List playViewUniteReqDescriptor = $convert.base64Decode(
    'ChBQbGF5Vmlld1VuaXRlUmVxEjEKA3ZvZBgBIAEoCzIfLmJpbGliaWxpLnBsYXllcnNoYXJlZC'
    '5WaWRlb1ZvZFIDdm9kEhQKBXNwbWlkGAIgASgJUgVzcG1pZBIcCglmcm9tU3BtaWQYAyABKAlS'
    'CWZyb21TcG1pZBJjCgxleHRyYUNvbnRlbnQYBCADKAsyPy5iaWxpYmlsaS5hcHAucGxheWVydW'
    '5pdGUudjEuUGxheVZpZXdVbml0ZVJlcS5FeHRyYUNvbnRlbnRFbnRyeVIMZXh0cmFDb250ZW50'
    'EhIKBGJ2aWQYBSABKAlSBGJ2aWQSGAoHYWRFeHRyYRgGIAEoCVIHYWRFeHRyYRI7CghmcmFnbW'
    'VudBgHIAEoCzIfLmJpbGliaWxpLnBsYXllcnNoYXJlZC5GcmFnbWVudFIIZnJhZ21lbnQSHAoJ'
    'ZnJvbVNjZW5lGAggASgJUglmcm9tU2NlbmUSOwoIcGxheUN0cmwYCSABKA4yHy5iaWxpYmlsaS'
    '5wbGF5ZXJzaGFyZWQuUGxheUN0cmxSCHBsYXlDdHJsGj8KEUV4dHJhQ29udGVudEVudHJ5EhAK'
    'A2tleRgBIAEoCVIDa2V5EhQKBXZhbHVlGAIgASgJUgV2YWx1ZToCOAE=');

@$core.Deprecated('Use playViewUniteReplyDescriptor instead')
const PlayViewUniteReply$json = {
  '1': 'PlayViewUniteReply',
  '2': [
    {
      '1': 'vodInfo',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.bilibili.playershared.VodInfo',
      '10': 'vodInfo'
    },
    {
      '1': 'playArcConf',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.bilibili.playershared.PlayArcConf',
      '10': 'playArcConf'
    },
    {
      '1': 'playDeviceConf',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.bilibili.playershared.PlayDeviceConf',
      '10': 'playDeviceConf'
    },
    {
      '1': 'event',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.bilibili.playershared.Event',
      '10': 'event'
    },
    {
      '1': 'supplement',
      '3': 5,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Any',
      '10': 'supplement'
    },
    {
      '1': 'playArc',
      '3': 6,
      '4': 1,
      '5': 11,
      '6': '.bilibili.playershared.PlayArc',
      '10': 'playArc'
    },
    {
      '1': 'qnTrialInfo',
      '3': 7,
      '4': 1,
      '5': 11,
      '6': '.bilibili.playershared.QnTrialInfo',
      '10': 'qnTrialInfo'
    },
    {
      '1': 'history',
      '3': 8,
      '4': 1,
      '5': 11,
      '6': '.bilibili.playershared.History',
      '10': 'history'
    },
    {
      '1': 'viewInfo',
      '3': 9,
      '4': 1,
      '5': 11,
      '6': '.bilibili.playershared.ViewInfo',
      '10': 'viewInfo'
    },
    {
      '1': 'fragmentVideo',
      '3': 10,
      '4': 1,
      '5': 11,
      '6': '.bilibili.playershared.FragmentVideo',
      '10': 'fragmentVideo'
    },
    {
      '1': 'videoCtrl',
      '3': 11,
      '4': 1,
      '5': 11,
      '6': '.bilibili.playershared.VideoCtrl',
      '10': 'videoCtrl'
    },
  ],
};

/// Descriptor for `PlayViewUniteReply`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List playViewUniteReplyDescriptor = $convert.base64Decode(
    'ChJQbGF5Vmlld1VuaXRlUmVwbHkSOAoHdm9kSW5mbxgBIAEoCzIeLmJpbGliaWxpLnBsYXllcn'
    'NoYXJlZC5Wb2RJbmZvUgd2b2RJbmZvEkQKC3BsYXlBcmNDb25mGAIgASgLMiIuYmlsaWJpbGku'
    'cGxheWVyc2hhcmVkLlBsYXlBcmNDb25mUgtwbGF5QXJjQ29uZhJNCg5wbGF5RGV2aWNlQ29uZh'
    'gDIAEoCzIlLmJpbGliaWxpLnBsYXllcnNoYXJlZC5QbGF5RGV2aWNlQ29uZlIOcGxheURldmlj'
    'ZUNvbmYSMgoFZXZlbnQYBCABKAsyHC5iaWxpYmlsaS5wbGF5ZXJzaGFyZWQuRXZlbnRSBWV2ZW'
    '50EjQKCnN1cHBsZW1lbnQYBSABKAsyFC5nb29nbGUucHJvdG9idWYuQW55UgpzdXBwbGVtZW50'
    'EjgKB3BsYXlBcmMYBiABKAsyHi5iaWxpYmlsaS5wbGF5ZXJzaGFyZWQuUGxheUFyY1IHcGxheU'
    'FyYxJECgtxblRyaWFsSW5mbxgHIAEoCzIiLmJpbGliaWxpLnBsYXllcnNoYXJlZC5RblRyaWFs'
    'SW5mb1ILcW5UcmlhbEluZm8SOAoHaGlzdG9yeRgIIAEoCzIeLmJpbGliaWxpLnBsYXllcnNoYX'
    'JlZC5IaXN0b3J5UgdoaXN0b3J5EjsKCHZpZXdJbmZvGAkgASgLMh8uYmlsaWJpbGkucGxheWVy'
    'c2hhcmVkLlZpZXdJbmZvUgh2aWV3SW5mbxJKCg1mcmFnbWVudFZpZGVvGAogASgLMiQuYmlsaW'
    'JpbGkucGxheWVyc2hhcmVkLkZyYWdtZW50VmlkZW9SDWZyYWdtZW50VmlkZW8SPgoJdmlkZW9D'
    'dHJsGAsgASgLMiAuYmlsaWJpbGkucGxheWVyc2hhcmVkLlZpZGVvQ3RybFIJdmlkZW9DdHJs');

@$core.Deprecated('Use playHalfChannelsReqDescriptor instead')
const PlayHalfChannelsReq$json = {
  '1': 'PlayHalfChannelsReq',
  '2': [
    {'1': 'aid', '3': 1, '4': 1, '5': 3, '10': 'aid'},
    {'1': 'cid', '3': 2, '4': 1, '5': 3, '10': 'cid'},
    {
      '1': 'extraContent',
      '3': 3,
      '4': 3,
      '5': 11,
      '6': '.bilibili.app.playerunite.v1.PlayHalfChannelsReq.ExtraContentEntry',
      '10': 'extraContent'
    },
    {'1': 'fromScene', '3': 4, '4': 1, '5': 9, '10': 'fromScene'},
    {
      '1': 'resourceType',
      '3': 5,
      '4': 1,
      '5': 14,
      '6': '.bilibili.app.playerunite.v1.ResourceType',
      '10': 'resourceType'
    },
  ],
  '3': [PlayHalfChannelsReq_ExtraContentEntry$json],
};

@$core.Deprecated('Use playHalfChannelsReqDescriptor instead')
const PlayHalfChannelsReq_ExtraContentEntry$json = {
  '1': 'ExtraContentEntry',
  '2': [
    {'1': 'key', '3': 1, '4': 1, '5': 9, '10': 'key'},
    {'1': 'value', '3': 2, '4': 1, '5': 9, '10': 'value'},
  ],
  '7': {'7': true},
};

/// Descriptor for `PlayHalfChannelsReq`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List playHalfChannelsReqDescriptor = $convert.base64Decode(
    'ChNQbGF5SGFsZkNoYW5uZWxzUmVxEhAKA2FpZBgBIAEoA1IDYWlkEhAKA2NpZBgCIAEoA1IDY2'
    'lkEmYKDGV4dHJhQ29udGVudBgDIAMoCzJCLmJpbGliaWxpLmFwcC5wbGF5ZXJ1bml0ZS52MS5Q'
    'bGF5SGFsZkNoYW5uZWxzUmVxLkV4dHJhQ29udGVudEVudHJ5UgxleHRyYUNvbnRlbnQSHAoJZn'
    'JvbVNjZW5lGAQgASgJUglmcm9tU2NlbmUSTQoMcmVzb3VyY2VUeXBlGAUgASgOMikuYmlsaWJp'
    'bGkuYXBwLnBsYXllcnVuaXRlLnYxLlJlc291cmNlVHlwZVIMcmVzb3VyY2VUeXBlGj8KEUV4dH'
    'JhQ29udGVudEVudHJ5EhAKA2tleRgBIAEoCVIDa2V5EhQKBXZhbHVlGAIgASgJUgV2YWx1ZToC'
    'OAE=');

@$core.Deprecated('Use playHalfChannelsReplyDescriptor instead')
const PlayHalfChannelsReply$json = {
  '1': 'PlayHalfChannelsReply',
  '2': [
    {
      '1': 'groups',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.bilibili.playershared.SettingGroup',
      '10': 'groups'
    },
  ],
};

/// Descriptor for `PlayHalfChannelsReply`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List playHalfChannelsReplyDescriptor = $convert.base64Decode(
    'ChVQbGF5SGFsZkNoYW5uZWxzUmVwbHkSOwoGZ3JvdXBzGAEgAygLMiMuYmlsaWJpbGkucGxheW'
    'Vyc2hhcmVkLlNldHRpbmdHcm91cFIGZ3JvdXBz');

@$core.Deprecated('Use playAdditionReqDescriptor instead')
const PlayAdditionReq$json = {
  '1': 'PlayAdditionReq',
};

/// Descriptor for `PlayAdditionReq`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List playAdditionReqDescriptor =
    $convert.base64Decode('Cg9QbGF5QWRkaXRpb25SZXE=');

@$core.Deprecated('Use playAdditionReplyDescriptor instead')
const PlayAdditionReply$json = {
  '1': 'PlayAdditionReply',
  '2': [
    {
      '1': 'ugcViewInfoMaterial',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.bilibili.app.playerunite.v1.UgcViewInfoMaterial',
      '10': 'ugcViewInfoMaterial'
    },
  ],
};

/// Descriptor for `PlayAdditionReply`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List playAdditionReplyDescriptor = $convert.base64Decode(
    'ChFQbGF5QWRkaXRpb25SZXBseRJiChN1Z2NWaWV3SW5mb01hdGVyaWFsGAEgASgLMjAuYmlsaW'
    'JpbGkuYXBwLnBsYXllcnVuaXRlLnYxLlVnY1ZpZXdJbmZvTWF0ZXJpYWxSE3VnY1ZpZXdJbmZv'
    'TWF0ZXJpYWw=');

@$core.Deprecated('Use ugcViewInfoMaterialDescriptor instead')
const UgcViewInfoMaterial$json = {
  '1': 'UgcViewInfoMaterial',
  '2': [
    {'1': 'title', '3': 1, '4': 1, '5': 9, '10': 'title'},
    {'1': 'btnText', '3': 2, '4': 1, '5': 9, '10': 'btnText'},
    {'1': 'btnUrl', '3': 3, '4': 1, '5': 9, '10': 'btnUrl'},
    {'1': 'btnJumpType', '3': 4, '4': 1, '5': 5, '10': 'btnJumpType'},
    {'1': 'descText', '3': 5, '4': 1, '5': 9, '10': 'descText'},
    {'1': 'descUrl', '3': 6, '4': 1, '5': 9, '10': 'descUrl'},
    {
      '1': 'track',
      '3': 7,
      '4': 3,
      '5': 11,
      '6': '.bilibili.app.playerunite.v1.UgcViewInfoMaterial.TrackEntry',
      '10': 'track'
    },
  ],
  '3': [UgcViewInfoMaterial_TrackEntry$json],
};

@$core.Deprecated('Use ugcViewInfoMaterialDescriptor instead')
const UgcViewInfoMaterial_TrackEntry$json = {
  '1': 'TrackEntry',
  '2': [
    {'1': 'key', '3': 1, '4': 1, '5': 9, '10': 'key'},
    {'1': 'value', '3': 2, '4': 1, '5': 9, '10': 'value'},
  ],
  '7': {'7': true},
};

/// Descriptor for `UgcViewInfoMaterial`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List ugcViewInfoMaterialDescriptor = $convert.base64Decode(
    'ChNVZ2NWaWV3SW5mb01hdGVyaWFsEhQKBXRpdGxlGAEgASgJUgV0aXRsZRIYCgdidG5UZXh0GA'
    'IgASgJUgdidG5UZXh0EhYKBmJ0blVybBgDIAEoCVIGYnRuVXJsEiAKC2J0bkp1bXBUeXBlGAQg'
    'ASgFUgtidG5KdW1wVHlwZRIaCghkZXNjVGV4dBgFIAEoCVIIZGVzY1RleHQSGAoHZGVzY1VybB'
    'gGIAEoCVIHZGVzY1VybBJRCgV0cmFjaxgHIAMoCzI7LmJpbGliaWxpLmFwcC5wbGF5ZXJ1bml0'
    'ZS52MS5VZ2NWaWV3SW5mb01hdGVyaWFsLlRyYWNrRW50cnlSBXRyYWNrGjgKClRyYWNrRW50cn'
    'kSEAoDa2V5GAEgASgJUgNrZXkSFAoFdmFsdWUYAiABKAlSBXZhbHVlOgI4AQ==');

const $core.Map<$core.String, $core.dynamic> PlayerServiceBase$json = {
  '1': 'Player',
  '2': [
    {
      '1': 'PlayViewUnite',
      '2': '.bilibili.app.playerunite.v1.PlayViewUniteReq',
      '3': '.bilibili.app.playerunite.v1.PlayViewUniteReply'
    },
    {
      '1': 'PlayHalfChannels',
      '2': '.bilibili.app.playerunite.v1.PlayHalfChannelsReq',
      '3': '.bilibili.app.playerunite.v1.PlayHalfChannelsReply'
    },
    {
      '1': 'PlayAddition',
      '2': '.bilibili.app.playerunite.v1.PlayAdditionReq',
      '3': '.bilibili.app.playerunite.v1.PlayAdditionReply'
    },
  ],
};

@$core.Deprecated('Use playerServiceDescriptor instead')
const $core.Map<$core.String, $core.Map<$core.String, $core.dynamic>>
    PlayerServiceBase$messageJson = {
  '.bilibili.app.playerunite.v1.PlayViewUniteReq': PlayViewUniteReq$json,
  '.bilibili.playershared.VideoVod': $0.VideoVod$json,
  '.bilibili.app.playerunite.v1.PlayViewUniteReq.ExtraContentEntry':
      PlayViewUniteReq_ExtraContentEntry$json,
  '.bilibili.playershared.Fragment': $0.Fragment$json,
  '.bilibili.playershared.FragmentInfo': $0.FragmentInfo$json,
  '.google.protobuf.Any': $1.Any$json,
  '.bilibili.app.playerunite.v1.PlayViewUniteReply': PlayViewUniteReply$json,
  '.bilibili.playershared.VodInfo': $0.VodInfo$json,
  '.bilibili.playershared.Stream': $0.Stream$json,
  '.bilibili.playershared.StreamInfo': $0.StreamInfo$json,
  '.bilibili.playershared.StreamLimit': $0.StreamLimit$json,
  '.bilibili.playershared.Scheme': $0.Scheme$json,
  '.bilibili.playershared.StreamInfo.ReportParamsEntry':
      $0.StreamInfo_ReportParamsEntry$json,
  '.bilibili.playershared.DashVideo': $0.DashVideo$json,
  '.bilibili.playershared.SegmentVideo': $0.SegmentVideo$json,
  '.bilibili.playershared.ResponseUrl': $0.ResponseUrl$json,
  '.bilibili.playershared.MultiDashVideo': $0.MultiDashVideo$json,
  '.bilibili.playershared.DashItem': $0.DashItem$json,
  '.bilibili.playershared.DolbyItem': $0.DolbyItem$json,
  '.bilibili.playershared.VolumeInfo': $0.VolumeInfo$json,
  '.bilibili.playershared.VolumeInfo.MultiSceneArgsEntry':
      $0.VolumeInfo_MultiSceneArgsEntry$json,
  '.bilibili.playershared.LossLessItem': $0.LossLessItem$json,
  '.bilibili.playershared.AIAudio': $0.AIAudio$json,
  '.bilibili.playershared.AIAudioItem': $0.AIAudioItem$json,
  '.bilibili.playershared.Badge': $0.Badge$json,
  '.bilibili.playershared.QnPanel': $0.QnPanel$json,
  '.bilibili.playershared.QnItem': $0.QnItem$json,
  '.bilibili.playershared.QnGroup': $0.QnGroup$json,
  '.bilibili.playershared.PlayArcConf': $0.PlayArcConf$json,
  '.bilibili.playershared.PlayArcConf.ArcConfsEntry':
      $0.PlayArcConf_ArcConfsEntry$json,
  '.bilibili.playershared.ArcConf': $0.ArcConf$json,
  '.bilibili.playershared.ExtraContent': $0.ExtraContent$json,
  '.bilibili.playershared.PlayDeviceConf': $0.PlayDeviceConf$json,
  '.bilibili.playershared.PlayDeviceConf.DeviceConfsEntry':
      $0.PlayDeviceConf_DeviceConfsEntry$json,
  '.bilibili.playershared.DeviceConf': $0.DeviceConf$json,
  '.bilibili.playershared.ConfValue': $0.ConfValue$json,
  '.bilibili.playershared.Event': $0.Event$json,
  '.bilibili.playershared.Shake': $0.Shake$json,
  '.bilibili.playershared.QnTip': $0.QnTip$json,
  '.bilibili.playershared.PlayArc': $0.PlayArc$json,
  '.bilibili.playershared.Interaction': $0.Interaction$json,
  '.bilibili.playershared.Node': $0.Node$json,
  '.bilibili.playershared.Dimension': $0.Dimension$json,
  '.bilibili.playershared.QnTrialInfo': $0.QnTrialInfo$json,
  '.bilibili.playershared.Toast': $0.Toast$json,
  '.bilibili.playershared.Button': $0.Button$json,
  '.bilibili.playershared.Button.ReportParamsEntry':
      $0.Button_ReportParamsEntry$json,
  '.bilibili.playershared.History': $0.History$json,
  '.bilibili.playershared.HistoryInfo': $0.HistoryInfo$json,
  '.bilibili.playershared.ViewInfo': $0.ViewInfo$json,
  '.bilibili.playershared.ViewInfo.DialogMapEntry':
      $0.ViewInfo_DialogMapEntry$json,
  '.bilibili.playershared.Dialog': $0.Dialog$json,
  '.bilibili.playershared.BackgroundInfo': $0.BackgroundInfo$json,
  '.bilibili.playershared.TextInfo': $0.TextInfo$json,
  '.bilibili.playershared.ImageInfo': $0.ImageInfo$json,
  '.bilibili.playershared.ButtonInfo': $0.ButtonInfo$json,
  '.bilibili.playershared.BadgeInfo': $0.BadgeInfo$json,
  '.bilibili.playershared.GradientColor': $0.GradientColor$json,
  '.bilibili.playershared.Report': $0.Report$json,
  '.bilibili.playershared.ButtonInfo.OrderReportParamsEntry':
      $0.ButtonInfo_OrderReportParamsEntry$json,
  '.bilibili.playershared.TaskParam': $0.TaskParam$json,
  '.bilibili.playershared.BottomDisplay': $0.BottomDisplay$json,
  '.bilibili.playershared.ExtData': $0.ExtData$json,
  '.bilibili.playershared.PlayListInfo': $0.PlayListInfo$json,
  '.bilibili.playershared.PlayList': $0.PlayList$json,
  '.bilibili.playershared.Banner': $0.Banner$json,
  '.bilibili.playershared.EpInlineVideoInfo': $0.EpInlineVideoInfo$json,
  '.bilibili.playershared.EpInlineVideo': $0.EpInlineVideo$json,
  '.bilibili.playershared.ChargingExt': $0.ChargingExt$json,
  '.bilibili.playershared.QrCode': $0.QrCode$json,
  '.bilibili.playershared.Dialog.ConditionsEntry':
      $0.Dialog_ConditionsEntry$json,
  '.bilibili.playershared.PromptBar': $0.PromptBar$json,
  '.bilibili.playershared.BenefitInfo': $0.BenefitInfo$json,
  '.bilibili.playershared.ComprehensiveToast': $0.ComprehensiveToast$json,
  '.bilibili.playershared.ComprehensiveToast.OrderReportParamsEntry':
      $0.ComprehensiveToast_OrderReportParamsEntry$json,
  '.bilibili.playershared.PayWallOnshowAction': $0.PayWallOnshowAction$json,
  '.bilibili.playershared.PayWallOnshowAction.OrderReportParamsEntry':
      $0.PayWallOnshowAction_OrderReportParamsEntry$json,
  '.bilibili.playershared.ExpSwitch': $0.ExpSwitch$json,
  '.bilibili.playershared.ExpSwitch.ExpAbEntry': $0.ExpSwitch_ExpAbEntry$json,
  '.bilibili.playershared.FullPromptBar': $0.FullPromptBar$json,
  '.bilibili.playershared.FoldData': $0.FoldData$json,
  '.bilibili.playershared.CountDownItem': $0.CountDownItem$json,
  '.bilibili.playershared.ResidentBar': $0.ResidentBar$json,
  '.bilibili.playershared.FragmentVideo': $0.FragmentVideo$json,
  '.bilibili.playershared.FragmentVideoInfo': $0.FragmentVideoInfo$json,
  '.bilibili.playershared.VideoCtrl': $0.VideoCtrl$json,
  '.bilibili.playershared.AutoQnCtl': $0.AutoQnCtl$json,
  '.bilibili.playershared.AutoQnCtl.SceneQnRangeEntry':
      $0.AutoQnCtl_SceneQnRangeEntry$json,
  '.bilibili.playershared.AutoQnRange': $0.AutoQnRange$json,
  '.bilibili.playershared.QnExp': $0.QnExp$json,
  '.bilibili.playershared.QnExpThree': $0.QnExpThree$json,
  '.bilibili.playershared.DeviceEnhance': $0.DeviceEnhance$json,
  '.bilibili.app.playerunite.v1.PlayHalfChannelsReq': PlayHalfChannelsReq$json,
  '.bilibili.app.playerunite.v1.PlayHalfChannelsReq.ExtraContentEntry':
      PlayHalfChannelsReq_ExtraContentEntry$json,
  '.bilibili.app.playerunite.v1.PlayHalfChannelsReply':
      PlayHalfChannelsReply$json,
  '.bilibili.playershared.SettingGroup': $0.SettingGroup$json,
  '.bilibili.playershared.SettingItem': $0.SettingItem$json,
  '.bilibili.playershared.SettingBase': $0.SettingBase$json,
  '.bilibili.playershared.SettingControl': $0.SettingControl$json,
  '.bilibili.playershared.SettingBase.ReportEntry':
      $0.SettingBase_ReportEntry$json,
  '.bilibili.playershared.SettingMore': $0.SettingMore$json,
  '.bilibili.playershared.SettingVertical': $0.SettingVertical$json,
  '.bilibili.playershared.SettingSwitch': $0.SettingSwitch$json,
  '.bilibili.app.playerunite.v1.PlayAdditionReq': PlayAdditionReq$json,
  '.bilibili.app.playerunite.v1.PlayAdditionReply': PlayAdditionReply$json,
  '.bilibili.app.playerunite.v1.UgcViewInfoMaterial': UgcViewInfoMaterial$json,
  '.bilibili.app.playerunite.v1.UgcViewInfoMaterial.TrackEntry':
      UgcViewInfoMaterial_TrackEntry$json,
};

/// Descriptor for `Player`. Decode as a `google.protobuf.ServiceDescriptorProto`.
final $typed_data.Uint8List playerServiceDescriptor = $convert.base64Decode(
    'CgZQbGF5ZXISbwoNUGxheVZpZXdVbml0ZRItLmJpbGliaWxpLmFwcC5wbGF5ZXJ1bml0ZS52MS'
    '5QbGF5Vmlld1VuaXRlUmVxGi8uYmlsaWJpbGkuYXBwLnBsYXllcnVuaXRlLnYxLlBsYXlWaWV3'
    'VW5pdGVSZXBseRJ4ChBQbGF5SGFsZkNoYW5uZWxzEjAuYmlsaWJpbGkuYXBwLnBsYXllcnVuaX'
    'RlLnYxLlBsYXlIYWxmQ2hhbm5lbHNSZXEaMi5iaWxpYmlsaS5hcHAucGxheWVydW5pdGUudjEu'
    'UGxheUhhbGZDaGFubmVsc1JlcGx5EmwKDFBsYXlBZGRpdGlvbhIsLmJpbGliaWxpLmFwcC5wbG'
    'F5ZXJ1bml0ZS52MS5QbGF5QWRkaXRpb25SZXEaLi5iaWxpYmlsaS5hcHAucGxheWVydW5pdGUu'
    'djEuUGxheUFkZGl0aW9uUmVwbHk=');
