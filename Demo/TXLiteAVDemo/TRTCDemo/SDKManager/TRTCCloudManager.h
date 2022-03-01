//
//  TRTCCloudManager.h
//  TXLiteAVDemo
//
//  Created by bluedang on 2021/5/17.
//  Copyright © 2021 Tencent. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "TRTCAudioConfig.h"
#import "TRTCCloud.h"
#import "TRTCRemoteUserManager.h"
#import "TRTCStreamConfig.h"
#import "TRTCVideoConfig.h"
#import "TRTCVideoView.h"

NS_ASSUME_NONNULL_BEGIN

@class TRTCCloudManager;

@interface TRTCSubRoomDelegate : NSObject <TRTCCloudDelegate>
//用来从TRTCSubCloud实例中获取回调并转发
@property(nonatomic) NSString *              subRoomId;
@property(weak, nonatomic) TRTCCloudManager *weakManager;
- (instancetype)initWithRoomId:(NSString *)roomId manager:(TRTCCloudManager *)manager;
- (void)onEnterRoom:(NSInteger)result;
- (void)onExitRoom:(NSInteger)reason;
- (void)onUserAudioAvailable:(NSString *)userId available:(BOOL)available;
- (void)onUserVideoAvailable:(NSString *)userId available:(BOOL)available;
- (void)onRemoteUserEnterRoom:(NSString *)userId;
- (void)onRemoteUserLeaveRoom:(NSString *)userId reason:(NSInteger)reason;
- (void)onRemoteVideoStatusUpdated:(NSString *)userId
                        streamType:(TRTCVideoStreamType)streamType
                      streamStatus:(TRTCAVStatusType)status
                            reason:(TRTCAVStatusChangeReason)reason
                         extrainfo:(nullable NSDictionary *)info;
@end

typedef NS_ENUM(NSInteger, TRTCVideoInputType) { TRTCVideoCamera, TRTCVideoFile, TRTCVideoCaptureScreen, TRTCVideoCaptureDevice };

typedef NS_ENUM(NSInteger, TRTCAudioInputType) { TRTCAudioMic, TRTCAudioCustom, TRTCAudioNone };

typedef NS_ENUM(NSInteger, TRTCRoomIdType) { TRTCIntRoomId, TRTCStringRoomId };

@protocol TRTCCloudManagerDelegate <NSObject>

@optional
- (void)roomSettingsManager:(TRTCCloudManager *)manager enableVODAttachToTRTC:(BOOL)isEnabled;
- (void)roomSettingsManager:(TRTCCloudManager *)manager enableVOD:(BOOL)isEnabled;
- (void)onUserVideoAvailable:(NSString *)userId available:(bool)available;
- (void)onVolumeEvaluationEnabled:(BOOL)enabled;
- (void)onScreenCaptureIsStarted:(BOOL)enabled;
- (void)onEnterRoom:(NSInteger)result;
- (void)onExitRoom:(NSInteger)reason;
- (void)onRecvSEIMsg:(NSString *)userId message:(NSData *)message;
- (void)onRecvCustomCmdMsgUserId:(NSString *)userId cmdID:(NSInteger)cmdID seq:(UInt32)seq message:(NSData *)message;
- (void)onConnectOtherRoom:(NSString *)userId errCode:(TXLiteAVError)errCode errMsg:(NSString *)errMsg;
- (void)onWarning:(TXLiteAVWarning)warningCode warningMsg:(NSString *)warningMsg extInfo:(NSDictionary *)extInfo;
- (void)onError:(TXLiteAVError)errCode errMsg:(NSString *)errMsg extInfo:(NSDictionary *)extInfo;
- (void)onMuteLocalAudio:(BOOL)isMute;
//子房间相关消息
- (void)onEnterSubRoom:(NSString *)roomId result:(NSInteger)result;
- (void)onExitSubRoom:(NSString *)roomId reason:(NSInteger)reason;
- (void)onSubRoomUserAudioAvailable:(NSString *)roomId userId:(NSString *)userId available:(BOOL)available;
- (void)onSubRoomUserVideoAvailable:(NSString *)roomId userId:(NSString *)userId available:(BOOL)available;
- (void)onSubRoomRemoteUserEnterRoom:(NSString *)roomId userId:(NSString *)userId;
- (void)onSubRoomRemoteUserLeaveRoom:(NSString *)roomId userId:(NSString *)userId reason:(NSInteger)reason;
//自定义音频消息
- (void)onRemoteUserAudioFrameMsg:(NSString *)userId message:(NSData *)message;
//网络音频消息
- (void)onRecvAudioMsg:(NSString *)userId msg:(NSString *)msg;
// 网络相关
- (void)onNetworkQuality:(TRTCQualityInfo *)localQuality remoteQuality:(NSArray<TRTCQualityInfo *> *)remoteQuality;
//录制相关
- (void)onLocalRecordComplete:(NSInteger)errCode storagePath:(NSString *)storagePath;
@end

