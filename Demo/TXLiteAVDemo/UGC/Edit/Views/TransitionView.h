//
//  TransitionView.h
//  TXLiteAVDemo_Enterprise
//
//  Created by xiang zhang on 2018/5/11.
//  Copyright © 2018年 Tencent. All rights reserved.
//

#import <UIKit/UIKit.h>

//TXTransitionType_LefRightSlipping,     //左右滑动
//TXTransitionType_UpDownSlipping,       //上下滑动
//TXTransitionType_Enlarge,              //放大
//TXTransitionType_Narrow,               //缩小
//TXTransitionType_RotationalScaling,    //旋转缩放
//TXTransitionType_FadeinFadeout,        //淡入淡出

@protocol TransitionViewDelegate <NSObject>
- (void)onVideoTransitionLefRightSlipping;
- (void)onVideoTransitionUpDownSlipping;
- (void)onVideoTransitionEnlarge;
- (void)onVideoTransitionNarrow;
- (void)onVideoTransitionRotationalScaling;
- (void)onVideoTransitionFadeinFadeout;
@end

@interface TransitionView : UIView
@property(nonatomic,weak) id<TransitionViewDelegate> delegate;
@end
