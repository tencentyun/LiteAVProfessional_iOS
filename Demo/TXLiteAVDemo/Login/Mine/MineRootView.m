//
//  MineRootView.m
//  TXLiteAVDemo_Enterprise
//
//  Created by peterwtma on 2021/7/20.
//  Copyright © 2021 Tencent. All rights reserved.
//

#import "MineRootView.h"
#import "MineViewModel.h"
#import "LayoutDefine.h"
#import "AppLocalized.h"
#import "ColorMacro.h"
#import "TXLiteAVSDKHeader.h"
#import "TRTCAlertViewModel.h"
#import "TRTCAlerts.h"
#import "MineAlertContentView.h"
#import <SDWebImage.h>
#import <Masonry.h>
#import "TXAppInfo.h"

@interface MineRootView()
@property (nonatomic, strong) MineViewModel *viewModel;
@property (nonatomic, strong) UIImageView *bgView;
@property (nonatomic, strong) UIView *containerView;
@property (nonatomic, strong) UIView *contentView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UIButton *backBtn;
@property (nonatomic, strong) UIButton *userNameBtn;
@property (nonatomic, strong) UILabel *userIdLabel;
@property (nonatomic, strong) UILabel *versionTip;
@property (nonatomic, strong) UILabel *bottomTip;
@property (nonatomic, assign) CGFloat headImageDiameter;
@property (nonatomic, strong) UIImageView *headImageView;
@property (nonatomic, strong) UIViewController *viewCV;
@end


@implementation MineRootView

+ (instancetype)initWithViewModel:(MineViewModel *)model {
    MineRootView* rootView = [[MineRootView alloc] init];
    if (rootView) {
        rootView.viewModel = model;
        rootView.layoutDefine = [[LayoutDefine alloc] init];
        [rootView initUI];
    }
    return rootView;
}

+ (instancetype)initWithViewModel:(MineViewModel *)model
               withViewController:(UIViewController*) viewController{
    MineRootView* rootView = [[MineRootView alloc] init];
    rootView.viewCV = viewController;
    if (rootView) {
        rootView.viewModel = model;
        rootView.layoutDefine = [[LayoutDefine alloc] init];
        [rootView initUI];
    }
    return rootView;
}

- (void)initUI {
    self.bgView = [[UIImageView alloc] initWithFrame:CGRectZero];
    self.bgView.image = [UIImage imageNamed:@"main_mine_headerbg"];
    self.bgView.contentMode = UIViewContentModeScaleAspectFill;
    
    
    self.containerView = [[UIView alloc] init];
    self.containerView.backgroundColor = [UIColor clearColor];
    
    self.contentView = [[UIView alloc] init];
    self.contentView.backgroundColor = [UIColor clearColor];
    
    self.titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    self.titleLabel.font = [UIFont fontWithName:(@"PingFangSC-Semibold") size:18];
    self.titleLabel.text = AppPortalLocalize(@"Demo.TRTC.Portal.Mine.personalcenter");
    self.titleLabel.textColor = [UIColor whiteColor];
    
    self.backBtn = [[UIButton alloc] init];
    //    self.backBtn.buttonType = UIButtonTypeCustom;
    [self.backBtn setImage:[UIImage imageNamed:@"back"] forState:normal];
    [self.backBtn sizeToFit];
    
    self.userNameBtn = [[UIButton alloc] init];
    [self.userNameBtn setTitle:@"USERID" forState:normal];
    self.userNameBtn.adjustsImageWhenHighlighted = false;
    [self.userNameBtn setTitleColor:[UIColor whiteColor] forState:normal];
    //        self.userNameBtn.titleLabel.font
    [self.userNameBtn setImage:[UIImage imageNamed:@"main_mine_edit"] forState:normal];
    
    self.userIdLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    self.userIdLabel.font = [UIFont fontWithName:@"PingFangSC-Regular" size:16];
    self.userIdLabel.textColor = [UIColor whiteColor];
    
    self.versionTip = [[UILabel alloc] init];
    self.versionTip.textAlignment = NSTextAlignmentCenter;
    self.versionTip.font = [UIFont systemFontOfSize:14];
    self.versionTip.textColor = UIColorFromRGB(0x525252);
    
    NSString *version = [TXAppInfo appVersionWithBuild];
    NSString *sdkVersionStr;
#if LIVE
    sdkVersionStr = [V2TXLivePremier getSDKVersionStr];
#else
    sdkVersionStr = [TXLiveBase getSDKVersionStr];
    if (!sdkVersionStr) {
        sdkVersionStr = @"1.0.0";
    }
#endif
    self.versionTip.text = V2Localize(@"V2.Live.LinkMicNew.loginTitle");
    NSString *versionStr = [NSString stringWithFormat:@" v%@(%@)", sdkVersionStr, version];
    if (self.versionTip.text) {
        self.versionTip.text = [self.versionTip.text stringByAppendingString:versionStr];
    } else {
        self.versionTip.text = versionStr;
    }
    
    self.versionTip.adjustsFontSizeToFitWidth = true;
    
    self.bottomTip = [[UILabel alloc] init];
    self.bottomTip.textAlignment = NSTextAlignmentCenter;
    self.bottomTip.font = [UIFont systemFontOfSize:14];
    self.bottomTip.textColor = [UIColor whiteColor];
    self.bottomTip.text = V2Localize(@"V2.Live.LinkMicNew.appusetoshowfunc");
    self.bottomTip.adjustsFontSizeToFitWidth = true;
    
    self.headImageDiameter = 100;
    
    self.headImageView = [[UIImageView alloc] initWithFrame:CGRectZero];
    self.headImageView.contentMode = UIViewContentModeScaleAspectFit;
    self.headImageView.layer.cornerRadius = self.headImageDiameter * 0.5;
    self.headImageView.clipsToBounds = true;
    
    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    self.tableView.backgroundColor = [UIColor clearColor];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone; //没有分割线
    self.tableView.contentInset = UIEdgeInsetsMake(50, 0, 0, 0);
    
    //生成视图层次布局
    [self constructViewHierarchy];
    //生成布局间约束
    [self addConstraint];
    //绑定事件
    [self bindInteraction];
}

