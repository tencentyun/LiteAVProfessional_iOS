//
//  TRTCChorusManager.m
//  TXLiteAVDemo
//
//  Created by zanhanding on 2021/7/2.
//  Copyright © 2021 Tencent. All rights reserved.
//

#import "TRTCChorusManager.h"
#import "TXAudioEffectManager.h"
#import "TRTCCloud.h"
#import "TXLiveBase.h"

#if defined(ENABLE_PUSH) && defined(ENABLE_PLAY)
#import "V2TXLivePusher.h"
#import "V2TXLivePlayer.h"
#endif

//通用宏定义
#define CHORUS_WEAKIFY(x) __weak __typeof(x) weak_##x = x
#define CHORUS_STRONGIFY_OR_RETURN(x) __strong __typeof(weak_##x) x = weak_##x; if (x == nil) {return;};
#define CHORUS_LOG_TAG TRTCChorusManager
//麦上相关
#define kStartChorusMsg @"startChorus"
#define kStopChorusMsg @"stopChorus"
#define CHORUS_MUSIC_START_DELAY 1000
#define CHORUS_PRELOAD_MUSIC_DELAY 400
//麦下相关
#define CHORUS_SEI_PAYLOAD_TYPE 242
#define V2TXLiveMode_SIMPLE 101
#define kMusicCurrentTs @"musicCurrentTS"

@interface TRTCCloud(ChorusLog)
// 打印一些合唱的关键log到本地日志中
- (void)apiLog:(NSString*)log;
@end

@interface TRTCChorusManager()
#if defined(ENABLE_PUSH) && defined(ENABLE_PLAY)
<V2TXLivePusherObserver, V2TXLivePlayerObserver, TRTCCloudDelegate>
#endif
//合唱麦上相关
@property (nonatomic) NSInteger startPlayChorusMusicTs;
@property (nonatomic) NSInteger requestStopChorusTs;
@property (strong, nonatomic) NSTimer* chorusLongTermTimer;
@property (strong, nonatomic) dispatch_source_t delayStartChorusMusicTimer;
@property (strong, nonatomic) dispatch_source_t preloadMusicTimer;
@property (strong, nonatomic) TXAudioMusicParam *musicParam;
@property (nonatomic) NSInteger musicDuration;

#if defined(ENABLE_PUSH) && defined(ENABLE_PLAY)
//合唱cdn相关
@property (strong, nonatomic) V2TXLivePusher *pusher;
@property (strong, nonatomic) V2TXLivePlayer *player;
#endif

@end

@implementation TRTCChorusManager {
    BOOL _isChorusOn;
}
- (instancetype)init {
    if (self = [super init]){
        [[TRTCCloud sharedInstance] apiLog:@"TRTCChorusManager init"];
        [TRTCCloud sharedInstance].delegate = self;
        // 防止 NSTimer 与当前对象循环引用
        CHORUS_WEAKIFY(self);
        self.chorusLongTermTimer = [NSTimer scheduledTimerWithTimeInterval:2.0 repeats:YES block:^(NSTimer * _Nonnull timer) {
            CHORUS_STRONGIFY_OR_RETURN(self);
            [self checkMusicProgress];
            [self sendStartChorusMsg];
        }];
        [self.chorusLongTermTimer setFireDate:[NSDate distantFuture]];
        self.musicParam = [[TXAudioMusicParam alloc] init];
        self.musicParam.ID = CHORUS_MUSIC_ID;
        self.musicParam.publish = NO;//合唱模式下音乐不推流
        //注意，如果 bgm 后缀非 mp3，请相应改动下面这行代码
        self.musicParam.path = [[NSBundle mainBundle] pathForResource:kChorusMusicName ofType:@"mp3"];
        // 预加载BGM
        [self preloadMusic:[[NSBundle mainBundle] pathForResource:kChorusMusicName ofType:@"mp3"] startMs:0];
        self.musicDuration = [[self audioEffecManager] getMusicDurationInMS:self.musicParam.path];
        [[self audioEffecManager] setAllMusicVolume:20];
        return self;
    }
    return nil;
}

- (void)dealloc {
    [[TRTCCloud sharedInstance] apiLog:@"TRTCChorusManager dealloc"];
    [self.chorusLongTermTimer setFireDate:[NSDate distantFuture]];
    [self.chorusLongTermTimer invalidate];
    self.chorusLongTermTimer = nil;
    [[self audioEffecManager] stopPlayMusic:CHORUS_MUSIC_ID];
}