@class TCBeautyPanel;
@class AudioEffectSettingView;

@interface TRTCCloudManager : NSObject

@property(strong, nonatomic,readonly) TRTCCloud *       trtcCloud;
@property(weak, nonatomic) UIView *                     localPreView;
@property(strong, nonatomic) NSMutableDictionary *      viewDic;
@property(weak, nonatomic) id<TRTCCloudManagerDelegate> delegate;
@property(strong, nonatomic) TRTCRemoteUserManager *    remoteUserManager;
@property(nonatomic) TRTCAppScene                       scene;
@property(strong, nonatomic) TRTCParams *               params;
@property(nonatomic) NSString *                         currentPublishingRoomId;
@property(nonatomic) BOOL                               enableVOD;
@property(nonatomic) BOOL                               enableAttachVodToTRTC;
// 本地录制相关
@property(nonatomic) TRTCRecordType   localRecordType;
@property(nonatomic) BOOL             enableLocalRecord;
@property(atomic, nullable) NSString *bindToAudioFrameMsg;

#pragma mark - enter config
@property(assign, nonatomic) TRTCRoleType       role;
@property(assign, nonatomic) TRTCVideoInputType videoInputType;
@property(assign, nonatomic) TRTCVideoInputType subVideoInputType;

@property(assign, nonatomic) TRTCAudioInputType audioInputType;
@property(assign, nonatomic) TXSystemVolumeType volumeType;
@property(assign, nonatomic) TXAudioRoute       audioRoute;
@property(assign, nonatomic) TRTCAudioQuality   audioQuality;
@property(assign, nonatomic) TRTCRoomIdType     roomIdType;
@property(strong, nonatomic) NSString *         roomId;
@property(strong, nonatomic) NSString *         userId;
#pragma mark - Meida File
@property(nonatomic, retain) AVAsset *customSourceAsset;

#pragma mark - Cam & Mic
- (void)switchCam:(BOOL)isFrontCam;
@property(assign, nonatomic) BOOL isFrontCam;
@property(assign, nonatomic) BOOL camEnable;
@property(assign, nonatomic) BOOL micEnable;

#pragma mark - Log
@property(assign, nonatomic) BOOL logEnable;
#pragma mark - configs
@property(strong, nonatomic) TRTCVideoConfig *           videoConfig;
@property(strong, nonatomic) TRTCAudioConfig *           audioConfig;
@property(strong, nonatomic, readonly) TRTCStreamConfig *streamConfig;

#pragma mark - video config
@property(assign, nonatomic) TRTCVideoResolution     resolution;
@property(assign, nonatomic) TRTCVideoResolutionMode resolutionMode;
@property(assign, nonatomic) TRTCVideoFillMode       videoFillMode;
@property(assign, nonatomic) TRTCVideoQosPreference  qosPreference;
@property(assign, nonatomic) TRTCVideoRotation       localVideoRotation;
@property(assign, nonatomic) TRTCVideoRotation       encodeVideoRotation;
@property(assign, nonatomic) TRTCVideoMirrorType     localMirror;
@property(assign, nonatomic) BOOL                    encodeMirrorEnable;
@property(assign, nonatomic) BOOL                    gSensorEnabled;
@property(assign, nonatomic) BOOL                    flashLightEnabled;
@property(assign, nonatomic) BOOL                    isVideoPause;
@property(assign, nonatomic) int                     videoFps;
@property(assign, nonatomic) int                     videoBitrate;
#pragma mark - audio config
@property(assign, nonatomic) BOOL      agcEnabled;
@property(assign, nonatomic) BOOL      aecEnabled;
@property(assign, nonatomic) BOOL      ansEnabled;
@property(assign, nonatomic) NSInteger captureVolume;
@property(assign, nonatomic) NSInteger playoutVolume;
@property(assign, nonatomic) BOOL      volumeEvaluationEnabled;
#pragma mark - pk room
@property(assign, nonatomic) BOOL      isCrossingRoom;
@property(strong, nonatomic) NSString *crossUserId;
@property(strong, nonatomic) NSString *crossRoomId;
#pragma mark - chorus
@property(nonatomic) BOOL enableChorus; // 是否开启合唱模式
@property(nonatomic,copy) NSString *chrousUri; // 合唱推拉流地址

