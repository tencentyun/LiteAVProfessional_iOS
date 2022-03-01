//
//  TRTCSettingsEffectMixedSoundCell.m
//  TXLiteAVDemo
//
//  Created by origin 李 on 2021/12/23.
//  Copyright © 2021 Tencent. All rights reserved.
//
#import "Masonry.h"
#import "ColorMacro.h"
#import "UIImage+Additions.h"
#import "TRTCCloudDef.h"
#import "TRTCSettingsEffectMixedSoundCell.h"
#import "NSTimer+BlcokTimer.h"
#import "TCUtil.h"


static NSInteger dataLocation;

@interface TRTCSettingsEffectMixedSoundCell ()

@property (strong, nonatomic) UIButton *playButton;
@property (strong, nonatomic) UIButton *stopButton;
@property (strong, nonatomic) NSTimer  *_Nullable time;
@property (strong, nonatomic) NSData   *pcmData;

@end

@implementation TRTCSettingsEffectMixedSoundCell

- (void)setupUI {
    [super setupUI];
    self.playButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.playButton setImage:[UIImage imageNamed:@"audio_play"] forState:UIControlStateNormal];
    self.playButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
    self.playButton.tintColor = UIColorFromRGB(0x05a764);
    [self.playButton setImage:[UIImage imageNamed:@"audio_pause"] forState:UIControlStateSelected];
    [self.playButton addTarget:self action:@selector(onClickPlayButton:) forControlEvents:UIControlEventTouchUpInside];
    [self.contentView addSubview:self.playButton];

    self.stopButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.stopButton setImage:[UIImage imageNamed:@"audio_stop"] forState:UIControlStateNormal];
    self.stopButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
    self.stopButton.tintColor = UIColorFromRGB(0x05a764);
    [self.stopButton addTarget:self action:@selector(onClickStopButton:) forControlEvents:UIControlEventTouchUpInside];
    [self.contentView addSubview:self.stopButton];

    [self.playButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.contentView);
        make.leading.equalTo(self.stopButton.mas_trailing).offset(18);
        make.size.mas_equalTo(CGSizeMake(30, 30));
    }];
    
    [self.stopButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.contentView);
        make.leading.equalTo(self.playButton.mas_trailing).offset(4);
        make.trailing.equalTo(self.contentView).offset(-18);
        make.size.mas_equalTo(CGSizeMake(30, 30));
    }];
}




- (void)didUpdateItem:(TRTCSettingsEffectMixedSoundItem *)item {
    if ([item isKindOfClass:[TRTCSettingsEffectMixedSoundItem class]]) {
        self.titleLabel.text = item.title;
    }
}

#pragma mark - Events
- (void)onClickPlayButton:(UIButton *)button {
    self.playButton.selected = !self.playButton.selected;
    if (self.playButton.selected) {
        TRTCSettingsEffectMixedSoundItem * mixedSoundItem =(TRTCSettingsEffectMixedSoundItem *)self.item;
        [mixedSoundItem.trtcCloud enableMixExternalAudioFrame:mixedSoundItem.settingPage.enablePublish playout:mixedSoundItem.settingPage.enablePlayout];
        [mixedSoundItem.trtcCloud setMixExternalAudioVolume:mixedSoundItem.settingPage.publishVolume playoutVolume:mixedSoundItem.settingPage.playoutVolume];
        if (self.time && [self.time isValid]) {
            self.time = nil;
        }
        dataLocation = 0;
        [self.playTime fire];
        if (mixedSoundItem.playAction) {
            mixedSoundItem.playAction();
        }
    } else {
        [self onClickStopButton:button];
    }
    
}

- (void)onClickStopButton:(id)sender {
    if ([self.time isValid]) {
        [self.time invalidate];
        self.time = nil;
        dataLocation = 0;
        self.playButton.selected = NO;
    };
}

- (NSTimer *)playTime{
    @weakify(self)
    _time = [NSTimer tx_scheduledTimerWithTimeInterval:0.05 block:^{
        @strongify(self)
        if ((dataLocation+8820) >= self.pcmData.length) {
            //循环播放
            dataLocation = 0;
        }
        NSRange range = NSMakeRange(dataLocation, 8820);
        NSData *data = [self.pcmData subdataWithRange:range];
        TRTCAudioFrame *audioFrame = [TRTCAudioFrame new];
        audioFrame.timestamp = 0;
        audioFrame.channels        = 2;
        audioFrame.sampleRate      = 44100;
        audioFrame.data            = data;
        TRTCSettingsEffectMixedSoundItem * mixedSoundItem =(TRTCSettingsEffectMixedSoundItem *)self.item;
        int time =  [mixedSoundItem.trtcCloud mixExternalAudioFrame:audioFrame];
        if (time>200) {
            sleep(0.1);
        }
        NSLog(@" can play time：%dms",time);
        dataLocation += 8820;
    } repeats:YES];
    return _time;
}

- (NSData *)pcmData{
    if (!_pcmData) {
        NSString *path = [[NSBundle mainBundle] pathForResource:@"mixExternAudio" ofType:@"pcm"];
        _pcmData = [[NSData alloc] initWithContentsOfFile:path];
    }
    return _pcmData;
}

- (void)dealloc {
    if (_time&&[_time isValid]) {
        [_time invalidate];
        _time = nil;
    }
}

@end

@interface TRTCSettingsEffectMixedSoundItem ()

@end

@implementation TRTCSettingsEffectMixedSoundItem
- (instancetype)initWithTRTCCloud:(TRTCCloud *)trtcCloud playAction:(void (^_Nullable)(void))playAction
 {
    if (self = [super init]) {
        _trtcCloud  = trtcCloud;
        _playAction = playAction;
    }
    return self;
}

+ (Class)bindedCellClass {
    return [TRTCSettingsEffectMixedSoundCell class];
}

- (NSString *)bindedCellId {
    return [TRTCSettingsEffectMixedSoundItem bindedCellId];
}

@end
