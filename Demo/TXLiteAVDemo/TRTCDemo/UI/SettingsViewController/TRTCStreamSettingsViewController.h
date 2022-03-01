/*
 * Module:   TRTCStreamSettingsViewController
 *
 * Function: 混流设置页
 *
 *    1. 通过TRTCCloudManager来开启关闭云端混流。
 *
 *    2. 显示房间的直播地址二维码。
 *
 */

#import "TRTCCloudManager.h"
#import "TRTCSettingsBaseViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface TRTCStreamSettingsViewController : TRTCSettingsBaseViewController

@property(strong, nonatomic) TRTCCloudManager *trtcCloudManager;

@end

NS_ASSUME_NONNULL_END
