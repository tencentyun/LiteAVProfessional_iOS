//
//  TRTCCloudManager.m
//  TXLiteAVDemo
//
//  Created by bluedang on 2021/5/17.
//  Copyright © 2021 Tencent. All rights reserved.
//

#import "TRTCCloudManager.h"

#import <TCBeautyPanel/TCBeautyPanel.h>
#import <AudioEffectSettingKit/AudioEffectSettingKit.h>
#import "CustomFrameRender.h"
#import "MediaFileSyncReader.h"
#import "AudioQueuePlay.h"
#import "WaterMarkProcessor.h"
#import "GenerateTestUserSig.h"
#import "CustomAudioFileReader.h"

@interface TRTCCloudManager() <TRTCCloudDelegate,
                               MediaFileSyncReaderDelegate,
                               CustomAudioFileReaderDelegate,
                               TRTCVideoRenderDelegate,
                               TRTCAudioFrameDelegate,
                               TRTCVideoFrameDelegate>
@property (strong, nonatomic) TRTCCloud *trtcCloud;
@property (strong, nonatomic) MediaFileSyncReader *mediaReader;
@property (strong, nonatomic) WaterMarkProcessor *waterMarkProcessor;
@property (assign, nonatomic) BOOL timestampWaterMarkEnable;
//@property (strong, nonatomic) AudioQueuePlay* audioPlayer;
//@property (strong, nonatomic) dispatch_queue_t audioPlayerQueue;
@end

@implementation TRTCCloudManager

- (WaterMarkProcessor *)waterMarkProcessor {
    if (!_waterMarkProcessor) {
        _waterMarkProcessor = [[WaterMarkProcessor alloc] init];
    }
    return _waterMarkProcessor;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _trtcCloud = [TRTCCloud sharedInstance];
        _role = TRTCRoleAnchor;
        _videoInputType = TRTCVideoCamera;
        _audioInputType = TRTCAudioMic;
        _volumeType = TXSystemVolumeTypeAuto;
        _audioRoute = TXAudioRouteSpeakerphone;
        _audioQuality = TRTCAudioQualityDefault;
        _roomIdType = TRTCIntRoomId;
        _viewDic = [[NSMutableDictionary alloc] init];
        _isFrontCam = YES;
                
        [_trtcCloud setDelegate:self];
        [_trtcCloud setLocalVideoProcessDelegete:self pixelFormat:TRTCVideoPixelFormat_NV12 bufferType:TRTCVideoBufferType_PixelBuffer];
    }
    return self;
}

- (void)dealloc
{
    _trtcCloud = nil;
    [TRTCCloud destroySharedIntance];
}

- (void)startSpeedTest:(NSString*)userId
            completion:(void(^)(TRTCSpeedTestResult* result,
                                NSInteger completedCount,
                                NSInteger totalCount))completion {
    [_trtcCloud startSpeedTest:SDKAPPID userId:userId userSig:[GenerateTestUserSig genTestUserSig:userId] completion:^(TRTCSpeedTestResult* result, NSInteger completedCount, NSInteger totalCount){
        completion(result, completedCount, totalCount);
    }];
}

- (void)stopSpeedTest {
    [_trtcCloud stopSpeedTest];
}

- (void)setupVideoConfig {
    if (!_videoConfig) { return; }
    
    [self.trtcCloud setVideoEncoderParam:self.videoConfig.videoEncConfig];
    [self.trtcCloud setVideoEncoderMirror:self.videoConfig.isRemoteMirrorEnabled];
    [self.trtcCloud setVideoMuteImage:self.videoConfig.isVideoMuteImage ?
                                     [UIImage imageNamed:@"background"] : nil fps:3];
    [self.trtcCloud setLocalRenderParams:self.videoConfig.localRenderParams];
    [self.trtcCloud setNetworkQosParam:self.videoConfig.qosConfig];
    if (self.videoConfig.isWaterMarkEnabled) {
        UIImage *image = [UIImage imageNamed:@"watermark"];
        [self.trtcCloud setWatermark:image streamType:TRTCVideoStreamTypeBig rect:CGRectMake(0.7, 0.1, 0.2, 0)];
    }
    self.gSensorEnabled = YES;
    self.timestampWaterMarkEnable = NO;
}

