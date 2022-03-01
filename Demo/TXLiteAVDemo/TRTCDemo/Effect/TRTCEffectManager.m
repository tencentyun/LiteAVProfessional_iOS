/*
* Module:   TRTCEffectManager
*
* Function: TRTC SDK的音效功能调用
*
*    1. Demo中内置了三个音效文件: 欢呼.m4a, giftSent.aac和on_mic.aac，可根据app实际需要更改
*
*    2. 每个音效都需要一个ID（effectId），调用API时，通过传入ID来控制对应音效。
*
*/

#import "TRTCEffectManager.h"
#import "TRTCCloud.h"
#import "TRTCCloudDef.h"

@interface TRTCEffectManager()

@property (strong, nonatomic) TRTCCloud *trtc;
@property (strong, nonatomic) NSArray<TRTCAudioEffectConfig *> *effects;

@end

@implementation TRTCEffectManager

- (instancetype)initWithTrtc:(TRTCCloud *)trtc {
    if (self = [super init]) {
        self.trtc = trtc;
        self.effects = [self setupEffects];
        self.globalVolume = 100;
        self.loopCount = 1;
    }
    return self;
}

- (NSArray<TRTCAudioEffectConfig *> *)setupEffects {
    return @[
        [self buildEffectWithId:0 path:[[NSBundle mainBundle] pathForResource:@"欢呼" ofType:@"m4a"]],
        [self buildEffectWithId:1 path:[[NSBundle mainBundle] pathForResource:@"giftSent" ofType:@"aac"]],
        [self buildEffectWithId:2 path:[[NSBundle mainBundle] pathForResource:@"on_mic" ofType:@"aac"]],
    ];
}

- (TRTCAudioEffectConfig *)buildEffectWithId:(int)effectId path:(NSString *)path {
    TRTCAudioEffectParam *params = [[TRTCAudioEffectParam alloc] initWith:effectId path:path];
    params.publish = YES;
    params.volume = 100;
    
    TRTCAudioEffectConfig *effect = [[TRTCAudioEffectConfig alloc] init];
    effect.params = params;
    return effect;
}

- (void)setLoopCount:(NSInteger)loopCount {
    _loopCount = loopCount;
    for (TRTCAudioEffectConfig *effect in self.effects) {
        effect.params.loopCount = (int)loopCount;
    }
}

- (void)updateEffect:(NSInteger)effectId volume:(NSInteger)volume {
    self.effects[effectId].params.volume = (int) volume;
    [self.trtc.getAudioEffectManager setMusicPlayoutVolume:(int32_t)effectId volume:volume];
    [self.trtc.getAudioEffectManager setMusicPublishVolume:(int32_t)effectId volume:volume];
}

- (void)toggleEffectPublish:(NSInteger)effectId {
    self.effects[effectId].params.publish = !self.effects[effectId].params.publish;
}

- (void)setGlobalVolume:(NSInteger)globalVolume {
    _globalVolume = globalVolume;
    for (TRTCAudioEffectConfig *effect in self.effects) {
        effect.params.volume = (int) globalVolume;
    }
    [[self.trtc getAudioEffectManager] setAllMusicVolume:globalVolume];
}

- (void)playEffect:(NSInteger)effectId {
    self.effects[effectId].playState = TRTCPlayStatePlaying;
    TRTCAudioEffectParam *lastParam = self.effects[effectId].params;
    
    TXAudioMusicParam *param = [TXAudioMusicParam new];
    param.loopCount = lastParam.loopCount;
    param.ID = lastParam.effectId;
    param.path = lastParam.path;
    param.publish = lastParam.publish;
    
    __weak typeof(self)weakSelf = self;
    [self.trtc.getAudioEffectManager startPlayMusic:param onStart:^(NSInteger errCode) {
        
    } onProgress:^(NSInteger progressMs, NSInteger durationMs) {
        
    } onComplete:^(NSInteger errCode) {
        [weakSelf stopEffect:effectId];
    }];
}

- (void)stopEffect:(NSInteger)effectId {
    self.effects[effectId].playState = TRTCPlayStateIdle;
    [self.trtc.getAudioEffectManager stopPlayMusic:(int32_t)effectId];
}

- (void)pauseEffect:(NSInteger)effectId {
    self.effects[effectId].playState = TRTCPlayStateOnPause;
    [self.trtc.getAudioEffectManager pausePlayMusic:(int32_t)effectId];
}

- (void)resumeEffect:(NSInteger)effectId {
    self.effects[effectId].playState = TRTCPlayStatePlaying;
    [self.trtc.getAudioEffectManager resumePlayMusic:(int32_t)effectId];
}

- (void)stopAllEffects {
    for (TRTCAudioEffectConfig *effect in self.effects) {
        effect.playState = TRTCPlayStateIdle;
        [self.trtc.getAudioEffectManager stopPlayMusic:(int32_t)effect.params.effectId];
    }
}

@end

#pragma mark - TRTCAudioEffectConfig

@implementation TRTCAudioEffectConfig

@end
