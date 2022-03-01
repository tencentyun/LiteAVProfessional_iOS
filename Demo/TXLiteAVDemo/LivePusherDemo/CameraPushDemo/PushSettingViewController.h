/**
 * Module:   PushSettingViewController
 *
 * Function: 推流相关的主要设置项
 */

#import <UIKit/UIKit.h>

#import "V2TXLiveDef.h"
#import "V2TXLivePusher.h"

@class PushSettingViewController;

@protocol PushSettingDelegate <NSObject>

// 是否开启耳返
- (void)onPushSetting:(PushSettingViewController *)vc enableAudioPreview:(BOOL)enableAudioPreview;

// 画质类型
- (void)onPushSetting:(PushSettingViewController *)vc videoQuality:(V2TXLiveVideoResolution)videoQuality;

// 音质类型
- (void)onPushSetting:(PushSettingViewController *)vc audioQuality:(V2TXLiveAudioQuality)qulity;

// SEI 消息
- (void)onPushSetting:(PushSettingViewController *)vc seiMessagePayloadType:(int)payloadType data:(NSData *)data;

@end

@interface                                         PushSettingViewController : UIViewController
@property(nonatomic, weak) id<PushSettingDelegate> delegate;
@property(nonatomic, weak) V2TXLivePusher *        pusher;

/*** 从文件中读取配置 ***/
+ (BOOL)getBandWidthAdjust;
+ (BOOL)getEnableHWAcceleration;
+ (BOOL)getEnableAudioPreview;
+ (NSInteger)getAudioQuality;
+ (V2TXLiveVideoResolution)getVideoQuality;

@end
