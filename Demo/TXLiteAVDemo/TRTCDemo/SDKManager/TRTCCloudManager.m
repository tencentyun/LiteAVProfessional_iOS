//
//  TRTCCloudManager.m
//  TXLiteAVDemo
//
//  Created by bluedang on 2021/5/17.
//  Copyright © 2021 Tencent. All rights reserved.
//

#import "TRTCCloudManager.h"

#import "AudioEffectSettingKit.h"
#import <BeautySettingKit/TCBeautyPanel.h>

#import "AudioQueuePlay.h"
#import "CoreImageFilter.h"
#import "CustomAudioFileReader.h"
#import "CustomFrameRender.h"
#import "GenerateTestUserSig.h"
#import "MediaFileSyncReader.h"
#import "TCUtil.h"
#import "TRTCCustomerCrypt.h"
#import "TRTCCustomerAudioPacketDelegate.h"
#import "TRTCVideoCustomPreprocessor.h"
#import "TestRenderVideoFrame.h"
#import "TestSendCustomVideoData.h"
#import "WaterMarkProcessor.h"

#define PLACE_HOLDER_LOCAL_MAIN @"$PLACE_HOLDER_LOCAL_MAIN$"
#define PLACE_HOLDER_LOCAL_SUB  @"$PLACE_HOLDER_LOCAL_SUB$"
#define PLACE_HOLDER_REMOTE     @"$PLACE_HOLDER_REMOTE$"

#if DEBUG
#define APPGROUP @"group.com.tencent.liteav.RPLiveStreamShare"
#else
#define APPGROUP @"group.com.tencent.liteav.RPLiveStreamRelease"  // App Store Group
#endif

@implementation TRTCSubRoomDelegate
- (instancetype)initWithRoomId:(NSString *)roomId manager:(TRTCCloudManager *)manager {
    if (self = [super init]) {
        _subRoomId   = roomId;
        _weakManager = manager;
    }
    return self;
}

//从TRTCSubClouds接收到回调后，转发给TRTCCloudManager的监听者（目前是TRTCMainViewController）
- (void)onEnterRoom:(NSInteger)result {
    if ([_weakManager.delegate respondsToSelector:@selector(onEnterSubRoom:result:)]) {
        [_weakManager.delegate onEnterSubRoom:_subRoomId result:result];
    }
}

- (void)onExitRoom:(NSInteger)reason {
    if ([_weakManager.delegate respondsToSelector:@selector(onExitSubRoom:reason:)]) {
        [_weakManager.delegate onExitSubRoom:_subRoomId reason:reason];
    }
}

- (void)onUserAudioAvailable:(NSString *)userId available:(BOOL)available {
    if ([_weakManager.delegate respondsToSelector:@selector(onSubRoomUserAudioAvailable:userId:available:)]) {
        [_weakManager.delegate onSubRoomUserAudioAvailable:_subRoomId userId:userId available:available];
    }
}

- (void)onRemoteUserEnterRoom:(NSString *)userId {
    if ([_weakManager.delegate respondsToSelector:@selector(onSubRoomRemoteUserEnterRoom:userId:)]) {
        [_weakManager.delegate onSubRoomRemoteUserEnterRoom:_subRoomId userId:userId];
    }
}

- (void)onRemoteUserLeaveRoom:(NSString *)userId reason:(NSInteger)reason {
    if ([_weakManager.delegate respondsToSelector:@selector(onSubRoomRemoteUserLeaveRoom:userId:reason:)]) {
        [_weakManager.delegate onSubRoomRemoteUserLeaveRoom:_subRoomId userId:userId reason:reason];
    }
}

- (void)onRemoteVideoStatusUpdated:(NSString *)userId
                        streamType:(TRTCVideoStreamType)streamType
                      streamStatus:(TRTCAVStatusType)status
                            reason:(TRTCAVStatusChangeReason)reason
                         extrainfo:(nullable NSDictionary *)info {
}

- (void)onNetworkQuality:(TRTCQualityInfo *)localQuality remoteQuality:(NSArray<TRTCQualityInfo *> *)remoteQuality {
    if ([_weakManager.delegate respondsToSelector:@selector(onNetworkQuality:remoteQuality:)]) {
        [_weakManager.delegate onNetworkQuality:localQuality remoteQuality:remoteQuality];
    }
}
//子房间主流
- (void)onUserVideoAvailable:(NSString *)userId available:(BOOL)available {
    if ([_weakManager.delegate respondsToSelector:@selector(onSubRoomUserVideoAvailable:userId:available:)]) {
        [_weakManager.delegate onSubRoomUserVideoAvailable:_subRoomId userId:userId available:available];
    }
}

//子房间子流
- (void)onUserSubStreamAvailable:(NSString *)userId available:(BOOL)available {
    NSString  *subUserId = [[NSString alloc] initWithFormat:@"%@-sub-SRoom", userId];
    TRTCCloud *subCloud = _weakManager.subClouds[_subRoomId];
    if (available) {
        TRTCVideoView *videoView = _weakManager.viewDic[subUserId];
        if (!videoView) {
            videoView = [[TRTCVideoView alloc] init];
            [videoView setUserId:userId];
            [videoView.audioVolumeIndicator setHidden:YES];
            _weakManager.viewDic[subUserId]  = videoView;
        }
        videoView.userConfig.isSubStream = true;
        [subCloud startRemoteView:userId streamType:TRTCVideoStreamTypeSub view:videoView];
        [subCloud setRemoteRenderParams:userId streamType:TRTCVideoStreamTypeSub params:videoView.userConfig.renderParams];
    } else {
        [_weakManager.viewDic[subUserId] removeFromSuperview];
        [_weakManager.viewDic removeObjectForKey:subUserId];
        [subCloud stopRemoteView:userId streamType:TRTCVideoStreamTypeSub];
    }
    if ([_weakManager.delegate respondsToSelector:@selector(onUserVideoAvailable:available:)]) {
        [_weakManager.delegate onUserVideoAvailable:subUserId available:available];
    }
}

@end

#define PLACE_HOLDER_LOCAL_MAIN @"$PLACE_HOLDER_LOCAL_MAIN$"
#define PLACE_HOLDER_LOCAL_SUB  @"$PLACE_HOLDER_LOCAL_SUB$"
#define PLACE_HOLDER_REMOTE     @"$PLACE_HOLDER_REMOTE$"

@interface TRTCCloudManager () <TRTCCloudDelegate,
                                MediaFileSyncReaderDelegate,
                                CustomAudioFileReaderDelegate,
                                TRTCVideoRenderDelegate,
                                TRTCAudioFrameDelegate,
                                TRTCVideoFrameDelegate,
                                RecvAudioMsgDelegate
                                >
@property(strong, nonatomic) TRTCCloud *                  trtcCloud;
@property(strong, nonatomic) MediaFileSyncReader *        mediaReader;
@property(strong, nonatomic) WaterMarkProcessor *         waterMarkProcessor;
@property(assign, nonatomic) BOOL                         timestampWaterMarkEnable;
@property(strong, nonatomic) TRTCVideoCustomPreprocessor *customPreprocessor;
@property(strong, nonatomic) TXDeviceManager *            deviceManager;
@property(strong, nonatomic) TXAudioEffectManager *       audioEffectManager;

@property(strong, nonatomic) CoreImageFilter *yuvPreprocessor;
@property(strong, atomic) NSMutableDictionary *streamVideoEncConfig;


// 视频文件播放
@property(strong, nonatomic) TestSendCustomVideoData *videoCaptureTester;
@property(strong, nonatomic) TestSendCustomVideoData *subVideoCaptureTester;
@property(strong, nonatomic) TestRenderVideoFrame *   renderTester;

//子房间
@property(strong, atomic) NSMutableDictionary<NSString *, TRTCCloud *> *          subClouds;
@property(strong, atomic) NSMutableDictionary<NSString *, TRTCSubRoomDelegate *> *subDelegates;

// 音频选路
@property(assign, nonatomic) UInt32 audioParallelMaxCount;
@property(strong, atomic) NSMutableArray<NSString *> *audioParallelIncludeUsers;
@end

@implementation TRTCCloudManager

- (WaterMarkProcessor *)waterMarkProcessor {
    if (!_waterMarkProcessor) {
        _waterMarkProcessor = [[WaterMarkProcessor alloc] init];
    }
    return _waterMarkProcessor;
}

- (instancetype)initWithParams:(TRTCParams *)params
                       scene:(TRTCAppScene)scene {
    self = [super init];
    if (self) {
        _trtcCloud          = [TRTCCloud sharedInstance];
        _params             = params;
        _scene              = scene;
        _role               = TRTCRoleAnchor;
        _videoInputType     = TRTCVideoCamera;
        _audioInputType     = TRTCAudioMic;
        _audioRoute         = TXAudioRouteSpeakerphone;
        _roomIdType         = TRTCIntRoomId;
        _viewDic            = [[NSMutableDictionary alloc] init];
        _isFrontCam         = YES;
        _videoConfig        = [[TRTCVideoConfig alloc] initWithScene:scene];
        _audioConfig        = [[TRTCAudioConfig alloc] init];
        _streamConfig       = [[TRTCStreamConfig alloc] init];
        _subClouds          = [[NSMutableDictionary alloc] init];
        _subDelegates       = [[NSMutableDictionary alloc] init];
        _yuvPreprocessor    = [[CoreImageFilter alloc] init];
        _deviceManager      = [_trtcCloud getDeviceManager];
        _audioEffectManager = [_trtcCloud getAudioEffectManager];
        _audioParallelMaxCount = 6;
        _audioParallelIncludeUsers = [[NSMutableArray alloc] init];
        [TRTCCustomerAudioPacketDeleagate sharedInstance].delegate = self;
        _customPreprocessor = [[TRTCVideoCustomPreprocessor alloc] init];
        [_trtcCloud setDelegate:self];
        [_trtcCloud setAudioFrameDelegate:self];
        [_trtcCloud setLocalVideoProcessDelegete:self pixelFormat:TRTCVideoPixelFormat_Unknown bufferType:TRTCVideoBufferType_PixelBuffer];
        _streamConfig.mixMode = TRTCTranscodingConfigMode_Manual;

    }
    return self;
}


