## 目录结构说明

本目录包含 iOS 版 专业版(Professional) SDK 的Demo 源代码，主要演示接口如何调用以及最基本的功能。

```
├─ SDK 
|  ├─ TXLiteAVSDK_Professional.framework // 如果您下载的是专业版 zip 包，解压后将出现此文件
|  ├─ TXLiteAVSDK_Enterprise.framework   // 如果您下载的是企业版 zip 包，解压后将出现此文件
|  ├─ TXLiteAVSDK_ReplayKitExt.framework   // 录屏直播需要的framework
├─ Demo // 专业版Demo，包括演示直播、点播、短视频、RTC 在内的多项功能
├── ReplaykitUpload
└── TXLiteAVDemo
    ├── App               // 程序入口界面
    ├── AudioSettingKit   // 音效面板，包含BGM播放，变声，混响，变调等效果
    ├── BeautySettingKit  // 美颜面板，包含美颜，滤镜，动效等效果
    ├── Debug             // 包含 GenerateTestUserSig，用于本地生成测试用的 UserSig
    ├── LivePlayerDemo    // 直播播放，可以扫码播放地址进行播放
    ├── LivePusherDemo    // 直播推流，包含推流时，设置美颜，音效，等基础操作
    ├── Login             // 一个演示性质的简单登录界面
    ├── LiveLinkMicDemoOld// 互动直播，包含连麦、聊天、点赞等特性
    ├── LiveLinkMicDemoNew// 互动直播新方案，超低延时直播等特性
    ├── SuperPlayerDemo   // 超级播放器 Demo，ugc视频发布后，会使用超级播放器进行播放
    ├── SuperPlayerKit    // 超级播放器组件
    ├── TRTCMeetingDemo   // 场景一：多人会议，类似腾讯会议，包含屏幕分享
    ├── TRTCVoiceRoomDemo // 场景二：语音聊天室，也叫语聊房，多人音频聊天场景
    ├── TRTCLiveRoomDemo  // 场景三：互动直播，包含连麦、PK、聊天、点赞等特性
    ├── TRTCAudioCallDemo // 场景四：音频通话，展示双人音频通话，有离线通知能力(需要自行配置推送证书)
    ├── TRTCVideoCallDemo // 场景五：视频通话，展示双人视频通话，有离线通知能力
    ├── UGCKit            // UGC 组件，包含视频录制，编辑，合成，发布上传等基础功能
    ├── UGCVideoEditDemo  // 视频编辑 Demo
    ├── UGCVideoJoinDemo  // 视频合成 Demo
    ├── UGCVideoRecordDemo// 视频录制 Demo
    └── UGCVideoUploadDemo// 视频发布上传 Demo
```

## SDK 分类和下载

腾讯云 专业版(Professional) SDK 基于 LiteAVSDK 统一框架设计和实现，该框架包含直播、点播、短视频、RTC、AI美颜在内的多项功能：

- 如果您需要使用多个功能而不希望打包多个 SDK，可以下载专业版：[TXLiteAVSDK_Professional.zip](https://cloud.tencent.com/document/product/647/32689#Professional)
- 如果您已经通过腾讯云商务购买了 AI 美颜 License，可以下载企业版：[TXLiteAVSDK_Enterprise.zip](https://cloud.tencent.com/document/product/647/32689#Enterprise)

## 相关文档链接

- [SDK 的版本更新历史](https://github.com/tencentyun/LiteAVProfessional_iOS/releases)
- [实时音视频（TRTC） API文档](http://doc.qcloudtrtc.com/md_introduction_trtc_iOS_mac_%E6%A6%82%E8%A7%88.html)
- [播放器（Player） API文档](https://github.com/tencentyun/SuperPlayer_iOS/wiki)
- [移动直播（MLVB） API文档](https://cloud.tencent.com/document/product/454/34753)
- [短视频（UGSV） API文档](http://doc.qcloudtrtc.com/group__TXUGCRecord__ios.html)
- [Demo体验](https://cloud.tencent.com/document/product/454/6555#.E7.B2.BE.E7.AE.80.E7.89.88-demo)

