//
//  LoginViewController.m
//  TXLiteAVDemo_Enterprise
//
//  Created by peterwtma on 2021/7/21.
//  Copyright © 2021 Tencent. All rights reserved.
//
#import "LoginViewController.h"
#import "ProfileManager.h"
#import "AppDelegate.h"
#import "PrivacyPopView.h"
#import "ProfileViewController.h"
#import "ToastView.h"
#import "AppLocalized.h"

@interface LoginViewController ()

@end

@implementation LoginViewController

- (void)viewDidLoad {
	[super viewDidLoad];
	[self loginProcess];
}

- (void)loginProcess {
    //开发模式免登录
    [ProfileManager.shared notLoginEnter:^{
        [self loginSucc];
    }];
	//first run privacy pop
	if ([PrivacyPopView isFirstRun]) {
		PrivacyPopView* popView = [[PrivacyPopView alloc] init];
		popView.rootVC = self;
		[popView show];
	}
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
            CSToast.text(V2Localize(@"V2.Live.LinkMicNew.loginsuccess")).show();
            AppDelegate* appDelegate = (AppDelegate*) UIApplication.sharedApplication.delegate;
            [appDelegate showPortalConroller];
		}
	}
}

@end


