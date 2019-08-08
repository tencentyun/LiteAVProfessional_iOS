//
//  VideoPreview.m
//  TCLVBIMDemo
//
//  Created by xiang zhang on 2017/4/18.
//  Copyright © 2017年 tencent. All rights reserved.
//

#import "VideoPreview.h"
#import "UIView+Additions.h"
#import <AVFoundation/AVFoundation.h>

#undef _MODULE_
#define _MODULE_ "TXVideoPreview"

#define playBtnWidth   34
#define playBtnHeight  46
#define pauseBtnWidth  27
#define pauseBtnHeight 42
#define controlBtnWidth 40

#undef _MODULE_
#define _MODULE_ "TXVideoPreview"

@interface VideoPreview()

@end

@implementation VideoPreview
{
    UIButton    *_playBtn;
    UIImageView *_coverView;
    UILabel     *_loopLabel;
    UILabel     *_fadeInLabel;
    UILabel     *_fadeOutLabel;
    UISwitch    *_loopSwitch;
    UISwitch    *_fadeInSwitch;
    UISwitch    *_fadeOutSwitch;
    CGFloat     _currentTime;
    BOOL        _videoIsPlay;
    BOOL        _appInbackground;
}
- (instancetype)initWithFrame:(CGRect)frame coverImage:(UIImage *)image
{
    self = [super initWithFrame:frame];
    if (self) {
        _renderView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.width, self.height)];
        [self addSubview:_renderView];
        
        if (image != nil) {
            _coverView = [[UIImageView alloc] initWithFrame:_renderView.frame];
            _coverView.contentMode = UIViewContentModeScaleAspectFit;
            _coverView.image = image;
            _coverView.hidden = NO;
            [self addSubview:_coverView];
        }
        
        _playBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_playBtn setBackgroundImage:[UIImage imageNamed:@"pause_ugc_edit"] forState:UIControlStateSelected];
        [_playBtn setBackgroundImage:[UIImage imageNamed:@"play_ugc_edit"] forState:UIControlStateNormal];

        [self setPlayBtn:_videoIsPlay];
        [_playBtn  addTarget:self action:@selector(playBtnClick) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:_playBtn];
        
        CGFloat font = 12.f;
        CGFloat offset = 14.f;
        _loopLabel = [[UILabel alloc] initWithFrame:CGRectMake(self.width - controlBtnWidth, 50, controlBtnWidth, controlBtnWidth)];
        _loopLabel.text = @"循环";
        _loopLabel.textColor = [UIColor whiteColor];
        _loopLabel.font = [UIFont systemFontOfSize:font];
        _loopSwitch = [[UISwitch alloc] initWithFrame:CGRectOffset(_loopLabel.frame, -offset, controlBtnWidth)];
        [_loopSwitch addTarget:self action:@selector(onBGMLoop:) forControlEvents:UIControlEventTouchUpInside];
        
        _fadeInLabel = [[UILabel alloc] initWithFrame:CGRectOffset(_loopSwitch.frame, +offset, controlBtnWidth)];
        _fadeInLabel.text = @"淡入";
        _fadeInLabel.textColor = [UIColor whiteColor];
        _fadeInLabel.font = [UIFont systemFontOfSize:font];
        _fadeInSwitch = [[UISwitch alloc] initWithFrame:CGRectOffset(_fadeInLabel.frame, -offset, controlBtnWidth)];
        [_fadeInSwitch addTarget:self action:@selector(onBGMFadeIn:) forControlEvents:UIControlEventTouchUpInside];
        
        _fadeOutLabel = [[UILabel alloc] initWithFrame:CGRectOffset(_fadeInSwitch.frame, +offset, controlBtnWidth)];
        _fadeOutLabel.text = @"淡出";
        _fadeOutLabel.textColor = [UIColor whiteColor];
        _fadeOutLabel.font = [UIFont systemFontOfSize:font];
        _fadeOutSwitch = [[UISwitch alloc] initWithFrame:CGRectOffset(_fadeOutLabel.frame, -offset, controlBtnWidth)];
        [_fadeOutSwitch addTarget:self action:@selector(onBGMFadeOut:) forControlEvents:UIControlEventTouchUpInside];
        
        [self addSubview:_loopLabel];
        [self addSubview:_loopSwitch];
        [self addSubview:_fadeInLabel];
        [self addSubview:_fadeInSwitch];
        [self addSubview:_fadeOutLabel];
        [self addSubview:_fadeOutSwitch];
        [self setBGMControlBtnHidden:YES];
                
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(applicationDidBecomeActive:)
                                                     name:UIApplicationDidBecomeActiveNotification
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(applicationWillResignActive:)
                                                     name:UIApplicationWillResignActiveNotification
                                                   object:nil];
         [[NSNotificationCenter defaultCenter] addObserver:self
                                                  selector:@selector(onAudioSessionEvent:)
                                                      name:AVAudioSessionInterruptionNotification
                                                    object:nil];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    _renderView.frame = CGRectMake(0, 0, self.width, self.height);
    _coverView.frame = _renderView.frame;
    if (_videoIsPlay) {
        _playBtn.frame = CGRectMake((self.frame.size.width - pauseBtnWidth)/2, (self.frame.size.height - pauseBtnHeight)/2 , pauseBtnWidth, pauseBtnHeight);
    } else {
        _playBtn.frame = CGRectMake((self.frame.size.width - playBtnWidth)/2, (self.frame.size.height - playBtnHeight)/2 , playBtnWidth, playBtnHeight);
    }
    
}