//subRoom
@property(strong, atomic, readonly) NSMutableDictionary<NSString *, TRTCCloud *> *          subClouds;
@property(strong, atomic, readonly) NSMutableDictionary<NSString *, TRTCSubRoomDelegate *> *subDelegates;

- (instancetype)initWithParams:(TRTCParams *)params
                       scene:(TRTCAppScene)scene NS_DESIGNATED_INITIALIZER;

- (instancetype)init NS_UNAVAILABLE;

#pragma mark - beauty % effect
- (void)configBeautyPanel:(TCBeautyPanel *)beautyPanel;
- (void)configAudioEffectPanel:(AudioEffectSettingView *)audioPanel;

#pragma mark - Screen Capture
- (void)startScreenCapture;
- (void)stopScreenCapture;

#pragma mark - SpeedTest

- (void)startSpeedTest:(NSString *)userId completion:(void (^)(TRTCSpeedTestResult *result, NSInteger completedCount, NSInteger totalCount))completion;
- (void)stopSpeedTest;

#pragma mark - Live
- (void)startLiveWithRoomId:(NSString *)roomId userId:(NSString *)userId;
- (void)stopLive;
- (void)addMainVideoView:(TRTCVideoView *)view userId:(NSString *)userId;
- (void)removeMainView:(NSString *)userId;
- (NSString *)getCdnUrlOfUser:(NSString *)userId;
- (void)updateStreamMix;
- (void)closeStreamMix;
- (void)enterLiveRoom:(NSString *)roomId userId:(NSString *)userId;
- (void)switchRole:(TRTCRoleType)role;
- (void)setWaterMark:(nullable UIImage *)image inRect:(CGRect)rect;
- (void)setVideoCodecType:(NSInteger)codecType;

/// 暂停屏幕采集
/// @param isPaused 暂时采集
- (void)pauseScreenCapture:(BOOL)isPaused;

/// 设置垫片推流
/// @param isEnabled 开启垫片推流
- (void)enableVideoMuteImage:(BOOL)isEnabled;

/// 设置是否开启清晰度增强
/// @param enable 是否开启
- (void)enableSharpnessEnhancement:(BOOL)enable;

- (void)enableTimestampWaterMark:(BOOL)isEnable;

- (void)snapshotLocalVideoWithUserId:(NSString *)userId type:(TRTCVideoStreamType)type completionBlock:(void (^)(TXImage *image))completionBlock;

- (void)setRemoteSubStreamRenderParams:(TRTCRenderParams *)params userId:(NSString *)userId;

- (void)enableHEVCEncode:(BOOL)enableHEVC;

- (void)addCustomerCrypt;

- (void)startCrossRoom:(NSString *)roomId userId:(NSString *)userId;

- (void)stopCrossRomm;

#pragma mark - SEI message

- (void)sendSEIMessage:(NSString *)message;

/// 发送自定义消息
/// @param message 消息内容，最大支持1kb
/// @result 发送是否成功
- (BOOL)sendCustomMessage:(NSString *)message;

- (BOOL)bindMsgToAudioFrame:(NSString *)message;

- (BOOL)sendMsgToAudioPacket:(NSString *)message;

#pragma mark - remote config

- (void)setRemoteVideoMute:(BOOL)enable userId:(NSString *)userId;
- (void)setRemoteAudioMute:(BOOL)enable userId:(NSString *)userId;
- (void)setRemoteVolume:(int)volume userId:(NSString *)userId;
- (void)setRemoteRenderParams:(TRTCRenderParams *)params userId:(NSString *)userId;

#pragma mark - Video Functions

/// 设置推送纯黑视频帧
/// @param enable 开启或关闭
/// @param size 黑帧size，默认CGSizeZero
- (void)enableBlackStream:(BOOL)enable size:(CGSize)size;

/// 设置视频推送
/// @param isMuted 推送关闭
- (void)setVideoMuted:(BOOL)isMuted;

