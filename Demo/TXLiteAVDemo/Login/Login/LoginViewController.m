//
//  LoginViewController.m
//  TXLiteAVDemo_Enterprise
//
//  Created by peterwtma on 2021/7/21.
//  Copyright © 2021 Tencent. All rights reserved.
//
#import "LoginViewController.h"
#import "ColorMacro.h"
#import "AppLocalized.h"
#import "TRTCLoginAlertView.h"
#import "WebViewController.h"
#import "ProfileManager.h"
#import "AppDelegate.h"
#import "PrivacyPopView.h"
#import "ProfileViewController.h"
#import "ToastView.h"
#import "TXLiteAVSDKHeader.h"
#import <WebKit/WebKit.h>
#import <Masonry.h>
#import "TXConfigManager.h"

void (^verifySuccessBlock)(NSString* _ticket, NSString* _random);
void (^verifyFailedBlock)(NSString* message);

#pragma- NSString extension
@interface NSString (textExtension)

@end

@implementation NSString (textExtension)
static NSString* verifySuccessStr = @"verifySuccess";
static NSString* verifyCancelStr = @"verifyCancel";
static NSString* verifyErrorStr = @"verifyError";
@end

#pragma- TRTCLoginAgreementTextView

@implementation TRTCLoginAgreementTextView

-(BOOL)canBecomeFirstResponder {
	return false;
}
@end


#pragma- LoginViewController

@interface LoginViewController ()<UITextViewDelegate, WKScriptMessageHandler, WKNavigationDelegate, UITextFieldDelegate>
@property (nonatomic, strong) UILabel *trtcTitle;
@property (nonatomic, strong) UIActivityIndicatorView *loading;
@property (nonatomic, assign) NSInteger verifyTime;
@property (nonatomic, strong) NSTimer *countTimer; //定时器
@property (nonatomic, strong) UILabel *phoneTip; //手机号
@property (nonatomic, strong) UITextField *phoneNumber; //手机号输入框
@property (nonatomic, assign) BOOL phoneNumberVaild; //是否是一个正确的手机号
@property (nonatomic, strong) UILabel *codeTip; //验证码
@property (nonatomic, strong) UITextField* verifyText; //验证码输入框
@property (nonatomic, assign) BOOL verifyTextVaild; //是否是一个正确的验证码
@property (nonatomic, strong) UIButton *loginButton; //登录按钮
@property (nonatomic, strong) UIButton *countryCodeBtn;
@property (nonatomic, strong) UIImageView *countryCodeTipsImageView;
@property (nonatomic, strong) UILabel *versionTip;
@property (nonatomic, strong) UILabel *bottomTip;
@property (nonatomic, strong) UIButton *verifyCodeBtn;
@property (nonatomic, strong) WKWebView *webView;
@property (nonatomic, strong) TRTCLoginCountryModel *countryModel;
//bolck声明
@property (nonatomic, copy) void (^verifySuccessBlock) (NSString*, NSString*);
@property (nonatomic, copy) void (^verifyFailedBlock) (NSString*);
@end

@implementation LoginViewController

- (void)viewDidLoad {
	[super viewDidLoad];

	[self setupUI];
	[self constructViewHierarchy];
	[self addConstraint];
	[self bindInteraction];
    if ([TXConfigManager shareInstance].isRelease) {
        [self loginProcess];
    }
}

- (void)loginProcess {
	//auto login
	[ProfileManager.shared autoLogin:^{
        [self loginSucc];
	 } fail:^(NSString *_error) {
        CSToast.text(V2Localize(@"V2.Live.LinkMicNew.loginfail")).show();
     }];

	//first run privacy pop
	if ([PrivacyPopView isFirstRun]) {
		PrivacyPopView* popView = [[PrivacyPopView alloc] init];
		popView.rootVC = self;
        __weak __typeof(self) weakSelf = self;
        popView.agreeBlock = ^{
            [weakSelf.agreementBtn setSelected:YES];
        };
        popView.disAgreeBlock = ^{
            [weakSelf.agreementBtn setSelected:NO];
        };
		[popView show];
	}
}