- (BOOL)startChorus {
    //开始合唱
    if (![self isNtpReady]) {
        [[TRTCCloud sharedInstance] apiLog:@"TRTCChorusManager startChorus failed, ntp is not ready, please call [TXLiveBase updateNetworkTime] first!"];
        return NO;
    }
    self.startPlayChorusMusicTs = [TXLiveBase getNetworkTimestamp] + CHORUS_MUSIC_START_DELAY;
    [[TRTCCloud sharedInstance] apiLog:[NSString stringWithFormat:@"TRTCChorusManager startChorus, schedule time:%ld, current_ntp:%ld", self.startPlayChorusMusicTs, [TXLiveBase getNetworkTimestamp]]];
    [self.chorusLongTermTimer setFireDate:[NSDate distantPast]];
    [self schedulePlayMusic:CHORUS_MUSIC_START_DELAY];
    [self sendStartChorusMsg];
    // 若成功合唱，通知合唱已开始
    _isChorusOn = YES;
    [self asyncDelegate:^{
        if (self.delegate && [self.delegate respondsToSelector:@selector(onChorusStart:message:)]) {
            [[TRTCCloud sharedInstance] apiLog:[NSString stringWithFormat:@"TRTCChorusManager calling onChorusStart, reason:ChorusStartReasonLocal, current_ntp:%ld", [TXLiveBase getNetworkTimestamp]]];
            [self.delegate onChorusStart:ChorusStartReasonLocal message:@"local user launched chorus"];
        }
    }];
    return YES;
}

- (void)stopChorus {//结束合唱
    if (!self.isChorusOn) {//若未进行合唱，直接返回
        [[TRTCCloud sharedInstance] apiLog:[NSString stringWithFormat:@"TRTCChorusManager stopChorus returned directly, current_ntp:%ld", [TXLiveBase getNetworkTimestamp]]];
        return;
    }
    [[TRTCCloud sharedInstance] apiLog:[NSString stringWithFormat:@"TRTCChorusManager stopChorus, current_ntp:%ld", [TXLiveBase getNetworkTimestamp]]];
    //合唱中，清理状态
    [self.chorusLongTermTimer setFireDate:[NSDate distantFuture]];
    self.requestStopChorusTs = [TXLiveBase getNetworkTimestamp];
    [self sendStopChorusMsg];
    [[self audioEffecManager] stopPlayMusic:CHORUS_MUSIC_ID];
    [self clearChorusState];
    //通知合唱已结束
    _isChorusOn = NO;
    [self asyncDelegate:^{
        if (self.delegate && [self.delegate respondsToSelector:@selector(onChorusStop:message:)]) {
            [[TRTCCloud sharedInstance] apiLog:[NSString stringWithFormat:@"TRTCChorusManager calling onChorusStop, reason:ChorusStopReasonLocal, current_ntp:%ld", [TXLiveBase getNetworkTimestamp]]];
            [self.delegate onChorusStop:ChorusStopReasonLocal message:@"local user stopped chorus"];
        }
    }];
}


- (BOOL)startCdnPush:(NSString *)url {
#if defined(ENABLE_PUSH) && defined(ENABLE_PLAY)
    if (!self.pusher) {
        [self initPusher];
    }
    V2TXLiveCode result = [self.pusher startPush:url];
    [[TRTCCloud sharedInstance] apiLog:[NSString stringWithFormat:@"TRTCChorusManager startCdnPush finished, result:%ld, current_ntp:%ld", result, [TXLiveBase getNetworkTimestamp]]];
    return result == V2TXLIVE_OK;
#else
    return NO;
#endif
}

- (void)stopCdnPush {
#if defined(ENABLE_PUSH) && defined(ENABLE_PLAY)
    if (!self.pusher) {
        [[TRTCCloud sharedInstance] apiLog:[NSString stringWithFormat:@"TRTCChorusManager stopCdnPush failed, pusher is nil, current_ntp:%ld", [TXLiveBase getNetworkTimestamp]]];
    }
    [[TRTCCloud sharedInstance] apiLog:[NSString stringWithFormat:@"TRTCChorusManager stopCdnPush, current_ntp:%ld", [TXLiveBase getNetworkTimestamp]]];
    [self.pusher stopPush];
#endif
}

- (BOOL)startCdnPlay:(NSString *)url view:(TXView *)view {
#if defined(ENABLE_PUSH) && defined(ENABLE_PLAY)
    if (!self.player) {
        [self initPlayer];
    }
    [self.player setRenderView:view];
    V2TXLiveCode result = [self.player startPlay:url];
    [[TRTCCloud sharedInstance] apiLog:[NSString stringWithFormat:@"TRTCChorusManager startCdnPlay finished, url:%@, view:%p, result:%ld, current_ntp:%ld", url, view, result, [TXLiveBase getNetworkTimestamp]]];
    return result == V2TXLIVE_OK;
#else
    return NO;
#endif
}

