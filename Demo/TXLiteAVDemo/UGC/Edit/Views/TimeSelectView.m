//
//  TimeSelectView.m
//  TXLiteAVDemo_Enterprise
//
//  Created by xiang zhang on 2017/10/27.
//  Copyright © 2017年 Tencent. All rights reserved.
//

#import "TimeSelectView.h"
#import "UIView+Additions.h"
#import "TXColor.h"

#define EFFCT_COUNT        4
#define EFFCT_IMAGE_WIDTH  65 * kScaleY
#define EFFCT_IMAGE_SPACE  20

@implementation TimeSelectView
{
    UIScrollView *_effectSelectView;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        CGFloat space = (self.width - EFFCT_IMAGE_WIDTH * EFFCT_COUNT) / (EFFCT_COUNT + 1);
        _effectSelectView = [[UIScrollView alloc] initWithFrame:CGRectMake(0,(CGRectGetHeight(frame) - EFFCT_IMAGE_WIDTH)/2, self.width,EFFCT_IMAGE_WIDTH)];
        NSArray *effectNameS = @[@"无",@"倒放",@"反复",@"慢动作"];
        for (int i = 0 ; i < EFFCT_COUNT ; i ++){
            UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
            [btn setFrame:CGRectMake(space + (space + EFFCT_IMAGE_WIDTH) * i, 0, EFFCT_IMAGE_WIDTH, EFFCT_IMAGE_WIDTH)];
            [btn setTitle:effectNameS[i] forState:UIControlStateNormal];
            btn.titleLabel.font = [UIFont systemFontOfSize:14];
            [btn setBackgroundColor:TXColor.cyan];
            btn.layer.cornerRadius = EFFCT_IMAGE_WIDTH / 2.0;
            btn.layer.masksToBounds = YES;
            btn.titleLabel.numberOfLines = 0;
            btn.tag = i;
            
            [btn addTarget:self action:@selector(onBtnClick:) forControlEvents:UIControlEventTouchUpInside];
            [_effectSelectView addSubview:btn];
        }
        [self addSubview:_effectSelectView];
    }
    return self;
}

- (void)onBtnClick:(UIButton *)btn
{
    if (btn.tag == 0) {
        if (_delegate && [_delegate respondsToSelector:@selector(onVideoTimeEffectsSpeed)]) {
            [_delegate onVideoTimeEffectsClear];
        }
    }
    else if (btn.tag == 1) {
        if (_delegate && [_delegate respondsToSelector:@selector(onVideoTimeEffectsSpeed)]) {
            [_delegate onVideoTimeEffectsBackPlay];
        }
    }
    else if (btn.tag == 2){
        if (_delegate && [_delegate respondsToSelector:@selector(onVideoTimeEffectsBackPlay)]) {
            [_delegate onVideoTimeEffectsRepeat];
        }
    }
    else if (btn.tag == 3){
        if (_delegate && [_delegate respondsToSelector:@selector(onVideoTimeEffectsRepeat)]) {
            [_delegate onVideoTimeEffectsSpeed];
        }
    }
    [self resetBtnColor:btn];
}

- (void)resetBtnColor:(UIButton *)btn
{
    for (UIButton * btn in _effectSelectView.subviews) {
        [btn setBackgroundColor:TXColor.cyan];
    }
    [btn setBackgroundColor:[UIColor grayColor]];
}

@end