- (void)dealloc {
    _trtcCloud = nil;
    [TRTCCloud destroySharedIntance];
}

- (void)startSpeedTest:(NSString *)userId completion:(void (^)(TRTCSpeedTestResult *result, NSInteger completedCount, NSInteger totalCount))completion {
    [_trtcCloud startSpeedTest:SDKAPPID
                        userId:userId
                       userSig:[GenerateTestUserSig genTestUserSig:userId]
                    completion:^(TRTCSpeedTestResult *result, NSInteger completedCount, NSInteger totalCount) {
                        completion(result, completedCount, totalCount);
                    }];
}

- (void)stopSpeedTest {
    [_trtcCloud stopSpeedTest];
}

- (void)setupVideoConfig {
    if (!_videoConfig) {
        return;
    }

    [self.trtcCloud setVideoEncoderParam:self.videoConfig.videoEncConfig];
    [self.trtcCloud setVideoEncoderMirror:self.videoConfig.isRemoteMirrorEnabled];
    [self.trtcCloud setVideoMuteImage:self.videoConfig.isVideoMuteImage ? [UIImage imageNamed:@"background"] : nil fps:3];
    [self.trtcCloud setLocalRenderParams:self.videoConfig.localRenderParams];
    [self.trtcCloud setNetworkQosParam:self.videoConfig.qosConfig];
    [self.trtcCloud setPriorRemoteVideoStreamType:self.videoConfig.prefersLowQuality ? TRTCVideoStreamTypeSmall : TRTCVideoStreamTypeBig];
    [self setVideoEnabled:self.videoConfig.isEnabled];
    [self switchCam:_isFrontCam];
        
    if (self.videoConfig.isCustomSubStreamCapture) {
        TRTCVideoEncParam *params = [TRTCVideoEncParam new];
        params.videoResolution    = TRTCVideoResolution_1280_720;
        params.videoBitrate       = 550;
        params.videoFps           = 10;
        [self.trtcCloud setSubStreamEncoderParam:params];
    }

    if (self.videoConfig.isWaterMarkEnabled) {
        UIImage *image = [UIImage imageNamed:@"watermark"];
        [self.trtcCloud setWatermark:image streamType:TRTCVideoStreamTypeBig rect:CGRectMake(0.7, 0.1, 0.2, 0)];
    }

    self.gSensorEnabled           = YES;
    self.timestampWaterMarkEnable = NO;
    [self updateCloudMixtureParams];
}

- (void)setupAudioConfig {
    self.audioConfig.isEarMonitoringEnabled = NO;
    self.volumeEvaluationEnabled            = NO;
    self.captureVolume                      = 100;
    self.playoutVolume                      = 100;
}

- (void)setVideoEnabled:(BOOL)isEnabled {
    [self setVideoEnabled:isEnabled streamType:TRTCVideoStreamTypeBig];
    [self setVideoEnabled:isEnabled streamType:TRTCVideoStreamTypeSub];
}

- (void)setVideoEnabled:(BOOL)isEnabled streamType:(TRTCVideoStreamType)streamType {
    if (streamType == TRTCVideoStreamTypeBig) {
        self.videoConfig.isEnabled = isEnabled;
    }

    if (isEnabled) {
        [self startLocalVideo:streamType];
    } else {
        [self stopLocalVideo:streamType];
    }
}

- (BOOL)isLiveAudience {
    return self.scene == TRTCAppSceneLIVE && self.params.role == TRTCRoleAudience;
}

- (void)startLocalVideo {
    [self setAudioMuted:NO];
    [self startLocalVideo:TRTCVideoStreamTypeBig];

    if (self.videoConfig.subSource != 0) {
        [self startLocalVideo:TRTCVideoStreamTypeSub];
    }
}

- (void)startLocalVideo:(TRTCVideoStreamType)streamType {
    [self setVideoMuted:NO];
    if (!self.videoConfig.isEnabled || self.isLiveAudience) {
        return;
    }

    if (streamType == TRTCVideoStreamTypeBig) {
        self.videoConfig.isH265Enabled = YES;
        switch (self.videoConfig.source) {
            case TRTCVideoSourceCamera:
                [self setVideoMuted:false];
                [self.trtcCloud startLocalPreview:_isFrontCam view:self.localPreView];
                break;
            case TRTCVideoSourceCustom:
                if (self.videoConfig.videoAsset) {                    // 使用视频文件
                    [self setupVideoCapture];
                    [self.trtcCloud enableCustomVideoCapture:YES];
                    [self.trtcCloud setLocalVideoRenderDelegate:self.renderTester pixelFormat:TRTCVideoPixelFormat_NV12 bufferType:TRTCVideoBufferType_PixelBuffer];
                    [self.renderTester addUser:nil videoView:self.localPreView];
                    [self.videoCaptureTester start];
                }
                break;
            case TRTCVideoSourceAppScreen:
                if (@available(iOS 11.0, *)) {
                    self.videoConfig.videoEncConfig.videoResolution = TRTCVideoResolution_1280_720;
                    self.videoConfig.videoEncConfig.videoFps        = 10;
                    self.videoConfig.videoEncConfig.videoBitrate    = 1600;
                    [self.trtcCloud startScreenCaptureInApp:self.videoConfig.videoEncConfig];
                }
                break;
            case TRTCVideoSourceDeviceScreen:
                if (@available(iOS 11.0, *)) {
                    self.videoConfig.videoEncConfig.videoResolution = TRTCVideoResolution_1280_720;
                    self.videoConfig.videoEncConfig.videoFps        = 10;
                    self.videoConfig.videoEncConfig.videoBitrate    = 1600;
                    [self.trtcCloud startScreenCaptureByReplaykit:self.videoConfig.videoEncConfig appGroup:APPGROUP];
                }
                break;
            case TRTCVideoSourceNone:
                break;
        }
    } else if (streamType == TRTCVideoStreamTypeSub) {
        [self startSubStreamVideo];
    }
}

- (void)setupVideoCapture {
    if (!self.videoCaptureTester) {
        self.videoCaptureTester = [[TestSendCustomVideoData alloc] initWithTRTCCloud:[TRTCCloud sharedInstance] mediaAsset:self.videoConfig.videoAsset];
        [self setVideoFps:self.videoCaptureTester.mediaReader.fps];
    }

    if (!self.subVideoCaptureTester) {
        self.subVideoCaptureTester = [[TestSendCustomVideoData alloc] initWithTRTCCloud:[TRTCCloud sharedInstance] mediaAsset:self.videoConfig.videoAsset];
        [self setSubStreamVideoFps:self.subVideoCaptureTester.mediaReader.fps];
    }
}

- (void)startSubStreamVideo {
    if (self.videoConfig.subSource == TRTCVideoSourceCustom && (self.videoConfig.source == TRTCVideoSourceCamera || self.videoConfig.source == TRTCVideoSourceCustom ||
                                                                self.videoConfig.source == TRTCVideoSourceAppScreen || self.videoConfig.source == TRTCVideoSourceDeviceScreen)) {
        [self setupVideoCapture];

        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 3 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            self.subVideoCaptureTester.streamType = 1;
            [self.trtcCloud enableCustomVideoCapture:TRTCVideoStreamTypeSub enable:YES];
            [self.subVideoCaptureTester start];
        });
    } else if (self.videoConfig.subSource == TRTCVideoSourceAppScreen && (self.videoConfig.source == TRTCVideoSourceCamera || self.videoConfig.source == TRTCVideoSourceCustom)) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 3 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            if (@available(iOS 13.0, *)) {
                [self.trtcCloud startScreenCaptureInApp:TRTCVideoStreamTypeSub encParam:self.videoConfig.subStreamVideoEncConfig];
            }
        });
    } else if (self.videoConfig.subSource == TRTCVideoSourceDeviceScreen && (self.videoConfig.source == TRTCVideoSourceCamera || self.videoConfig.source == TRTCVideoSourceCustom)) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 3 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            if (@available(iOS 11.0, *)) {
                [self.trtcCloud startScreenCaptureByReplaykit:TRTCVideoStreamTypeSub encParam:self.videoConfig.subStreamVideoEncConfig appGroup:APPGROUP];
            }
        });
    }
}

- (void)enterSubRoom:(TRTCParams *)params {
    TRTCCloud *subCloud = [[TRTCCloud sharedInstance] createSubCloud];
    //不论是字符串房间号还是数字房间号，在这里都用字符串做主键；因此同时进入数值与字符串相同的两个房间会出问题
    NSString *stringRoomId = params.roomId ? [@(params.roomId) stringValue] : params.strRoomId;
    [_subClouds setValue:subCloud forKey:stringRoomId];

    TRTCSubRoomDelegate *subDelegate = [[TRTCSubRoomDelegate alloc] initWithRoomId:stringRoomId manager:self];
    [subCloud setDelegate:subDelegate];
    [_subDelegates setValue:subDelegate forKey:stringRoomId];
    //进入子房间
    [subCloud enterRoom:params appScene:_scene];
}

- (void)exitSubRoom:(NSString *)roomId {
    //不论是字符串房间号还是数字房间号，在这里都用字符串做主键；因此同时进入数值与字符串相同的两个房间会出问题
    TRTCCloud *subCloud = [_subClouds objectForKey:roomId];
    [subCloud exitRoom];
    [[TRTCCloud sharedInstance] destroySubCloud:subCloud];
    [_subClouds removeObjectForKey:roomId];
}