- (void)constructViewHierarchy {
	[self.view addSubview:self.loading];
	[self.view addSubview:self.trtcTitle];
	[self.view addSubview:self.inputBackImage];
	[self.view addSubview:self.phoneNumber];
	[self.view addSubview:self.phoneTip];
	[self.view addSubview:self.countryCodeBtn];
	[self.view addSubview:self.countryCodeTipsImageView];
	[self.view addSubview:self.codeTip];
	[self.view addSubview: self.verifyText];
	[self.view addSubview:self.verifyCodeBtn];
	[self.view addSubview:self.agreementBtn];
	[self.view addSubview:self.agreementTextView];
	[self.view addSubview:self.loginButton];
	[self.view addSubview:self.bottomTip];
	[self.view addSubview:self.versionTip];
}

- (void)addConstraint {
	[self.loading mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.height.mas_equalTo(40);
        make.centerX.centerY.equalTo(self.view);
	 }];
	[self.trtcTitle mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.trailing.mas_equalTo(10);
        make.top.mas_equalTo(self.view.frame.size.height * 40.0 / 667);
	 }];
	[self.inputBackImage mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(@20);
        make.trailing.equalTo(@-20);
        make.top.mas_equalTo(self.view.frame.size.height * 170.0/667);
        make.height.mas_equalTo(100);
	 }];
	[self.phoneNumber mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.inputBackImage.mas_top).offset(10);
        make.leading.mas_equalTo(140);
        make.trailing.mas_equalTo(-35);
        make.height.mas_equalTo(30);
	 }];
	[self.phoneTip mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.mas_equalTo(30);
        make.top.mas_equalTo(self.inputBackImage.mas_top).offset(10);
        make.width.lessThanOrEqualTo(@100);
        make.height.equalTo(@30);
	 }];
	[self.countryCodeBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.phoneTip);
        make.trailing.mas_equalTo(-35);
        make.width.mas_equalTo(self.countryCodeBtn.frame.size.width + self.countryCodeTipsImageView.frame.size.width+10);
	 }];
	[self.countryCodeTipsImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.trailing.centerY.equalTo(self.countryCodeBtn);
	 }];
	[self.codeTip mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.mas_equalTo(30);
        make.bottom.equalTo(self.inputBackImage.mas_bottom).offset(-10);
        make.width.lessThanOrEqualTo(@100);
        make.height.equalTo(@30);
	 }];
	[self.verifyText mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(self.inputBackImage.mas_bottom).offset(-10);
        make.leading.equalTo(@140);
        make.trailing.equalTo(@-35);
        make.height.equalTo(@30);
	 }];
	[self.verifyCodeBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.verifyText).offset(10);
        make.centerY.equalTo(self.verifyText).offset(1);
        make.height.equalTo(@30);
	 }];
	[self.agreementBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.inputBackImage.mas_bottom).offset(6);
        make.leading.equalTo(self.inputBackImage);
        make.size.mas_equalTo(CGSizeMake(12, 12));
	 }];
	[self.agreementTextView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(self.agreementBtn.mas_trailing);
        make.top.equalTo(self.agreementBtn);
        make.trailing.equalTo(self.inputBackImage);
        make.height.equalTo(@40);
	 }];
	[self.loginButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.agreementTextView.mas_bottom).offset(10);
        make.height.equalTo(@46);
        make.leading.trailing.equalTo(self.inputBackImage);
	 }];
	[self.bottomTip mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(self.view).offset(-12);
        make.leading.trailing.equalTo(self.view);
        make.height.equalTo(@30);
	 }];
	[self.versionTip mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(self.bottomTip.mas_top).offset(-2);
        make.height.equalTo(@12);
        make.leading.trailing.equalTo(self.view);
	 }];
}

