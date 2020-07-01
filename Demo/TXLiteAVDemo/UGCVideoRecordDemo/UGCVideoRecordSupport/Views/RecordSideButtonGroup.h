//
//  RecordSideButtonGroup.h
//  TXLiteAVDemo
//
//  Created by cui on 2019/10/1.
//  Copyright © 2019 Tencent. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface RecordSideButtonGroup : UIControl
@property (readonly, nonatomic) NSArray<UIButton *>* buttons;
@property (assign, nonatomic) NSUInteger selectedIndex;
- (instancetype)initWithButtons:(NSArray<UIButton *> *)buttons buttonSize:(CGSize)size spacing:(CGFloat)spacing;
@end

NS_ASSUME_NONNULL_END
