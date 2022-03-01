//
//  TRTCCdnPlayerSettingsViewController.h
//  TXLiteAVDemo
//
//  Created by origin 李 on 2021/8/19.
//  Copyright © 2021 Tencent. All rights reserved.
//

#import "TRTCCdnPlayerManager.h"
#import "TRTCSettingsBaseViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface TRTCCdnPlayerSettingsViewController : TRTCSettingsBaseViewController
@property(strong, nonatomic) TRTCCdnPlayerManager *manager;
@end

NS_ASSUME_NONNULL_END

