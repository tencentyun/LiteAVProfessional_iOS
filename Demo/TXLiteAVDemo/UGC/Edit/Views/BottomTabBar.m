//
//  BottomTabBar.m
//  DeviceManageIOSApp
//
//  Created by rushanting on 2017/5/11.
//  Copyright © 2017年 tencent. All rights reserved.
//

#import "BottomTabBar.h"
#import "TXColor.h"
#import "UIView+Additions.h"

#define kButtonCount 7
#define kButtonNormalColor TXColor.black;

@implementation BottomTabBar
{
    UIButton*       _btnCut;        //裁剪
    UIButton*       _btnTime;       //时间特效
    UIButton*       _btnFilter;     //滤镜
    UIButton*       _btnMusic;      //混音
    UIButton*       _btnEffect;     //特效
    UIButton*       _btnText;       //字幕
    UIButton*       _btnPaster;     //贴纸
}

- (id)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        
        
        _btnCut = [[UIButton alloc] init];
//        _btnCut.backgroundColor = kButtonNormalColor;
        [_btnCut addTarget:self action:@selector(onCutBtnClicked) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:_btnCut];
        
        _btnTime = [[UIButton alloc] init];
        //        _btnCut.backgroundColor = kButtonNormalColor;
        [_btnTime addTarget:self action:@selector(onTimeBtnClicked) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:_btnTime];
        
        _btnEffect = [[UIButton alloc] init];
        //        _btnMusic.backgroundColor = kButtonNormalColor;
        [_btnEffect addTarget:self action:@selector(onEffectBtnClicked) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:_btnEffect];
        
        _btnFilter = [[UIButton alloc] init];
//        _btnFilter.backgroundColor = kButtonNormalColor;
        [_btnFilter addTarget:self action:@selector(onFilterBtnClicked) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:_btnFilter];
        
        _btnMusic = [[UIButton alloc] init];
//        _btnMusic.backgroundColor = kButtonNormalColor;
        [_btnMusic addTarget:self action:@selector(onMusicBtnClicked) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:_btnMusic];
        
        _btnPaster = [[UIButton alloc] init];
//        _btnPaster.backgroundColor = kButtonNormalColor;
        [_btnPaster addTarget:self action:@selector(onPasterBtnClicked) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:_btnPaster];
        
        _btnText = [[UIButton alloc] init];
//        _btnText.backgroundColor = kButtonNormalColor;
        [_btnText addTarget:self action:@selector(onTextBtnClicked) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:_btnText];
        
        __weak BottomTabBar *wself = self;
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0), ^{
            UIImage *cut = [UIImage imageNamed:@"ic_cut" inBundle:nil compatibleWithTraitCollection:nil];
            UIImage *cut_press = [UIImage imageNamed:@"ic_cut_press" inBundle:nil compatibleWithTraitCollection:nil];
            UIImage *time = [UIImage imageNamed:@"time" inBundle:nil compatibleWithTraitCollection:nil];
            UIImage *time_press = [UIImage imageNamed:@"time_press" inBundle:nil compatibleWithTraitCollection:nil];
            UIImage *music = [UIImage imageNamed:@"ic_music" inBundle:nil compatibleWithTraitCollection:nil];
            UIImage *music_press = [UIImage imageNamed:@"ic_music_press" inBundle:nil compatibleWithTraitCollection:nil];
            UIImage *beautiful = [UIImage imageNamed:@"ic_beautiful" inBundle:nil compatibleWithTraitCollection:nil];
            UIImage *beautiful_press = [UIImage imageNamed:@"ic_beautiful_press" inBundle:nil compatibleWithTraitCollection:nil];
            UIImage *decorate = [UIImage imageNamed:@"decorate_nor" inBundle:nil compatibleWithTraitCollection:nil];
            UIImage *decorate_press = [UIImage imageNamed:@"decorate_pressed" inBundle:nil compatibleWithTraitCollection:nil];
            UIImage *word = [UIImage imageNamed:@"ic_word" inBundle:nil compatibleWithTraitCollection:nil];
            UIImage *word_press = [UIImage imageNamed:@"ic_word_press" inBundle:nil compatibleWithTraitCollection:nil];
            UIImage *selectedImage = [UIImage imageNamed:@"tab" inBundle:nil compatibleWithTraitCollection:nil];
            UIImage *unselectedImage = [UIImage imageNamed:@"button_gray" inBundle:nil compatibleWithTraitCollection:nil];
            dispatch_async(dispatch_get_main_queue(), ^{
                __strong BottomTabBar *self = wself;
                if (!self) {
                    return;
                }
                [self->_btnCut setImage:cut forState:UIControlStateNormal];
                [self->_btnCut setImage:cut_press forState:UIControlStateHighlighted];
                
                [self->_btnTime setImage:time forState:UIControlStateNormal];
                [self->_btnTime setImage:time_press forState:UIControlStateHighlighted];
                
                [self->_btnEffect setImage:music forState:UIControlStateNormal];
                [self->_btnEffect setImage:music_press forState:UIControlStateHighlighted];
                
                [self->_btnFilter setImage:beautiful forState:UIControlStateNormal];
                [self->_btnFilter setImage:beautiful_press forState:UIControlStateHighlighted];
                
                [self->_btnMusic setImage:music forState:UIControlStateNormal];
                [self->_btnMusic setImage:music_press forState:UIControlStateHighlighted];
                
                [self->_btnPaster setImage:decorate forState:UIControlStateNormal];
                [self->_btnPaster setImage:decorate_press forState:UIControlStateHighlighted];
                
                [self->_btnText setImage:word forState:UIControlStateNormal];
                [self->_btnText setImage:word_press forState:UIControlStateHighlighted];
#define SET_BACKGROUND(x) [(x) setBackgroundImage:unselectedImage forState:UIControlStateNormal]; [(x) setBackgroundImage:selectedImage forState:UIControlStateSelected];
                SET_BACKGROUND(self->_btnCut);
                SET_BACKGROUND(self->_btnTime);
                SET_BACKGROUND(self->_btnEffect);
                SET_BACKGROUND(self->_btnFilter);
                SET_BACKGROUND(self->_btnMusic);
                SET_BACKGROUND(self->_btnPaster);
                SET_BACKGROUND(self->_btnText);
#undef SET_BACKGROUND
            });
        });
        [self onCutBtnClicked];
        
    }
    
    return self;
}