- (void)stopCdnPlay {
#if defined(ENABLE_PUSH) && defined(ENABLE_PLAY)
    if (!self.player) {
        [[TRTCCloud sharedInstance] apiLog:[NSString stringWithFormat:@"TRTCChorusManager stopCdnPlay failed, player is nil, current_ntp:%ld", [TXLiveBase getNetworkTimestamp]]];
    }
    [[TRTCCloud sharedInstance] apiLog:[NSString stringWithFormat:@"TRTCChorusManager stopCdnPlay, current_ntp:%ld", [TXLiveBase getNetworkTimestamp]]];
    [self.player stopPlay];
#endif
}


#pragma mark - TRTCCloudDelegate
- (void)onRecvCustomCmdMsgUserId:(NSString *)userId cmdID:(NSInteger)cmdID seq:(UInt32)seq message:(NSData *)message {
    if (![self isNtpReady]) {//ntp校时为完成，直接返回
        [[TRTCCloud sharedInstance] apiLog:@"TRTCChorusManager ignore command, ntp is not ready"];;
        return;
    }
    
    NSString *msg = [[NSString alloc] initWithData:message encoding:NSUTF8StringEncoding];
    if(msg == nil) {
        [[TRTCCloud sharedInstance] apiLog:[NSString stringWithFormat:@"TRTCChorusManager ignore command, userId:%@, msg:%@, current_ntp:%ld", userId, msg, [TXLiveBase getNetworkTimestamp]]];
        return;
    }
    
    NSError *error;
    NSDictionary *json = [NSJSONSerialization JSONObjectWithData:[msg dataUsingEncoding:NSUTF8StringEncoding]
                                                        options:NSJSONReadingMutableContainers
                                                        error:&error];
    if(error) {
        [[TRTCCloud sharedInstance] apiLog:[NSString stringWithFormat:@"TRTCChorusManager ignore command, userId:%@, json error:%@, current_ntp:%ld", userId, error, [TXLiveBase getNetworkTimestamp]]];
        return;
    }
    
    NSObject *cmdObj = [json objectForKey:@"cmd"];
    if(![cmdObj isKindOfClass:[NSString class]]) {
        [[TRTCCloud sharedInstance] apiLog:[NSString stringWithFormat:@"TRTCChorusManager ignore command, userId:%@, cmdObj is not a NSString, current_ntp:%ld", userId, [TXLiveBase getNetworkTimestamp]]];
        return;
    }
    
    NSString *cmd = (NSString *)cmdObj;
    
    if ([cmd isEqualToString:kStartChorusMsg]) {
        NSObject *startPlayMusicTsObj = [json objectForKey:@"startPlayMusicTS"];
        if (!startPlayMusicTsObj || (![startPlayMusicTsObj isKindOfClass:[NSNumber class]])){
            [[TRTCCloud sharedInstance] apiLog:[NSString stringWithFormat:@"TRTCChorusManager ignore start command, userId:%@, startPlayMusicTS not found, current_ntp:%ld", userId, [TXLiveBase getNetworkTimestamp]]];
            return;
        }
        NSInteger startPlayMusicTs = ((NSNumber *)startPlayMusicTsObj).longLongValue;
        if (startPlayMusicTs < self.requestStopChorusTs) {
            //当前收到的命令是在请求停止合唱之前发出的，需要忽略掉，否则会导致请求停止后又开启了合唱
            [[TRTCCloud sharedInstance] apiLog:[NSString stringWithFormat:@"TRTCChorusManager receive kStartChorusMsg that sent before requesting stop, ignore. userId:%@, startPlayMusicTs:%ld, requestStopChorusTs:%ld, current_ntp:%ld", userId, startPlayMusicTs, self.requestStopChorusTs, [TXLiveBase getNetworkTimestamp]]];
            return;
        }
        if (self.isChorusOn == NO) {
            NSInteger startDelayMS = startPlayMusicTs - [TXLiveBase getNetworkTimestamp];
            if (startDelayMS <= -self.musicDuration) {
                //若 delayMs 为负数，代表约定的合唱开始时间在当前时刻之前
                //进一步，若 delayMs 为负，并且绝对值大于 BGM 时长，证明此时合唱已经结束了，应当忽略此次消息
                [self clearChorusState];
                [[TRTCCloud sharedInstance] apiLog: [NSString stringWithFormat:@"TRTCChorusManager ignore command, chorus is over, userId:%@, startPlayMusicTs:%ld current_ntp:%ld", userId, startPlayMusicTs, [TXLiveBase getNetworkTimestamp]]];
                return;
            }
            [[TRTCCloud sharedInstance] apiLog:[NSString stringWithFormat:@"TRTCChorusManager schedule time:%ld, delay:%ld, current_ntp:%ld", startPlayMusicTs, startDelayMS, [TXLiveBase getNetworkTimestamp]]];
            //副唱开始合唱后，也发送 kStartChorusMsg 信令，这样若主唱重进房则可恢复合唱进度
            self.startPlayChorusMusicTs = startPlayMusicTs;
            [self.chorusLongTermTimer setFireDate:[NSDate distantPast]];
            [self schedulePlayMusic:(startDelayMS)];
            // 通知合唱已开始
            _isChorusOn = YES;
            [self asyncDelegate:^{
                if (self.delegate && [self.delegate respondsToSelector:@selector(onChorusStart:message:)]) {
                    [[TRTCCloud sharedInstance] apiLog:[NSString stringWithFormat:@"TRTCChorusManager calling onChorusStart, reason:ChorusStartReasonRemote, current_ntp:%ld", [TXLiveBase getNetworkTimestamp]]];
                    [self.delegate onChorusStart:ChorusStartReasonRemote message:@"remote user launched chorus"];
                }
            }];
        }
    } else if ([cmd isEqualToString:kStopChorusMsg]) {
        NSObject *requestStopTsObj = [json objectForKey:@"requestStopTS"];
        if (!requestStopTsObj || (![requestStopTsObj isKindOfClass:[NSNumber class]])) {
            [[TRTCCloud sharedInstance] apiLog:[NSString stringWithFormat:@"TRTCChorusManager ignore stop command, requestStopTS not found, userId:%@, current_ntp:%ld", userId, [TXLiveBase getNetworkTimestamp]]];
            return;
        }
        self.requestStopChorusTs = ((NSNumber *)requestStopTsObj).longLongValue;
        [[TRTCCloud sharedInstance] apiLog:[NSString stringWithFormat:@"TRTCChorusManager receive stop command, userId:%@, requestStopTS:%ld, current_ntp:%ld", userId, self.requestStopChorusTs, [TXLiveBase getNetworkTimestamp]]];
        [[self audioEffecManager] stopPlayMusic:CHORUS_MUSIC_ID];
        [self clearChorusState];
        // 通知合唱已结束
        _isChorusOn = NO;
        [self asyncDelegate:^{
            if (self.delegate && [self.delegate respondsToSelector:@selector(onChorusStop:message:)]) {
                [[TRTCCloud sharedInstance] apiLog:[NSString stringWithFormat:@"TRTCChorusManager calling onChorusStop, reason:ChorusStopReasonRemote, current_ntp:%ld", [TXLiveBase getNetworkTimestamp]]];
                [self.delegate onChorusStop:ChorusStopReasonRemote message:@"remote user stopped chorus"];
            }
        }];
    }
}