- (void)stopLocalVideo {
    [self stopLocalVideo:TRTCVideoStreamTypeBig];
    [self stopLocalVideo:TRTCVideoStreamTypeSub];
}

- (void)stopLocalVideo:(TRTCVideoStreamType)streamType {
    if (streamType == TRTCVideoStreamTypeBig) {
        switch (self.videoConfig.source) {
            case TRTCVideoSourceCamera:
                [self.trtcCloud stopLocalPreview];
                break;
            case TRTCVideoSourceCustom:
                [self.trtcCloud enableCustomVideoCapture:NO];
                if (self.videoCaptureTester) {
                    [self.videoCaptureTester stop];
                    self.videoCaptureTester = nil;
                }
                [self.mediaReader stop];
                break;
            case TRTCVideoSourceAppScreen:
            case TRTCVideoSourceDeviceScreen:
                if (@available(iOS 11.0, *)) {
                    [self.trtcCloud stopScreenCapture];
                }
                break;
        }
    } else if (streamType == TRTCVideoStreamTypeSub) {
        switch (self.videoConfig.subSource) {
            case TRTCVideoSourceCamera:
                break;
            case TRTCVideoSourceCustom:
                [self.trtcCloud enableCustomVideoCapture:TRTCVideoStreamTypeSub enable:NO];
                if (self.subVideoCaptureTester) {
                    [self.subVideoCaptureTester stop];
                    self.subVideoCaptureTester = nil;
                }
                break;
            case TRTCVideoSourceAppScreen:
            case TRTCVideoSourceDeviceScreen:
                if (@available(iOS 11.0, *)) {
                    [self.trtcCloud stopScreenCapture];
                }
                break;
        }
    }
}

- (void)enableHEVCEncode:(BOOL)enableHEVC {
    NSDictionary *json       = @{@"api" : @"enableHevcEncode", @"params" : @{@"enable" : @(enableHEVC)}};
    NSString *    jsonString = [self jsonStringFrom:json];
    [_trtcCloud callExperimentalAPI:jsonString];
}

- (void)addCustomerCrypt {
    [_trtcCloud callExperimentalAPI:[self jsonStringFrom:@{
                    @"api" : @"setEncodedDataProcessingListener",
                    @"params" : @{@"listener" : @((uint64_t)[[TRTCCustomerCrypt sharedInstance] getEncodedDataProcessingListener])}
                }]];
}

- (void)enterLiveRoom:(NSString *)roomId userId:(NSString *)userId {
    _roomId = roomId;
    _userId = userId;

    self.params.sdkAppId    = SDKAPPID;
    self.params.userId      = userId;
    self.params.userSig     = [GenerateTestUserSig genTestUserSig:userId];
    self.params.role        = _role;
    if (_roomIdType == TRTCIntRoomId) {
        self.params.roomId = [roomId intValue];
        self.params.strRoomId = @"";
    } else {
        self.params.strRoomId = roomId;
        self.params.roomId = 0;
    }
    
    [_trtcCloud callExperimentalAPI:[self jsonStringFrom:@{
        @"api" : @"setAudioPacketExtraDataListener",
        @"params" : @{
                @"listener" : @((uint64_t)[[TRTCCustomerAudioPacketDeleagate sharedInstance] getAudioPacketDelegate])
        }
    }]];

    [_trtcCloud enterRoom:self.params appScene:self.scene];
    
    if (_volumeType != -1) {
        [[_trtcCloud getDeviceManager] setSystemVolumeType:_volumeType];
    }
    [[_trtcCloud getDeviceManager] setAudioRoute:_audioRoute];
    _isCrossingRoom = NO;

    [self setupAudioConfig];
    if (!self.enableChorus) {
        [self setupVideoConfig];
        [self startLocalVideo];
    }

    if (self.params.role == TRTCRoleAnchor) {
        self.currentPublishingRoomId = self.params.roomId ? [@(self.params.roomId) stringValue] : self.params.strRoomId;
    }
    [self startLocalAudio];
}

- (void)switchRole:(TRTCRoleType)role {
    if (_role == role) {
        return;
    }
    _role = role;
    self.params.role = role;
    [_trtcCloud switchRole:role];
}

- (void)startLiveWithRoomId:(NSString *)roomId userId:(NSString *)userId {
    [self enterLiveRoom:roomId userId:userId];

    if ((_videoInputType == TRTCVideoFile) && !self.enableChorus) {
        [_trtcCloud setLocalVideoRenderDelegate:self pixelFormat:TRTCVideoPixelFormat_NV12 bufferType:TRTCVideoBufferType_PixelBuffer];
        [_trtcCloud enableCustomVideoCapture:TRTCVideoStreamTypeBig enable:true];
        [_trtcCloud enableCustomAudioCapture:true];
        [_mediaReader start];
        //        [_audioPlayer start];
        return;
    }

    if (_audioInputType == TRTCAudioCustom && _videoInputType != TRTCVideoFile) {
        [_trtcCloud enableCustomAudioCapture:true];
        [CustomAudioFileReader sharedInstance].delegate = self;
        [[CustomAudioFileReader sharedInstance] start:48000 channels:1 framLenInSample:960];
        return;
    }

    if ( _audioInputType != TRTCAudioNone ) {
        [self startLocalAudio];
    } else {
        [_trtcCloud stopLocalAudio];
    }
}

- (void)stopLive {
    [self stopLocalVideo];
    [self stopLocalAudio];
    [_trtcCloud exitRoom];
    for (TRTCCloud *cloud in [self.subClouds allValues]) {
        [cloud exitRoom];
        [[TRTCCloud sharedInstance] destroySubCloud:cloud];
    }
    [_subClouds removeAllObjects];
    [_subDelegates removeAllObjects];
    [_viewDic removeAllObjects];
}

- (void)addMainVideoView:(TRTCVideoView *)view userId:(NSString *)userId {
    [view.audioVolumeIndicator setHidden:!_volumeEvaluationEnabled];
    [self.viewDic setObject:view forKey:userId];
}

- (void)removeMainView:(NSString *)userId {
    [self.viewDic removeObjectForKey:userId];
}

- (void)setLocalPreView:(UIView *)localPreView {
    _localPreView = localPreView;
    if (_videoInputType == TRTCVideoCamera) {
        if (!localPreView) {
            [_trtcCloud stopLocalPreview];
        } else {
            [_trtcCloud startLocalPreview:YES view:_localPreView];
        }
    }
}

- (void)switchCam:(BOOL)isFrontCam {
    _isFrontCam = isFrontCam;
    [[_trtcCloud getDeviceManager] switchCamera:isFrontCam];
}

- (void)setCamEnable:(BOOL)camEnable {
    if (_videoInputType != TRTCVideoCamera) {
        return;
    }

    _camEnable = camEnable;
    if (camEnable) {
        [_trtcCloud startLocalPreview:_isFrontCam view:_localPreView];
        if (self.logEnable) {
            [self setLogEnable:true];
        }
    } else {
        [_trtcCloud stopLocalPreview];
    }
}

- (void)setMicEnable:(BOOL)micEnable {
    if (_audioInputType == TRTCAudioNone) {
        return;
    }

    _micEnable = micEnable;
    [_trtcCloud muteLocalAudio:!micEnable];
}

- (void)setLogEnable:(BOOL)logEnable {
    _logEnable = logEnable;
    if (logEnable) {
        [_trtcCloud setDebugViewMargin:_userId margin:UIEdgeInsetsMake(0.1, 0.05, 0.2, 0.1)];
        [_trtcCloud showDebugView:2];
    } else {
        [_trtcCloud showDebugView:0];
    }
}

- (void)configBeautyPanel:(TCBeautyPanel *)beautyPanel {
    beautyPanel.actionPerformer = [TCBeautyPanelActionProxy proxyWithSDKObject:_trtcCloud];
}

- (void)configAudioEffectPanel:(AudioEffectSettingView *)audioPanel {
    [audioPanel setAudioEffectManager:[_trtcCloud getAudioEffectManager]];
}
#pragma mark - Screen Capture
- (void)startScreenCapture {
    TRTCVideoEncParam *params = [TRTCVideoEncParam new];
    params.videoResolution    = TRTCVideoResolution_1280_720;
    params.videoBitrate       = 550;
    params.videoFps           = 10;
    if (@available(iOS 11.0, *)) {
        if (self.videoConfig.source == TRTCVideoSourceDeviceScreen) {
            [self.trtcCloud startScreenCaptureByReplaykit:TRTCVideoStreamTypeBig encParam:params appGroup:@"group.com.tencent.liteav.RPLiveStreamShare"];
        }
        if (self.videoConfig.subSource == TRTCVideoSourceDeviceScreen) {
            [self.trtcCloud startScreenCaptureByReplaykit:TRTCVideoStreamTypeSub encParam:params appGroup:@"group.com.tencent.liteav.RPLiveStreamShare"];
        }
    } else {
        // Fallback on earlier versions
    }
}
- (void)stopScreenCapture {
    if (@available(iOS 11.0, *)) {
        [self.trtcCloud stopScreenCapture];
    } else {
        // Fallback on earlier versions
    }
}

#pragma mark - Video config

- (void)enableBlackStream:(BOOL)enable size:(CGSize)size {
    NSDictionary *json       = @{@"api" : @"enableBlackStream", @"params" : @{@"enable" : @(enable), @"width" : @(size.width), @"height" : @(size.height)}};
    NSString *    jsonString = [self jsonStringFrom:json];
    [self.trtcCloud callExperimentalAPI:jsonString];
}

- (void)setResolution:(TRTCVideoResolution)resolution {
    self.videoConfig.videoEncConfig.videoResolution = resolution;
    if (DEBUGSwitch) {
        [self updateStreamVideoEnc:resolution ResolutionMode:self.videoConfig.videoEncConfig.resMode];
    }
    [self.trtcCloud setVideoEncoderParam:self.videoConfig.videoEncConfig];
    
}


