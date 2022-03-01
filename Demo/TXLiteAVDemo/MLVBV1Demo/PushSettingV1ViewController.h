/**
 * Module:   PushSettingV1ViewController
 *
 * Function: 推流相关的主要设置项
 */

#import <UIKit/UIKit.h>
#import "TXLiveSDKTypeDef.h"

@class PushSettingV1ViewController;

@protocol PushSettingV1Delegate <NSObject>

// 是否开启带宽适应
- (void)onPushSetting:(PushSettingV1ViewController *)vc enableBandwidthAdjust:(BOOL)enableBandwidthAdjust;

// 是否开启硬件加速
- (void)onPushSetting:(PushSettingV1ViewController *)vc enableHWAcceleration:(BOOL)enableHWAcceleration;

// 是否开启耳返
- (void)onPushSetting:(PushSettingV1ViewController *)vc enableAudioPreview:(BOOL)enableAudioPreview;

// 画质类型
- (void)onPushSetting:(PushSettingV1ViewController *)vc videoQuality:(TX_Enum_Type_VideoQuality)videoQuality;

// 音质类型
- (void)onPushSetting:(PushSettingV1ViewController *)vc audioQuality:(NSInteger)qulity;

// 混响效果
- (void)onPushSetting:(PushSettingV1ViewController *)vc reverbType:(TXReverbType)reverbType;

// 变声类型
- (void)onPushSetting:(PushSettingV1ViewController *)vc voiceChangerType:(TXVoiceChangerType)voiceChangerType;

@end


@interface PushSettingV1ViewController : UIViewController
@property (nonatomic, weak) id<PushSettingV1Delegate> delegate;

/*** 从文件中读取配置 ***/
+ (BOOL)getBandWidthAdjust;
+ (BOOL)getEnableHWAcceleration;
+ (BOOL)getEnableAudioPreview;
+ (NSInteger)getAudioQuality;
+ (TX_Enum_Type_VideoQuality)getVideoQuality;
+ (TXReverbType)getReverbType;
+ (TXVoiceChangerType)getVoiceChangerType;

@end

