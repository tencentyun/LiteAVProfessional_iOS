//
//  PrivacyPopView.m
//  TXLiteAVDemo_Enterprise
//
//  Created by peterwtma on 2021/8/4.
//  Copyright © 2021 Tencent. All rights reserved.
//

#import "PrivacyPopView.h"
#import "AppLocalized.h"
#import "ColorMacro.h"
#import "WebViewController.h"
#import <Masonry.h>

static NSString* PrivacyPopKey = @"PrivacyPopKey";
@interface PrivacyPopView ()<UITextViewDelegate>

@property (nonatomic, strong) NSString *titleText;
@property (nonatomic, strong) NSString *messageText;
@property (nonatomic, strong) UIView *contentView;
@property (nonatomic, strong) UILabel *title;
@property (nonatomic, strong) UITextView *message;
@property (nonatomic, strong) UIView *lineView;
@property (nonatomic, strong) UIButton *agreeBtn;
@property (nonatomic, strong) UIButton *disAgreeBtn;
@end

@implementation PrivacyPopView

- (void)didMoveToWindow {
	[self initUI];
	//生成视图层次布局
	[self constructViewHierarchy];
	//约束布局
	[self addConstraint];
}


- (void)initUI {
	self.contentView = [[UIView alloc] initWithFrame:CGRectZero];
	self.contentView.backgroundColor = [UIColor whiteColor];
	self.contentView.layer.cornerRadius = 6;
	self.contentView.layer.masksToBounds = true;

	self.title = [[UILabel alloc] initWithFrame:CGRectZero];
	[self.title setText:AppPortalLocalize(@"Demo.TRTC.Portal.popTitle")];
	self.title.textColor = [UIColor whiteColor];
	self.title.textAlignment = NSTextAlignmentCenter;
	self.title.font = [UIFont systemFontOfSize:20];
	self.title.adjustsFontSizeToFitWidth = true;

	self.message = [[UITextView alloc] initWithFrame:CGRectZero textContainer:nil];
	self.message.delegate = self;
	self.message.backgroundColor = [UIColor clearColor];
	[self.message setEditable:false];
	self.message.textContainerInset = UIEdgeInsetsZero;
	self.message.dataDetectorTypes = UIDataDetectorTypeLink;

	NSString* totalStr = LocalizeReplace(AppPortalLocalize(@"Demo.TRTC.Portal.popMessage"), V2Localize(@"Demo.TRTC.Portal.<private>"), V2Localize(@"Demo.TRTC.Portal.<agreement>"));
	NSString* privaStr = V2Localize(@"Demo.TRTC.Portal.<private>");
	NSString* protoStr = V2Localize(@"Demo.TRTC.Portal.<agreement>");

	NSRange privaR = [totalStr rangeOfString:privaStr];
	NSRange protoR = [totalStr rangeOfString:protoStr];

	NSRange totalRange = NSMakeRange(0, totalStr.length);

	NSMutableAttributedString* attr = [[NSMutableAttributedString alloc] initWithString:totalStr];
	NSMutableParagraphStyle* style = [[NSMutableParagraphStyle alloc] init];
	style.alignment = NSTextAlignmentJustified;
	[attr addAttribute:NSParagraphStyleAttributeName value:style range:totalRange];

	[attr addAttribute:NSFontAttributeName value:[UIFont fontWithName:@"PingFangSC-Regular" size:17] range:totalRange];
	[attr addAttribute:NSForegroundColorAttributeName value:[UIColor lightGrayColor] range:totalRange];
	[attr addAttribute:NSLinkAttributeName value:@"privacy" range:privaR];
	[attr addAttribute:NSLinkAttributeName value:@"protocol" range:protoR];
	[attr addAttribute:NSForegroundColorAttributeName value:[UIColor lightGrayColor] range:privaR];
	[attr addAttribute:NSForegroundColorAttributeName value:[UIColor lightGrayColor] range:protoR];

	self.message.attributedText = attr;

	self.lineView = [[UIView alloc] initWithFrame:CGRectZero];
	self.lineView.backgroundColor = UIColorFromRGB(0x666666);


	self.agreeBtn = [[UIButton alloc] init];
	[self.agreeBtn addTarget:self action:@selector(onAgreeBtnClick) forControlEvents:UIControlEventTouchUpInside];
	[self.agreeBtn setTitle:AppPortalLocalize(@"Demo.TRTC.Portal.agree") forState:normal];
	[self.agreeBtn setTitleColor:[UIColor whiteColor] forState:normal];
	self.agreeBtn.backgroundColor = [UIColor blackColor];


	self.disAgreeBtn = [[UIButton alloc] init];
	[self.disAgreeBtn addTarget:self action:@selector(onDisAgreeBtnClick) forControlEvents:UIControlEventTouchUpInside];
	[self.disAgreeBtn setTitle:AppPortalLocalize(@"Demo.TRTC.Portal.disagree") forState:normal];
	[self.disAgreeBtn setTitleColor:[UIColor blackColor] forState:normal];
}