#if defined(ENABLE_PUSH) && defined(ENABLE_PLAY)
-(BOOL)isCdnPushing {
    return self.pusher.isPushing;
}

-(BOOL)isCdnPlaying {
    return self.player.isPlaying;
}

#pragma mark - V2TXLivePlayerObserver
- (void)onReceiveSeiMessage:(id<V2TXLivePlayer>)player payloadType:(int)payloadType data:(NSData *)data {
    NSString *msg = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    if(msg == nil) {
//        [[TRTCCloud sharedInstance] apiLog:[NSString stringWithFormat:@"TRTCChorusManager onReceiveSeiMessage ignored, msessage is nil, current_ntp:%ld", [TXLiveBase getNetworkTimestamp]]];
        return;
    }
    
    NSError *error;
    NSDictionary *json = [NSJSONSerialization JSONObjectWithData:[msg dataUsingEncoding:NSUTF8StringEncoding]
                                                        options:NSJSONReadingMutableContainers
                                                        error:&error];
    if(!error) {
        NSObject *progressObj = [json objectForKey:kMusicCurrentTs];
        if (progressObj && [progressObj isKindOfClass:[NSNumber class]]) {
            NSInteger progress = ((NSNumber *)progressObj).integerValue;
            //通知歌曲进度，用户会在这里进行歌词的滚动
            [self asyncDelegate:^{
                if (self.delegate && [self.delegate respondsToSelector:@selector(onMusicPlayProgress:duration:)]) {
                    [self.delegate onMusicPlayProgress:progress duration:self.musicDuration];
                }
            }];
        } else {
            [[TRTCCloud sharedInstance] apiLog:[NSString stringWithFormat:@"TRTCChorusManager onReceiveSeiMessage ignored, music progress not found, current_ntp:%ld", [TXLiveBase getNetworkTimestamp]]];
        }
    } else {
        [[TRTCCloud sharedInstance] apiLog:[NSString stringWithFormat:@"TRTCChorusManager onReceiveSeiMessage ignored, JSONObjectWithData error:%@, current_ntp:%ld", error.localizedDescription, [TXLiveBase getNetworkTimestamp]]];
    }
}

