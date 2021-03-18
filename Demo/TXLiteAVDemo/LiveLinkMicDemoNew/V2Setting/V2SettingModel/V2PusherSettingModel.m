#import "V2PusherSettingModel.h"

static NSString *const kVideoConfig = @"V2TRTCVideoConfig";
static NSString *const kAudioConfig = @"V2TRTCAudioConfig";

@implementation V2BitrateRange

- (instancetype)initWithMin:(NSInteger)min max:(NSInteger)max defaultBitrate:(NSInteger)defaultBitrate step:(NSInteger)step {
    if (self = [super init]) {
        self.minBitrate = min;
        self.maxBitrate = max;
        self.defaultBitrate = defaultBitrate;
        self.step = step;
    }
    return self;
}

@end

@interface V2PusherSettingModel()

@property (nonatomic, strong) UIImage *waterMarkImg;
@property (nonatomic, assign) CGRect waterMarkRect;

@end

@implementation V2PusherSettingModel
- (instancetype)initWithPusher:(V2TXLivePusher *)pusher {
    if (self = [super init]) {
        self.pusher = pusher;
        
        self.videoEnabled = YES;
        self.isVideoMuted = NO;
        self.videoResolution = V2TXLiveVideoResolution960x540;
        self.resolutionMode = V2TXLiveVideoResolutionModePortrait;
        self.localMirrorType = V2TXLiveMirrorTypeAuto;
        self.isRemoteMirrorEnabled = NO;
        
        [self loadLocalVideoConfig];
        
        self.volumeType = TRTCSystemVolumeTypeAuto;
        self.isEarMonitoringEnabled = NO;
        self.isEnableVolumeEvaluation = NO;
        self.captureVolume = 100;
        self.startMicphone = YES;
        
        [self loadLocalAudioConfig];
        
        [self applyConfig];
    }
    
    return self;
}

#pragma mark - Video Functions

- (void)setVideoEnabled:(BOOL)videoEnabled {
    _videoEnabled = videoEnabled;
    if (videoEnabled) {
        [self.pusher startCamera:self.pusher.getDeviceManager.isFrontCamera];
        [UIApplication sharedApplication].idleTimerDisabled = YES;
    } else {
        [self.pusher stopCamera];
        [UIApplication sharedApplication].idleTimerDisabled = NO;
    }
}

- (void)setIsVideoMuted:(BOOL)isVideoMuted {
    _isVideoMuted = isVideoMuted;
    if (!isVideoMuted) {
        [self.pusher startCamera:self.pusher.getDeviceManager.isFrontCamera];
        [UIApplication sharedApplication].idleTimerDisabled = YES;
    } else {
        [self.pusher stopCamera];
        [UIApplication sharedApplication].idleTimerDisabled = NO;
    }
}

- (void)setVideoResolution:(V2TXLiveVideoResolution)videoResolution {
    _videoResolution = videoResolution;
    [self.pusher setVideoQuality:_videoResolution resolutionMode:_resolutionMode];
}

- (void)setLocalMirrorType:(V2TXLiveMirrorType)localMirrorType {
    _localMirrorType = localMirrorType;
    [self.pusher setRenderMirror:localMirrorType];
}

- (void)setIsRemoteMirrorEnabled:(BOOL)isRemoteMirrorEnabled {
    _isRemoteMirrorEnabled = isRemoteMirrorEnabled;
    [self.pusher setEncoderMirror:isRemoteMirrorEnabled];
}

- (void)setWaterMark:(UIImage *)image inRect:(CGRect)rect {
    self.waterMarkImg = image;
    self.waterMarkRect = rect;
    if (image == nil) {
        [self.pusher setWatermark:nil x:0.0 y:0.0 scale:0.0];
    } else {
        CGFloat scale = rect.size.width/image.size.width;
        [self.pusher setWatermark:image x:rect.origin.x y:rect.origin.y scale:scale];
    }
}

- (void)snapshot {
    [self.pusher snapshot];
}

