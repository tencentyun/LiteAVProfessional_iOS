//
//  AppUtils.h
//  TXLiteAVDemo_Enterprise
//
//  Created by peterwtma on 2021/8/9.
//  Copyright © 2021 Tencent. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AppDelegate.h"

NS_ASSUME_NONNULL_BEGIN

@interface AppUtils : NSObject
@property (nonatomic, strong) AppDelegate *appDelegate;
@property (nonatomic, strong) NSString *curUserId;
+ (instancetype)shared;
- (void)showMainController;
- (void)showLoginController;
- (void)alertUserTips:(UIViewController*)_vc;
@end

NS_ASSUME_NONNULL_END