- (BOOL)isPlaying
{
    return _videoIsPlay;
}

- (void)removeNotification
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)stopObservingAudioNotification
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVAudioSessionInterruptionNotification object:nil];
}

- (void)startObservingAudioNotification
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onAudioSessionEvent:)
                                                 name:AVAudioSessionInterruptionNotification
                                               object:nil];
}

- (void)applicationDidBecomeActive:(NSNotification *)noti
{
    if (_appInbackground){
        if (_delegate && [_delegate respondsToSelector:@selector(onVideoWillEnterForeground)]) {
            [_delegate onVideoWillEnterForeground];
        }
        _appInbackground = NO;
    }
}

- (void)applicationWillResignActive:(NSNotification *)noti
{
    if (_videoIsPlay) {
        [self playBtnClick];
    }
    if (!_appInbackground) {
        if (_delegate && [_delegate respondsToSelector:@selector(onVideoEnterBackground)]) {
            [_delegate onVideoEnterBackground];
        }
        _appInbackground = YES;
    }
}

- (void) onAudioSessionEvent: (NSNotification *) notification
{
    NSDictionary *info = notification.userInfo;
    AVAudioSessionInterruptionType type = [info[AVAudioSessionInterruptionTypeKey] unsignedIntegerValue];
    if (type == AVAudioSessionInterruptionTypeBegan) {
        if (_videoIsPlay) {
            [self playBtnClick];
        }
        
        if (!_appInbackground) {
            if (_delegate && [_delegate respondsToSelector:@selector(onVideoEnterBackground)]) {
                [_delegate onVideoEnterBackground];
            }
            _appInbackground = YES;
        }
       
        if (_videoIsPlay) {
            _videoIsPlay = NO;
            [self setPlayBtn:_videoIsPlay];
        }
         _coverView.hidden = YES;
    }
}


- (void)setPlayBtnHidden:(BOOL)isHidden
{
    _playBtn.hidden = isHidden;
}

- (void)playVideo
{
    [self playBtnClick];
}

- (void)playBtnClick
{
    _coverView.hidden = YES;
    
    if (_videoIsPlay) {
        _videoIsPlay = NO;
        [self setPlayBtn:_videoIsPlay];
        
        if (_delegate && [_delegate respondsToSelector:@selector(onVideoPause)]) {
            [_delegate onVideoPause];
        }
    }else{
        _videoIsPlay = YES;
        [self setPlayBtn:_videoIsPlay];
        
        if (_currentTime == 0) {
            if (_delegate && [_delegate respondsToSelector:@selector(onVideoPlay)]) {
                [_delegate onVideoPlay];
            }
        }else{
            if (_delegate && [_delegate respondsToSelector:@selector(onVideoResume)]) {
                [_delegate onVideoResume];
            }
        }
    }
}

-(void) setPlayBtn:(BOOL)videoIsPlay
{
    if (videoIsPlay) {
        _coverView.hidden = YES;
    }
    _playBtn.selected = videoIsPlay;
    _videoIsPlay = videoIsPlay;
}

#pragma BGM Control
- (void)setBGMControlBtnHidden:(BOOL)isHidden;
{
    _loopLabel.hidden = isHidden;
    _loopSwitch.hidden = isHidden;
    _fadeInLabel.hidden = isHidden;
    _fadeInSwitch.hidden = isHidden;
    _fadeOutLabel.hidden = isHidden;
    _fadeOutSwitch.hidden = isHidden;
}

-(void) onPreviewProgress:(CGFloat)time
{
    _currentTime = time;
    if (_delegate && [_delegate respondsToSelector:@selector(onVideoPlayProgress:)]) {
        [_delegate onVideoPlayProgress:time];
    }
}

-(void) onPreviewFinished
{
    if (_delegate && [_delegate respondsToSelector:@selector(onVideoPlayFinished)]) {
        [_delegate onVideoPlayFinished];
    }
}

- (void)onBGMLoop:(UISwitch *)sender
{
    if (_delegate && [_delegate respondsToSelector:@selector(onBGMLoop:)]) {
        [_delegate onBGMLoop:[sender isOn]];
    }
}

- (void)onBGMFadeIn:(UISwitch *)sender
{
    if (_delegate && [_delegate respondsToSelector:@selector(onBGMFadeIn:)]) {
        [_delegate onBGMFadeIn:[sender isOn]];
    }
}

- (void)onBGMFadeOut:(UISwitch *)sender
{
    if (_delegate && [_delegate respondsToSelector:@selector(onBGMFadeOut:)]) {
        [_delegate onBGMFadeOut:[sender isOn]];
    }
}
@end