+ (NSArray<NSNumber *> *)resolutions {
    return @[
        @(V2TXLiveVideoResolution160x160),
        @(V2TXLiveVideoResolution270x270),
        @(V2TXLiveVideoResolution480x480),
        @(V2TXLiveVideoResolution320x240),
        @(V2TXLiveVideoResolution480x360),
        @(V2TXLiveVideoResolution640x480),
        @(V2TXLiveVideoResolution320x180),
        @(V2TXLiveVideoResolution480x270),
        @(V2TXLiveVideoResolution640x360),
        @(V2TXLiveVideoResolution960x540),
        @(V2TXLiveVideoResolution1280x720),
        @(V2TXLiveVideoResolution1920x1080)
    ];
}

+ (NSArray<NSString *> *)resolutionNames {
    return @[
        @"160x160",
        @"270x270",
        @"480x480",
        @"320x240",
        @"480x360",
        @"640x480",
        @"320x180",
        @"480x270",
        @"640x360",
        @"960x540",
        @"1280x720",
        @"1920x1080"
    ];
}

+ (V2BitrateRange *)bitrateRangeOf:(V2TXLiveVideoResolution)resolution {
    switch (resolution) {
        case V2TXLiveVideoResolution160x160:
            return [[V2BitrateRange alloc] initWithMin:100 max:150 defaultBitrate:150 step:10];
        case V2TXLiveVideoResolution270x270:
            return [[V2BitrateRange alloc] initWithMin:200 max:300 defaultBitrate:300 step:10];
        case V2TXLiveVideoResolution480x480:
            return [[V2BitrateRange alloc] initWithMin:350 max:525 defaultBitrate:525 step:10];
        case V2TXLiveVideoResolution320x240:
            return [[V2BitrateRange alloc] initWithMin:250 max:375 defaultBitrate:375 step:10];
        case V2TXLiveVideoResolution480x360:
            return [[V2BitrateRange alloc] initWithMin:400 max:600 defaultBitrate:600 step:10];
        case V2TXLiveVideoResolution640x480:
            return [[V2BitrateRange alloc] initWithMin:600 max:900 defaultBitrate:900 step:10];
        case V2TXLiveVideoResolution320x180:
            return [[V2BitrateRange alloc] initWithMin:250 max:400 defaultBitrate:400 step:10];
        case V2TXLiveVideoResolution480x270:
            return [[V2BitrateRange alloc] initWithMin:350 max:550 defaultBitrate:550 step:10];
        case V2TXLiveVideoResolution640x360:
            return [[V2BitrateRange alloc] initWithMin:500 max:900 defaultBitrate:900 step:10];
        case V2TXLiveVideoResolution960x540:
            return [[V2BitrateRange alloc] initWithMin:800 max:1500 defaultBitrate:1500 step:10];
        case V2TXLiveVideoResolution1280x720:
            return [[V2BitrateRange alloc] initWithMin:1000 max:1800 defaultBitrate:1800 step:10];
        case V2TXLiveVideoResolution1920x1080:
            return [[V2BitrateRange alloc] initWithMin:2500 max:3000 defaultBitrate:3000 step:10];
        default:
            assert(false);
            return [[V2BitrateRange alloc] init];
    }
}

+ (NSArray<NSString *> *)fpsList {
    return @[@"15", @"20", @"24"];
}

#pragma mark - Audio Functions

- (void)setStartMicphone:(BOOL)startMicphone {
    _startMicphone = startMicphone;
    if (startMicphone) {
        [self.pusher startMicrophone];
    } else {
        [self.pusher stopMicrophone];
    }
}

- (void)setIsAudioMuted:(BOOL)isAudioMuted {
    _isAudioMuted = isAudioMuted;
    if (!isAudioMuted) {
        [self.pusher startMicrophone];
    } else {
        [self.pusher stopMicrophone];
    }
}

- (void)setVolumeType:(TRTCSystemVolumeType)volumeType {
    _volumeType = volumeType;
    [[self.pusher getDeviceManager] setSystemVolumeType:(TXSystemVolumeType)volumeType];
}

- (void)setIsEarMonitoringEnabled:(BOOL)isEarMonitoringEnabled {
    _isEarMonitoringEnabled = isEarMonitoringEnabled;
    [self.pusher.getAudioEffectManager enableVoiceEarMonitor:isEarMonitoringEnabled];
}

- (void)setIsEnableVolumeEvaluation:(BOOL)isEnableVolumeEvaluation {
    _isEnableVolumeEvaluation = isEnableVolumeEvaluation;
    [self.pusher enableVolumeEvaluation:isEnableVolumeEvaluation?200:0];
}