- (void)onAudioLoading:(id<V2TXLivePlayer>)player extraInfo:(NSDictionary *)extraInfo {
    NSLog(@"----- onAudioLoading");
    if (self.delegate && [self.delegate respondsToSelector:@selector(onCdnPlayStatusUpdate:)]) {
        [[TRTCCloud sharedInstance] apiLog:[NSString stringWithFormat:@"TRTCChorusManager calling onCdnPlayStatusUpdate, status:onLoading, current_ntp:%ld", [TXLiveBase getNetworkTimestamp]]];
        [self.delegate onCdnPlayStatusUpdate:CdnPlayStatusLoading];
    }
}

- (void)onAudioPlaying:(id<V2TXLivePlayer>)player firstPlay:(BOOL)firstPlay extraInfo:(NSDictionary *)extraInfo {
    NSLog(@"----- onAudioPlaying firstPlay: %d",firstPlay);
    if (self.delegate && [self.delegate respondsToSelector:@selector(onCdnPlayStatusUpdate:)]) {
        [[TRTCCloud sharedInstance] apiLog:[NSString stringWithFormat:@"TRTCChorusManager calling onCdnPlayStatusUpdate, status:onPlaying, current_ntp:%ld", [TXLiveBase getNetworkTimestamp]]];
        [self.delegate onCdnPlayStatusUpdate:CdnPlayStatusPlaying];
    }
}

- (void)onError:(id<V2TXLivePlayer>)player
           code:(V2TXLiveCode)code
        message:(NSString *)msg
      extraInfo:(NSDictionary *)extraInfo {
    if (code == V2TXLIVE_ERROR_DISCONNECTED) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(onCdnPlayStatusUpdate:)]) {
            [[TRTCCloud sharedInstance] apiLog:[NSString stringWithFormat:@"TRTCChorusManager calling onCdnPlayStatusUpdate, status:stop, current_ntp:%ld", [TXLiveBase getNetworkTimestamp]]];
            [self.delegate onCdnPlayStatusUpdate:CdnPlayStatusStopped];
        }
    }
    [[TRTCCloud sharedInstance] apiLog:[NSString stringWithFormat:@"TRTCChorusManager player onError, code:%ld, msg:%@, current_ntp:%ld", code, msg, [TXLiveBase getNetworkTimestamp]]];
}

- (void)onWarning:(id<V2TXLivePlayer>)player
             code:(V2TXLiveCode)code
          message:(NSString *)msg
        extraInfo:(NSDictionary *)extraInfo {
    [[TRTCCloud sharedInstance] apiLog:[NSString stringWithFormat:@"TRTCChorusManager player onWarning, code:%ld, msg:%@, current_ntp:%ld", code, msg, [TXLiveBase getNetworkTimestamp]]];
}

#pragma mark - V2TXLivePusherObserver
- (void)onPushStatusUpdate:(V2TXLivePushStatus)status message:(NSString *)msg extraInfo:(NSDictionary *)extraInfo {
    [self asyncDelegate:^{
        [[TRTCCloud sharedInstance] apiLog:[NSString stringWithFormat:@"TRTCChorusManager calling onCdnPushStatusUpdate, v2_status:%ld, current_ntp:%ld", status, [TXLiveBase getNetworkTimestamp]]];
        if (self.delegate && [self.delegate respondsToSelector:@selector(onCdnPushStatusUpdate:)]) {
            CdnPushStatus result;
            switch (status) {
                case V2TXLivePushStatusConnecting:
                    result = CdnPushStatusConnecting;
                    break;
                case V2TXLivePushStatusDisconnected:
                    result = CdnPushStatusDisconnected;
                    break;
                case V2TXLivePushStatusReconnecting:
                    result = CdnPushStatusReconnecting;
                    break;
                case V2TXLivePushStatusConnectSuccess:
                    result = CdnPushStatusConnectSuccess;
                    break;
                default:
                    [[TRTCCloud sharedInstance] apiLog:[NSString stringWithFormat:@"TRTCChorusManager calling onCdnPushStatusUpdate, v2_status translate error, current_ntp:%ld", [TXLiveBase getNetworkTimestamp]]];
                    break;
            }
            [self.delegate onCdnPushStatusUpdate:result];
        }
    }];
}

