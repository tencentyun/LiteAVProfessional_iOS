//
//  TRTCAlerts.h
//  TXLiteAVDemo_Enterprise
//
//  Created by peterwtma on 2021/8/6.
//  Copyright © 2021 Tencent. All rights reserved.
//

#import "TRTCAlertViewModel.h"
#import <UIKit/UIKit.h>


NS_ASSUME_NONNULL_BEGIN

@interface TRTCAlertContentView : UIView
@property (nonatomic, copy) void(^willDissmiss)(void);
@property (nonatomic, copy) void(^didDismiss)(void);
- (void)constructViewHierarchy;
- (void)activateConstraints;
- (void)bindInteraction;
- (void)dismiss;
- (void)show;
@end


@interface TRTCAvatarListAlertView : TRTCAlertContentView
@property (nonatomic, copy) void(^didClickConfirmBtn)(void);
- (instancetype)initWithFrame:(CGRect)frame viewModel:(TRTCAlertViewModel *)viewModel;
@end

NS_ASSUME_NONNULL_END
