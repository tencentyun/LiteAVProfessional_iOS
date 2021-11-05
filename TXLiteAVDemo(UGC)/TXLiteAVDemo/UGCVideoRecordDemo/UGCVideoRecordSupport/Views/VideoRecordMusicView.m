//
//  VideoRecordMusicView.m
//  TXLiteAVDemo
//
//  Created by zhangxiang on 2017/9/13.
//  Copyright © 2017年 Tencent. All rights reserved.
//

#import "VideoRecordMusicView.h"
#import "TXColor.h"
#import "UIView+Additions.h"

@implementation VideoRecordMusicView
{
    UISlider *_sldVolumeForBGM;
    UISlider *_sldVolumeForVoice;
    UISlider *_sldProcessForBGM;
    NSMutableArray* _audioEffectArry;
    NSMutableArray* _audioEffectArry2;
    UIScrollView* _audioScrollView;
    UIScrollView* _audioScrollView2;
}

-(instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _audioEffectArry = [NSMutableArray arrayWithObjects:@"原声", @"KTV", @"房间", @"会堂", @"低沉", @"洪亮", @"金属", @"磁性", nil];
        _audioEffectArry2 = [NSMutableArray arrayWithObjects:@"原声", @"熊孩子", @"萝莉", @"大叔", @"重金属", @"外国人", @"困兽", @"死肥仔", @"强电流", @"重机械", @"空灵", nil];
        [self initUI];
    }
    return self;
}