- (void)onError:(V2TXLiveCode)code message:(NSString *)msg extraInfo:(NSDictionary *)extraInfo {
    [[TRTCCloud sharedInstance] apiLog:[NSString stringWithFormat:@"TRTCChorusManager pusher onError, code:%ld, msg:%@, current_ntp:%ld", code, msg, [TXLiveBase getNetworkTimestamp]]];
}

- (void)onWarning:(V2TXLiveCode)code message:(NSString *)msg extraInfo:(NSDictionary *)extraInfo {
    [[TRTCCloud sharedInstance] apiLog:[NSString stringWithFormat:@"TRTCChorusManager pusher onWarning, code:%ld, msg:%@, current_ntp:%ld", code, msg, [TXLiveBase getNetworkTimestamp]]];
}

#pragma mark - Private methods
- (void)initPusher {
    [[TRTCCloud sharedInstance] apiLog:[NSString stringWithFormat:@"TRTCChorusManager initPusher, current_ntp:%ld", [TXLiveBase getNetworkTimestamp]]];
    self.pusher = [[V2TXLivePusher alloc] initWithLiveMode:V2TXLiveMode_SIMPLE];
    [self.pusher setObserver:self];
    V2TXLiveVideoEncoderParam *param = [V2TXLiveVideoEncoderParam new];
    param.videoResolution = V2TXLiveVideoResolution960x540;
    param.videoResolutionMode = V2TXLiveVideoResolutionModePortrait;
    param.minVideoBitrate = 800;
    param.videoBitrate = 1500;
    param.videoFps = 15;
    [self.pusher setVideoQuality:param];
    [self.pusher setAudioQuality:V2TXLiveAudioQualityDefault];
}

- (void)initPlayer {
    [[TRTCCloud sharedInstance] apiLog:[NSString stringWithFormat:@"TRTCChorusManager initPlayer, current_ntp:%ld", [TXLiveBase getNetworkTimestamp]]];
    self.player = [[V2TXLivePlayer alloc] init];
    [self.player setObserver:self];
    [self.player enableReceiveSeiMessage:YES payloadType:CHORUS_SEI_PAYLOAD_TYPE];
}
#endif

- (void)clearChorusState {
    [[TRTCCloud sharedInstance] apiLog:[NSString stringWithFormat:@"TRTCChorusManager clearChorusState, current_ntp:%ld", [TXLiveBase getNetworkTimestamp]]];
    //注意这里不要将 requestStopChorusTs 置 0，否则可能影响过滤无效信令
    self.startPlayChorusMusicTs = 0;
    if (self.delayStartChorusMusicTimer) {
        dispatch_source_cancel(self.delayStartChorusMusicTimer);
        self.delayStartChorusMusicTimer = nil;
    }
    if (self.preloadMusicTimer) {
        dispatch_source_cancel(self.preloadMusicTimer);
        self.preloadMusicTimer = nil;
    }
    [self.chorusLongTermTimer setFireDate:[NSDate distantFuture]];
}

