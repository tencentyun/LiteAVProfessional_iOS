//
//  PrivacyPopView.h
//  TXLiteAVDemo_Enterprise
//
//  Created by peterwtma on 2021/8/4.
//  Copyright © 2021 Tencent. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN
typedef void (^AgreeBlock)();
typedef void (^DisAgreeBlock)();

@interface PrivacyPopView : UIView
@property (nonatomic, weak) UIViewController *rootVC;
@property (nonatomic, copy) AgreeBlock agreeBlock;
@property (nonatomic, copy) DisAgreeBlock disAgreeBlock;
- (void)show;
- (void)dismiss;
+ (BOOL)isFirstRun;
@end

NS_ASSUME_NONNULL_END