//绑定事件
- (void) bindInteraction {
	self.phoneNumber.delegate = self;
	self.verifyText.delegate = self;

	//绑定同意用户协议按钮点击事件
	[self.agreementBtn addTarget:self action:@selector(agreementCheckboxBtnClick) forControlEvents:UIControlEventTouchUpInside];

	//绑定登录按钮事件
	[self.loginButton addTarget:self action:@selector(loginButtonClick) forControlEvents:UIControlEventTouchUpInside];

	//绑定选择国家电话号前缀码事件
	[self.countryCodeBtn addTarget:self action:@selector(countryCodeBtnClick) forControlEvents:UIControlEventTouchUpInside];

	//绑定点击获取验证码按钮
	[self.verifyCodeBtn addTarget:self action:@selector(verifyCodeBtnClick)  forControlEvents:UIControlEventTouchUpInside];

	//监听手机号输入
	[self.phoneNumber addTarget:self action:@selector(phoneNumberChange) forControlEvents:UIControlEventEditingChanged];

	//监听验证码输入
	[self.verifyText addTarget:self action:@selector(verifyTextChange) forControlEvents:UIControlEventEditingChanged];

	//监听verifyTime 的变化
	[self addObserver:self forKeyPath:@"verifyTime" options:NSKeyValueObservingOptionNew context:nil];
}

//绘制UI
- (void)setupUI {
	//设置加载菊花
	self.loading = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(0, 0, 100, 60)];

	NSArray* colors = @[(__bridge id)[UIColor colorWithRed:(19.0/255.0) green:(41.0/255.0) blue:(75.0/255.0) alpha:1].CGColor, (__bridge id)[UIColor colorWithRed:(5.0/255.0) green:(12.0/255.0) blue:(23.0/255.0) alpha:1].CGColor];
	CAGradientLayer* gradientLayer = [CAGradientLayer layer];
	gradientLayer.colors = colors;
	gradientLayer.startPoint = CGPointMake(0, 0);
	gradientLayer.endPoint = CGPointMake(1, 1);
	gradientLayer.frame = self.view.bounds;
	[self.view.layer insertSublayer:gradientLayer atIndex:0];

	self.webView = [self loadWKWebView];

	self.trtcTitle = [[UILabel alloc] init];
	self.trtcTitle.textAlignment = NSTextAlignmentCenter;
	[self.trtcTitle setFont:[UIFont systemFontOfSize:18]];
	[self.trtcTitle setTextColor:[UIColor whiteColor]];
	self.trtcTitle.text = V2Localize(@"V2.Live.LinkMicNew.loginTitle");

	self.inputBackImage = [[UIImageView alloc] init];
	self.inputBackImage.backgroundColor = UIColorFromRGB(0x092650);


	//手机号
	self.phoneTip = [[UILabel alloc] init];
	[self.phoneTip setText:V2Localize(@"V2.Live.LoginMock.mobilenumber")];
	self.phoneTip.textColor = [UIColor whiteColor];
	self.phoneTip.font = [UIFont systemFontOfSize:16];
	self.phoneTip.adjustsFontSizeToFitWidth = true;
	self.phoneTip.minimumScaleFactor = 0.5;

	//验证码
	self.codeTip = [[UILabel alloc] init];
	self.codeTip.text = V2Localize(@"V2.Live.LoginMock.verificationcode");
	self.codeTip.textColor = [UIColor whiteColor];
	self.codeTip.font = [UIFont systemFontOfSize:16];
	self.codeTip.adjustsFontSizeToFitWidth = true;
	self.codeTip.minimumScaleFactor = 0.5;

	//登录按钮
	self.loginButton = [[UIButton alloc] init];
	self.loginButton.backgroundColor = UIColorFromRGB(0x0062E3);
	[self.loginButton setTitle:V2Localize(@"V2.Live.LoginMock.login") forState:normal];
	[self.loginButton setTitleColor:[UIColor whiteColor] forState:normal];
	self.loginButton.layer.cornerRadius = 4;

	self.agreementBtn = [[UIButton alloc] init];
	[self.agreementBtn setImage:[UIImage imageNamed:@"checkbox_nor"] forState:UIControlStateNormal];
	[self.agreementBtn setImage:[UIImage imageNamed:@"checkbox_sel"] forState:UIControlStateSelected];
	[self.agreementBtn sizeToFit];

	self.agreementTextView = [[TRTCLoginAgreementTextView alloc] init];
	[self initAgreementTextView];

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
	self.versionTip.text = [NSString stringWithFormat:@"TRTC v%@(%@)", sdkVersionStr, version];
	self.versionTip.adjustsFontSizeToFitWidth = true;

	self.bottomTip = [[UILabel alloc] init];
	self.bottomTip.textAlignment = NSTextAlignmentCenter;
	self.bottomTip.font = [UIFont systemFontOfSize:14];
	self.bottomTip.textColor = UIColorFromRGB(0x525252);
	self.bottomTip.text = V2Localize(@"V2.Live.LinkMicNew.appusetoshowfunc");
	self.bottomTip.adjustsFontSizeToFitWidth = true;

	self.verifyCodeBtn = [[UIButton alloc] init];
	self.verifyCodeBtn.backgroundColor = [UIColor clearColor];
	[self.verifyCodeBtn setTitleColor:[UIColor colorWithRed:(0.0) green:(110.0/255.0) blue:(253.0/255.0) alpha:1] forState:normal];
	[self.verifyCodeBtn setTitle:V2Localize(@"V2.Live.LinkMicNew.getverificationcode") forState:normal];

	//TODO-- countryModel
	self.countryCodeBtn = [[UIButton alloc] init];
	[self.countryCodeBtn setTitle:@"+86" forState:normal];
	[self.countryCodeBtn setTitleColor:[UIColor whiteColor] forState:normal];
	self.countryCodeBtn.titleEdgeInsets = UIEdgeInsetsMake(0, 0, 0, self.countryCodeTipsImageView.frame.size.width);
    [self.countryCodeBtn sizeToFit];
	self.view.backgroundColor = UIColorFromRGB(0x242424);

	self.phoneNumber = [[UITextField alloc] init];
	self.phoneNumber.textColor = [UIColor whiteColor];
	self.phoneNumber.attributedPlaceholder = [self setTextFieldAttribute:V2Localize(@"V2.Live.LinkMicNew.enterphonenumber")];
	self.phoneNumber.keyboardType = UIKeyboardTypePhonePad;

	self.countryCodeTipsImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"arrow"]];
	[self.countryCodeTipsImageView setUserInteractionEnabled:FALSE];
	[self.countryCodeTipsImageView sizeToFit];

	self.verifyText = [[UITextField alloc] init];
	self.verifyText.textColor = [UIColor whiteColor];
	self.verifyText.attributedPlaceholder = [self setTextFieldAttribute:V2Localize(@"V2.Live.LinkMicNew.enterverificationcode")];
	self.verifyText.keyboardType = UIKeyboardTypePhonePad;
}