- (void)setCaptureVolume:(NSInteger)captureVolume {
    _captureVolume = captureVolume;
    [self.pusher.getAudioEffectManager setVoiceVolume:captureVolume];
}

#pragma mark -

- (void)saveConfig {
    NSDictionary *videoDict = [self videoConfigDictionaryRepresentation];
    NSDictionary *audioDict = [self audioConfigDictionaryRepresentation];
    [[NSUserDefaults standardUserDefaults] setValue:videoDict forKey:kVideoConfig];
    [[NSUserDefaults standardUserDefaults] setValue:audioDict forKey:kAudioConfig];
}

- (void)applyConfig {
    [self applyVideoConfig];
    [self applyAudioConfig];
}

#pragma mark - private

- (void)loadLocalVideoConfig {
    NSDictionary *dict = [[NSUserDefaults standardUserDefaults] dictionaryForKey:kVideoConfig];
    if (dict) {
        if ([dict objectForKey:@"videoResolution"]) {
            self.videoResolution = [[dict objectForKey:@"videoResolution"] intValue];
        }
        if ([dict objectForKey:@"resolutionMode"]) {
            self.resolutionMode = [[dict objectForKey:@"resolutionMode"] intValue];
        }
        if ([dict objectForKey:@"localMirrorType"]) {
            self.localMirrorType = [[dict objectForKey:@"localMirrorType"] intValue];
        }
        if ([dict objectForKey:@"isRemoteMirrorEnabled"]) {
            self.isRemoteMirrorEnabled = [[dict objectForKey:@"isRemoteMirrorEnabled"] intValue];
        }
    }
}

- (NSDictionary *)videoConfigDictionaryRepresentation {
    return @{
        @"videoResolution" : @(self.videoResolution),
        @"resolutionMode" : @(self.resolutionMode),
        @"localMirrorType" : @(self.localMirrorType),
        @"isRemoteMirrorEnabled" : @(self.isRemoteMirrorEnabled),
    };
}

- (void)applyVideoConfig {
    [self setVideoResolution:self.videoResolution];
    [self setLocalMirrorType:self.localMirrorType];
    [self setIsRemoteMirrorEnabled:self.isRemoteMirrorEnabled];
    [self setIsVideoMuted:self.isVideoMuted];
    [self setWaterMark:self.waterMarkImg inRect:self.waterMarkRect];
}

- (void)loadLocalAudioConfig {
    NSDictionary *dict = [[NSUserDefaults standardUserDefaults] dictionaryForKey:kAudioConfig];
    if (dict) {
        if ([dict objectForKey:@"volumeType"]) {
            self.volumeType = [[dict objectForKey:@"volumeType"] intValue];
        }
        if ([dict objectForKey:@"isEarMonitoringEnabled"]) {
            self.isEarMonitoringEnabled = [[dict objectForKey:@"isEarMonitoringEnabled"] intValue];
        }
        if ([dict objectForKey:@"isAudioMuted"]) {
            self.isAudioMuted = [[dict objectForKey:@"isAudioMuted"] intValue];
        }
        if ([dict objectForKey:@"startMicphone"]) {
            self.startMicphone = [[dict objectForKey:@"startMicphone"] intValue];
        }
        if ([dict objectForKey:@"isEnableVolumeEvaluation"]) {
            self.isEnableVolumeEvaluation = [[dict objectForKey:@"isEnableVolumeEvaluation"] intValue];
        }
    }
}

- (NSDictionary *)audioConfigDictionaryRepresentation {
    return @{
        @"volumeType": @(self.volumeType),
        @"isEarMonitoringEnabled": @(self.isEarMonitoringEnabled),
        @"isAudioMuted": @(self.isAudioMuted),
        @"startMicphone": @(self.startMicphone),
        @"isEnableVolumeEvaluation": @(self.isEnableVolumeEvaluation),
    };
}

- (void)applyAudioConfig {
    [self setVolumeType:self.volumeType];
    self.isEarMonitoringEnabled = self.isEarMonitoringEnabled;
    self.isEnableVolumeEvaluation = self.isEnableVolumeEvaluation;
    [self setIsAudioMuted:self.isAudioMuted];
}

@end
