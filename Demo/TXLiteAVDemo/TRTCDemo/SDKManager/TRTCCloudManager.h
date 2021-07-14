//
//  TRTCCloudManager.h
//  TXLiteAVDemo
//
//  Created by bluedang on 2021/5/17.
//  Copyright © 2021 Tencent. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TRTCCloud.h"

#import "TRTCVideoView.h"
#import "TRTCVideoConfig.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, TRTCVideoInputType) {
    TRTCVideoCamera,
    TRTCVideoFile,
    TRTCVideoCaptureDevice,
    TRTCVideoNone
};

typedef NS_ENUM(NSInteger, TRTCAudioInputType) {
    TRTCAudioMic,
    TRTCAudioCustom,
    TRTCAudioNone
};

typedef NS_ENUM(NSInteger, TRTCRoomIdType) {
    TRTCIntRoomId,
    TRTCStringRoomId
};

@protocol TRTCCloudManagerDelegate <NSObject>

@optional
- (void)onUserVideoAvailable:(NSString*)userId available:(bool)available;
- (void)onVolumeEvaluationEnabled:(BOOL)enabled;
- (void)onScreenCaptureIsStarted:(BOOL)enabled;
- (void)onEnterRoom:(NSInteger)result;
- (void)onExitRoom:(NSInteger)reason;
- (void)onRecvSEIMsg:(NSString *)userId message:(NSData *)message;
- (void)onConnectOtherRoom:(NSString *)userId errCode:(TXLiteAVError)errCode errMsg:(NSString *)errMsg;
- (void)onWarning:(TXLiteAVWarning)warningCode warningMsg:(NSString *)warningMsg extInfo:(NSDictionary *)extInfo;
- (void)onError:(TXLiteAVError)errCode errMsg:(NSString *)errMsg extInfo:(NSDictionary *)extInfo;
@end

@class TCBeautyPanel;
@class AudioEffectSettingView;

@interface TRTCCloudManager : NSObject

@property (weak, nonatomic) UIView *localPreView;
@property (strong, nonatomic) NSMutableDictionary *viewDic;
@property (weak, nonatomic) id<TRTCCloudManagerDelegate> delegate;


#pragma mark - enter config
@property (assign, nonatomic) TRTCRoleType role;
@property (assign, nonatomic) TRTCVideoInputType videoInputType;
@property (assign, nonatomic) TRTCAudioInputType audioInputType;
@property (assign, nonatomic) TXSystemVolumeType volumeType;
@property (assign, nonatomic) TXAudioRoute audioRoute;
@property (assign, nonatomic) TRTCAudioQuality audioQuality;
@property (assign, nonatomic) TRTCRoomIdType roomIdType;

@property (strong, nonatomic) NSString *roomId;
@property (strong, nonatomic) NSString *userId;

#pragma mark - Meida File
@property (nonatomic, retain) AVAsset* customSourceAsset;

#pragma mark - Screen Capture
- (void)startScreenCapture;
- (void)stopScreenCapture;

#pragma mark - SpeedTest

- (void)startSpeedTest:(NSString*)userId completion:(void(^)(TRTCSpeedTestResult* result, NSInteger completedCount, NSInteger totalCount))completion;
- (void)stopSpeedTest;

#pragma mark - Live
- (void)startLiveWithRoomId:(NSString*)roomId userId:(NSString*)userId;
- (void)stopLive;
- (void)addMainVideoView:(TRTCVideoView*)view userId:(NSString*)userId;
- (void)removeMainView:(NSString*)userId;
- (NSString *)getCdnUrlOfUser:(NSString *)userId;
- (void)updateStreamMix;
- (void)closeStreamMix;

- (void)enterLiveRoom:(NSString*)roomId userId:(NSString*)userId;
- (void)switchRole:(TRTCRoleType)role;

#pragma mark - Cam & Mic
- (void)switchCam;
@property (assign, nonatomic) BOOL isFrontCam;
@property (assign, nonatomic) BOOL camEnable;
@property (assign, nonatomic) BOOL micEnable;

#pragma mark - Log
@property (assign, nonatomic) BOOL logEnable;

#pragma mark - beauty % effect
- (void)configBeautyPanel:(TCBeautyPanel*)beautyPanel;
- (void)configAudioEffectPanel:(AudioEffectSettingView*)audioPanel;

#pragma mark - configs
@property (strong, nonatomic) TRTCVideoConfig *videoConfig;
//@property (strong, nonatomic) TRTCAudioConfig *audioConfig;

#pragma mark - video config
@property (assign, nonatomic) TRTCVideoResolution resolution;
@property (assign, nonatomic) TRTCVideoResolutionMode resolutionMode;
@property (assign, nonatomic) TRTCVideoFillMode videoFillMode;
@property (assign, nonatomic) TRTCVideoQosPreference qosPreference;
@property (assign, nonatomic) TRTCVideoRotation localVideoRotation;
@property (assign, nonatomic) TRTCVideoRotation encodeVideoRotation;
@property (assign, nonatomic) TRTCVideoMirrorType localMirror;
@property (assign, nonatomic) BOOL encodeMirrorEnable;
@property (assign, nonatomic) BOOL gSensorEnabled;
@property (assign, nonatomic) BOOL flashLightEnabled;
@property (assign, nonatomic) BOOL isVideoPause;
@property (assign, nonatomic) int videoFps;
@property (assign, nonatomic) int videoBitrate;

- (void)setWaterMark:(nullable UIImage*)image inRect:(CGRect)rect;
/// 设置垫片推流
/// @param isEnabled 开启垫片推流
- (void)enableVideoMuteImage:(BOOL)isEnabled;
/// 设置是否开启清晰度增强
/// @param enable 是否开启
- (void)enableSharpnessEnhancement:(BOOL)enable;

- (void)enableTimestampWaterMark:(BOOL)isEnable;

- (void)snapshotLocalVideoWithUserId:(NSString*)userId type:(TRTCVideoStreamType)type completionBlock:(void (^)(TXImage *image))completionBlock;

- (void)setRemoteSubStreamRenderParams:(TRTCRenderParams*)params userId:(NSString*)userId;

#pragma mark - audio config
@property (assign, nonatomic) BOOL agcEnabled;
@property (assign, nonatomic) BOOL aecEnabled;
@property (assign, nonatomic) BOOL ansEnabled;
@property (assign, nonatomic) BOOL earMonitoringEnabled;
@property (assign, nonatomic) NSInteger captureVolume;
@property (assign, nonatomic) NSInteger playoutVolume;
@property (assign, nonatomic) BOOL volumeEvaluationEnabled;

#pragma mark - pk room
@property (assign, nonatomic) BOOL isCrossingRoom;
@property (strong, nonatomic) NSString *crossUserId;
- (void)startCrossRoom:(NSString*)roomId userId:(NSString*)userId;
- (void)stopCrossRomm;

#pragma mark - SEI message

- (void)sendSEIMessage:(NSString*)message;

#pragma mark - remote config
- (void)setRemoteVideoMute:(BOOL)enable userId:(NSString*)userId;
- (void)setRemoteAudioMute:(BOOL)enable userId:(NSString*)userId;
- (void)setRemoteVolume:(int)volume userId:(NSString*)userId;
- (void)setRemoteRenderParams:(TRTCRenderParams*)params userId:(NSString*)userId;

@end

NS_ASSUME_NONNULL_END
