//
//  MineRootView.h
//  TXLiteAVDemo
//
//  Created by peterwtma on 2021/7/20.
//  Copyright © 2021 Tencent. All rights reserved.
//


#import <UIKit/UIKit.h>
#import "LayoutDefine.h"

@class MineViewModel;
@class MinTableViewCellModel;

NS_ASSUME_NONNULL_BEGIN

@interface MineRootView : UIView
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic,strong) LayoutDefine *layoutDefine;
+ (instancetype)initWithViewModel:(MineViewModel *)model;
+ (instancetype)initWithViewModel:(MineViewModel *)model
               withViewController:(UIViewController*) viewController;
@end

@interface MineTableViewCell : UITableViewCell
@property (nonatomic, strong) MinTableViewCellModel *model;
@property (nonatomic, strong) UIImageView *detailImageView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UIImageView *titleImageView;
@end

NS_ASSUME_NONNULL_END
