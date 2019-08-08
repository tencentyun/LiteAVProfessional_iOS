//
//  VideoEffectSlider.h
//  TXLiteAVDemo
//
//  Created by xiang zhang on 2017/11/3.
//  Copyright © 2017年 Tencent. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TXLiteAVSDKHeader.h"

@protocol VideoEffectViewDelegate <NSObject>
- (void)onVideoEffectBeginClick:(TXEffectType)effectType;
- (void)onVideoEffectEndClick:(TXEffectType)effectType;
@end

@interface EffectSelectView : UIView
@property (nonatomic,weak) id <VideoEffectViewDelegate> delegate;
@end
