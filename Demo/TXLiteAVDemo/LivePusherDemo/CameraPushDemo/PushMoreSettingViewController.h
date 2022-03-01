/**
 * Module:   PushMoreSettingViewController
 *
 * Function: 推流相关的更多设置项
 */

#import <UIKit/UIKit.h>
#import "V2TXLivePusher.h"
@class PushMoreSettingViewController;

@protocol PushMoreSettingDelegate <NSObject>

// 是否开启隐私模式（关闭摄像头，并发送pauseImg图片）
- (void)onPushMoreSetting:(PushMoreSettingViewController *)vc disableVideo:(BOOL)disable;

// 是否开启静音模式（发送静音数据，但是不关闭麦克风）
- (void)onPushMoreSetting:(PushMoreSettingViewController *)vc muteAudio:(BOOL)mute;

// 是否开启观看端镜像
- (void)onPushMoreSetting:(PushMoreSettingViewController *)vc mirrorVideo:(BOOL)mirror;

// 是否开启后置闪光灯
- (void)onPushMoreSetting:(PushMoreSettingViewController *)vc openTorch:(BOOL)open;

// 是否开启调试信息
- (void)onPushMoreSetting:(PushMoreSettingViewController *)vc debugLog:(BOOL)show;

// 是否添加图像水印
- (void)onPushMoreSetting:(PushMoreSettingViewController *)vc waterMark:(BOOL)enable;

// 是否开启手动点击曝光对焦
- (void)onPushMoreSetting:(PushMoreSettingViewController *)vc touchFocus:(BOOL)enable;

// 是否开启横屏推流
- (void)onPushMoreSetting:(PushMoreSettingViewController *)vc resolutionLandscap:(BOOL)enable;

// 本地截图
- (void)onPushMoreSettingSnapShot:(PushMoreSettingViewController *)vc;

// 弹框提示
- (void)onPushMoreSetting:(PushMoreSettingViewController *)vc alertTips:(NSString *)text;

@end

@interface                                             PushMoreSettingViewController : UITableViewController
@property(nonatomic, weak) id<PushMoreSettingDelegate> delegate;
@property(nonatomic, weak) V2TXLivePusher             *pusher;

/*** 从文件中读取配置 ***/
+ (BOOL)isDisableVideo;
+ (BOOL)isMuteAudio;
+ (BOOL)isMirrorVideo;
+ (BOOL)isOpenTorch;
+ (BOOL)isShowDebugLog;
+ (BOOL)isEnableDelayCheck;
+ (BOOL)isEnableWaterMark;
+ (BOOL)isEnableTouchFocus;
+ (BOOL)isEnableResolutionLandscap;

/*** 写配置文件 ***/
+ (void)setDisableVideo:(BOOL)disable;

- (void)updateOpenTorch:(BOOL)disable;

@end