- (void)setupAudioConfig {
    self.agcEnabled = true;
    self.aecEnabled = false;
    self.ansEnabled = false;
    self.earMonitoringEnabled = false;
    self.volumeEvaluationEnabled = false;
    self.captureVolume = 100;
    self.playoutVolume = 100;
}

- (void)enterLiveRoom:(NSString*)roomId userId:(NSString*)userId {
    _roomId = roomId;
    _userId = userId;
    
    TRTCParams* params = [TRTCParams new];
    params.sdkAppId = SDKAPPID;
    params.userId = userId;
    params.userSig = [GenerateTestUserSig genTestUserSig:userId];
    params.role = _role;
    if (_roomIdType == TRTCIntRoomId) {
        params.roomId = [roomId intValue];
    } else {
        params.strRoomId = roomId;
    }
    
    
    [_trtcCloud enterRoom:params appScene:TRTCAppSceneLIVE];

    [[_trtcCloud getDeviceManager] setSystemVolumeType:_volumeType];
    [[_trtcCloud getDeviceManager] setAudioRoute:_audioRoute];
    
    _videoConfig = [[TRTCVideoConfig alloc] initWithScene:TRTCAppSceneLIVE];
    _isCrossingRoom = NO;
    
    [self setupVideoConfig];
    [self setupAudioConfig];
}

- (void)switchRole:(TRTCRoleType)role {
    if (_role == role) { return; }
    _role = role;
    
    [_trtcCloud switchRole:role];
    if (role == TRTCRoleAnchor) {
        [_trtcCloud startLocalAudio:_audioQuality];
    } else {
        [_trtcCloud stopLocalAudio];
    }
}

- (void)startLiveWithRoomId:(NSString*)roomId userId:(NSString*)userId {
    [self enterLiveRoom:roomId userId:userId];
    
    if (_videoInputType == TRTCVideoFile) {
        [_trtcCloud setLocalVideoRenderDelegate:self
                                    pixelFormat:TRTCVideoPixelFormat_NV12
                                     bufferType:TRTCVideoBufferType_PixelBuffer];
        [_trtcCloud enableCustomVideoCapture:TRTCVideoStreamTypeBig enable:true];
        [_trtcCloud enableCustomAudioCapture:true];
        [_mediaReader start];
//        [_audioPlayer start];
        return;
    }
    
    if (_audioInputType == TRTCAudioCustom) {
        [_trtcCloud enableCustomAudioCapture:true];
        [CustomAudioFileReader sharedInstance].delegate = self;
        [[CustomAudioFileReader sharedInstance] start:48000 channels:1 framLenInSample:960];
        return;
    }
    
    if (_audioInputType != TRTCAudioNone) {
//        [_trtcCloud setAudioFrameDelegate:nil];
        [_trtcCloud startLocalAudio:_audioQuality];
    }
}

- (void)stopLive {
    if (self.videoInputType == TRTCVideoFile) {
        [_trtcCloud setLocalVideoRenderDelegate:nil
                                    pixelFormat:TRTCVideoPixelFormat_NV12
                                     bufferType:TRTCVideoBufferType_PixelBuffer];
        [_trtcCloud enableCustomVideoCapture:TRTCVideoStreamTypeBig enable:false];
        [_trtcCloud enableCustomAudioCapture:false];
        [_mediaReader stop];
    } else if (self.audioInputType == TRTCAudioCustom){
        [_trtcCloud enableCustomAudioCapture:false];
        [[CustomAudioFileReader sharedInstance] stop];
        [CustomAudioFileReader sharedInstance].delegate = nil;
    } else {
        [_trtcCloud stopLocalAudio];
    }
    [self setLogEnable:false];
//    [_audioPlayer stop];
    [_trtcCloud exitRoom];
    [_viewDic removeAllObjects];
}

- (void)addMainVideoView:(TRTCVideoView*)view userId:(NSString*)userId{
    [view.audioVolumeIndicator setHidden:!_volumeEvaluationEnabled];
    [self.viewDic setObject:view forKey:userId];
}

