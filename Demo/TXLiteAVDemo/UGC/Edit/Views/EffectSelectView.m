//
//  VideoEffectSlider.m
//  TXLiteAVDemo
//
//  Created by xiang zhang on 2017/11/3.
//  Copyright © 2017年 Tencent. All rights reserved.
//

#import "EffectSelectView.h"
#import "UIView+Additions.h"
#import "TXColor.h"
#import "TXCVEFColorPalette.h"

#define EFFCT_IMAGE_WIDTH  65 * kScaleY
#define EFFCT_IMAGE_SPACE  20

@interface EffectSelectView()
{
    UIScrollView *_effectSelectView;
}
@end
@implementation EffectSelectView
- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        NSString *cnNum = @"一二三四五六七八九十";
        NSUInteger effectCount = (NSUInteger)TXEffectType_Count;
        const CGFloat minSpacing = 3.0;
        const CGFloat cellWidth = floorf(EFFCT_IMAGE_WIDTH);
        CGFloat space = floorf(self.width - cellWidth * effectCount) / (effectCount + 1);
        space = MAX(minSpacing, space);
        _effectSelectView = [[UIScrollView alloc] initWithFrame:CGRectMake(0,(self.height - cellWidth)/2, self.width,cellWidth)];
        _effectSelectView.showsHorizontalScrollIndicator = NO;
        for (int i = 0 ; i < effectCount ; i ++){
            UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
            [btn setFrame:CGRectMake(space + (space + cellWidth) * i, 0, cellWidth, cellWidth)];
            NSString *indexString = [cnNum substringWithRange:NSMakeRange(i%10, 1)];
            if (i >= 10) {
                indexString = [@"十" stringByAppendingString:indexString];
            }
            NSString *title = [@"特效" stringByAppendingString: indexString];
            [btn setTitle:title forState:UIControlStateNormal];
            btn.titleLabel.font = [UIFont systemFontOfSize:14];
            btn.titleLabel.adjustsFontSizeToFitWidth = YES;
            [btn setBackgroundColor:[UIColor blueColor]];
            btn.layer.cornerRadius = cellWidth / 2.0;
            btn.layer.masksToBounds = YES;
            btn.titleLabel.numberOfLines = 0;
            btn.tag = i;
            
            [btn addTarget:self action:@selector(beginPress:) forControlEvents:UIControlEventTouchDown];
            [btn addTarget:self action:@selector(endPress:) forControlEvents:UIControlEventTouchUpInside | UIControlEventTouchUpOutside];
            [_effectSelectView addSubview:btn];
            UIColor *color = TXCVEFColorPaletteColorAtIndex(btn.tag);
            [btn setBackgroundColor:color];
        }
        CGSize contentSize = _effectSelectView.bounds.size;
        CGFloat contentWidth = (space + cellWidth) * effectCount + space;
        if (contentWidth > contentSize.width) {
            contentSize.width = contentWidth;
            [_effectSelectView setContentSize:contentSize];
        }
        [self addSubview:_effectSelectView];
    }
    return self;
}

//响应事件
-(void) beginPress: (UIButton *) button {
    CGFloat offset = _effectSelectView.contentOffset.x;
    if (offset < 0 || offset > _effectSelectView.contentSize.width - _effectSelectView.bounds.size.width) {
        // 在回弹区域会触发button事件被cancel,导致收不到 TouchEnd 事件
        return;
    }
    TXEffectType type = (TXEffectType)button.tag;
    [self.delegate onVideoEffectBeginClick:type];
}

//响应事件
-(void) endPress: (UIButton *) button {
    TXEffectType type = (TXEffectType)button.tag;
    [self.delegate onVideoEffectEndClick:type];
}
@end
