//
//  AppUtils.m
//  TXLiteAVDemo_Enterprise
//
//  Created by peterwtma on 2021/8/9.
//  Copyright © 2021 Tencent. All rights reserved.
//

#import "AppUtils.h"
#import "AppLocalized.h"


@implementation AppUtils

static AppUtils* _instance;
+ (instancetype)shared {
    if (!_instance) {
        _instance = [[AppUtils alloc] init];
    }
    return _instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.appDelegate = (AppDelegate*)UIApplication.sharedApplication.delegate;
    }
    return self;
}

- (void)showMainController {
    [self.appDelegate showPortalConroller];
}

- (void)showLoginController {
    [self.appDelegate showLoginController];
}

- (void)alertUserTips:(UIViewController*)_vc {
    // 提醒用户不要用demo App来做违法的事情
    // 每天提醒一次
    NSDate *currentDate = [NSDate date];
    NSInteger nowDay =  [NSCalendar.currentCalendar component:NSCalendarUnitDay fromDate:currentDate];
    NSInteger day = (NSInteger)[NSUserDefaults.standardUserDefaults objectForKey:@"UserTipsKey"];
    if (day == nowDay) {
        return;
    }
    [NSUserDefaults.standardUserDefaults setInteger:nowDay forKey:@"UserTipsKey"];
    [NSUserDefaults.standardUserDefaults synchronize];
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:LoginNetworkLocalize(@"LoginNetwork.AppUtils.warmprompt") message:LoginNetworkLocalize(@"LoginNetwork.AppUtils.tomeettheregulatory") preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *okView = [UIAlertAction actionWithTitle:LoginNetworkLocalize(@"LoginNetwork.AppUtils.determine") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
    }];
    [alert addAction:okView];
    [_vc presentViewController:alert animated:true completion:nil];
}
@end