- (void)setSubStreamResolution:(TRTCVideoResolution)resolution {
    self.videoConfig.subStreamVideoEncConfig.videoResolution = resolution;
    [self.trtcCloud setSubStreamEncoderParam:self.videoConfig.subStreamVideoEncConfig];
}

- (void)setResolutionMode:(TRTCVideoResolutionMode)resolutionMode {
    self.videoConfig.videoEncConfig.resMode = resolutionMode;
    if (DEBUGSwitch) {
        [self updateStreamVideoEnc:self.videoConfig.videoEncConfig.videoResolution ResolutionMode:resolutionMode];
    }
    [self.trtcCloud setVideoEncoderParam:self.videoConfig.videoEncConfig];
}

- (void)updateStreamVideoEnc:(TRTCVideoResolution)resolution ResolutionMode:(TRTCVideoResolutionMode)resolutionMode{
    NSMutableDictionary *params = [self.streamVideoEncConfig objectForKey:@"params"];
    NSNumber *videoHeight;
    NSNumber *videoWidth;
    switch (resolution) {
        case TRTCVideoResolution_160_160:
            videoWidth  = @(160);
            videoHeight = @(160);
            break;
        case TRTCVideoResolution_320_180:
            videoWidth  = @(180);
            videoHeight = @(320);
            break;
        case TRTCVideoResolution_320_240:
            videoWidth  = @(240);
            videoHeight = @(320);
            break;
        case TRTCVideoResolution_640_360:
            videoWidth  = @(360);
            videoHeight = @(640);
            break;
        case TRTCVideoResolution_480_480:
            videoWidth  = @(480);
            videoHeight = @(480);
            break;
        case TRTCVideoResolution_640_480:
            videoWidth  = @(480);
            videoHeight = @(640);
            break;
        case TRTCVideoResolution_960_540:
            videoWidth  = @(540);
            videoHeight = @(960);
            break;
        case TRTCVideoResolution_1280_720:
            videoWidth  = @(720);
            videoHeight = @(1280);
            break;
        case TRTCVideoResolution_1920_1080:
            videoWidth  = @(1080);
            videoHeight = @(1920);
            break;
        default:
            break;
    }
    BOOL isPortrait = resolutionMode == TRTCVideoResolutionModePortrait;
    if (isPortrait) {
        [params setValue:videoHeight forKey:@"videoHeight"];
        [params setValue:videoWidth forKey:@"videoWidth"];
    } else {
        [params setValue:videoWidth forKey:@"videoHeight"];
        [params setValue:videoHeight forKey:@"videoWidth"];
    }
    [self.streamVideoEncConfig setObject:params forKey:@"params"];
    NSString *jsonString = [self jsonStringFrom:self.streamVideoEncConfig];
    [self.trtcCloud callExperimentalAPI:jsonString];
}


- (void)setVideoFillMode:(TRTCVideoFillMode)videoFillMode {
    self.videoConfig.localRenderParams.fillMode = videoFillMode;
    [self.trtcCloud setLocalRenderParams:self.videoConfig.localRenderParams];
}

- (void)setLocalMirror:(TRTCVideoMirrorType)mirrorType {
    self.videoConfig.localRenderParams.mirrorType = mirrorType;
    [self.trtcCloud setLocalRenderParams:self.videoConfig.localRenderParams];
}

- (void)setEncodeMirrorEnable:(BOOL)remoteMirrorEnable {
    self.videoConfig.isRemoteMirrorEnabled = remoteMirrorEnable;
    [self.trtcCloud setVideoEncoderMirror:remoteMirrorEnable];
}

- (void)setLocalMirrorType:(TRTCVideoMirrorType)localMirrorType {
    self.videoConfig.localRenderParams.mirrorType = localMirrorType;
    [self.trtcCloud setLocalRenderParams:self.videoConfig.localRenderParams];
}

- (void)setRemoteMirrorType:(TRTCVideoMirrorType)remoteMirrorType {
    [self.trtcCloud setLocalRenderParams:self.videoConfig.localRenderParams];
}

- (void)setLocalVideoRotation:(TRTCVideoRotation)localVideoRotation {
    self.videoConfig.localRenderParams.rotation = localVideoRotation;
    [self.trtcCloud setLocalRenderParams:self.videoConfig.localRenderParams];
}

- (void)setEncodeVideoRotation:(TRTCVideoRotation)encodeVideoRotation {
    [self.trtcCloud setVideoEncoderRotation:encodeVideoRotation];
}

- (void)setQosPreference:(TRTCVideoQosPreference)qosPreference {
    self.videoConfig.qosConfig.preference = qosPreference;
    [self.trtcCloud setNetworkQosParam:self.videoConfig.qosConfig];
}

- (void)setIsVideoPause:(BOOL)isVideoPause {
    self.videoConfig.isMuted = isVideoPause;
    [self.trtcCloud muteLocalVideo:TRTCVideoStreamTypeBig mute:isVideoPause];
}

- (void)pauseScreenCapture:(BOOL)isPaused {
    self.videoConfig.isScreenCapturePaused = isPaused;
    if (@available(iOS 11.0, *)) {
        if (isPaused) {
            [self.trtcCloud pauseScreenCapture];
        } else {
            [self.trtcCloud resumeScreenCapture];
        }
    }
}

- (void)setSubStreamVideoFps:(int)fps {
    self.videoConfig.subStreamVideoEncConfig.videoFps = fps;
    [self.trtcCloud setSubStreamEncoderParam:self.videoConfig.subStreamVideoEncConfig];
}

- (void)setVideoFps:(int)videoFps {
    self.videoConfig.videoEncConfig.videoFps = videoFps;
    [self.trtcCloud setVideoEncoderParam:self.videoConfig.videoEncConfig];
}

- (void)setCaptureResolution:(NSInteger)resolutionIndex {
    self.videoConfig.captureResolutionIndex = resolutionIndex;
    CGSize resolution                       = [TRTCVideoConfig.captureResolutions[resolutionIndex] CGSizeValue];
    [self setExperimentConfig:@"setCaptureResolution" params:@{@"width" : @(resolution.width), @"height" : @(resolution.height)}];
}

- (void)setVideoBitrate:(int)videoBitrate {
    self.videoConfig.videoEncConfig.videoBitrate = videoBitrate;
    [self.trtcCloud setVideoEncoderParam:self.videoConfig.videoEncConfig];
}

- (void)setCustomProcessFormat:(TRTCVideoPixelFormat)format {
    self.videoConfig.format  = format;
    TRTCVideoBufferType type = format == TRTCVideoPixelFormat_Texture_2D ? TRTCVideoBufferType_Texture : TRTCVideoBufferType_PixelBuffer;

    [self.customPreprocessor invalidateBindedTexture];
    if (format == TRTCVideoPixelFormat_Unknown) {
        [self.trtcCloud setLocalVideoProcessDelegete:nil pixelFormat:format bufferType:TRTCVideoBufferType_Unknown];
    } else {
        [self.trtcCloud setLocalVideoProcessDelegete:self pixelFormat:format bufferType:type];
    }
}

- (void)setCustomBrightness:(CGFloat)brightness {
    self.videoConfig.brightness        = brightness;
    self.customPreprocessor.brightness = brightness;
}

- (void)setSubStreamVideoBitrate:(int)bitrate {
    self.videoConfig.subStreamVideoEncConfig.videoBitrate = bitrate;
    [self.trtcCloud setSubStreamEncoderParam:self.videoConfig.subStreamVideoEncConfig];
}

- (void)enableHEVCAbility:(BOOL)enableHEVCAbility {
    // change Ability 测试入口，需要的话临时添加测试代码
}
- (void)setVideoMuted:(BOOL)isMuted {
    self.videoConfig.isMuted = isMuted;
    [self.trtcCloud muteLocalVideo:isMuted];
}

- (void)pushAudioStreamInSubRoom:(NSString *)roomId push:(BOOL)isPush {
    self.audioConfig.isMuted = !isPush;
    [[_subClouds objectForKey:roomId] muteLocalAudio:!isPush];
    if ([self.delegate respondsToSelector:@selector(onMuteLocalAudio:)]) {
        [self.delegate onMuteLocalAudio:!isPush];
    }
}

- (void)pushVideoStreamInSubRoom:(NSString *)roomId push:(BOOL)isPush {
    self.videoConfig.isMuted = !isPush;
    [[_subClouds objectForKey:roomId] muteLocalVideo:!isPush];
}

- (void)switchSubRoomRole:(TRTCRoleType)role roomId:(NSString *)roomId {
    if (role == TRTCRoleAnchor) {
        self.currentPublishingRoomId = roomId;
    }
    [self.subClouds[roomId] switchRole:role];
}

- (void)setAudioMuted:(BOOL)isMuted {
    self.audioConfig.isMuted = isMuted;
    [self.trtcCloud muteLocalAudio:isMuted];
    if ([self.delegate respondsToSelector:@selector(onMuteLocalAudio:)]) {
        [self.delegate onMuteLocalAudio:isMuted];
    }
}

- (void)setWaterMark:(nullable UIImage *)image inRect:(CGRect)rect {
    [self.trtcCloud setWatermark:image streamType:TRTCVideoStreamTypeBig rect:rect];
    [self.trtcCloud setWatermark:image streamType:TRTCVideoStreamTypeSub rect:rect];
}

- (void)setVideoCodecType:(NSInteger)codecType{

    NSNumber *videoBitrate    = @(self.videoConfig.videoEncConfig.videoBitrate);
    self.streamVideoEncConfig = [@{@"api" : @"setVideoEncodeParamEx", @"params" : [@{@"codecType" : @(codecType), @"videoWidth" :@(360), @"videoHeight" :@(640), @"videoFps" :@(15), @"videoBitrate" :videoBitrate} mutableCopy]} mutableCopy];
    NSString *jsonString   = [self jsonStringFrom:self.streamVideoEncConfig];
    [self.trtcCloud callExperimentalAPI:jsonString];
}