- (void)layoutSubviews
{
    [super layoutSubviews];
    
    CGFloat buttonWidth= self.width / kButtonCount;
    int i = 0;
    _btnCut.frame = CGRectMake(buttonWidth * i++, 0, buttonWidth, self.height);
    _btnTime.frame = CGRectMake(buttonWidth * i++, 0, buttonWidth, self.height);
    _btnEffect.frame = CGRectMake(buttonWidth * i++, 0, buttonWidth, self.height);
    _btnFilter.frame = CGRectMake(buttonWidth * i++, 0, buttonWidth, self.height);
    _btnMusic.frame = CGRectMake(buttonWidth * i++, 0, buttonWidth, self.height);
    _btnPaster.frame = CGRectMake(buttonWidth * i++, 0, buttonWidth, self.height);
    _btnText.frame = CGRectMake(buttonWidth * i++, 0, buttonWidth, self.height);
}

- (void)resetButtonNormal
{
    [_btnCut setSelected:NO];
    [_btnTime setSelected:NO];
    [_btnFilter setSelected:NO];
    [_btnMusic setSelected:NO];
    [_btnEffect setSelected:NO];
    [_btnPaster setSelected:NO];
    [_btnText setSelected:NO];
}


#pragma mark - click handle
- (void)onCutBtnClicked
{
    [self resetButtonNormal];
    [_btnCut setSelected:YES];
    [self.delegate onCutBtnClicked];
}

- (void)onTimeBtnClicked
{
    [self resetButtonNormal];
    [_btnTime setSelected:YES];
    [self.delegate onTimeBtnClicked];
}

- (void)onEffectBtnClicked
{
    [self resetButtonNormal];
    [_btnEffect setSelected:YES];
    [self.delegate onEffectBtnClicked];
}

- (void)onFilterBtnClicked
{
    [self resetButtonNormal];
    [_btnFilter setSelected:YES];
    [self.delegate onFilterBtnClicked];
}

- (void)onMusicBtnClicked
{
    [self resetButtonNormal];
    [_btnMusic setSelected:YES];
    [self.delegate onMusicBtnClicked];
}

- (void)onTextBtnClicked
{
    [self resetButtonNormal];
    [_btnText setSelected:YES];
    [self.delegate onTextBtnClicked];
}

- (void)onPasterBtnClicked
{
    [self resetButtonNormal];
    [_btnPaster setSelected:YES];
    [self.delegate onPasterBtnClicked];
}

@end
