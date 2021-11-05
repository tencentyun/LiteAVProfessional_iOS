//
//  ProfileViewController.m
//  TXLiteAVDemo_Enterprise
//
//  Created by peterwtma on 2021/8/4.
//  Copyright © 2021 Tencent. All rights reserved.
//

#import "ProfileViewController.h"
#import "ColorMacro.h"
#import "ProfileManager.h"
#import "AppDelegate.h"
#import "ToastView.h"
#import <Masonry.h>
#import <SDWebImage.h>
#import "AppLocalized.h"
@interface ProfileViewController ()
@property (nonatomic, strong) UILabel *signTitle;
@property (nonatomic, strong) UIImageView *inputBackImage;
@property (nonatomic, strong) CAGradientLayer *gradientLayer;
@property (nonatomic, strong) UIImageView *avatarView;
@property (nonatomic, strong) UILabel *warnTip;
@property (nonatomic, strong) UILabel *userNameTip;
@property (nonatomic, strong) UIButton *signButton;
@property (nonatomic, strong) UITextField *userName;
@property (nonatomic, strong) UIActivityIndicatorView *loading;
@property (nonatomic, assign) BOOL userNameVaild;
@end

@implementation ProfileViewController

- (void)viewDidLoad {
	[super viewDidLoad];

	[self initUI];
	//生成视图层次布局
	[self constructViewHierarchy];
	//约束布局
	[self addConstraint];
	//绑定事件
	[self bindInteraction];
}


- (void)initUI {
	self.loading = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(0, 0, 100, 60)];
	UIColor* loadingColor = UIColorFromRGB(0x00A66B);
	self.loading.color = loadingColor;
	UIColor* color1 = [UIColor colorWithRed:(19.0/255.0) green:(41.0/255.0) blue:(75.0/255.0) alpha:1];
	UIColor* color2 = [UIColor colorWithRed:(5.0/255.0) green:(12.0/255.0) blue:(23.0/255.0) alpha:1];
	NSArray* colors = @[color1, color2];
    self.view.backgroundColor = UIColorFromRGB(0x242424);
	self.signTitle = [[UILabel alloc] init];
	self.signTitle.textColor = [UIColor whiteColor];
	[self.signTitle setText:V2Localize(@"V2.Live.LoginMock.regist")];
	self.signTitle.textAlignment = NSTextAlignmentCenter;

	self.inputBackImage = [[UIImageView alloc] init];
	self.inputBackImage.backgroundColor = UIColorFromRGB(0x092650);

	self.gradientLayer = [[CAGradientLayer alloc] init];
	self.gradientLayer.startPoint = CGPointMake(0, 0);
	self.gradientLayer.endPoint = CGPointMake(1, 1);
	self.gradientLayer.colors = colors;
	self.gradientLayer.frame = self.view.bounds;
	[self.view.layer insertSublayer:self.gradientLayer atIndex:0];

	self.avatarView = [[UIImageView alloc] init];
	self.avatarView.backgroundColor = [UIColor lightGrayColor];

	NSString* url = ProfileManager.shared.curUserModel.avatar;
	if(!url) {
		url = @"";
	}
	[self.avatarView sd_setImageWithURL:[NSURL URLWithString:url] placeholderImage:nil options:SDWebImageContinueInBackground];
	self.avatarView.layer.masksToBounds = true;
	self.avatarView.layer.cornerRadius = 40.0;

	self.warnTip = [[UILabel alloc] init];
	[self.warnTip setText:V2Localize(@"V2.Live.LoginMock.warnTip")];
	self.warnTip.backgroundColor = [UIColor clearColor];
	self.warnTip.textColor = UIColorFromRGB(0x6B82A8);
	self.warnTip.font = [UIFont systemFontOfSize:14];

	self.userName = [[UITextField alloc] init];
	self.userName.textColor = [UIColor whiteColor];

	self.userNameTip = [[UILabel alloc] init];
	[self.userNameTip setText:V2Localize(@"V2.Live.LoginMock.username")];
	self.userNameTip.textColor = [UIColor whiteColor];
	self.userNameTip.font = [UIFont systemFontOfSize:16];

	self.signButton = [[UIButton alloc] init];
	self.signButton.backgroundColor = UIColorFromRGB(0x092650);
	[self.signButton setTitle:V2Localize(@"V2.Live.LoginMock.regist") forState:normal];
	[self.signButton setTitleColor:[UIColor whiteColor] forState:normal];
	self.signButton.layer.cornerRadius = 4;
}