- (void)constructViewHierarchy {
    [self addSubview:_bgView];
    [self addSubview:_containerView];
    [self.containerView addSubview:_contentView];
    [self.contentView addSubview:_userNameBtn];
    [self.contentView addSubview:_userIdLabel];
    [self.contentView addSubview:_tableView];
    [self.containerView addSubview:_headImageView];
    [self addSubview:_titleLabel];
    [self addSubview:_backBtn];
    [self addSubview:_bottomTip];
    [self addSubview:_versionTip];
}

- (void)addConstraint{
    [self.titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.mas_equalTo(self.titleLabel.superview);
        make.top.mas_equalTo(self.titleLabel.superview).offset(self.layoutDefine.deviceSafeTopHeight+20);
    }];
    
    [self.backBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.mas_equalTo(_titleLabel);
        make.leading.mas_equalTo(self.backBtn.superview).offset(20);
    }];
    
    [self.bgView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.trailing.top.equalTo(self.bgView.superview);
        make.height.equalTo(self.bgView.mas_width).multipliedBy(220.0/375.0);
    }];
    
    [self.containerView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.bgView.mas_bottom).offset(-32-self.headImageDiameter * 0.5);
        make.leading.trailing.bottom.equalTo(self.containerView.superview);
    }];
    
    [self.contentView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.contentView.superview).offset(self.headImageDiameter * 0.5);
        make.leading.trailing.bottom.equalTo(self.contentView.superview);
    }];
    
    [self.userNameBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.userNameBtn.superview).offset(self.headImageDiameter * 0.5);
        make.centerX.equalTo(self.userNameBtn.superview);
    }];
    
    [self.userIdLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.userNameBtn.mas_bottom).offset(4);
        make.centerX.equalTo(self.userIdLabel.superview);
    }];
    
    [self.tableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.userIdLabel.mas_bottom).offset(10);
        make.leading.trailing.bottom.equalTo(self.tableView.superview);
    }];
    
    [self.headImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.centerX.equalTo(self.headImageView.superview);
        make.size.mas_equalTo(CGSizeMake(self.headImageDiameter, self.headImageDiameter));
    }];
    
    [self.bottomTip mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(self).offset(-12);
        make.leading.trailing.equalTo(self);
        make.height.equalTo(@30);
    }];
    
    [self.versionTip mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(self.bottomTip.mas_top).offset(-2);
        make.height.mas_equalTo(12);
        make.leading.trailing.equalTo(self);
    }];
}

- (void)updateHeadImage{
    if(self.viewModel.user) {
        [self.headImageView sd_setImageWithURL:[NSURL URLWithString:self.viewModel.user.avatar] placeholderImage:nil options:SDWebImageContinueInBackground];
    }
}

