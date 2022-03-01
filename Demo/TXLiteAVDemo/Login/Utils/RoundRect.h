//
//  RoundRect.h
//  TXLiteAVDemo_Enterprise
//
//  Created by peterwtma on 2021/8/8.
//  Copyright © 2021 Tencent. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIView(Extension)
- (void)roundedRect:(CGRect)rect byRoundingCorners:(UIRectCorner)byRoundingCorners cornerRadii:(CGSize) cornerRadii;

- (void)roundedCircle:(CGRect)rect;
@end

NS_ASSUME_NONNULL_END