- (void)schedulePlayMusic:(NSInteger)delayMs {
    [[TRTCCloud sharedInstance] apiLog:[NSString stringWithFormat:@"TRTCChorusManager schedulePlayMusic delayMs:%ld, current_ntp:%ld", delayMs, [TXLiveBase getNetworkTimestamp]]];
    CHORUS_WEAKIFY(self);
    
    TXAudioMusicStartBlock startBlock = ^(NSInteger errCode){
        CHORUS_STRONGIFY_OR_RETURN(self);
        if (errCode != 0) {
            [[TRTCCloud sharedInstance] apiLog:[NSString stringWithFormat:@"TRTCChorusManager start play music failed %ld, current_ntp:%ld", errCode, [TXLiveBase getNetworkTimestamp]]];
            [self clearChorusState];
            //通知合唱已结束
            self->_isChorusOn = NO;
            [self asyncDelegate:^{
                if (self.delegate && [self.delegate respondsToSelector:@selector(onChorusStop:message:)]) {
                    [[TRTCCloud sharedInstance] apiLog:[NSString stringWithFormat:@"TRTCChorusManager calling onChorusStop, reason:ChorusStopReasonMusicFailed, current_ntp:%ld", [TXLiveBase getNetworkTimestamp]]];
                    [self.delegate onChorusStop:ChorusStopReasonMusicFailed message:@"music start failed"];
                }
            }];
        }
        [[TRTCCloud sharedInstance] apiLog:[NSString stringWithFormat:@"TRTCChorusManager start play music, current_progress:%ld, current_ntp:%ld", [[self audioEffecManager] getMusicCurrentPosInMS:CHORUS_MUSIC_ID], [TXLiveBase getNetworkTimestamp]]];
    };
    
    TXAudioMusicProgressBlock progressBlock = ^(NSInteger progressMs, NSInteger durationMs){
        CHORUS_STRONGIFY_OR_RETURN(self);
        //通知歌曲进度，用户会在这里进行歌词的滚动
        [self asyncDelegate:^{
            if (self.delegate && [self.delegate respondsToSelector:@selector(onMusicPlayProgress:duration:)]) {
                [self.delegate onMusicPlayProgress:progressMs duration:durationMs];
            }
        }];
#if defined(ENABLE_PUSH) && defined(ENABLE_PLAY)
        if (self.pusher.isPushing) {
            NSDictionary *progressMsg = @{
                kMusicCurrentTs: @(progressMs),
            };
            NSString *jsonString = [self jsonStringFrom:progressMsg];
            [self.pusher sendSeiMessage:CHORUS_SEI_PAYLOAD_TYPE data:[jsonString dataUsingEncoding:NSUTF8StringEncoding]];
        }
#endif
    };
    
    TXAudioMusicCompleteBlock completedBlock = ^(NSInteger errCode){
        [[TRTCCloud sharedInstance] apiLog:[NSString stringWithFormat:@"TRTCChorusManager music play completed, errCode:%ld current_ntp:%ld", errCode, [TXLiveBase getNetworkTimestamp]]];
        CHORUS_STRONGIFY_OR_RETURN(self);
        //播放完成后停止自定义消息的发送
        [self clearChorusState];
        //通知合唱已结束
        self->_isChorusOn = NO;
        [self asyncDelegate:^{
            if (self.delegate && [self.delegate respondsToSelector:@selector(onChorusStop:message:)]) {
                [[TRTCCloud sharedInstance] apiLog:[NSString stringWithFormat:@"TRTCChorusManager calling onChorusStop, reason:ChorusStopReasonMusicFinished, current_ntp:%ld", [TXLiveBase getNetworkTimestamp]]];
                [self.delegate onChorusStop:ChorusStopReasonMusicFinished message:@"chorus music finished playing"];
            }
        }];
    };
    
    if (delayMs > 0) {
        if (!self.delayStartChorusMusicTimer) {
            NSInteger initialTime = [TXLiveBase getNetworkTimestamp];
            self.delayStartChorusMusicTimer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0));
            dispatch_source_set_timer(self.delayStartChorusMusicTimer, DISPATCH_TIME_NOW, DISPATCH_TIME_FOREVER, 0);
            
            CHORUS_WEAKIFY(self);
            dispatch_source_set_event_handler(self.delayStartChorusMusicTimer, ^{
                while (true) {
                    //轮询，直到当前时间为约定好的播放时间再进行播放，之所以不直接用timer在约定时间执行是由于精度问题，可能会相差几百毫秒
                    CHORUS_STRONGIFY_OR_RETURN(self);
                    if ([TXLiveBase getNetworkTimestamp] > (initialTime + delayMs)) {
                        if(!self->_isChorusOn) {
                            //若达到预期播放时间时，合唱已被停止，则跳过此次播放
                            [[TRTCCloud sharedInstance] apiLog:[NSString stringWithFormat:@"TRTCChorusManager schedulePlayMusic abort, chorus has been stopped, current_ntp:%ld", [TXLiveBase getNetworkTimestamp]]];
                            break;
                        }
                        [[self audioEffecManager] startPlayMusic:self.musicParam onStart:startBlock onProgress:progressBlock onComplete:completedBlock];
                        break;
                    }
                }
            });
            dispatch_resume(self.delayStartChorusMusicTimer);
        }
    } else {
        [[self audioEffecManager] startPlayMusic:self.musicParam onStart:startBlock onProgress:progressBlock onComplete:completedBlock];
        if (delayMs < 0) {
            NSInteger startMS = -delayMs + CHORUS_PRELOAD_MUSIC_DELAY;
            [self preloadMusic:self.musicParam.path startMs:startMS];
            if (!self.preloadMusicTimer) {
                NSInteger initialTime = [TXLiveBase getNetworkTimestamp];
                self.preloadMusicTimer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0));
                dispatch_source_set_timer(self.preloadMusicTimer, DISPATCH_TIME_NOW, DISPATCH_TIME_FOREVER, 0);
                
                CHORUS_WEAKIFY(self);
                dispatch_source_set_event_handler(self.preloadMusicTimer, ^{
                    while (true) {
                        //轮询，直到当前时间为约定时间再执行，之所以不直接用timer在约定时间执行是由于精度问题，可能会相差几百毫秒
                        CHORUS_STRONGIFY_OR_RETURN(self);
                        if ([TXLiveBase getNetworkTimestamp] > (initialTime + CHORUS_PRELOAD_MUSIC_DELAY)) {
                            if(!self->_isChorusOn) {
                                //若达到预期播放时间时，合唱已被停止，则跳过此次播放
                                [[TRTCCloud sharedInstance] apiLog:[NSString stringWithFormat:@"TRTCChorusManager schedulePlayMusic abort, chorus has been stopped, current_ntp:%ld", [TXLiveBase getNetworkTimestamp]]];
                                break;
                            }
                            [[self audioEffecManager] startPlayMusic:self.musicParam onStart:startBlock onProgress:progressBlock onComplete:completedBlock];
                            [[TRTCCloud sharedInstance] apiLog:[NSString stringWithFormat:@"TRTCChorusManager calling startPlayMusic, startMs:%ld, current_ntp:%ld", startMS, [TXLiveBase getNetworkTimestamp]]];
                            break;
                        }
                    }
                });
                dispatch_resume(self.preloadMusicTimer);
            }
        }
    }
    
}

