//
//  TransitionView.m
//  TXLiteAVDemo_Enterprise
//
//  Created by xiang zhang on 2018/5/11.
//  Copyright © 2018年 Tencent. All rights reserved.
//

#import "TransitionView.h"
#import "UIView+Additions.h"
#import "TXColor.h"

#define TRANSITIN_IMAGE_WIDTH  65 * kScaleY
#define TRANSITIN_IMAGE_SPACE  10

@implementation TransitionView
{
    UIScrollView *_transitionView;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        NSArray *transitionNameS = @[@"左右",@"上下",@"放大",@"缩小",@"旋转",@"淡入淡出"];
        _transitionView = [[UIScrollView alloc] initWithFrame:CGRectMake(0,0, self.width,TRANSITIN_IMAGE_WIDTH)];
        _transitionView.contentSize = CGSizeMake((TRANSITIN_IMAGE_WIDTH + TRANSITIN_IMAGE_SPACE) * transitionNameS.count, TRANSITIN_IMAGE_WIDTH);
        _transitionView.showsVerticalScrollIndicator = NO;
        _transitionView.showsHorizontalScrollIndicator = NO;
        for (int i = 0 ; i < transitionNameS.count ; i ++){
            UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
            [btn setFrame:CGRectMake(TRANSITIN_IMAGE_SPACE + (TRANSITIN_IMAGE_SPACE + TRANSITIN_IMAGE_WIDTH) * i, 0, TRANSITIN_IMAGE_WIDTH, TRANSITIN_IMAGE_WIDTH)];
            [btn setTitle:transitionNameS[i] forState:UIControlStateNormal];
            btn.titleLabel.font = [UIFont systemFontOfSize:14];
            [btn setBackgroundColor:TXColor.cyan];
            btn.layer.cornerRadius = TRANSITIN_IMAGE_WIDTH / 2.0;
            btn.layer.masksToBounds = YES;
            btn.titleLabel.numberOfLines = 0;
            btn.tag = i;
            
            [btn addTarget:self action:@selector(onBtnClick:) forControlEvents:UIControlEventTouchUpInside];
            [_transitionView addSubview:btn];
            
            if (i == 0) {
                [self resetBtnColor:btn];
            }
        }
        [self addSubview:_transitionView];
    }
    return self;
}

- (void)onBtnClick:(UIButton *)btn
{
    if (btn.tag == 0) {
        if (_delegate && [_delegate respondsToSelector:@selector(onVideoTransitionUpDownSlipping)]) {
            [_delegate onVideoTransitionLefRightSlipping];
        }
    }
    else if (btn.tag == 1) {
        if (_delegate && [_delegate respondsToSelector:@selector(onVideoTransitionUpDownSlipping)]) {
            [_delegate onVideoTransitionUpDownSlipping];
        }
    }
    else if (btn.tag == 2){
        if (_delegate && [_delegate respondsToSelector:@selector(onVideoTransitionEnlarge)]) {
            [_delegate onVideoTransitionEnlarge];
        }
    }
    else if (btn.tag == 3){
        if (_delegate && [_delegate respondsToSelector:@selector(onVideoTransitionNarrow)]) {
            [_delegate onVideoTransitionNarrow];
        }
    }
    else if (btn.tag == 4){
        if (_delegate && [_delegate respondsToSelector:@selector(onVideoTransitionNarrow)]) {
            [_delegate onVideoTransitionRotationalScaling];
        }
    }
    else if (btn.tag == 5){
        if (_delegate && [_delegate respondsToSelector:@selector(onVideoTransitionNarrow)]) {
            [_delegate onVideoTransitionFadeinFadeout];
        }
    }
    [self resetBtnColor:btn];
}

- (void)resetBtnColor:(UIButton *)btn
{
    for (UIButton * btn in _transitionView.subviews) {
        [btn setBackgroundColor:TXColor.cyan];
    }
    [btn setBackgroundColor:[UIColor grayColor]];
}
@end
