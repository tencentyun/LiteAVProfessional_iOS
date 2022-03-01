//
//  TRTCChorusManager.h
//  TXLiteAVDemo
//
//  Created by zanhanding on 2021/7/2.
//  Copyright © 2021 Tencent. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TRTCCloudDelegate.h"

//使用此数值作为背景音乐播放的 musicId，当您在外界调用 TXAudioEffectManager startPlayMusic 的时候请注意不要传入相同的 musicId
#define CHORUS_MUSIC_ID 999
//歌曲文件名，后缀名默认为 mp3
#define kChorusMusicName @"beijinghuanyingni"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, ChorusStartReason) {
    // 远端某个用户发起合唱
    ChorusStartReasonRemote = 0,
    // 本地用户发起合唱
    ChorusStartReasonLocal = 1,
};

typedef NS_ENUM(NSInteger, ChorusStopReason) {
    // 合唱音乐起播失败，被迫终止
    ChorusStopReasonMusicFailed = 0,
    // 远端某个用户请求停止合唱
    ChorusStopReasonRemote = 1,
    // 本地用户停止合唱
    ChorusStopReasonLocal = 2,
    // 合唱歌曲播放完毕，自动停止
    ChorusStopReasonMusicFinished = 3,
};

typedef NS_ENUM(NSInteger, CdnPushStatus) {
    // 与服务器断开连接
    CdnPushStatusDisconnected = 0,
    // 正在连接服务器
    CdnPushStatusConnecting = 1,
    // 连接服务器成功
    CdnPushStatusConnectSuccess = 2,
    // 重连服务器中
    CdnPushStatusReconnecting = 3,
};

typedef NS_ENUM(NSInteger, CdnPlayStatus) {
    // 播放停止
    CdnPlayStatusStopped = 0,
    // 正在播放
    CdnPlayStatusPlaying = 1,
    // 正在缓冲
    CdnPlayStatusLoading = 2,
};

@protocol TRTCChorusDelegate <NSObject>

/**
 * 合唱已开始
 * 您可以监听这个接口来处理 UI 和业务逻辑
 */
- (void)onChorusStart:(ChorusStartReason)reason message:(NSString *)msg;

/**
 * 合唱已停止
 * 您可以监听这个接口来处理 UI 和业务逻辑
 */
- (void)onChorusStop:(ChorusStopReason)reason message:(NSString *)msg;

/**
 * 合唱音乐进度回调
 * 您可以监听这个接口来处理进度条和歌词的滚动
 */
- (void)onMusicPlayProgress:(NSInteger)curPtsMS duration:(NSInteger)durationMS;

/**
 * 合唱 CDN 推流连接状态状态改变回调
 * @param status 连接状态
 * @note 此回调透传 V2TXLivePusherObserver onPushStatusUpdate 回调
 */
- (void)onCdnPushStatusUpdate:(CdnPushStatus)status;

/**
 * 合唱 CDN 播放状态改变回调
 * @param status 播放状态
 * @note 此回调透传 V2TXLivePlayerObserver onAudioPlayStatusUpdate 回调
 */
- (void)onCdnPlayStatusUpdate:(CdnPlayStatus)status;

@end

@interface TRTCChorusManager : NSObject <TRTCCloudDelegate>
@property (nonatomic, readonly) BOOL isChorusOn;///是否在合唱中
@property (nonatomic, weak) id<TRTCChorusDelegate> delegate;
@property (nonatomic, readonly) BOOL isCdnPushing;///是否推流中
@property (nonatomic, readonly) BOOL isCdnPlaying;///是否拉流中

/**
 * 开始合唱
 * 调用后，会收到 onChorusStart 回调，并且房间内的远端用户也会开始合唱
 * @note 中途加入的用户也会一并开始合唱，音乐进度会与其它用户自动对齐
 */
- (BOOL)startChorus;

/**
 * 停止合唱
 * 调用后，会收到 onChorusStop 回调，并且房间内的远端用户也会停止合唱
 */
- (void)stopChorus;

/**
 * 开始合唱 CDN 推流
 *
 * @param url 推流地址
 * @return YES：推流成功；NO：推流失败
 */
- (BOOL)startCdnPush:(NSString *)url;

/**
 * 停止合唱 CDN 推流
 */
- (void)stopCdnPush;

/**
 * 开始合唱 CDN 播放
 *
 * @param url  拉流地址
 * @param view 承载视频的 view
 * @return YES：拉流成功；NO：拉流失败
 */
- (BOOL)startCdnPlay:(NSString *)url view:(TXView *)view;

/**
 * 停止合唱 CDN 播放
 */
- (void)stopCdnPlay;

@end

NS_ASSUME_NONNULL_END