- (BOOL)isNtpReady {
    return [TXLiveBase getNetworkTimestamp] > 0;
}

- (NSString *)jsonStringFrom:(NSDictionary *)dict {
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dict options:0 error:NULL];
    return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
}

- (void)checkMusicProgress {
    NSInteger currentProgress = [[self audioEffecManager] getMusicCurrentPosInMS:CHORUS_MUSIC_ID];
    NSInteger estimatedProgress = [TXLiveBase getNetworkTimestamp] - self.startPlayChorusMusicTs;
    if (estimatedProgress >= 0 && labs(currentProgress - estimatedProgress) > 60) {
        [[TRTCCloud sharedInstance] apiLog:[NSString stringWithFormat:@"TRTCChorusManager checkMusicProgress triggered seek, currentProgress:%ld, estimatedProgress:%ld, current_ntp:%ld", currentProgress, estimatedProgress, [TXLiveBase getNetworkTimestamp]]];
        [[self audioEffecManager] seekMusicToPosInMS:CHORUS_MUSIC_ID pts:estimatedProgress];
    }
}

- (void)sendStartChorusMsg {
    NSDictionary *json = @{
            @"cmd": kStartChorusMsg,
            @"startPlayMusicTS": @(self.startPlayChorusMusicTs),
        };
    NSString *jsonString = [self jsonStringFrom:json];
    [self sendCustomMessage:jsonString reliable:NO];
}

- (void)sendStopChorusMsg {
    NSDictionary *json = @{
            @"cmd": kStopChorusMsg,
            @"requestStopTS": @(self.requestStopChorusTs),
        };
    NSString *jsonString = [self jsonStringFrom:json];
    [self sendCustomMessage:jsonString reliable:YES];
}

- (BOOL)sendCustomMessage:(NSString *)message reliable:(BOOL)reliable {
    NSData * _Nullable data = [message dataUsingEncoding:NSUTF8StringEncoding];
    if (data != nil) {
        return [[TRTCCloud sharedInstance] sendCustomCmdMsg:1 data:data reliable:reliable ordered:reliable];
    }
    return NO;
}

- (void)preloadMusic:(NSString *)path startMs:(NSInteger)startMs {
    [[TRTCCloud sharedInstance] apiLog:[NSString stringWithFormat:@"TRTCChorusManager preloadMusic, current_ntp:%ld", [TXLiveBase getNetworkTimestamp]]];
    NSDictionary *jsonDict = @{
            @"api": @"preloadMusic",
            @"params": @{
                @"musicId": @(CHORUS_MUSIC_ID),
                @"path": path,
                @"startTimeMS": @(startMs),
            }
        };
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:jsonDict options:0 error:NULL];
    NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    [[TRTCCloud sharedInstance] callExperimentalAPI:jsonString];
}

- (TXAudioEffectManager *)audioEffecManager {
    return [[TRTCCloud sharedInstance] getAudioEffectManager];
}

- (void)asyncDelegate:(void(^)())block
{
    CHORUS_WEAKIFY(self);
        dispatch_async(dispatch_get_main_queue(), ^{
            CHORUS_STRONGIFY_OR_RETURN(self);
            block();
        });
}

@end
