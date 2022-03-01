//
//  ToastView.h
//  TXLiteAVDemo_Enterprise
//
//  Created by peterwtma on 2021/8/8.
//  Copyright © 2021 Tencent. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface CSToast : UIView

/**
 概述:
 关于工具:
 本工具是一个简单的提示框（Toast）。
 默认以window为载体，显示在window中心。可以调整距离上下边的距离。
 可以指定在某个View中显示，默认显示在中心，不可以调整位置。
 Toast接收点击事件，点击时可以移除。
 viewDidAppear:之后调用有效。
 
 关于API:支持OC风格，也支持链式风格。
 链式风格API，一般形式：
 CSToast.xxx(...).xxx(...).show();
 位置属性权重说明：inView > top > bottom. 及同时设置时，权重高的生效。
 
 默认配置:
 text            --> two spaces（两个空格）
 inView          --> window
 backgroundColor --> black 0.8(alpha)
 textColor       --> white
 duration        --> 1.5s
 fontSize        --> 15
 maxFontSize     --> 22
 minFontSize     --> 10
 maxWidth        --> 180 + 30
 */

////////////////////////////////<< OC风格 >>//////////////////////////////////////////////
+ (void)showWithText:(NSString *)text;
+ (void)showWithText:(NSString *)text duration:(CGFloat)duration;
+ (void)showWithText:(NSString *)text topOffset:(CGFloat)topOffset;
+ (void)showWithText:(NSString *)text topOffset:(CGFloat)topOffset duration:(CGFloat)duration;
+ (void)showWithText:(NSString *)text bottomOffset:(CGFloat)bottomOffset;
+ (void)showWithText:(NSString *)text bottomOffset:(CGFloat)bottomOffset duration:(CGFloat)duration;
+ (void)showWithText:(NSString *)text inView:(UIView *)view;
+ (void)showWithText:(NSString *)text inView:(UIView *)view duration:(CGFloat)duration;


////////////////////////////////<< 链式风格 >>//////////////////////////////////////////////
// 例如：CSToast.text(@"Hello Joslyn").show();
+ (CSToast *(^)(NSString *text))text;
- (CSToast *(^)(CGFloat fontSize))fontSize;
- (CSToast *(^)(CGFloat duration))duration;
- (CSToast *(^)(CGFloat topOffset))top;
- (CSToast *(^)(CGFloat bottomOffset))bottom;
- (CSToast *(^)(UIColor *textColor))textColor;
- (CSToast *(^)(UIColor *bgColor))bgColor;  // Toast的背景色。默认为黑色 透明度0.8。
- (CSToast *(^)(UIView *view))inView;       // 展示的容器，默认为window
- (void(^)())show;                          // 展示时在末尾必须调用。


@end