- (void)enableVideoMuteImage:(BOOL)isEnabled {
    self.videoConfig.isVideoMuteImage = isEnabled;
    [self.trtcCloud setVideoMuteImage:isEnabled ? [UIImage imageNamed:@"background"] : nil fps:3];
}

- (void)enableSharpnessEnhancement:(BOOL)enable {
    [[self.trtcCloud getBeautyManager] enableSharpnessEnhancement:enable];
}

- (void)enableTimestampWaterMark:(BOOL)isEnable {
    self.timestampWaterMarkEnable = isEnable;
}

- (void)snapshotLocalVideoWithUserId:(NSString *)userId type:(TRTCVideoStreamType)type completionBlock:(void (^)(TXImage *image))completionBlock {
    [self.trtcCloud snapshotVideo:userId type:type sourceType:TRTCSnapshotSourceTypeView completionBlock:completionBlock];
}

- (void)setGSensorEnabled:(BOOL)gSensorEnabled {
    _gSensorEnabled      = gSensorEnabled;
    TRTCGSensorMode mode = gSensorEnabled ? TRTCGSensorMode_UIAutoLayout : TRTCGSensorMode_Disable;
    [self.trtcCloud setGSensorMode:mode];
}

- (void)setFlashLightEnabled:(BOOL)flashLightEnabled {
    _flashLightEnabled = flashLightEnabled;
    [[self.trtcCloud getDeviceManager] enableCameraTorch:flashLightEnabled];
}

#pragma mark - Audio config
- (void)setExperimentConfig:(NSString *)key params:(NSDictionary *)params {
    NSDictionary *json = @{@"api" : key, @"params" : params};
    [self.trtcCloud callExperimentalAPI:[self jsonStringFrom:json]];
}

- (NSString *)jsonStringFrom:(NSDictionary *)dict {
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dict options:0 error:NULL];
    return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
}

- (void)setVolumeType:(TXSystemVolumeType)volumeType {
    //-1为不选
    _volumeType = volumeType;
    if (volumeType == -1) {
        return;
    }
    [[_trtcCloud getDeviceManager] setSystemVolumeType:_volumeType];
}

- (void)setAudioEnabled:(BOOL)isEnabled {
    self.audioConfig.isEnabled = isEnabled;
    if (isEnabled) {
        [self setupTrtcAudio];
        [self startLocalAudio];
    } else {
        [self stopLocalAudio];
    }
}

- (void)setAgcEnabled:(BOOL)agcEnabled {
    _agcEnabled = agcEnabled;
    [self setExperimentConfig:@"enableAudioAGC" params:@{@"enable" : @(agcEnabled)}];
}

- (void)setAecEnabled:(BOOL)aecEnabled {
    _aecEnabled = aecEnabled;
    [self setExperimentConfig:@"enableAudioAEC" params:@{@"enable" : @(aecEnabled)}];
}

- (void)setAnsEnabled:(BOOL)ansEnabled {
    _ansEnabled = ansEnabled;
    [self setExperimentConfig:@"enableAudioANS" params:@{@"enable" : @(ansEnabled)}];
}

- (void)setCaptureVolume:(NSInteger)captureVolume {
    _captureVolume = captureVolume;
    [self.trtcCloud setAudioCaptureVolume:captureVolume];
}

- (void)setPlayoutVolume:(NSInteger)playoutVolume {
    _playoutVolume = playoutVolume;
    [self.trtcCloud setAudioPlayoutVolume:playoutVolume];
}

- (void)setEarMonitoringEnabled:(BOOL)earMonitoringEnabled {
    self.audioConfig.isEarMonitoringEnabled = earMonitoringEnabled;
    [[self.trtcCloud getAudioEffectManager] enableVoiceEarMonitor:earMonitoringEnabled];
}

- (void)setAudioRoute:(TXAudioRoute)audioRoute {
    _audioRoute = audioRoute;
    _audioConfig.route = (TRTCAudioRoute)audioRoute;
    [[self.trtcCloud getDeviceManager] setAudioRoute:audioRoute];
}

- (void)setVolumeEvaluationEnabled:(BOOL)volumeEvaluationEnabled {
    _volumeEvaluationEnabled = volumeEvaluationEnabled;
    [self.trtcCloud enableAudioVolumeEvaluation:volumeEvaluationEnabled ? 300 : 0];
    for (TRTCVideoView *view in [self.viewDic allValues]) {
        [view.audioVolumeIndicator setHidden:!volumeEvaluationEnabled];
    }
}

- (void)setEarMonitoringVolume:(NSInteger)volume {
    [[self.trtcCloud getAudioEffectManager] setVoiceEarMonitorVolume:volume];
}
- (void)setUpdatevoicePitchVolume:(double)volume {
    [[self.trtcCloud getAudioEffectManager] setVoicePitch:volume];
}

#pragma mark - Live Player
- (NSString *)getCdnUrlOfUser:(NSString *)userId {
    return [NSString stringWithFormat:@"http://%@.liveplay.myqcloud.com/live/%@_%@_%@_main.flv", @(TX_BIZID), @(SDKAPPID), self.roomId, userId];
}

- (void)closeStreamMix {
    [self.trtcCloud setMixTranscodingConfig:nil];
}

- (void)updateStreamMix {
    if (self.streamConfig.mixMode == TRTCTranscodingConfigMode_Unknown) {
        [self.trtcCloud setMixTranscodingConfig:nil];
        return;
    }
    int videoWidth  = 720;
    int videoHeight = 1280;

    // 小画面宽高
    int subWidth  = 180;
    int subHeight = 320;

    int offsetX = 5;
    int offsetY = 50;

    int bitrate = 1500;

    TRTCTranscodingConfig *config = [TRTCTranscodingConfig new];
    config.appId                  = TX_APPID;
    config.bizId                  = TX_BIZID;
    config.videoWidth             = videoWidth;
    config.videoHeight            = videoHeight;
    config.videoGOP               = 1;
    config.videoFramerate         = 15;
    config.videoBitrate           = bitrate;
    config.audioSampleRate        = 48000;
    config.audioBitrate           = 64;
    config.audioChannels          = 1;

    TRTCMixUser *broadCaster = [TRTCMixUser new];
    broadCaster.userId       = self.userId;
    broadCaster.rect         = CGRectMake(0, 0, videoWidth, videoHeight);
    broadCaster.zOrder       = 1;
    NSMutableArray *mixUsers = [NSMutableArray new];
    [mixUsers addObject:broadCaster];

    int index = 0;
    for (TRTCVideoView *videoView in [self.viewDic allValues]) {
        if ([videoView.userId isEqualToString:self.userId]) {
            continue;
        }
        TRTCMixUser *audience = [TRTCMixUser new];
        audience.userId       = videoView.userId;
        audience.zOrder       = 2 + index;
        audience.roomID       = videoView.roomId;
        audience.streamType   = TRTCVideoStreamTypeBig;
        //辅流判断：辅流的Id为原userId + "-sub"
        if ([videoView.userId hasSuffix:@"-sub"]) {
            NSArray *spritStrs = [videoView.userId componentsSeparatedByString:@"-"];
            if (spritStrs.count < 2) {
                return;
            }
            NSString *realUserId = [videoView.userId substringWithRange:NSMakeRange(0, [videoView.userId length] - 4)];;
            audience.userId      = realUserId;
            audience.streamType  = TRTCVideoStreamTypeSub;
        }
        if (index < 3) {
            // 前三个小画面靠右从下往上铺
            audience.rect = CGRectMake(videoWidth - offsetX - subWidth, videoHeight - offsetY - index * subHeight - subHeight, subWidth, subHeight);
        } else if (index < 6) {
            // 后三个小画面靠左从下往上铺
            audience.rect = CGRectMake(offsetX, videoHeight - offsetY - (index - 3) * subHeight - subHeight, subWidth, subHeight);
        } else {
            // 最多只叠加六个小画面
        }

        [mixUsers addObject:audience];
        ++index;
    }

    config.mixUsers = mixUsers;
    config.mode     = TRTCTranscodingConfigMode_Manual;
    [self.trtcCloud setMixTranscodingConfig:config];
}

#pragma mark - pk room

- (void)startCrossRoom:(NSString *)roomId userId:(NSString *)userId {
    NSDictionary *pkParams = @{
        @"strRoomId" : roomId,
        @"userId" : userId,
    };
    NSData *  jsonData   = [NSJSONSerialization dataWithJSONObject:pkParams options:0 error:nil];
    NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];

    self.crossRoomId = roomId;
    [self.trtcCloud connectOtherRoom:jsonString];
    [self.remoteUserManager addUser:userId roomId:roomId];
}

- (void)stopCrossRomm {
    self.isCrossingRoom = NO;
    [self.trtcCloud disconnectOtherRoom];
}

#pragma mark - SEI message

- (void)sendSEIMessage:(NSString *)message {
    [self.trtcCloud sendSEIMsg:[message dataUsingEncoding:NSUTF8StringEncoding] repeatCount:1];
}

- (BOOL)sendCustomMessage:(NSString *)message {
    NSData *_Nullable data = [message dataUsingEncoding:NSUTF8StringEncoding];
    if (data != nil) {
        return [self.trtcCloud sendCustomCmdMsg:1 data:data reliable:YES ordered:NO];
    }
    return NO;
}

- (BOOL)bindMsgToAudioFrame:(NSString *)message {
    _bindToAudioFrameMsg = message;
    return YES;
}


- (BOOL)sendMsgToAudioPacket:(NSString *)message {
    [[TRTCCustomerAudioPacketDeleagate sharedInstance] bindMsgToAudioPkg:message];
    return YES;
}

