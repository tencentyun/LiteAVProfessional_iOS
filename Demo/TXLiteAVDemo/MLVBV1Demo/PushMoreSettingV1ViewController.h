/**
 * Module:   PushMoreSettingV1ViewController
 *
 * Function: 推流相关的更多设置项
 */

#import <UIKit/UIKit.h>

@class PushMoreSettingV1ViewController;

@protocol PushMoreSettingV1Delegate <NSObject>

// 是否开启隐私模式（关闭摄像头，并发送pauseImg图片）
- (void)onPushMoreSetting:(PushMoreSettingV1ViewController *)vc disableVideo:(BOOL)disable;

// 是否开启静音模式（发送静音数据，但是不关闭麦克风）
- (void)onPushMoreSetting:(PushMoreSettingV1ViewController *)vc muteAudio:(BOOL)mute;

// 是否开启观看端镜像
- (void)onPushMoreSetting:(PushMoreSettingV1ViewController *)vc mirrorVideo:(BOOL)mirror;

// 是否开启后置闪光灯
- (void)onPushMoreSetting:(PushMoreSettingV1ViewController *)vc openTorch:(BOOL)open;

// 是否开启横屏推流
- (void)onPushMoreSetting:(PushMoreSettingV1ViewController *)vc horizontalPush:(BOOL)enable;

// 是否开启调试信息
- (void)onPushMoreSetting:(PushMoreSettingV1ViewController *)vc debugLog:(BOOL)show;

// 是否添加图像水印
- (void)onPushMoreSetting:(PushMoreSettingV1ViewController *)vc waterMark:(BOOL)enable;

// 延迟测定工具条
- (void)onPushMoreSetting:(PushMoreSettingV1ViewController *)vc delayCheck:(BOOL)enable;

// 是否开启手动点击曝光对焦
- (void)onPushMoreSetting:(PushMoreSettingV1ViewController *)vc touchFocus:(BOOL)enable;

// 是否开启手势放大预览画面
- (void)onPushMoreSetting:(PushMoreSettingV1ViewController *)vc videoZoom:(BOOL)enable;

// 是否开始纯音频
- (void)onPushMoreSetting:(PushMoreSettingV1ViewController *)vc pureAudioPush:(BOOL)enable;

// 是否开启清晰度增强
- (void)onPushMoreSetting:(PushMoreSettingV1ViewController *)vc enableSharpnessEnhancement:(BOOL)enable;

// 是否开启H265编码
- (void)onPushMoreSetting:(PushMoreSettingV1ViewController *)vc enableHEVC:(BOOL)enable;

// 本地截图
- (void)onPushMoreSettingSnapShot:(PushMoreSettingV1ViewController *)vc;

// 发送消息
- (void)onPushMoreSettingSendMessage:(PushMoreSettingV1ViewController *)vc message:(NSString*)message;

// 采集帧率 @param fps 采集帧率
- (void)onPushMoreSetting:(PushMoreSettingV1ViewController *)vc captureFPS:(NSInteger)fps;
@end

@interface PushMoreSettingV1ViewController : UITableViewController
@property (nonatomic, weak) id<PushMoreSettingV1Delegate> delegate;

/*** 从文件中读取配置 ***/
+ (BOOL)isDisableVideo;
+ (BOOL)isMuteAudio;
+ (BOOL)isMirrorVideo;
+ (BOOL)isOpenTorch;
+ (BOOL)isHorizontalPush;
+ (BOOL)isShowDebugLog;
+ (BOOL)isEnableDelayCheck;
+ (BOOL)isEnableWaterMark;
+ (BOOL)isEnableTouchFocus;
+ (BOOL)isEnableVideoZoom;
+ (BOOL)isEnablePureAudioPush;
+ (BOOL)isEnableHEVC;

/*** 写配置文件 ***/
+ (void)setDisableVideo:(BOOL)disable;

@end
