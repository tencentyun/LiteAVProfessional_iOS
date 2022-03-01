//
//  TXVodPlayConfig.h
//  TXLiteAVSDK
//
//  Created by annidyfeng on 2017/9/12.
//  Copyright © 2017年 Tencent. All rights reserved.
//

#ifndef TXVodPlayConfig_h
#define TXVodPlayConfig_h

#import <Foundation/Foundation.h>

/// @defgroup TXVodPlayConfig_ios TXVodPlayConfig
/// 点播播放器关键类型定义
/// @{

/// 播放器选择
typedef NS_ENUM(NSInteger, TX_Enum_PlayerType) {
    PLAYER_FFPLAY   = 0,          //基于FFmepg，支持软解，兼容性更好
    PLAYER_AVPLAYER = 1,          //基于系统播放器
};

/// 播放器配置参数
@interface TXVodPlayConfig : NSObject

/// 播放器连接重试次数：最小值为1，最大值为10，默认值为 3
@property(nonatomic, assign) int connectRetryCount;

/// 播放器连接重试间隔：单位秒，最小值为3, 最大值为30，默认值为3
@property(nonatomic, assign) int connectRetryInterval;

/// 超时时间：单位秒，默认10s
@property NSTimeInterval timeout;

/// 视频渲染对象回调的视频格式。支持kCVPixelFormatType_32BGRA、kCVPixelFormatType_420YpCbCr8BiPlanarFullRange、kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange
@property(nonatomic, assign) OSType playerPixelFormatType;

/// stopPlay 的时候是否保留最后一帧画面，默认值为 NO
@property(nonatomic, assign) BOOL keepLastFrameWhenStop;

/**
 * 注意：缓存目录应该是单独的目录，SDK可能会清掉其中的文件
 */
@property NSString *cacheFolderPath;        ///< 视频缓存目录，点播MP4、HLS有效

@property int maxCacheItems;                ///< 最多缓存文件个数

@property NSInteger playerType;             ///< 播放器类型

@property NSDictionary *headers;            ///< 自定义 HTTP Headers

@property BOOL enableAccurateSeek;          ///< 是否精确 seek，默认YES。开启精确后seek，seek 的时间平均多出200ms

@property BOOL autoRotate;                  ///< 播放 MP4 文件时，若设为YES则根据文件中的旋转角度自动旋转。旋转角度可在 EVT_VIDEO_CHANGE_ROTATION 事件中获得。默认YES

/**
 * 平滑切换码率。默认NO
 *  设为NO时，切换清晰度会有少许停顿，但文件打开速度会加快。设为YES，当IDR对齐时，平滑切换清晰度。
 */
@property BOOL smoothSwitchBitrate;

/**
 * 设置进度回调间隔时间
 *  若不设置，SDK默认间隔0.5秒回调一次
 */
@property NSTimeInterval progressInterval;

/**
 * 最大预加载大小，单位 MB
 *  此设置会影响playableDuration，设置越大，提前缓存的越多
 */
@property int maxBufferSize;
@end

/// @}
#endif /* TXVodPlayConfig_h */
