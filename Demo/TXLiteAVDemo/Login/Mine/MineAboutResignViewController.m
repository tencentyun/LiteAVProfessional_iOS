//
//  MineAboutResignViewController.m
//  TXLiteAVDemo_Enterprise
//
//  Created by peterwtma on 2021/8/7.
//  Copyright © 2021 Tencent. All rights reserved.
//

#import "MineAboutResignViewController.h"
#import "ColorMacro.h"
#import "AppLocalized.h"
#import "ProfileManager.h"
#import "AppDelegate.h"
#import "ToastView.h"
#import <Masonry.h>

@interface MineAboutResignViewController ()
@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) UILabel *tipsLabel;
@property (nonatomic, strong) UILabel *numberLabel;
@property (nonatomic, strong) UIButton *confirmBtn;
@property (nonatomic, strong) UIButton *backBtn;
@property (nonatomic, strong) UIActivityIndicatorView *loading;
@end

@implementation MineAboutResignViewController
- (instancetype)init {
	self = [super init];
	if (self) {
		[self initUI];
	}
	return self;
}


- (void)initUI {
	self.imageView = [[UIImageView alloc] initWithFrame:CGRectZero];
	self.imageView.image = [UIImage imageNamed:@"resign"];

	self.tipsLabel = [[UILabel alloc] initWithFrame:CGRectZero];
	self.tipsLabel.font = [UIFont fontWithName:@"PingFangSC-Regular" size:16];
	self.tipsLabel.textColor = [UIColor whiteColor];
	self.tipsLabel.numberOfLines = 0;
	self.tipsLabel.adjustsFontSizeToFitWidth = true;
	self.tipsLabel.minimumScaleFactor = 0.5;
	self.tipsLabel.text = AppPortalLocalize(@"Demo.TRTC.Portal.resigntips");

	self.numberLabel = [[UILabel alloc] init];
	self.numberLabel.font = [UIFont fontWithName:@"PingFangSC-Regular" size:16];
	self.numberLabel.textColor = [UIColor whiteColor];
	self.numberLabel.numberOfLines = 0;
	self.numberLabel.adjustsFontSizeToFitWidth = true;
	self.numberLabel.minimumScaleFactor = 0.5;

	self.confirmBtn = [[UIButton alloc] init];
	[self.confirmBtn setTitle:AppPortalLocalize(@"Demo.TRTC.Portal.confirmresign") forState:normal];
	[self.confirmBtn.titleLabel setTextColor:[UIColor whiteColor]];
	self.confirmBtn.backgroundColor = UIColorFromRGB(0x006EFF);
	[self.confirmBtn addTarget:self action:@selector(resignBtnClick) forControlEvents:UIControlEventTouchUpInside];

	self.loading = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(0, 0, 100, 60)];

	if (ProfileManager.shared.curUserModel) {
		self.numberLabel.text = LocalizeReplaceXX(AppPortalLocalize(@"Demo.TRTC.Portal.currentaccount"), ProfileManager.shared.curUserModel.phone);
	} else {
		self.numberLabel.text = @"";
	}
}

- (void)resignPhoneNumber {
	[self.loading startAnimating];
	[ProfileManager.shared resign:^{
        //停止动画
        [self.loading stopAnimating];
        AppDelegate* appDelegate = (AppDelegate*) UIApplication.sharedApplication.delegate;
        [appDelegate showLoginController];
	 } failed:^(NSString *_error) {
	         [self.loading stopAnimating];
	 }];
}

- (void)resignBtnClick {
	UIAlertController *alert = [UIAlertController alertControllerWithTitle:AppPortalLocalize(@"Demo.TRTC.Portal.alerttoresign") message:@"" preferredStyle:UIAlertControllerStyleAlert];

	UIAlertAction *cancel = [UIAlertAction actionWithTitle:AppPortalLocalize(@"App.PortalViewController.cancel") style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {

				 }];

	UIAlertAction *confirm = [UIAlertAction actionWithTitle:AppPortalLocalize(@"Demo.TRTC.Portal.confirmresign") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
	                                  [self resignPhoneNumber];
				  }];
	[alert addAction:cancel];
	[alert addAction:confirm];
	[self presentViewController:alert animated:true completion:nil];
}

- (void)viewDidLoad {
	[super viewDidLoad];

	NSArray* colors = @[(__bridge id)[UIColor colorWithRed:(19.0/255.0) green:(41.0/255.0) blue:(75.0/255.0) alpha:1].CGColor, (__bridge id)[UIColor colorWithRed:(5.0/255.0) green:(12.0/255.0) blue:(23.0/255.0) alpha:1].CGColor];
	CAGradientLayer* gradientLayer = [CAGradientLayer layer];
	gradientLayer.colors = colors;
	gradientLayer.startPoint = CGPointMake(0, 0);
	gradientLayer.endPoint = CGPointMake(1, 1);
	gradientLayer.frame = self.view.bounds;
	[self.view.layer insertSublayer:gradientLayer atIndex:0];

	self.title = AppPortalLocalize(@"Demo.TRTC.Portal.resignaccount");

	self.backBtn = [UIButton buttonWithType:UIButtonTypeCustom];
	[self.backBtn setImage:[UIImage imageNamed:@"back"] forState:normal];
	[self.backBtn addTarget:self action:@selector(backBtnClick) forControlEvents:UIControlEventTouchUpInside];
	[self.backBtn sizeToFit];
	UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithCustomView:self.backBtn];
	item.tintColor = [UIColor clearColor];

	self.navigationItem.leftBarButtonItem = item;

	[self constructViewHierarchy];
	[self addConstraint];
	[self bindInteraction];
}

- (void)backBtnClick {
	[self.navigationController popViewControllerAnimated:TRUE];
}

- (void)addConstraint {
	[self.imageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.imageView.superview);
        make.top.equalTo(self.view.mas_top).offset(200);
	 }];

	[self.tipsLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.imageView.mas_bottom).offset(20);
        make.centerX.equalTo(self.tipsLabel.superview);
        make.leading.greaterThanOrEqualTo(self.tipsLabel.superview).offset(40);
        make.trailing.lessThanOrEqualTo(self.tipsLabel.superview).offset(-40);
	 }];

	[self.numberLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.tipsLabel.mas_bottom).offset(10);
        make.centerX.equalTo(self.numberLabel.superview);
        make.leading.greaterThanOrEqualTo(self.numberLabel.superview).offset(40);
        make.trailing.lessThanOrEqualTo(self.numberLabel.superview).offset(-40);
	 }];

	[self.confirmBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.numberLabel.mas_bottom).offset(20);
        make.leading.equalTo(self.confirmBtn.superview).offset(40);
        make.trailing.equalTo(self.confirmBtn.superview).offset(-40);
        make.height.mas_equalTo(56);
	 }];

	[self.loading mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.height.mas_equalTo(40);
        make.centerX.centerY.equalTo(self.view);
	 }];
}

- (void)constructViewHierarchy {
	[self.view addSubview:self.imageView];
	[self.view addSubview:self.tipsLabel];
	[self.view addSubview:self.numberLabel];
	[self.view addSubview:self.confirmBtn];
	[self.view addSubview:self.loading];
}

- (void)bindInteraction {

}
@end