- (void)switchRoom:(TRTCSwitchRoomConfig *)switchRoomConfig {
    if ([self.currentPublishingRoomId isEqualToString:self.params.roomId ? [@(self.params.roomId) stringValue] : self.params.strRoomId]) {
        //若之前正在主房间中推流，则更新推流房间为新的房间号
        self.currentPublishingRoomId = switchRoomConfig.roomId ? [@(switchRoomConfig.roomId) stringValue] : switchRoomConfig.strRoomId;
    }
    self.params.roomId    = switchRoomConfig.roomId;
    self.params.strRoomId = switchRoomConfig.strRoomId;
    if (switchRoomConfig.userSig) {
        self.params.userSig = switchRoomConfig.userSig;
    }
    if (switchRoomConfig.privateMapKey) {
        self.params.privateMapKey = switchRoomConfig.privateMapKey;
    }
    [self.trtcCloud switchRoom:switchRoomConfig];
}

#pragma mark - remote config
- (void)setRemoteVideoMute:(BOOL)enable userId:(NSString *)userId {
    [self.trtcCloud muteRemoteVideoStream:userId mute:enable];
}

- (void)setRemoteAudioMute:(BOOL)enable userId:(NSString *)userId {
    [self.trtcCloud muteRemoteAudio:userId mute:enable];
}
- (void)setRemoteVolume:(int)volume userId:(NSString *)userId {
    [self.trtcCloud setRemoteAudioVolume:userId volume:volume];
}

- (void)setRemoteRenderParams:(TRTCRenderParams *)params userId:(NSString *)userId {
    [self.trtcCloud setRemoteRenderParams:userId streamType:TRTCVideoStreamTypeBig params:params];
}

- (void)setRemoteSubStreamRenderParams:(TRTCRenderParams *)params userId:(NSString *)userId {
    [self.trtcCloud setRemoteRenderParams:userId streamType:TRTCVideoStreamTypeSub params:params];
}

#pragma mark - Local Record
- (void)startLocalRecording {
    self.enableLocalRecord     = YES;
    NSTimeInterval   now       = [[NSDate date] timeIntervalSince1970];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyyMMddHHmmss"];
    NSDate *                  NowDate  = [NSDate dateWithTimeIntervalSince1970:now];
    NSString *                timeStr  = [formatter stringFromDate:NowDate];
    NSString *                fileName = [NSTemporaryDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"mediaRecord%@.mp4", timeStr]];
    TRTCLocalRecordingParams *params   = [[TRTCLocalRecordingParams alloc] init];
    params.filePath                    = fileName;
    params.interval                    = 1000;
    params.recordType                  = self.localRecordType;
    [self.trtcCloud startLocalRecording:params];
}

- (void)resetTRTCClouldDelegate {
    [self.trtcCloud setDelegate:self];
}

- (void)stopLocalRecording {
    self.enableLocalRecord = NO;
    [self.trtcCloud stopLocalRecording];
}


- (void)setRemoteAudioParallelParams:(UInt32)maxCount {
    // 清空之前用户配置，避免冲突
    for (NSString *user in self.viewDic.allKeys) {
        TRTCVideoView *videoView = self.viewDic[user];
        videoView.userConfig.isAudioParallelMustPlayed = NO;
        self.viewDic[user] = videoView;
    }
    
    self.audioParallelMaxCount = maxCount;
    [self.audioParallelIncludeUsers removeAllObjects];
    
    TRTCAudioParallelParams *audioParallelParams = [TRTCAudioParallelParams new];
    audioParallelParams.maxCount = self.audioParallelMaxCount;
    audioParallelParams.includeUsers = self.audioParallelIncludeUsers;
    
    [self.trtcCloud setRemoteAudioParallelParams:audioParallelParams];
}

- (BOOL)setRemoteAudioParallelParams:(BOOL)isAdd userId:(NSString *)userId {
    if (self.audioParallelMaxCount == 0 || (isAdd && self.audioParallelMaxCount - [self.audioParallelIncludeUsers count] <= 1)) {
        return NO;
    }
    
    if (isAdd) {
        [self.audioParallelIncludeUsers addObject:userId];
    } else {
        [self.audioParallelIncludeUsers removeObject:userId];
    }
    
    TRTCAudioParallelParams *audioParallelParams = [TRTCAudioParallelParams new];
    audioParallelParams.maxCount = self.audioParallelMaxCount;
    audioParallelParams.includeUsers = self.audioParallelIncludeUsers;
    
    [self.trtcCloud setRemoteAudioParallelParams:audioParallelParams];
    return YES;
}


#pragma mark - Media File

- (void)setCustomSourceAsset:(AVAsset *)customSourceAsset {
    _customSourceAsset = customSourceAsset;
    self.mediaReader   = nil;
    self.mediaReader   = [[MediaFileSyncReader alloc] initWithAVAsset:_customSourceAsset];
    [self.mediaReader setDelegate:self];
}

#pragma mark - MediaFileSyncReader Delegate
- (void)onReadVideoFrameAtFrameIntervals:(CVImageBufferRef)imageBuffer timeStamp:(UInt64)timeStamp {
    TRTCVideoFrame *videoFrame = [TRTCVideoFrame new];
    videoFrame.bufferType      = TRTCVideoBufferType_PixelBuffer;
    videoFrame.pixelFormat     = TRTCVideoPixelFormat_NV12;
    videoFrame.pixelBuffer     = imageBuffer;
    TRTCVideoRotation rotation = TRTCVideoRotation_0;
    if (self.mediaReader.angle == 90) {
        rotation = TRTCVideoRotation_90;
    } else if (self.mediaReader.angle == 180) {
        rotation = TRTCVideoRotation_180;
    } else if (self.mediaReader.angle == 270) {
        rotation = TRTCVideoRotation_270;
    }
    videoFrame.rotation = rotation;

    [self.trtcCloud sendCustomVideoData:TRTCVideoStreamTypeBig frame:videoFrame];
}

- (void)onReadAudioFrameAtFrameIntervals:(NSData *)pcmData timeStamp:(UInt64)timeStamp {
    TRTCAudioFrame *audioFrame = [TRTCAudioFrame new];
    audioFrame.channels        = _mediaReader.audioChannels;
    audioFrame.sampleRate      = _mediaReader.audioSampleRate;
    audioFrame.data            = pcmData;

    [self.trtcCloud sendCustomAudioData:audioFrame];
}

#pragma mark - CustomAudioFileReaderDelegate

- (void)onAudioCapturePcm:(NSData *)pcmData sampleRate:(int)sampleRate channels:(int)channels ts:(uint32_t)timestampMs {
    TRTCAudioFrame *frame = [[TRTCAudioFrame alloc] init];
    frame.data            = pcmData;
    frame.sampleRate      = sampleRate;
    frame.channels        = channels;
    // use sdk timestamp
    frame.timestamp       = 0;

    [self.trtcCloud sendCustomAudioData:frame];
}

#pragma mark - TRTC Delegate

- (void)onRemoteUserEnterRoom:(NSString *)userId {
    TRTCVideoView *videoView = [[TRTCVideoView alloc] init];
    [videoView setUserId:userId];
    [videoView setRoomId:self.roomId];
    [videoView.audioVolumeIndicator setHidden:!_volumeEvaluationEnabled];

    self.viewDic[userId] = videoView;
    [self.remoteUserManager addUser:userId roomId:self.roomId];
    
    if (self.audioInputType != TRTCAudioCustom) {
        return;
    }
}

- (void)onRemoteUserLeaveRoom:(NSString *)userId reason:(NSInteger)reason {
    [self.viewDic[userId] removeFromSuperview];
    [self.viewDic removeObjectForKey:userId];
    
    NSString *subUserId = [[NSString alloc] initWithFormat:@"%@-sub", userId];
    if ([self.viewDic.allKeys containsObject:subUserId]) {
        [self.viewDic[subUserId] removeFromSuperview];
        [self.viewDic removeObjectForKey:subUserId];
    }
    
    [self.remoteUserManager removeUser:userId];
    if (_isCrossingRoom && [self.crossUserId isEqualToString:userId]) {
        _isCrossingRoom = NO;
    }
    [self updateStreamMix];
}

//主房间主流
- (void)onUserVideoAvailable:(NSString *)userId available:(BOOL)available {
    if (available) {
        if (userId != nil) {
            TRTCVideoView *videoView = self.viewDic[userId];
            if (!videoView) {
                videoView = [[TRTCVideoView alloc] init];
                [videoView setUserId:userId];
                [videoView setRoomId:self.crossRoomId];
                [videoView.audioVolumeIndicator setHidden:!_volumeEvaluationEnabled];
                [self.viewDic setValue:videoView forKey:userId];
            }
            [self.trtcCloud startRemoteView:userId streamType:TRTCVideoStreamTypeBig view:videoView];
            [self setRemoteVideoMute:videoView.userConfig.isVideoMuted userId:userId];
            [self.trtcCloud setRemoteRenderParams:userId streamType:TRTCVideoStreamTypeBig params:videoView.userConfig.renderParams];
        }
        [_trtcCloud setDebugViewMargin:userId margin:UIEdgeInsetsMake(0.1, 0.05, 0.2, 0.1)];
    } else {
        [self.trtcCloud stopRemoteView:userId streamType:TRTCVideoStreamTypeBig];
    }
    if ([self.delegate respondsToSelector:@selector(onUserVideoAvailable:available:)]) {
        [self.delegate onUserVideoAvailable:userId available:available];
    }
    [self updateStreamMix];
}

