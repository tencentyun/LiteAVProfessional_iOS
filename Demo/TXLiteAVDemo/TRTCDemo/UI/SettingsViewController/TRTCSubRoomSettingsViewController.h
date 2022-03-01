/*
 * Module:   TRTCSubRoomSettingsViewController
 *
 * Function: 子房间设置页
 *
 *    1. 包括: 进入/退出子房间、控制在子房间和主房间内的推流切换
 *
 *    2. 同时只能在一个房间内进行推流，子房间的说明可参见TRTC的文档或TRTCCloud.h中的接口注释。
 */

#import "TRTCCloudManager.h"
#import "TRTCSettingsBaseViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface TRTCSubRoomSettingsViewController : TRTCSettingsBaseViewController

- (instancetype)initWithCloudManager:(TRTCCloudManager *)trtcCloudManager;
@property(strong, nonatomic) TRTCCloudManager *trtcCloudManager;
@property(strong, nonatomic) TRTCParams *      params;

@end

NS_ASSUME_NONNULL_END
