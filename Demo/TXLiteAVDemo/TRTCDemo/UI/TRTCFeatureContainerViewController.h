/*
 * Module:   TRTCFeatureContainerViewController
 *
 * Function: 音视频设置弹出页，包含五个子页面：视频、音频、混流、跨房PK和其它
 *
 */

#import "TRTCAudioRecordManager.h"
#import "TRTCCloudManager.h"
#import "TRTCSettingsContainerViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface TRTCFeatureContainerViewController : TRTCSettingsContainerViewController

@property(strong, nonatomic) TRTCCloudManager *      trtcCloudManager;
@property(strong, nonatomic) TRTCAudioRecordManager *recordManager;

@end

NS_ASSUME_NONNULL_END
