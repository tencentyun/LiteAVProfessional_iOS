/*
 * Module:   TRTCPKSettingsViewController
 *
 * Function: 跨房PK页
 *
 *    1. 通过TRTCCloudManager来开启或关闭跨房连麦。
 *
 */

#import <UIKit/UIKit.h>

#import "TRTCCloudManager.h"
#import "TRTCSettingsBaseViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface TRTCPKSettingsViewController : TRTCSettingsBaseViewController

@property(strong, nonatomic) TRTCCloudManager *trtcCloudManager;
- (void)syncButtonStatus;
@end

NS_ASSUME_NONNULL_END
