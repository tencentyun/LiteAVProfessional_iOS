//
//  MineAlertContentView.h
//  TXLiteAVDemo_Enterprise
//
//  Created by peterwtma on 2021/8/5.
//  Copyright © 2021 Tencent. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MineViewModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface MineAlertContentView : UIView
@property (nonatomic, copy) void(^willDissmiss)(void);
@property (nonatomic, copy) void(^didDismiss)(void);
@property (nonatomic, strong) UIView  *bgView;
@property (nonatomic, strong) UIView  *contentView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) MineViewModel *viewModel;
- (instancetype)initWithFrame:(CGRect)frame viewModel:(MineViewModel*)viewModel;
- (void)constructViewHierarchy;
- (void)addConstraint;
- (void)bindInteraction;
- (void)dismiss;
- (void)initUI;
- (void)show;
@end

@interface MineUserIdEditView : MineAlertContentView
- (void)constructViewHierarchy;
- (void)addConstraint;
- (void)bindInteraction;
- (instancetype)initWithFrame:(CGRect)frame viewModel:(MineViewModel*)viewModel;
@end

NS_ASSUME_NONNULL_END