- (void)removeMainView:(NSString*)userId {
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

- (void)switchCam {
    if (_videoInputType != TRTCVideoCamera) {
        return;
    }

    _isFrontCam = !_isFrontCam;
    [[_trtcCloud getDeviceManager] switchCamera:_isFrontCam];
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

- (void)configBeautyPanel:(TCBeautyPanel*)beautyPanel {
    beautyPanel.actionPerformer = [TCBeautyPanelActionProxy proxyWithSDKObject:_trtcCloud];
}

- (void)configAudioEffectPanel:(AudioEffectSettingView*)audioPanel {
    [audioPanel setAudioEffectManager:[_trtcCloud getAudioEffectManager]];
}
#pragma mark - Screen Capture
- (void)startScreenCapture {
    TRTCVideoEncParam *params = [TRTCVideoEncParam new];
    params.videoResolution = TRTCVideoResolution_1280_720;
    params.videoBitrate = 550;
    params.videoFps = 10;
    [self.trtcCloud startScreenCaptureByReplaykit:params
                                         appGroup:@"group.com.tencent.liteav.RPLiveStreamShare"];
}
- (void)stopScreenCapture {
    [self.trtcCloud stopScreenCapture];
}


#pragma mark - Video config

- (void)setResolution:(TRTCVideoResolution)resolution {
    self.videoConfig.videoEncConfig.videoResolution = resolution;
    [self.trtcCloud setVideoEncoderParam:self.videoConfig.videoEncConfig];
}

- (void)setResolutionMode:(TRTCVideoResolutionMode)resolutionMode {
    self.videoConfig.videoEncConfig.resMode = resolutionMode;
    [self.trtcCloud setVideoEncoderParam:self.videoConfig.videoEncConfig];
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
    [self.trtcCloud muteLocalVideo:isVideoPause];
}

- (void)setVideoFps:(int)videoFps {
    self.videoConfig.videoEncConfig.videoFps = videoFps;
    [self.trtcCloud setVideoEncoderParam:self.videoConfig.videoEncConfig];
}

- (void)setVideoBitrate:(int)videoBitrate {
    self.videoConfig.videoEncConfig.videoBitrate = videoBitrate;
    [self.trtcCloud setVideoEncoderParam:self.videoConfig.videoEncConfig];
}

- (void)setWaterMark:(nullable UIImage*)image inRect:(CGRect)rect {
    [self.trtcCloud setWatermark:image streamType:TRTCVideoStreamTypeBig rect:rect];
    [self.trtcCloud setWatermark:image streamType:TRTCVideoStreamTypeSub rect:rect];
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

- (void)snapshotLocalVideoWithUserId:(NSString*)userId type:(TRTCVideoStreamType)type completionBlock:(void (^)(TXImage *image))completionBlock {
    [self.trtcCloud snapshotVideo:userId type:type sourceType:TRTCSnapshotSourceTypeView completionBlock:completionBlock];
}

- (void)setGSensorEnabled:(BOOL)gSensorEnabled {
    _gSensorEnabled = gSensorEnabled;
    TRTCGSensorMode mode = gSensorEnabled ? TRTCGSensorMode_UIAutoLayout : TRTCGSensorMode_Disable;
    [self.trtcCloud setGSensorMode:mode];
}

- (void)setFlashLightEnabled:(BOOL)flashLightEnabled {
    _flashLightEnabled = flashLightEnabled;
    [[self.trtcCloud getDeviceManager] enableCameraTorch:flashLightEnabled];
}

#pragma mark - Audio config
- (void)setExperimentConfig:(NSString *)key params:(NSDictionary *)params {
    NSDictionary *json = @{
        @"api": key,
        @"params": params
    };
    [self.trtcCloud callExperimentalAPI:[self jsonStringFrom:json]];
}

- (NSString *)jsonStringFrom:(NSDictionary *)dict {
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dict options:0 error:NULL];
    return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
}

- (void)setVolumeType:(TXSystemVolumeType)volumeType {
    _volumeType = volumeType;
    [[_trtcCloud getDeviceManager] setSystemVolumeType:_volumeType];
}

- (void)setAgcEnabled:(BOOL)agcEnabled {
    _agcEnabled = agcEnabled;
    [self setExperimentConfig:@"enableAudioAGC" params:@{ @"enable": @(agcEnabled) }];
}

- (void)setAecEnabled:(BOOL)aecEnabled {
    _aecEnabled = aecEnabled;
    [self setExperimentConfig:@"enableAudioAEC" params:@{ @"enable": @(aecEnabled) }];
}

- (void)setAnsEnabled:(BOOL)ansEnabled {
    _ansEnabled = ansEnabled;
    [self setExperimentConfig:@"enableAudioANS" params:@{ @"enable": @(ansEnabled) }];
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
    _earMonitoringEnabled = earMonitoringEnabled;
    [[self.trtcCloud getAudioEffectManager] enableVoiceEarMonitor:earMonitoringEnabled];
}

- (void)setAudioRoute:(TXAudioRoute)audioRoute {
    _audioRoute = audioRoute;
    [[self.trtcCloud getDeviceManager] setAudioRoute:audioRoute];
}

- (void)setVolumeEvaluationEnabled:(BOOL)volumeEvaluationEnabled {
    _volumeEvaluationEnabled = volumeEvaluationEnabled;
    [self.trtcCloud enableAudioVolumeEvaluation:volumeEvaluationEnabled ? 300 : 0];
    for (TRTCVideoView *view in [self.viewDic allValues]) {
        [view.audioVolumeIndicator setHidden:!volumeEvaluationEnabled];
    }
}

#pragma mark - Live Player
- (NSString *)getCdnUrlOfUser:(NSString *)userId {
    return [NSString stringWithFormat:@"http://%@.liveplay.myqcloud.com/live/%@_%@_%@_main.flv", @(TX_BIZID), @(SDKAPPID), self.roomId, userId];
}

- (void)closeStreamMix {
    [self.trtcCloud setMixTranscodingConfig:nil];
}

- (void)updateStreamMix {
    int videoWidth  = 720;
    int videoHeight = 1280;
    
    // 小画面宽高
    int subWidth  = 180;
    int subHeight = 320;
    
    int offsetX = 5;
    int offsetY = 50;
    
    int bitrate = 200;
    
    TRTCTranscodingConfig* config = [TRTCTranscodingConfig new];
    config.appId = TX_APPID;
    config.bizId = TX_BIZID;
    config.videoWidth = videoWidth;
    config.videoHeight = videoHeight;
    config.videoGOP = 1;
    config.videoFramerate = 15;
    config.videoBitrate = bitrate;
    config.audioSampleRate = 48000;
    config.audioBitrate = 64;
    config.audioChannels = 1;
    
    NSMutableArray* mixUsers = [NSMutableArray new];
    
    for (int index = 0; index < 7; index++) {
        TRTCMixUser* mixUser = [TRTCMixUser new];
        if (!index) {
            mixUser.userId = @"$PLACE_HOLDER_LOCAL_MAIN$";
            mixUser.rect = CGRectMake(0, 0, videoWidth, videoHeight);
        } else {
            mixUser.userId = @"$PLACE_HOLDER_REMOTE$";
            index -= 1;
            if (index < 3) {
                // 前三个小画面靠右从下往上铺
                mixUser.rect = CGRectMake(videoWidth - offsetX - subWidth, videoHeight - offsetY - index * subHeight - subHeight, subWidth, subHeight);
            } else if (index < 6) {
                // 后三个小画面靠左从下往上铺
                mixUser.rect = CGRectMake(offsetX, videoHeight - offsetY - (index - 3) * subHeight - subHeight, subWidth, subHeight);
            } else {
                // 最多只叠加六个小画面
            }
            index++;
        }
        mixUser.zOrder = index;
        mixUser.roomID = self.roomId;
        [mixUsers addObject:mixUser];
    }
        
    config.mixUsers = mixUsers;
    config.mode = TRTCTranscodingConfigMode_Template_PresetLayout;
    [self.trtcCloud setMixTranscodingConfig:config];
}

#pragma mark - pk room

- (void)startCrossRoom:(NSString*)roomId userId:(NSString*)userId {
    NSDictionary* pkParams = @{
        @"strRoomId" : roomId,
        @"userId" : userId,
    };
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:pkParams options:0 error:nil];
    NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    
    [self.trtcCloud connectOtherRoom:jsonString];
}

- (void)stopCrossRomm {
    self.isCrossingRoom = NO;
    
    [self.trtcCloud disconnectOtherRoom];
}

#pragma mark - SEI message

- (void)sendSEIMessage:(NSString*)message {
    [self.trtcCloud sendSEIMsg:[message dataUsingEncoding:NSUTF8StringEncoding] repeatCount:1];
}

#pragma mark - remote config
- (void)setRemoteVideoMute:(BOOL)enable userId:(NSString*)userId {
    [self.trtcCloud muteRemoteVideoStream:userId mute:enable];
}
- (void)setRemoteAudioMute:(BOOL)enable userId:(NSString*)userId {
    [self.trtcCloud muteRemoteAudio:userId mute:enable];
}
- (void)setRemoteVolume:(int)volume userId:(NSString*)userId {
    [self.trtcCloud setRemoteAudioVolume:userId volume:volume];
}

- (void)setRemoteRenderParams:(TRTCRenderParams*)params userId:(NSString*)userId {
    [self.trtcCloud setRemoteRenderParams:userId streamType:TRTCVideoStreamTypeBig params:params];
}

- (void)setRemoteSubStreamRenderParams:(TRTCRenderParams*)params userId:(NSString*)userId {
    [self.trtcCloud setRemoteRenderParams:userId streamType:TRTCVideoStreamTypeSub params:params];
}

#pragma mark - Media File

- (void)setCustomSourceAsset:(AVAsset *)customSourceAsset {
    _customSourceAsset = customSourceAsset;
    
//    [self.trtcCloud setAudioFrameDelegate:self];

    self.mediaReader = nil;
    self.mediaReader = [[MediaFileSyncReader alloc] initWithAVAsset:_customSourceAsset];
    [self.mediaReader setDelegate:self];
    
//    self.audioPlayer = nil;
//    self.audioPlayer = [[AudioQueuePlay alloc] init];
    
//    dispatch_queue_attr_t attr = dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_SERIAL, QOS_CLASS_DEFAULT, 0);
//    _audioPlayerQueue = dispatch_queue_create("com.media.audioplayer", attr);
}

#pragma mark - MediaFileSyncReader Delegate
- (void)onReadVideoFrameAtFrameIntervals:(CVImageBufferRef)imageBuffer timeStamp:(UInt64)timeStamp {
    TRTCVideoFrame* videoFrame = [TRTCVideoFrame new];
    videoFrame.bufferType = TRTCVideoBufferType_PixelBuffer;
    videoFrame.pixelFormat = TRTCVideoPixelFormat_NV12;
    videoFrame.pixelBuffer = imageBuffer;
    TRTCVideoRotation rotation = TRTCVideoRotation_0;
    if (self.mediaReader.angle == 90) {
        rotation = TRTCVideoRotation_90;
    }
    else if (self.mediaReader.angle == 180) {
        rotation = TRTCVideoRotation_180;
    }
    else if (self.mediaReader.angle == 270) {
        rotation = TRTCVideoRotation_270;
    }
    videoFrame.rotation = rotation;

    [self.trtcCloud sendCustomVideoData:TRTCVideoStreamTypeBig frame:videoFrame];
}

- (void)onReadAudioFrameAtFrameIntervals:(NSData *)pcmData timeStamp:(UInt64)timeStamp {
    TRTCAudioFrame *audioFrame = [TRTCAudioFrame new];
    audioFrame.channels = _mediaReader.audioChannels;
    audioFrame.sampleRate = _mediaReader.audioSampleRate;
    audioFrame.data = pcmData;
    
    [self.trtcCloud sendCustomAudioData:audioFrame];
}

#pragma mark - CustomAudioFileReaderDelegate

- (void)onAudioCapturePcm:(NSData *)pcmData sampleRate:(int)sampleRate channels:(int)channels ts:(uint32_t)timestampMs {
    TRTCAudioFrame * frame = [[TRTCAudioFrame alloc] init];
    frame.data = pcmData;
    frame.sampleRate = sampleRate;
    frame.channels = channels;
    frame.timestamp = timestampMs;
    
    [self.trtcCloud sendCustomAudioData:frame];
}

#pragma mark - TRTC Delegate

- (void)onRemoteUserEnterRoom:(NSString *)userId {
    TRTCVideoView* videoView = [[TRTCVideoView alloc] init];
    [videoView setUserId:userId];
    [videoView.audioVolumeIndicator setHidden:!_volumeEvaluationEnabled];

    self.viewDic[userId] = videoView;
    if (self.audioInputType != TRTCAudioCustom) {
        return;
    }
}

- (void)onRemoteUserLeaveRoom:(NSString *)userId reason:(NSInteger)reason {
    [self.viewDic[userId] removeFromSuperview];
    [self.viewDic removeObjectForKey:userId];
    
    if (_isCrossingRoom && [self.crossUserId isEqualToString:userId]) {
        _isCrossingRoom = NO;
    }
}

- (void)onUserSubStreamAvailable:(NSString *)userId available:(BOOL)available {
    NSString *subUserId = [[NSString alloc] initWithFormat:@"%@-sub", userId];

    if (available) {
        TRTCVideoView* videoView = [[TRTCVideoView alloc] init];
        [videoView setUserId:subUserId];
        [videoView.audioVolumeIndicator setHidden:!_volumeEvaluationEnabled];
        self.viewDic[subUserId] = videoView;
        videoView.userConfig.isSubStream = true;

        [self.trtcCloud startRemoteView:userId streamType:TRTCVideoStreamTypeSub
                                   view:self.viewDic[subUserId]];
        [self.trtcCloud setRemoteRenderParams:userId streamType:TRTCVideoStreamTypeSub params:videoView.userConfig.renderParams];
    } else {
        [self.viewDic[subUserId] removeFromSuperview];
        [self.viewDic removeObjectForKey:subUserId];
        [self.trtcCloud stopRemoteView:userId streamType:TRTCVideoStreamTypeSub];
    }
    if ([self.delegate respondsToSelector:@selector(onUserVideoAvailable:available:)]) {
        [self.delegate onUserVideoAvailable:subUserId available:available];
    }
}

- (void)onUserVideoAvailable:(NSString *)userId available:(BOOL)available {
    if (available) {
        [self.trtcCloud startRemoteView:userId streamType:TRTCVideoStreamTypeBig
                                   view:self.viewDic[userId]];
        TRTCVideoView* videoView = self.viewDic[userId];
        [self setRemoteVideoMute:videoView.userConfig.isVideoMuted userId:userId];
        [_trtcCloud setDebugViewMargin:userId margin:UIEdgeInsetsMake(0.1, 0.05, 0.2, 0.1)];
    } else {
        [self.trtcCloud stopRemoteView:userId streamType:TRTCVideoStreamTypeBig];
    }

    if ([self.delegate respondsToSelector:@selector(onUserVideoAvailable:available:)]) {
        [self.delegate onUserVideoAvailable:userId available:available];
    }
}

- (void)onUserVoiceVolume:(NSArray<TRTCVolumeInfo *> *)userVolumes totalVolume:(NSInteger)totalVolume {
    for (TRTCVolumeInfo *info in userVolumes) {
        NSString* userId;
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

- (void)onRecvSEIMsg:(NSString *)userId message:(NSData *)message {
    if ([self.delegate respondsToSelector:@selector(onRecvSEIMsg:message:)]) {
        [self.delegate onRecvSEIMsg:userId message:message];
    }
}

- (void)onConnectOtherRoom:(NSString *)userId errCode:(TXLiteAVError)errCode errMsg:(NSString *)errMsg {
    if (errCode == ERR_NULL) {
        self.isCrossingRoom = true;
        self.crossUserId = userId;
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

#pragma mark - TRTCVideoRenderDelegate

- (void)onRenderVideoFrame:(TRTCVideoFrame *)frame userId:(NSString *)userId
                streamType:(TRTCVideoStreamType)streamType {
    CFRetain(frame.pixelBuffer);
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        [CustomFrameRender renderImageBuffer:frame.pixelBuffer forView:weakSelf.viewDic[weakSelf.userId]];
        CFRelease(frame.pixelBuffer);
    });
}

#pragma mark - TRTCAudioFrameDelegate

- (void)onMixedAllAudioFrame:(TRTCAudioFrame *)frame {
//    __weak typeof(self) weakSelf = self;
//    NSData* data = frame.data;
//    dispatch_async(_audioPlayerQueue, ^{
//        [weakSelf.audioPlayer playWithData:data];
//    });
}

#pragma mark - TRTCVideoFrameDelegate
- (uint32_t)onProcessVideoFrame:(TRTCVideoFrame *_Nonnull)srcFrame dstFrame:(TRTCVideoFrame *_Nonnull)dstFrame {
    if (self.timestampWaterMarkEnable) {
        self.waterMarkProcessor.pixelBuffer = srcFrame.pixelBuffer;
        dstFrame.pixelBuffer = self.waterMarkProcessor.outputPixelBuffer;
    } else {
        dstFrame.pixelBuffer = srcFrame.pixelBuffer;
    }
    return 0;
}

@end