- (void)updateUserId{
    if (self.viewModel.user) {
        self.userIdLabel.text = [NSString stringWithFormat:(@"ID:%@"),self.viewModel.user.userId];
    }
}

- (void)updateUserName{
    if (self.viewModel.user) {
        [self.userNameBtn setTitle:self.viewModel.user.name forState:normal];
        [self.userNameBtn sizeToFit];
        CGFloat totalWidth = self.userNameBtn.frame.size.width;
        CGFloat imageWidth = self.userNameBtn.imageView.frame.size.width;
        CGFloat titleWidth = totalWidth - imageWidth;
        CGFloat spacing = 4;
        self.userNameBtn.titleEdgeInsets = UIEdgeInsetsMake(0, -imageWidth-spacing * 0.5, 0, imageWidth+spacing * 0.5);
        self.userNameBtn.imageEdgeInsets = UIEdgeInsetsMake(0, titleWidth+spacing * 0.5, 0, -titleWidth-spacing * 0.5);
        [self.userNameBtn mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.userNameBtn.superview).offset(self.headImageDiameter * 0.5);
            make.centerX.equalTo(self.userNameBtn.superview);
            make.width.mas_equalTo(totalWidth + spacing);
        }];
    }
}

- (void)userIdBtnClick{
    MineUserIdEditView* alert = [[MineUserIdEditView alloc] initWithFrame:CGRectZero viewModel:self.viewModel];
    [self addSubview:alert];
    [alert mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.superview);
    }];
    [alert layoutIfNeeded];
    [alert show];
    alert.didDismiss = ^{
        [self updateUserName];
    };
}

- (void)headBtnClick {
    TRTCAlertViewModel *model = [[TRTCAlertViewModel alloc] init];
    TRTCAvatarListAlertView *alert = [[TRTCAvatarListAlertView alloc] initWithFrame:CGRectZero viewModel:model];
    
    alert.didClickConfirmBtn = ^{
        if (ProfileManager.shared.curUserModel.avatar) {
            [self.headImageView sd_setImageWithURL:[NSURL URLWithString:ProfileManager.shared.curUserModel.avatar] placeholderImage:nil options:SDWebImageContinueInBackground];
        }
        [ProfileManager.shared synchronizUserInfo];
    };
    alert.willDissmiss = ^{
        [self updateHeadImage];
    };
    
    [self addSubview:alert];
    [alert mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(alert.superview);
    }];
    [alert layoutIfNeeded];
    [alert show];
}

- (void)bindInteraction{
    //注册返回按钮事件
    [self.backBtn addTarget:self action:@selector(backBtnClick) forControlEvents:UIControlEventTouchUpInside];
    [self.userNameBtn addTarget:self action:@selector(userIdBtnClick) forControlEvents:UIControlEventTouchUpInside];
    
    UITapGestureRecognizer* myTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(headBtnClick)];
    [self.headImageView addGestureRecognizer:myTap];
    self.headImageView.userInteractionEnabled = true;
    
    [self updateHeadImage];
    [self updateUserId];
    [self updateUserName];
}

- (void)backBtnClick {
    if(self.viewCV) {
        [self.viewCV.navigationController popViewControllerAnimated:TRUE];
    }
}

@end

#pragma mark - MineTableViewCell
@implementation MineTableViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if(self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.backgroundColor = [UIColor clearColor];
        self.detailImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"main_mine_detail"]];
    }
    return self;
}

- (void)didMoveToWindow{
    [super didMoveToWindow];
    if(self.model) {
        self.titleImageView = [[UIImageView alloc] initWithImage:self.model.image];
        self.titleLabel = [[UILabel alloc] init];
        self.titleLabel.text = self.model.title;
        self.titleLabel.textColor = [UIColor whiteColor];
    }
    
    [self constructViewHierarchy];
    [self addConstraint];
}

- (void)constructViewHierarchy{
    [self.contentView addSubview:self.titleImageView];
    [self.contentView addSubview:self.titleLabel];
    [self.contentView addSubview:self.detailImageView];
}

- (void)addConstraint{
    [self.titleImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.contentView.mas_leading).offset(36);
        make.centerY.equalTo(self.titleImageView.superview);
    }];
    [self.detailImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.trailing.equalTo(self.detailImageView.superview).offset(-20);
        make.centerY.equalTo(self.titleImageView);
    }];
    [self.titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.titleImageView);
        make.leading.equalTo(self.titleImageView.mas_centerX).offset(28);
        make.trailing.lessThanOrEqualTo(self.detailImageView.mas_leading).offset(-10);
    }];
}
@end