//主房间子流
- (void)onUserSubStreamAvailable:(NSString *)userId available:(BOOL)available {
    NSString *subUserId = [[NSString alloc] initWithFormat:@"%@-sub", userId];

    if (available) {
        TRTCVideoView *videoView = [[TRTCVideoView alloc] init];
        [videoView setUserId:subUserId];
        [videoView.audioVolumeIndicator setHidden:!_volumeEvaluationEnabled];
        self.viewDic[subUserId]          = videoView;
        videoView.userConfig.isSubStream = true;

        [self.trtcCloud startRemoteView:userId streamType:TRTCVideoStreamTypeSub view:self.viewDic[subUserId]];
        [self.trtcCloud setRemoteRenderParams:userId streamType:TRTCVideoStreamTypeSub params:videoView.userConfig.renderParams];
    } else {
        [self.viewDic[subUserId] removeFromSuperview];
        [self.viewDic removeObjectForKey:subUserId];
        [self.trtcCloud stopRemoteView:userId streamType:TRTCVideoStreamTypeSub];
    }

    if ([self.delegate respondsToSelector:@selector(onUserVideoAvailable:available:)]) {
        [self.delegate onUserVideoAvailable:subUserId available:available];
    }
    [self updateStreamMix];
}

- (void)onUserVoiceVolume:(NSArray<TRTCVolumeInfo *> *)userVolumes totalVolume:(NSInteger)totalVolume {
    for (TRTCVolumeInfo *info in userVolumes) {
        NSString *userId;
        if (info.userId == nil) {
            userId = self.userId;
        } else {
            userId = info.userId;
        }
        [self.viewDic[userId] setAudioVolumeRadio:(info.volume / 100.0)];
    }
}

- (void)onEnterRoom:(NSInteger)result {
    if ([self.delegate respondsToSelector:@selector(onEnterRoom:)]) {
        [self.delegate onEnterRoom:result];
    }
}

- (void)onExitRoom:(NSInteger)reason {
    if ([self.delegate respondsToSelector:@selector(onExitRoom:)]) {
        [self.delegate onExitRoom:reason];
    }
}

- (void)onScreenCaptureStarted {
    if ([self.delegate respondsToSelector:@selector(onScreenCaptureIsStarted:)]) {
        [self.delegate onScreenCaptureIsStarted:true];
    }
}

- (void)onScreenCaptureStoped:(int)reason {
    if ([self.delegate respondsToSelector:@selector(onScreenCaptureIsStarted:)]) {
        [self.delegate onScreenCaptureIsStarted:false];
    }
}

- (void)onRecvCustomCmdMsgUserId:(NSString *)userId cmdID:(NSInteger)cmdID seq:(UInt32)seq message:(NSData *)message {
    if ([self.delegate respondsToSelector:@selector(onRecvCustomCmdMsgUserId:cmdID:seq:message:)]) {
        [self.delegate onRecvCustomCmdMsgUserId:userId cmdID:cmdID seq:seq message:message];
    }
}

- (void)onRecvSEIMsg:(NSString *)userId message:(NSData *)message {
    if ([self.delegate respondsToSelector:@selector(onRecvSEIMsg:message:)]) {
        [self.delegate onRecvSEIMsg:userId message:message];
    }
}

- (void)onConnectOtherRoom:(NSString *)userId errCode:(TXLiteAVError)errCode errMsg:(NSString *)errMsg {
    if (errCode == ERR_NULL) {
        self.isCrossingRoom = true;
        self.crossUserId    = userId;

        TRTCVideoView *videoView = [[TRTCVideoView alloc] init];
        [videoView setUserId:userId];
        [videoView setRoomId:self.crossRoomId];
        [videoView.audioVolumeIndicator setHidden:!_volumeEvaluationEnabled];

        self.viewDic[userId] = videoView;
    }
    if ([self.delegate respondsToSelector:@selector(onConnectOtherRoom:errCode:errMsg:)]) {
        [self.delegate onConnectOtherRoom:userId errCode:errCode errMsg:errMsg];
    }
}

- (void)onWarning:(TXLiteAVWarning)warningCode warningMsg:(NSString *)warningMsg extInfo:(NSDictionary *)extInfo {
    if ([self.delegate respondsToSelector:@selector(onWarning:warningMsg:extInfo:)]) {
        [self.delegate onWarning:warningCode warningMsg:warningMsg extInfo:extInfo];
    }
}

- (void)onError:(TXLiteAVError)errCode errMsg:(NSString *)errMsg extInfo:(NSDictionary *)extInfo {
    if ([self.delegate respondsToSelector:@selector(onError:errMsg:extInfo:)]) {
        [self.delegate onError:errCode errMsg:errMsg extInfo:extInfo];
    }
}

- (void)onNetworkQuality:(TRTCQualityInfo *)localQuality remoteQuality:(NSArray<TRTCQualityInfo *> *)remoteQuality {
    if ([self.delegate respondsToSelector:@selector(onNetworkQuality:remoteQuality:)]) {
        [self.delegate onNetworkQuality:localQuality remoteQuality:remoteQuality];
    }
}

#pragma mark - TRTCVideoRenderDelegate

- (void)onRenderVideoFrame:(TRTCVideoFrame *)frame userId:(NSString *)userId streamType:(TRTCVideoStreamType)streamType {
    CFRetain(frame.pixelBuffer);
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        [CustomFrameRender renderImageBuffer:frame.pixelBuffer forView:weakSelf.viewDic[weakSelf.userId]];
        CFRelease(frame.pixelBuffer);
    });
}

#pragma mark - TRTCAudioFrameDelegate

- (void)onCapturedRawAudioFrame:(TRTCAudioFrame *)frame {
}

- (void)onLocalProcessedAudioFrame:(TRTCAudioFrame *)frame {
    if (_bindToAudioFrameMsg) {
        NSData *_Nullable data = [_bindToAudioFrameMsg dataUsingEncoding:NSUTF8StringEncoding];
        frame.extraData = data;
        _bindToAudioFrameMsg = nil;
    }
}

- (void)onRemoteUserAudioFrame:(TRTCAudioFrame *)frame userId:(NSString *)userId {
    if (frame.extraData != NULL && frame.extraData.length != 0) {
        if ([self.delegate respondsToSelector:@selector(onRemoteUserAudioFrameMsg:message:)]) {
            [self.delegate onRemoteUserAudioFrameMsg:userId message:frame.extraData];
        }
    }
}

- (void)onMixedPlayAudioFrame:(TRTCAudioFrame *)frame {
}

- (void)onMixedAllAudioFrame:(TRTCAudioFrame *)frame {
}

#pragma mark - TRTCVideoFrameDelegate

- (uint32_t)onProcessVideoFrame:(TRTCVideoFrame *_Nonnull)srcFrame dstFrame:(TRTCVideoFrame *_Nonnull)dstFrame {
    if (srcFrame.pixelFormat == TRTCVideoPixelFormat_Texture_2D) {
        dstFrame.textureId = [self.customPreprocessor processTexture:srcFrame.textureId width:srcFrame.width height:srcFrame.height];
    } else if (srcFrame.data) {
        memcpy(dstFrame.data.bytes, srcFrame.data.bytes, srcFrame.data.length);
    } else if (srcFrame.pixelFormat == TRTCVideoPixelFormat_NV12 || srcFrame.pixelFormat == TRTCVideoPixelFormat_32BGRA) {
        CIImage *image = [self.yuvPreprocessor filterPixelBuffer:srcFrame];
        [self.yuvPreprocessor.fContex render:image toCVPixelBuffer:dstFrame.pixelBuffer];
    } else if (srcFrame.pixelFormat == TRTCVideoPixelFormat_I420) {
        dstFrame.pixelBuffer = srcFrame.pixelBuffer;
    }

    if (self.timestampWaterMarkEnable) {
        self.waterMarkProcessor.pixelBuffer = srcFrame.pixelBuffer;
        dstFrame.pixelBuffer                = self.waterMarkProcessor.outputPixelBuffer;
    }
    return 0;
}

#pragma mark - Private
- (void)startLocalAudio {
    if (!self.audioConfig.isEnabled) {
        return;
    }
    if (!self.isLiveAudience){
        if (self.audioConfig.isCustomCapture) {
            [self.trtcCloud enableCustomAudioCapture:YES];
            if (self.videoConfig.source != TRTCVideoSourceCustom) {
                [CustomAudioFileReader sharedInstance].delegate = self;
                [[CustomAudioFileReader sharedInstance] start:48000 channels:1 framLenInSample:960];
            }
        } else {
            [self.trtcCloud startLocalAudio:_audioQuality];
        }
    }
    // 由于设置音频质量会更改音频类型，所以要重新设置
    if (_volumeType != -1) {
        [[_trtcCloud getDeviceManager] setSystemVolumeType:_volumeType];
    }
}

- (void)stopLocalAudio {
    [self.trtcCloud muteLocalAudio:false];
    if (self.audioConfig.isCustomCapture) {
        [self.trtcCloud enableCustomAudioCapture:NO];
        [[CustomAudioFileReader sharedInstance] stop];
        [CustomAudioFileReader sharedInstance].delegate = nil;
    } else {
        [self.trtcCloud stopLocalAudio];
    }
}

- (void)setupTrtcAudio {
    [self.deviceManager setAudioRoute:self.audioConfig.route];
    [self.audioEffectManager enableVoiceEarMonitor:self.audioConfig.isEarMonitoringEnabled];
}

#pragma mark - Stream
- (void)setMixMode:(TRTCTranscodingConfigMode)mixMode {
    self.streamConfig.mixMode = mixMode;
    [self updateCloudMixtureParams];
}

- (void)setQosControlMode:(TRTCQosControlMode)mode {
    self.videoConfig.qosConfig.controlMode = mode;
    [self.trtcCloud setNetworkQosParam:self.videoConfig.qosConfig];
}
- (void)setSmallVideoEnabled:(BOOL)isEnabled {
    self.videoConfig.isSmallVideoEnabled = isEnabled;
    [self.trtcCloud enableEncSmallVideoStream:isEnabled withQuality:self.videoConfig.smallVideoEncConfig];
}

