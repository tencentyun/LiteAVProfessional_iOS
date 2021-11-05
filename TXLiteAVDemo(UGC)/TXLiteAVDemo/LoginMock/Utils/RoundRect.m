//
//  RoundRect.m
//  TXLiteAVDemo_Enterprise
//
//  Created by peterwtma on 2021/8/8.
//  Copyright © 2021 Tencent. All rights reserved.
//

#import "RoundRect.h"

@implementation UIView(Extension)

/// 切部分圆角
///
/// - Parameters:
///   - rect: 传入View的Rect
///   - byRoundingCorners: 裁剪位置
///   - cornerRadii: 裁剪半径
- (void)roundedRect:(CGRect)rect byRoundingCorners:(UIRectCorner)byRoundingCorners cornerRadii:(CGSize) cornerRadii {
    UIBezierPath* maskPath = [UIBezierPath bezierPathWithRoundedRect:rect byRoundingCorners:byRoundingCorners cornerRadii:cornerRadii];
    CAShapeLayer* maskLayer = [[CAShapeLayer alloc] init];
    maskLayer.frame = self.bounds;
    maskLayer.path = maskPath.CGPath;
    self.layer.mask = maskLayer;
}

/// 切圆角
///
/// - Parameter rect: 传入view的Rect
- (void)roundedCircle:(CGRect)rect {
    [self roundedRect:rect byRoundingCorners:UIRectCornerAllCorners cornerRadii:CGSizeMake(self.bounds.size.width / 2, self.bounds.size.height / 2)];
}

@end