-(void)constructViewHierarchy {
	[self.view addSubview:self.loading];
	[self.view addSubview:self.signTitle];
	[self.view addSubview:self.avatarView];
	[self.view addSubview:self.inputBackImage];
	[self.view addSubview:self.userNameTip];
	[self.view addSubview:self.userName];
	[self.view addSubview:self.warnTip];
	[self.view addSubview:self.signButton];
}


- (void)addConstraint {
	[self.loading mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.height.mas_equalTo(40);
        make.centerX.centerY.equalTo(self.view);
	 }];

	[self.signTitle mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.mas_equalTo(32);
        make.top.mas_equalTo(50);
        make.trailing.mas_equalTo(-32);
        make.height.mas_equalTo(30);
	 }];

	[self.avatarView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo((self.view.bounds.size.width - 80) / 2.0);
        make.right.mas_equalTo(-(self.view.bounds.size.width - 80) / 2.0);
        make.top.mas_equalTo(self.signTitle.mas_bottom).offset(30);
        make.width.height.mas_equalTo(80);
	 }];

	[self.inputBackImage mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.mas_equalTo(20);
        make.trailing.mas_equalTo(-20);
        make.top.equalTo(self.avatarView.mas_bottom).offset(30);
        make.height.mas_equalTo(50);
	 }];


	[self.userName mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.inputBackImage.mas_top).offset(15);
        make.leading.mas_equalTo(100);
        make.trailing.mas_equalTo(-32);
        make.height.mas_equalTo(30);
	 }];

	[self.userNameTip mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.mas_equalTo(35);
        make.top.equalTo(self.inputBackImage.mas_top).offset(13);
        make.width.mas_equalTo(100);
        make.height.mas_equalTo(30);
	 }];

	[self.warnTip mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.inputBackImage.mas_bottom).offset(20);
        make.leading.mas_equalTo(30);
        make.trailing.mas_equalTo(-30);
        make.height.mas_equalTo(20);
	 }];
	[self.signButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.inputBackImage.mas_bottom).offset(80);
        make.height.mas_equalTo(46);
        make.leading.trailing.equalTo(self.inputBackImage);
	 }];
}

- (void)signButtonClick {
	if(!self.userName.text || !self.userNameVaild) {
		return;
	}
    [self.loading startAnimating];
	[ProfileManager.shared setNickName:self.userName.text success:^{
        [self.loading stopAnimating];
        CSToast.text(V2Localize(@"V2.Live.LoginMock.registsuccess")).show();
        AppDelegate* appDelegate = (AppDelegate*) UIApplication.sharedApplication.delegate;
        [appDelegate showPortalConroller];
        if (ProfileManager.shared.curUserModel) {
        ProfileManager.shared.curUserModel.name = self.userName.text;
        [ProfileManager.shared synchronizUserInfo];
}
	 } failed:^(NSString *_error) {
	         [[NSOperationQueue mainQueue] addOperationWithBlock:^{
	                  [self.loading stopAnimating];
	                  [self.navigationController popViewControllerAnimated:true];
		  }];

	 }];
}

- (void)userNameTextChange {
	if (self.userName.text.length < 2 || self.userName.text.length >= 20) {
		self.userNameVaild = false;
	} else {
		self.userNameVaild = true;
	}
}

- (void)bindInteraction {
	[self.signButton addTarget:self action:@selector(signButtonClick) forControlEvents:UIControlEventTouchUpInside];

	[self.userName addTarget:self action:@selector(userNameTextChange) forControlEvents:UIControlEventEditingChanged];
}
@end