- (void)setPrefersLowQuality:(BOOL)prefersLowQuality {
    self.videoConfig.prefersLowQuality = prefersLowQuality;
    TRTCVideoStreamType type           = prefersLowQuality ? TRTCVideoStreamTypeSmall : TRTCVideoStreamTypeBig;
    [self.trtcCloud setPriorRemoteVideoStreamType:type];
}

- (void)switchTorch {
    self.videoConfig.isTorchOn = !self.videoConfig.isTorchOn;
    [self.deviceManager enableCameraTorch:self.videoConfig.isTorchOn];
}

- (void)setEnableVOD:(BOOL)enableVOD {
    _enableVOD = enableVOD;
    if (self.delegate && [self.delegate respondsToSelector:@selector(roomSettingsManager:enableVOD:)]) {
        [self.delegate roomSettingsManager:self enableVOD:enableVOD];
    }
}

- (void)setEnableAttachVodToTRTC:(BOOL)enableAttachVodToTRTC {
    if (_videoConfig.subSource == TRTCVideoSourceNone) {
        _enableAttachVodToTRTC = enableAttachVodToTRTC;
        if (self.delegate && [self.delegate respondsToSelector:@selector(roomSettingsManager:enableVODAttachToTRTC:)]) {
            [self.delegate roomSettingsManager:self enableVODAttachToTRTC:enableAttachVodToTRTC];
        }
    }
}

- (void)setAutoFocusEnabled:(BOOL)isEnabled {
    self.videoConfig.isAutoFocusOn = isEnabled;
    [self.deviceManager enableCameraAutoFocus:isEnabled];
}

- (void)setMixBackgroundImage:(NSString *)imageId {
    self.streamConfig.backgroundImage = imageId;
    [self updateCloudMixtureParams];
}

- (void)setMixStreamId:(NSString *)streamId {
    self.streamConfig.streamId = streamId;
    [self updateCloudMixtureParams];
}
- (void)updateCloudMixtureParams {
    if (self.streamConfig.mixMode == TRTCTranscodingConfigMode_Unknown) {
        [self.trtcCloud setMixTranscodingConfig:nil];
        return;
    } else if (self.streamConfig.mixMode == TRTCTranscodingConfigMode_Template_PureAudio || self.streamConfig.mixMode == TRTCTranscodingConfigMode_Template_ScreenSharing) {
        TRTCTranscodingConfig *config = [TRTCTranscodingConfig new];
        config.appId                  = TX_APPID;
        config.bizId                  = TX_BIZID;
        config.mode                   = self.streamConfig.mixMode;
        config.streamId               = self.streamConfig.streamId;
        [self.trtcCloud setMixTranscodingConfig:config];
        return;
    }

    int videoWidth  = 720;
    int videoHeight = 1280;

    // 小画面宽高
    int subWidth  = 180;
    int subHeight = 320;

    int offsetX = 5;
    int offsetY = 50;

    int bitrate = 200;

    switch (self.videoConfig.videoEncConfig.videoResolution) {
        case TRTCVideoResolution_160_160: {
            videoWidth  = 160;
            videoHeight = 160;
            subWidth    = 32;
            subHeight   = 48;
            offsetY     = 10;
            bitrate     = 200;
            break;
        }
        case TRTCVideoResolution_320_180: {
            videoWidth  = 192;
            videoHeight = 336;
            subWidth    = 54;
            subHeight   = 96;
            offsetY     = 30;
            bitrate     = 400;
            break;
        }
        case TRTCVideoResolution_320_240: {
            videoWidth  = 240;
            videoHeight = 320;
            subWidth    = 54;
            subHeight   = 96;
            offsetY     = 30;
            bitrate     = 400;
            break;
        }
        case TRTCVideoResolution_480_480: {
            videoWidth  = 480;
            videoHeight = 480;
            subWidth    = 72;
            subHeight   = 128;
            bitrate     = 600;
            break;
        }
        case TRTCVideoResolution_640_360: {
            videoWidth  = 368;
            videoHeight = 640;
            subWidth    = 90;
            subHeight   = 160;
            bitrate     = 800;
            break;
        }
        case TRTCVideoResolution_640_480: {
            videoWidth  = 480;
            videoHeight = 640;
            subWidth    = 90;
            subHeight   = 160;
            bitrate     = 800;
            break;
        }
        case TRTCVideoResolution_960_540: {
            videoWidth  = 544;
            videoHeight = 960;
            subWidth    = 160;
            subHeight   = 288;
            bitrate     = 1000;
            break;
        }
        case TRTCVideoResolution_1280_720: {
            videoWidth  = 720;
            videoHeight = 1280;
            subWidth    = 192;
            subHeight   = 336;
            bitrate     = 1500;
            break;
        }
        case TRTCVideoResolution_1920_1080: {
            videoWidth  = 1088;
            videoHeight = 1920;
            subWidth    = 272;
            subHeight   = 480;
            bitrate     = 1900;
            break;
        }
        default:
            assert(false);
            break;
    }

    TRTCTranscodingConfig *config = [TRTCTranscodingConfig new];
    config.appId                  = TX_APPID;
    config.bizId                  = TX_BIZID;
    config.videoWidth             = videoWidth;
    config.videoHeight            = videoHeight;
    config.videoGOP               = 1;
    config.videoFramerate         = 15;
    config.videoBitrate           = bitrate;
    config.audioSampleRate        = 48000;
    config.audioBitrate           = 64;
    config.audioChannels          = 1;
    config.backgroundImage        = self.streamConfig.backgroundImage;
    config.streamId               = self.streamConfig.streamId;

    // 设置混流后主播的画面位置
    TRTCMixUser *broadCaster = [TRTCMixUser new];
    broadCaster.userId       = self.streamConfig.mixMode == TRTCTranscodingConfigMode_Template_PresetLayout ? PLACE_HOLDER_LOCAL_MAIN : self.params.userId;

    // 设置背景图后，本地画面缩小到左上角，防止背景图被遮挡无法测试
    if (self.streamConfig.backgroundImage.length > 0) {
        broadCaster.rect = CGRectMake(0, 0, videoWidth / 2, videoHeight / 2);
    } else {
        broadCaster.rect = CGRectMake(0, 0, videoWidth, videoHeight);
    }

    NSMutableArray *mixUsers = [NSMutableArray new];
    [mixUsers addObject:broadCaster];

    // 设置混流后各个小画面的位置
    __block int index = 0;
    [self.remoteUserManager.remoteUsers enumerateKeysAndObjectsUsingBlock:^(NSString *userId, TRTCRemoteUserConfig *settings, BOOL *stop) {
        TRTCMixUser *audience = [TRTCMixUser new];
        audience.userId       = self.streamConfig.mixMode == TRTCTranscodingConfigMode_Template_PresetLayout ? PLACE_HOLDER_REMOTE : userId;
        audience.zOrder       = 2 + index;
        audience.roomID       = settings.roomId;
        //辅流判断：辅流的Id为原userId + "-sub"
        if ([userId hasSuffix:@"-sub"]) {
            NSArray *spritStrs = [userId componentsSeparatedByString:@"-"];
            if (spritStrs.count < 2) {
                return;
            }
            NSString *realUserId = self.streamConfig.mixMode == TRTCTranscodingConfigMode_Template_PresetLayout ? PLACE_HOLDER_REMOTE : spritStrs[0];
            audience.userId      = realUserId;
            audience.streamType  = TRTCVideoStreamTypeSub;
        }
        if (index < 3) {
            // 前三个小画面靠右从下往上铺
            audience.rect = CGRectMake(videoWidth - offsetX - subWidth, videoHeight - offsetY - index * subHeight - subHeight, subWidth, subHeight);
        } else if (index < 6) {
            // 后三个小画面靠左从下往上铺
            audience.rect = CGRectMake(offsetX, videoHeight - offsetY - (index - 3) * subHeight - subHeight, subWidth, subHeight);
        } else {
            // 最多只叠加六个小画面
        }

        [mixUsers addObject:audience];
        ++index;
    }];

    // 辅路
    TRTCMixUser *broadCasterSub = [TRTCMixUser new];
    broadCasterSub.zOrder       = 2 + index;
    broadCasterSub.userId       = PLACE_HOLDER_LOCAL_SUB;
    broadCasterSub.streamType   = TRTCVideoStreamTypeSub;
    if (index < 3) {
        // 前三个小画面靠右从下往上铺
        broadCasterSub.rect = CGRectMake(videoWidth - offsetX - subWidth, videoHeight - offsetY - index * subHeight - subHeight, subWidth, subHeight);
    } else if (index < 6) {
        // 后三个小画面靠左从下往上铺
        broadCasterSub.rect = CGRectMake(offsetX, videoHeight - offsetY - (index - 3) * subHeight - subHeight, subWidth, subHeight);
    } else {
        // 最多只叠加六个小画面
    }
    [mixUsers addObject:broadCasterSub];

    config.mixUsers = mixUsers;
    config.mode     = self.streamConfig.mixMode;
    if (!_trtcCloud) {
        _trtcCloud = [TRTCCloud sharedInstance];
    }
    [_trtcCloud setMixTranscodingConfig:config];
}

#pragma mark - TRTCCustomerAudioPacketDeleagate RecvAudioMsgDelegate
- (void)onRecvAudioMsg:(NSString *)userId msg:(NSString *)msg {
    if (self.delegate && [self.delegate respondsToSelector:@selector(onRecvAudioMsg:msg:)]) {
        [self.delegate onRecvAudioMsg:userId msg:msg];
    }
}

#pragma mark - TRTCCloudDelegate
- (void)onLocalRecordComplete:(NSInteger)errCode storagePath:(NSString *)storagePath {
    if([self.delegate respondsToSelector:@selector(onLocalRecordComplete:storagePath:)]){
        [self.delegate onLocalRecordComplete:errCode storagePath:storagePath];
    }
}

@end