-(void)initUI{
    self.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.9];
    
    //***
    //BGM
    UIButton *btnSelectBGM = [[UIButton alloc] initWithFrame:CGRectMake(10, 15, 50, 20)];
    btnSelectBGM.titleLabel.font = [UIFont systemFontOfSize:12.f];
    btnSelectBGM.layer.borderColor = TXColor.cyan.CGColor;
    [btnSelectBGM.layer setMasksToBounds:YES];
    [btnSelectBGM.layer setCornerRadius:6];
    [btnSelectBGM.layer setBorderWidth:1.0];
    [btnSelectBGM setTitle:@"伴奏" forState:UIControlStateNormal];
    [btnSelectBGM setTitleColor:TXColor.cyan forState:UIControlStateNormal];
    [btnSelectBGM addTarget:self action:@selector(onBtnMusicSelected) forControlEvents:UIControlEventTouchUpInside];
    
    UIButton *btnStopBGM = [[UIButton alloc] initWithFrame:CGRectMake(btnSelectBGM.right + 10, 15, 50, 20)];
    btnStopBGM.titleLabel.font = [UIFont systemFontOfSize:12.f];
    btnStopBGM.layer.borderColor = TXColor.cyan.CGColor;
    [btnStopBGM.layer setMasksToBounds:YES];
    [btnStopBGM.layer setCornerRadius:6];
    [btnStopBGM.layer setBorderWidth:1.0];
    [btnStopBGM setTitle:@"结束" forState:UIControlStateNormal];
    [btnStopBGM setTitleColor:TXColor.cyan forState:UIControlStateNormal];
    [btnStopBGM addTarget:self action:@selector(onBtnMusicStoped) forControlEvents:UIControlEventTouchUpInside];
    
    UILabel *labelLoop = [[UILabel alloc] initWithFrame:CGRectMake(btnStopBGM.right + 10, 15, 60, 20)];
    labelLoop.font = [UIFont systemFontOfSize:14.f];
    labelLoop.textColor = [UIColor blackColor];
    labelLoop.text = @"BGM循环";
    
    UISwitch *switchLoop = [[UISwitch alloc] initWithFrame:CGRectMake(labelLoop.right + 10, 10, 50, 20)];
    [switchLoop addTarget:self action:@selector(onBtnMusicLoop:) forControlEvents:UIControlEventTouchUpInside];
    [switchLoop setOn:YES];
   
    UILabel *labVolumeForBGM = [[UILabel alloc] initWithFrame:CGRectMake(15, btnSelectBGM.bottom + 25, 30, 20)];
    [labVolumeForBGM setText:@"伴奏"];
    [labVolumeForBGM setFont:[UIFont systemFontOfSize:12.f]];
    labVolumeForBGM.textColor = TXColor.cyan;
    //    [_labVolumeForBGM sizeToFit];
    
    _sldVolumeForBGM = [[UISlider alloc] initWithFrame:CGRectMake(labVolumeForBGM.right + 40, labVolumeForBGM.y, 300, 20)];
    _sldVolumeForBGM.minimumValue = 0;
    _sldVolumeForBGM.maximumValue = 2;
    _sldVolumeForBGM.value = 1;
    [_sldVolumeForBGM setThumbImage:[UIImage imageNamed:@"slider"] forState:UIControlStateNormal];
    [_sldVolumeForBGM setMinimumTrackImage:[UIImage imageNamed:@"green"] forState:UIControlStateNormal];
    [_sldVolumeForBGM setMaximumTrackImage:[UIImage imageNamed:@"gray"] forState:UIControlStateNormal];
    [_sldVolumeForBGM addTarget:self action:@selector(onBGMValueChange:) forControlEvents:UIControlEventValueChanged];
    
    UILabel *labVolumeForVoice = [[UILabel alloc] initWithFrame:CGRectMake(15, _sldVolumeForBGM.bottom + 15, 30, 20)];
    [labVolumeForVoice setText:@"人声"];
    [labVolumeForVoice setFont:[UIFont systemFontOfSize:12.f]];
    labVolumeForVoice.textColor = TXColor.cyan;
    //    [_labVolumeForVoice sizeToFit];
    
    _sldVolumeForVoice = [[UISlider alloc] initWithFrame:CGRectMake(labVolumeForVoice.right + 40, labVolumeForVoice.y, 300, 20)];
    _sldVolumeForVoice.minimumValue = 0;
    _sldVolumeForVoice.maximumValue = 2;
    _sldVolumeForVoice.value = 1;
    [_sldVolumeForVoice setThumbImage:[UIImage imageNamed:@"slider"] forState:UIControlStateNormal];
    [_sldVolumeForVoice setMinimumTrackImage:[UIImage imageNamed:@"green"] forState:UIControlStateNormal];
    [_sldVolumeForVoice setMaximumTrackImage:[UIImage imageNamed:@"gray"] forState:UIControlStateNormal];
    [_sldVolumeForVoice addTarget:self action:@selector(onVoiceValueChange:) forControlEvents:UIControlEventValueChanged];
    
    
    UILabel *labBGMProcess = [[UILabel alloc] initWithFrame:CGRectMake(15, _sldVolumeForVoice.bottom + 15, 30, 20)];
    [labBGMProcess setText:@"音乐"];
    [labBGMProcess setFont:[UIFont systemFontOfSize:12.f]];
    labBGMProcess.textColor = TXColor.cyan;
    //    [_labVolumeForVoice sizeToFit];
    
    _sldProcessForBGM = [[UISlider alloc] initWithFrame:CGRectMake(labBGMProcess.right + 40, labBGMProcess.y, 300, 20)];
    _sldProcessForBGM.minimumValue = 0;
    _sldProcessForBGM.maximumValue = 0;
    _sldProcessForBGM.value = 0;
    [_sldProcessForBGM setContinuous:NO];
    [_sldProcessForBGM setThumbImage:[UIImage imageNamed:@"slider"] forState:UIControlStateNormal];
    [_sldProcessForBGM setMinimumTrackImage:[UIImage imageNamed:@"green"] forState:UIControlStateNormal];
    [_sldProcessForBGM setMaximumTrackImage:[UIImage imageNamed:@"gray"] forState:UIControlStateNormal];
    [_sldProcessForBGM addTarget:self action:@selector(onBGMPlayChange:) forControlEvents:UIControlEventValueChanged];
    [_sldProcessForBGM addTarget:self action:@selector(onBGMPlayBeginChange:) forControlEvents:UIControlEventTouchDragInside];
    
    //混响效果
    CGFloat btnSpace = 10;
    CGFloat btnWidth = 40;
    _audioScrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, _sldProcessForBGM.bottom + 15, self.width, btnWidth)];
    _audioScrollView.contentSize = CGSizeMake((btnWidth + btnSpace) * _audioEffectArry.count, btnWidth);
    _audioScrollView.showsVerticalScrollIndicator = NO;
    _audioScrollView.showsHorizontalScrollIndicator = NO;
    for (int i=0; i<_audioEffectArry.count; ++i) {
        UIButton *btn = [[UIButton alloc] initWithFrame:CGRectMake(btnSpace +(btnWidth + btnSpace) * i, 0, btnWidth, btnWidth)];
        btn.titleLabel.font = [UIFont systemFontOfSize:12.f];
        [btn setTitle:[_audioEffectArry objectAtIndex:i] forState:UIControlStateNormal];
        [btn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [btn setTitleColor:[UIColor whiteColor] forState:UIControlStateSelected];
        [btn setBackgroundImage:[UIImage imageNamed:@"round-unselected"] forState:UIControlStateNormal];
        [btn.layer setMasksToBounds:YES];
        [btn.layer setCornerRadius:btnWidth/2];
        [btn addTarget:self action:@selector(selectEffect:) forControlEvents:UIControlEventTouchUpInside];
        btn.tag = i;
        [_audioScrollView addSubview:btn];
        
        if (i == 0) {
            btn.selected = YES;
            [btn setBackgroundImage:[UIImage imageNamed:@"round-selected"] forState:UIControlStateNormal];
        }
    }
    
    //变声类型
    _audioScrollView2 = [[UIScrollView alloc] initWithFrame:CGRectMake(0, _audioScrollView.bottom + 5, self.width, btnWidth)];
    _audioScrollView2.contentSize = CGSizeMake((btnWidth + btnSpace) * _audioEffectArry2.count, btnWidth);
    _audioScrollView2.showsVerticalScrollIndicator = NO;
    _audioScrollView2.showsHorizontalScrollIndicator = NO;
    for (int i=0; i<_audioEffectArry2.count; ++i) {
        UIButton *btn = [[UIButton alloc] initWithFrame:CGRectMake(btnSpace +(btnWidth + btnSpace) * i, 0, btnWidth, btnWidth)];
        btn.titleLabel.font = [UIFont systemFontOfSize:12.f];
        [btn setTitle:[_audioEffectArry2 objectAtIndex:i] forState:UIControlStateNormal];
        [btn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [btn setTitleColor:[UIColor whiteColor] forState:UIControlStateSelected];
        [btn setBackgroundImage:[UIImage imageNamed:@"round-unselected"] forState:UIControlStateNormal];
        [btn.layer setMasksToBounds:YES];
        [btn.layer setCornerRadius:btnWidth/2];
        [btn addTarget:self action:@selector(selectEffect2:) forControlEvents:UIControlEventTouchUpInside];
        btn.tag = i;
        [_audioScrollView2 addSubview:btn];
        
        if (i == 0) {
            btn.selected = YES;
            [btn setBackgroundImage:[UIImage imageNamed:@"round-selected"] forState:UIControlStateNormal];
        }
    }
    
    [self addSubview:btnSelectBGM];
    [self addSubview:btnStopBGM];
    [self addSubview:labelLoop];
    [self addSubview:switchLoop];
    [self addSubview:labVolumeForBGM];
    [self addSubview:_sldVolumeForBGM];
    [self addSubview:labVolumeForVoice];
    [self addSubview:_sldVolumeForVoice];
    [self addSubview:labBGMProcess];
    [self addSubview:_sldProcessForBGM];
    [self addSubview:_audioScrollView];
    [self addSubview:_audioScrollView2];
}

-(void)setBGMDuration:(CGFloat)duration
{
    _sldProcessForBGM.maximumValue = duration;
}

-(void)setBGMPlayTime:(CGFloat)time
{
    _sldProcessForBGM.value = time;
}

-(void)onBtnMusicSelected
{
    if (_delegate && [_delegate respondsToSelector:@selector(onBtnMusicSelected)]) {
        [_delegate onBtnMusicSelected];
    }
}

-(void)onBtnMusicStoped
{
    if (_delegate && [_delegate respondsToSelector:@selector(onBtnMusicStoped)]) {
        [_delegate onBtnMusicStoped];
    }
}

-(void)onBtnMusicLoop:(UISwitch *)switchLoop
{
    if (_delegate && [_delegate respondsToSelector:@selector(onBtnMusicLoop:)]) {
        [_delegate onBtnMusicLoop:switchLoop.isOn];
    }
}

-(void)onBGMPlayBeginChange:(UISlider *)slider
{
    if (_delegate && [_delegate respondsToSelector:@selector(onBGMValueChange:)]) {
        [_delegate onBGMPlayBeginChange];
    }
}

-(void)onBGMValueChange:(UISlider *)slider
{
    if (_delegate && [_delegate respondsToSelector:@selector(onBGMValueChange:)]) {
        [_delegate onBGMValueChange:slider];
    }
}

-(void)onVoiceValueChange:(UISlider *)slider
{
    if (_delegate && [_delegate respondsToSelector:@selector(onVoiceValueChange:)]) {
        [_delegate onVoiceValueChange:slider];
    }
}

-(void)onBGMPlayChange:(UISlider *)slider
{
    if (_delegate && [_delegate respondsToSelector:@selector(onBGMPlayChange:)]) {
        [_delegate onBGMPlayChange:slider];
    }
}

- (void)selectEffect:(UIButton *)button {
    for(UIView *view in _audioScrollView.subviews){
        if ([view isKindOfClass:[UIButton class]]) {
            UIButton *btn = (UIButton *)view;
            btn.selected = NO;
            [btn setBackgroundImage:[UIImage imageNamed:@"round-unselected"] forState:UIControlStateNormal];
        }
    }
    button.selected = YES;
    [button setBackgroundImage:[UIImage imageNamed:@"round-selected"] forState:UIControlStateNormal];
    if (self.delegate) [self.delegate selectEffect:button.tag];
}

- (void)selectEffect2:(UIButton *)button {
    for(UIButton *view in _audioScrollView2.subviews){
        if ([view isKindOfClass:[UIButton class]]) {
            UIButton *btn = (UIButton *)view;
            btn.selected = NO;
            [btn setBackgroundImage:[UIImage imageNamed:@"round-unselected"] forState:UIControlStateNormal];
        }
    }
    button.selected = YES;
    [button setBackgroundImage:[UIImage imageNamed:@"round-selected"] forState:UIControlStateNormal];
    if (self.delegate) [self.delegate selectEffect2:button.tag >= 5 ? button.tag + 1 : button.tag];
}

-(void)resetUI
{
    _sldVolumeForBGM.value = 1;
    _sldVolumeForVoice.value = 1;
    _sldProcessForBGM.value = 0;
    for(UIView *view in _audioScrollView.subviews){
        if ([view isKindOfClass:[UIButton class]]) {
            UIButton *btn = (UIButton *)view;
            if (btn.tag == 0) {
                btn.selected = YES;
                [btn setBackgroundImage:[UIImage imageNamed:@"round-selected"] forState:UIControlStateNormal];
            }else{
                btn.selected = NO;
                [btn setBackgroundImage:[UIImage imageNamed:@"round-unselected"] forState:UIControlStateNormal];
            }
        }
    }
    for(UIView *view in _audioScrollView2.subviews){
        if ([view isKindOfClass:[UIButton class]]) {
            UIButton *btn = (UIButton *)view;
            if (btn.tag == 0) {
                btn.selected = YES;
                [btn setBackgroundImage:[UIImage imageNamed:@"round-selected"] forState:UIControlStateNormal];
            }else{
                btn.selected = NO;
                [btn setBackgroundImage:[UIImage imageNamed:@"round-unselected"] forState:UIControlStateNormal];
            }
        }
    }
}
@end
