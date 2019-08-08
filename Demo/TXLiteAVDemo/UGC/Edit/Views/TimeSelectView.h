//
//  TimeSelectView.h
//  TXLiteAVDemo_Enterprise
//
//  Created by xiang zhang on 2017/10/27.
//  Copyright © 2017年 Tencent. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol TimeSelectViewDelegate <NSObject>
- (void)onVideoTimeEffectsClear;
- (void)onVideoTimeEffectsSpeed;
- (void)onVideoTimeEffectsBackPlay;
- (void)onVideoTimeEffectsRepeat;
@end

@interface TimeSelectView : UIView
@property(nonatomic,weak) id<TimeSelectViewDelegate> delegate;
@end
