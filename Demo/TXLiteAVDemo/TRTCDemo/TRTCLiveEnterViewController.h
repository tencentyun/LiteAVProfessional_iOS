//
//  TRTCEntranceViewController.h
//  TXLiteAVDemo_Enterprise
//
//  Created by bluedang on 2021/5/13.
//  Copyright © 2021 Tencent. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "TRTCSettingsBaseViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface TRTCLiveEnterViewController : TRTCSettingsBaseViewController

@property(strong, nonatomic) TRTCSettingsSegmentItem *roleItem;
@property(assign, nonatomic) TRTCAppScene scene;

@property(nonatomic) BOOL useCppWrapper;  // 若使用C++全平台接口，则不再显示音效播放界面，因为相关接口已废弃

@end

NS_ASSUME_NONNULL_END