- (void)initAgreementTextView {
	self.agreementTextView.delegate = self;
	self.agreementTextView.backgroundColor = [UIColor clearColor];
	[self.agreementTextView setEditable:FALSE];
	self.agreementTextView.textContainerInset = UIEdgeInsetsZero;
	self.agreementTextView.textContainer.lineFragmentPadding = 0;
	self.agreementTextView.dataDetectorTypes = UIDataDetectorTypeLink;

	NSString *totalStr = LocalizeReplace(V2Localize(@"Demo.TRTC.Portal.privateandagreement"), V2Localize(@"Demo.TRTC.Portal.<private>"),  V2Localize(@"Demo.TRTC.Portal.<agreement>"));
	NSString *privaStr = V2Localize(@"Demo.TRTC.Portal.<private>");
	NSString *protoStr = V2Localize(@"Demo.TRTC.Portal.<agreement>");

	NSRange privaR = [totalStr rangeOfString:privaStr];
	NSRange protoR = [totalStr rangeOfString:protoStr];
	NSRange totalRange = NSMakeRange(0, totalStr.length);

	NSMutableAttributedString *attr = [[NSMutableAttributedString alloc] initWithString:totalStr];
	NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
	style.alignment = NSTextAlignmentCenter;
	[attr addAttribute:NSParagraphStyleAttributeName value:style range:totalRange];
	[attr addAttribute:NSFontAttributeName value: [UIFont fontWithName:@"PingFangSC-Regular" size:10] range:totalRange];
	[attr addAttribute:NSForegroundColorAttributeName value:[UIColor lightGrayColor] range:totalRange];
	[attr addAttribute:NSLinkAttributeName value:@"privacy" range:privaR];
	[attr addAttribute:NSLinkAttributeName value:@"protocol" range:protoR];
	[attr addAttribute:NSForegroundColorAttributeName value:[UIColor blueColor] range:privaR];
	[attr addAttribute:NSForegroundColorAttributeName value:[UIColor blueColor] range:protoR];
	self.agreementTextView.attributedText = attr;
}

