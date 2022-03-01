//
//  TRTCSettingsSwitchButtonCell.m
//  TXLiteAVDemo
//
//  Created by origin 李 on 2021/12/22.
//  Copyright © 2021 Tencent. All rights reserved.
//

#import "TRTCSettingsSwitchButtonCell.h"
#import "ColorMacro.h"
#import "Masonry.h"
#import "AppLocalized.h"
#import "UIButton+TRTC.h"
#import "NSTimer+BlcokTimer.h"
#import "TCUtil.h"
#import "AudioQueuePlay.h"
#import "UIImage+Additions.h"
#import "HUDHelper.h"
#define  CHANNEL    1
#define  SAMPLE_RATE   48000
#define  AUDIO_INTERVAL_MS  20;
#define  AUDIO_FRAME_LENGTH   1920


@interface TRTCSettingsSwitchButtonCell ()

@property(strong, nonatomic) UISwitch *switcher;
@property(strong, nonatomic) UIButton *playButton;
@property(strong, nonatomic) AudioQueuePlay *audioQueuePlay;
@property(strong, nonatomic) dispatch_queue_t audioPlayerQueue;

@end

@implementation TRTCSettingsSwitchButtonCell

- (void)setupUI {
    [super setupUI];
    self.switcher = [[UISwitch alloc] init];
    self.playButton = [UIButton trtc_cellButtonWithTitle:TRTCLocalize(@"Demo.TRTC.audio.renderPlay")];
    [self.playButton setTitle:TRTCLocalize(@"Demo.TRTC.audio.renderStop") forState:UIControlStateSelected];
    self.playButton.enabled = NO;
    [self.playButton addTarget:self action:@selector(onClickPlayButton:) forControlEvents:UIControlEventTouchUpInside];
    [self.contentView addSubview:self.playButton];
    [self.playButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.contentView);
        make.trailing.equalTo(self.contentView).offset(-18);
    }];
    [self.switcher addTarget:self action:@selector(onClickSwitch:) forControlEvents:UIControlEventValueChanged];
    self.switcher.onTintColor = UIColorFromRGB(0x2364db);
    [self.contentView addSubview:self.switcher];
    [self.titleLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.contentView).offset(9);
        make.top.equalTo(self.contentView).offset(15);
    }];
    [self.switcher mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.contentView);
        make.right.equalTo(self.titleLabel).offset(80);
    }];
}

- (void)didUpdateItem:(TRTCSettingsBaseItem *)item {
    if ([item isKindOfClass:[TRTCSettingsSwitchButtonItem class]]) {
        TRTCSettingsSwitchButtonItem *switchItem = (TRTCSettingsSwitchButtonItem *)item;
        self.switcher.on                         = switchItem.isOn;
    }
}

- (void)onClickSwitch:(id)sender {
    TRTCSettingsSwitchButtonItem *item = (TRTCSettingsSwitchButtonItem *)self.item;
    item.isOn = self.switcher.isOn;
    if (item.isOn) {
        self.playButton.enabled = YES;
        [[HUDHelper sharedInstance] tipMessage:TRTCLocalize(@"Demo.TRTC.audio.renderTip")];
    } else {
        [self.audioQueuePlay stop];
    }
    if (item.switchAction) {
        item.switchAction(self.switcher.isOn);
    }
}

- (void)onClickPlayButton:(id)sender {
    self.playButton.selected = !self.playButton.selected;
    if (self.playButton.selected) {
        TRTCSettingsSwitchButtonItem *item = (TRTCSettingsSwitchButtonItem *)self.item;
        if (item.isOn) {
            @weakify(self)
            [self.audioQueuePlay start];
            for (TRTCAudioFrame *audioFrame in item.getCustomAudioFrames) {
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.02 * NSEC_PER_SEC)), self.audioPlayerQueue, ^{
                    @strongify(self)
                    [self.audioQueuePlay playWithData:audioFrame.data];
                });
            }
        }
    } else {
        [self.audioQueuePlay stop];
    }
}

- (AudioQueuePlay *)audioQueuePlay {
    if (!_audioQueuePlay) {
        _audioQueuePlay = [[AudioQueuePlay alloc]init];
    }
    return _audioQueuePlay;
}

- (dispatch_queue_t)audioPlayerQueue{
    if (!_audioPlayerQueue) {
        dispatch_queue_attr_t attr = dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_SERIAL, QOS_CLASS_DEFAULT, 0);
        _audioPlayerQueue = dispatch_queue_create("com.media.audioplayer", attr);
    }
    return _audioPlayerQueue;
}

@end

@implementation TRTCSettingsSwitchButtonItem

- (instancetype)initWithTitle:(NSString *)title isOn:(BOOL)isOn switchAction:(void (^_Nullable)(BOOL))switchAction  playAction:(void (^_Nullable)(TRTCAudioFrame* customAudioFrame))playAction {
    if (self = [super init]) {
        self.title    = title;
        _isOn         = isOn;
        _switchAction = switchAction;
        _playAction   = playAction;
    }
    return self;
}

+ (Class)bindedCellClass {
    return [TRTCSettingsSwitchButtonCell class];
}

- (NSString *)bindedCellId {
    return [TRTCSettingsSwitchButtonItem bindedCellId];
}

- (NSArray *)getCustomAudioFrames {
    if (self.audioFrames.count>0) {
        return [self.audioFrames copy];
    }
    return nil;
}

- (void)setIsOn:(BOOL)isOn {
    _isOn = isOn;
    [self.trtcCloud enableCustomAudioRendering:isOn];
    [self.audioFrames removeAllObjects];
    _countNum = 0;
    if (isOn) {
        [self.time fire];
    }else{
        if ([self.time isValid]) {
            [self.time invalidate];
        }
    }
}

- (NSMutableArray *)audioFrames {
    if (!_audioFrames) {
        _audioFrames = [[NSMutableArray alloc]init];
    }
    return _audioFrames;
}

- (NSTimer *)time{
    @weakify(self)
    if (!_time) {
        _time = [NSTimer tx_scheduledTimerWithTimeInterval:0.02 block:^{
            @strongify(self)
            if (self.countNum == 1500) {
                if ([self.time isValid]) {
                    [self.time invalidate];
                }
                return;
            }
            TRTCAudioFrame *audioFrame = [TRTCAudioFrame new];
            audioFrame.channels        = CHANNEL;
            audioFrame.sampleRate      = SAMPLE_RATE;
            Byte *bytes                = malloc(sizeof(Byte) * AUDIO_FRAME_LENGTH);
            audioFrame.data            = [NSData  dataWithBytes:bytes length:AUDIO_FRAME_LENGTH];
            [self.trtcCloud getCustomAudioRenderingFrame:audioFrame];
            [self.audioFrames  addObject:audioFrame];
            self.countNum ++;
        } repeats:YES];
    }
    return _time;
}

@end
