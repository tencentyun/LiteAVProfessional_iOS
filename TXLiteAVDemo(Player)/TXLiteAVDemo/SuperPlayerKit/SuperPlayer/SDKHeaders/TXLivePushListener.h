/*
 * Module:   TXLivePushListener @ TXLiteAVSDK
 *
 * Function: 腾讯云直播推流的回调通知
 *
 * Version: <:Version:>
 */

#import <Foundation/Foundation.h>

/// @defgroup TXLivePushListener_ios TXLivePushListener
/// 腾讯云直播推流的回调通知
/// @{
@protocol TXLivePushListener <NSObject>

/**
 * 事件通知
 * @param EvtID 参见 TXLiveSDKEventDef.h
 * @param param 参见 TXLiveSDKTypeDef.h
 */
- (void)onPushEvent:(int)EvtID withParam:(NSDictionary *)param;

/**
 * 状态通知
 * @param param 参见 TXLiveSDKTypeDef.h
 */
- (void)onNetStatus:(NSDictionary *)param;


/////////////////////////////////////////////////////////////////////////////////
//
//              屏幕分享回调
//
/////////////////////////////////////////////////////////////////////////////////

/**
 * 当屏幕分享开始时，SDK 会通过此回调通知
 */
- (void)onScreenCaptureStarted;

/**
 * 当屏幕分享暂停时，SDK 会通过此回调通知
 *
 * @param reason 原因，0：用户主动暂停；1：屏幕窗口不可见暂停
 */
- (void)onScreenCapturePaused:(int)reason;

/**
 * 当屏幕分享恢复时，SDK 会通过此回调通知
 *
 * @param reason 恢复原因，0：用户主动恢复；1：屏幕窗口恢复可见从而恢复分享
 */
- (void)onScreenCaptureResumed:(int)reason;

/**
 * 当屏幕分享停止时，SDK 会通过此回调通知
 *
 * @param reason 停止原因，0：用户主动停止；1：屏幕窗口关闭导致停止
 */
- (void)onScreenCaptureStoped:(int)reason;

@end
/// @}