- (void) phoneNumberChange {
	if (self.phoneNumber.text.length == 11) {
		self.phoneNumberVaild = true;
		//如果手机号合格，那就更新到ProfileManager中
		ProfileManager.shared.phone = self.phoneNumber.text;
	} else {
        if (self.phoneNumber.text.length > 11) {
            ProfileManager.shared.phone = [self.phoneNumber.text substringWithRange:NSMakeRange(0,11)];
            self.phoneNumber.text = ProfileManager.shared.phone;
            self.phoneNumberVaild = true;
        } else {
            self.phoneNumberVaild = false;
        }
	}
}

- (void) verifyTextChange {
	if (self.verifyText.text.length == 6) {
		self.verifyTextVaild = true;
		ProfileManager.shared.code = self.verifyText.text;
	} else {
        if (self.verifyText.text.length > 6) {
            ProfileManager.shared.code = [self.verifyText.text substringWithRange:NSMakeRange(0,6)];
            self.verifyText.text = ProfileManager.shared.code;
            self.verifyTextVaild = true;
        }else{
            self.verifyTextVaild = false;
        }
	}
}

//加载验证码图片
- (void) showVerifyWebView:(void (^)(NSString* ticket, NSString* randomStr)) success failed:(void (^)(NSString* err))failed {
    
    [[ProfileManager shared] requestGslb:^{
        [self.view addSubview:self.webView];
        [self.webView mas_makeConstraints:^(MASConstraintMaker *make) {
                 make.edges.equalTo(self.webView.superview);
         }];

        NSString* path = [NSBundle.mainBundle pathForResource:@"VerifyPicture" ofType:@"html"];
        if (!path) {
            failed(@"");
            return;
        }
        NSURL* pathUrl = [NSURL fileURLWithPath:path];
        NSURLRequest* req = [NSURLRequest requestWithURL:pathUrl];

        verifySuccessBlock = success;
        verifyFailedBlock = failed;
        [self.webView loadRequest:req];
        
        
      } fail:^(NSString *_error) {
          [self.loading stopAnimating];
    }];
}

- (void) verifyCodeBtnClick {
	if (self.verifyTime != 0) {
		return;
	}

	if (!self.phoneNumberVaild) {
		CSToast.text(V2Localize(@"V2.Live.LinkMicNew.entertruephonenum")).show();
		return;
	}
    
    if (!self.agreementBtn.isSelected) {
        CSToast.text(V2Localize(@"Demo.TRTC.Portal.agreeprivatefirst")).show();
        return;
    }

	[self.phoneNumber resignFirstResponder];
	[self.verifyText resignFirstResponder];

	//设置国家码前缀
	NSString* countryCode = @"86";
	if (self.countryModel) {
		countryCode = self.countryModel.code;
	}
	ProfileManager.shared.countryCode = countryCode;

	//加载动画
	[self.loading startAnimating];
	[self showVerifyWebView:^(NSString *ticket, NSString *randomStr) {
	         [ProfileManager.shared sendVerifyCode:ticket randomStr:randomStr sucess:^{
                 [self.loading stopAnimating];
                 //设置弹出框
                 CSToast.text(V2Localize(@"V2.Live.LinkMicNew.verificationcodesent")).show();
                 [self startTimer];
	                 
		  } failed:^(NSString *_error) {
              //停止动画
              [self.loading stopAnimating];
              CSToast.text(_error).show();
		  }];
	 } failed:^(NSString *err) {
	         //停止动画
	         [self.loading stopAnimating];
	         CSToast.text(@"验证失败").show();
	 }];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
	if([keyPath isEqualToString:@"verifyTime"]) {
		id time = [change objectForKey:@"new"];
		if (![time isEqual:@0]) {
			[self.verifyCodeBtn setTitle:[NSString stringWithFormat:@"%@s", time] forState:normal];
		} else {
			[self.verifyCodeBtn setTitle:V2Localize(@"V2.Live.LinkMicNew.getverificationcode") forState:normal];
		}
	}
}

- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];

	[self stopTimer];
}

- (void)startTimer {
	[self stopTimer];
	self.verifyTime = 60;
	self.countTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(countDownVerifyTime) userInfo:nil repeats:true];
}

- (void)stopTimer {
	if ([self.countTimer isValid]) {
		[self.countTimer invalidate]; //停止并删除定时器
	}
	self.countTimer = nil;
	self.verifyTime = 0;
}

- (void)countDownVerifyTime {
	if (self.verifyTime > 0) {
		self.verifyTime--;
	} else {
		[self stopTimer];
	}
}

- (WKWebView*) loadWKWebView {
	WKWebViewConfiguration* config = [[WKWebViewConfiguration alloc] init];

	WKPreferences* preference = [[WKPreferences alloc] init];
	preference.javaScriptEnabled = true;
	preference.javaScriptCanOpenWindowsAutomatically = true;

	config.preferences = preference;

	WKUserContentController* wkUserController = [[WKUserContentController alloc] init];
	[wkUserController addScriptMessageHandler:self name:@"verifySuccess"];
	[wkUserController addScriptMessageHandler:self name:@"verifyError"];
	[wkUserController addScriptMessageHandler:self name:@"verifyCancel"];

	config.userContentController = wkUserController;


	WKWebView* webview = [[WKWebView alloc] initWithFrame:CGRectZero configuration:config];

	[webview setOpaque:false];
	webview.backgroundColor = [UIColor clearColor];
	webview.scrollView.backgroundColor = [UIColor clearColor];
	webview.navigationDelegate = self;
	return webview;
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
	NSString* js = @"document.getElementsByClassName('navbar')[0].style.display='none'";
	[self.webView evaluateJavaScript:js completionHandler:nil];
    NSString *jscallVerify = [NSString stringWithFormat:@"callVerify('%@');",[ProfileManager shared].captcha_web_appid];
    
    [self.webView evaluateJavaScript:jscallVerify completionHandler:nil];
}

- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message {
	if([message.name isEqualToString: @"verifySuccess"]) {
		if ( !(message.body && [message.body isKindOfClass:[NSString class]]) ) {
			[self.webView removeFromSuperview];
			return;
		}
		id data = [message.body dataUsingEncoding:NSUTF8StringEncoding];
		if (!data) {
			[self.webView removeFromSuperview];
			return;
		}
		id parameter = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:nil];

		if ([parameter objectForKey:@"ticket"] && [parameter objectForKey:@"randstr"]) {
			NSString* randstr = [parameter objectForKey:@"randstr"];
			NSString* ticket = [parameter objectForKey:@"ticket"];

			verifySuccessBlock(ticket, randstr);
		}

		[self.webView removeFromSuperview];
	} else if ([message.name isEqualToString:@"verifyCancel"]) {
		[self.webView removeFromSuperview];
	} else if ([message.name isEqualToString:@"verifyError"]) {
		if ( !(message.body && [message.body isKindOfClass:[NSString class]]) ) {
			[self.webView removeFromSuperview];
			return;
		}
		verifyFailedBlock(message.body);
	} else {
		return;
	}
}

//点击城市按钮
- (void)countryCodeBtnClick {
	TRTCLoginCountryAlert *alert = [[TRTCLoginCountryAlert alloc] init];

	[self.view addSubview:alert];
	[alert mas_makeConstraints:^(MASConstraintMaker *make) {
	         make.edges.equalTo(alert.superview);
	 }];
	[alert.superview layoutIfNeeded];
	[alert show];
	alert.didSelect = ^(TRTCLoginCountryModel * _Nonnull model) {
		self.countryModel = model;
		[self.countryCodeBtn setTitle:model.displayTitle forState:normal];
		[self.countryCodeBtn sizeToFit];
		CGFloat width = self.countryCodeBtn.frame.size.width;
		CGFloat imgWidth = self.countryCodeTipsImageView.frame.size.width;
		self.countryCodeBtn.titleEdgeInsets = UIEdgeInsetsMake(0, -imgWidth, 0, imgWidth);
		[self.countryCodeBtn mas_updateConstraints:^(MASConstraintMaker *make) {
		         make.width.mas_equalTo(width + imgWidth);
		 }];
	};
}