- (void)constructViewHierarchy {
	[self addSubview:self.contentView];
	[self.contentView addSubview:self.title];
	[self.contentView addSubview:self.message];
	[self.contentView addSubview:self.agreeBtn];
	[self.contentView addSubview:self.disAgreeBtn];
	[self.contentView addSubview:self.lineView];
	self.frame = UIScreen.mainScreen.bounds;
}

- (void)addConstraint {
	[self.contentView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self);
        make.leading.equalTo(self.mas_leading).offset(40);
        make.trailing.equalTo(self.mas_trailing).offset(-40);
        make.height.equalTo(self.contentView.mas_width).multipliedBy(0.8);
	 }];

	[self.title mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.contentView.mas_top).offset(20);
        make.leading.equalTo(self.contentView.mas_leading).offset(10);
        make.trailing.equalTo(self.contentView.mas_trailing).offset(-10);
        make.height.mas_equalTo(30);
	 }];

	[self.message mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.title.mas_bottom).offset(10);
        make.leading.trailing.equalTo(self.title);
        make.bottom.equalTo(self.contentView.mas_bottom).offset(-50);
	 }];

	[self.lineView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.message.mas_bottom);
        make.trailing.leading.equalTo(self.contentView);
        make.height.mas_equalTo(1);
	 }];

	[self.disAgreeBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.contentView.mas_centerX).multipliedBy(0.5);
        make.width.equalTo(self.contentView.mas_width).multipliedBy(0.5);
        make.top.equalTo(self.message.mas_bottom);
        make.bottom.equalTo(self.contentView.mas_bottom);
	 }];

	[self.agreeBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.contentView.mas_centerX).multipliedBy(1.5);
        make.width.equalTo(self.contentView.mas_width).multipliedBy(0.5);
        make.top.equalTo(self.message.mas_bottom);
        make.bottom.equalTo(self.contentView.mas_bottom);
	 }];
}

- (void)onAgreeBtnClick {
    if(_agreeBlock){
        _agreeBlock();
    }
	[self dismiss];
}

- (void)onDisAgreeBtnClick {
    if(_disAgreeBlock){
        _disAgreeBlock();
    }
	[self dismiss];
}

- (void)show {
	if (self.rootVC) {
		[self.rootVC.view addSubview:self];
	}
}

- (void)dismiss {
	[self removeFromSuperview];
}

+ (BOOL)isFirstRun {
	NSData* cacheData = [NSUserDefaults.standardUserDefaults objectForKey:@"PrivacyPopKey"];
	if (cacheData) {
		return false;
	}
	[NSUserDefaults.standardUserDefaults setValue:@"true" forKey:@"PrivacyPopKey"];
	return true;
}


#pragma mark ---UITextViewDelegate

- (void)showPrivacy {
	WebViewController* webViewController = [[WebViewController alloc] initWithUrlString:@"https://web.sdk.qcloud.com/document/Tencent-Video-Cloud-Toolkit-Privacy-Protection-Guidelines.html" withTitleString:V2Localize(@"Demo.TRTC.Portal.private")];
	[self.rootVC.navigationController pushViewController:webViewController animated:TRUE];
}

- (void)showProtocol {
	WebViewController* webViewController = [[WebViewController alloc] initWithUrlString:@"https://web.sdk.qcloud.com/document/Tencent-Video-Cloud-Toolkit-User-Agreement.html" withTitleString:V2Localize(@"Demo.TRTC.Portal.agreement")];
	[self.rootVC.navigationController pushViewController:webViewController animated:TRUE];
}

- (BOOL)textView:(UITextView *)textView shouldInteractWithURL:(NSURL *)URL inRange:(NSRange)characterRange {
	if ([URL.absoluteString isEqualToString:@"privacy"]) {
		[self showPrivacy];
	}
	else if ([URL.absoluteString isEqualToString:@"protocol"]) {
		[self showProtocol];
	}
	return TRUE;
}
@end