/// 设置主路、辅路视频采集
/// @param isEnabled 开启视频采集
- (void)setVideoEnabled:(BOOL)isEnabled;

/// 设置采集分辨率
/// @param resolutionIndex 采集分辨率index
- (void)setCaptureResolution:(NSInteger)resolutionIndex;

/// 设置辅路分辨率
/// @param resolution 分辨率
- (void)setSubStreamResolution:(TRTCVideoResolution)resolution;

/// 设置辅路码率
/// @param bitrate 码率
- (void)setSubStreamVideoBitrate:(int)bitrate;

/// 设置帧率
/// @param fps 帧率
- (void)setSubStreamVideoFps:(int)fps;

/// 设置是否在某个子房间内推送音频流
/// @param roomId 子房间 ID
/// @param push 是否推流
- (void)pushAudioStreamInSubRoom:(NSString *)roomId push:(BOOL)isPush;

/// 设置是否在某个子房间内推送视频流
/// @param roomId 子房间 ID
/// @param isPush 是否推流
- (void)pushVideoStreamInSubRoom:(NSString *)roomId push:(BOOL)isPush;

/// 切换子房间身份
/// @param role 用户在房间的身份：主播或观众
/// @param roomId 房间号
- (void)switchSubRoomRole:(TRTCRoleType)role roomId:(NSString *)roomId;

/// 设置音频推送
/// @param isMuted YES：静音；NO：取消静音
- (void)setAudioMuted:(BOOL)isMuted;

/// 设置本地镜像
/// @param type 本地镜像模式
- (void)setLocalMirrorType:(TRTCVideoMirrorType)type;

/// 设置第三方美颜回调format
/// @param format 回调视频帧 format
- (void)setCustomProcessFormat:(TRTCVideoPixelFormat)format;

/// 调整画面亮度，用于测试 texture 回调
/// @param brightness 画面亮度，取值范围 -1.0 ~ 1.0
- (void)setCustomBrightness:(CGFloat)brightness;

#pragma mark - Audio Functions

/// 设置音频采集
/// @param isEnabled 开启音频采集
- (void)setAudioEnabled:(BOOL)isEnabled;

/// 开启耳返
/// @param earMonitoringEnabled 是否开启耳返
- (void)setEarMonitoringEnabled:(BOOL)earMonitoringEnabled;

/// 设置耳返音量
/// @param volume 耳返音量
- (void)setEarMonitoringVolume:(NSInteger)volume;
/// 设置音调
/// @param volume 音调
- (void)setUpdatevoicePitchVolume:(double)volume;

#pragma mark - Stream

- (void)setMixMode:(TRTCTranscodingConfigMode)mixMode;
/// 设置混流背景图
/// @param imageId 背景图ID

- (void)setMixBackgroundImage:(NSString *_Nullable)imageId;

/// 设置混流自定义流ID
/// @param streamId 混流流ID
- (void)setMixStreamId:(NSString *_Nullable)streamId;

/// 设置流控方案
/// @param mode 流控方案
- (void)setQosControlMode:(TRTCQosControlMode)mode;

/// 设置双路编码
/// @param isEnabled 开启双路编码
- (void)setSmallVideoEnabled:(BOOL)isEnabled;

/// 设置是否默认观看低清
/// @param prefersLowQuality 默认观看低清
- (void)setPrefersLowQuality:(BOOL)prefersLowQuality;

/// 切换闪光灯
- (void)switchTorch;

/// 设置自动对焦
/// @param isEnabled 开启自动对焦
- (void)setAutoFocusEnabled:(BOOL)isEnabled;

#pragma mark - Room
/// 切换到房间
- (void)switchRoom:(TRTCSwitchRoomConfig *)switchRoomConfig;

#pragma mark - Media Record
/// 开启本地媒体录制
- (void)startLocalRecording;

/// 停止本地媒体录制
- (void)stopLocalRecording;

/// 并发选路配置
- (void)setRemoteAudioParallelParams:(UInt32)maxCount;
- (BOOL)setRemoteAudioParallelParams:(BOOL)isAdd userId:(NSString *)userId;

/// 加入子房间
- (void)enterSubRoom:(TRTCParams *)params;

/// 离开子房间
- (void)exitSubRoom:(NSString *)roomId;

- (void)resetTRTCClouldDelegate;
@end

NS_ASSUME_NONNULL_END