//选择
- (void)agreementCheckboxBtnClick {
	[self.agreementBtn setSelected:!self.agreementBtn.isSelected];
}

- (void)showProfileVC {
	ProfileViewController* profileVC = [[ProfileViewController alloc] init];
	[self.navigationController pushViewController:profileVC animated:true];
}

- (void)loginSucc {
	if ([ProfileManager shared].curUserModel) {
		if ([ProfileManager shared].curUserModel.name.length == 0) {
            [self showProfileVC];
		} else {
            [self.loading stopAnimating];
            CSToast.text(V2Localize(@"V2.Live.LinkMicNew.loginsuccess")).show();
            AppDelegate* appDelegate = (AppDelegate*) UIApplication.sharedApplication.delegate;
            [appDelegate showPortalConroller];
		}
	}
}


//登录按钮点击
- (void)loginButtonClick {
	if (!self.agreementBtn.isSelected) {
		CSToast.text(V2Localize(@"Demo.TRTC.Portal.agreeprivatefirst")).show();
		return;
	}

	if (!self.phoneNumberVaild) {
		CSToast.text(V2Localize(@"V2.Live.LinkMicNew.entertruephonenum")).show();
		return;
	}

	if (!self.verifyTextVaild) {
		CSToast.text(V2Localize(@"V2.Live.LinkMicNew.enterverificationcode")).show();
		return;
	}

	[self.loading startAnimating];

	//加载动画
	[[ProfileManager shared] login:^{
        [self.loading stopAnimating];
	         [self loginSucc];
	 } fail:^(NSString* err) {
         [self.loading stopAnimating];
         CSToast.text(err).show();
	 } autoLogin:false];
}

//set TextFiled Attribute
- (NSMutableAttributedString*)setTextFieldAttribute:(NSString*)text {
	NSMutableAttributedString *attr = [[NSMutableAttributedString alloc] initWithString:text];
	NSRange range = NSMakeRange(0, attr.length);
	[attr addAttribute:NSForegroundColorAttributeName value:[UIColor grayColor] range:range];
	return attr;
}


#pragma mark ---UITextViewDelegate

- (void)showPrivacy {
	WebViewController* webViewController = [[WebViewController alloc] initWithUrlString:@"https://web.sdk.qcloud.com/document/Tencent-Video-Cloud-Toolkit-Privacy-Protection-Guidelines.html" withTitleString:V2Localize(@"Demo.TRTC.Portal.private")];
	[self.navigationController pushViewController:webViewController animated:TRUE];
}

- (void)showProtocol {
	WebViewController* webViewController = [[WebViewController alloc] initWithUrlString:@"https://web.sdk.qcloud.com/document/Tencent-Video-Cloud-Toolkit-User-Agreement.html" withTitleString:V2Localize(@"Demo.TRTC.Portal.agreement")];
	[self.navigationController pushViewController:webViewController animated:TRUE];
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

#pragma mark - UITextFieldDelegate
- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
	if (textField == self.phoneNumber) {
		self.phoneNumber.attributedPlaceholder = nil;
	}
	if (textField == self.verifyText) {
		self.verifyText.attributedPlaceholder = nil;
	}
	return YES;
}

- (BOOL)textFieldShouldEndEditing:(UITextField *)textField {
	if (textField == self.phoneNumber) {
		self.phoneNumber.attributedPlaceholder = [self setTextFieldAttribute:V2Localize(@"V2.Live.LinkMicNew.enterphonenumber")];
	}
	if (textField == self.verifyText) {
		self.verifyText.attributedPlaceholder = [self setTextFieldAttribute:V2Localize(@"V2.Live.LinkMicNew.enterverificationcode")];
	}
	return YES;
}

@end


