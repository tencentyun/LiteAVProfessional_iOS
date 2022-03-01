//
//  LayoutDefine.h
//  TXLiteAVDemo
//
//  Created by peterwtma on 2021/7/20.
//  Copyright © 2021 Tencent. All rights reserved.
//
#import <UIKit/UIKit.h>

@interface LayoutDefine : NSObject
@property (nonatomic, assign) CGFloat screenWidth;
@property (nonatomic, assign) CGFloat screenHeight;
@property (nonatomic, assign) CGFloat deviceSafeTopHeight;
@property (nonatomic, assign) CGFloat deviceSafeBottomHeight;
- (CGFloat)widthConvertPixel:(CGFloat)w;
+ (CGFloat)convertPixel:(CGFloat)h;
@end
