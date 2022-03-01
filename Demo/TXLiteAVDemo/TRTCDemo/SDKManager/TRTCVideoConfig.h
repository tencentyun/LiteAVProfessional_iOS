/*
 * Module:   TRTCVideoConfig
 *
 * Function: 保存视频的设置项，并提供每个分辨率下对应的码率支持
 *
 *    1. 分辨率对应的码率配置在TRTCBitrateRange对象中，包括最小、最大和推荐码率，以及码率调整的步长
 */

#import <AVFoundation/AVFoundation.h>
#import <Foundation/Foundation.h>

#import "TRTCCloud.h"
#import "TRTCCloudDef.h"

NS_ASSUME_NONNULL_BEGIN

typedef enum : NSUInteger {
    TRTCVideoSourceCamera = 0,
    TRTCVideoSourceCustom,
    TRTCVideoSourceAppScreen,
    TRTCVideoSourceDeviceScreen,
    TRTCVideoSourceNone,
} TRTCVideoSource;

@class TRTCBitrateRange;

/// 视频参数
@interface TRTCVideoConfig : NSObject

- (instancetype)initWithScene:(TRTCAppScene)scene NS_DESIGNATED_INITIALIZER;

- (instancetype)init NS_UNAVAILABLE;

- (NSDictionary *)dictionaryRepresentation;

@property(nonatomic) TRTCVideoSource source;

@property(nonatomic) TRTCVideoSource subSource;

@property(nonatomic) TRTCVideoStreamType streamType;

/// 开启265硬编
@property(nonatomic) BOOL isH265Enabled;

/// 开启视频采集
@property(nonatomic) BOOL isEnabled;

/// 开启自定义辅路
@property(nonatomic) BOOL isCustomSubStreamCapture;

/// 视频静画
@property(nonatomic) BOOL isMuted;

/// 暂停屏幕采集
@property(nonatomic) BOOL isScreenCapturePaused;

/// 主视频编码
@property(strong, nonatomic) TRTCVideoEncParam *videoEncConfig;

/// 小画面视频编码
@property(strong, nonatomic) TRTCVideoEncParam *smallVideoEncConfig;

/// 辅路视频编码
@property(strong, nonatomic) TRTCVideoEncParam *subStreamVideoEncConfig;

/// 流控设置
@property(strong, nonatomic) TRTCNetworkQosParam *qosConfig;

/// 使用前置摄像头，默认值为YES
@property(nonatomic) BOOL isFrontCamera;

/// 开启闪光灯，默认值为NO
@property(nonatomic) BOOL isTorchOn;

/// 开启自动对焦，默认值为YES
@property(nonatomic) BOOL isAutoFocusOn;

/// 是否开启垫片，默认值为YES
@property(nonatomic) BOOL isVideoMuteImage;

/// 是否开启时间戳水印，默认值为NO
@property(nonatomic) BOOL isTimestampWaterMark;

/// 本地视频镜像，默认值为YES
@property(nonatomic) BOOL isLocalMirrorEnabled;

/// 远程视频镜像，默认值为YES
@property(nonatomic) BOOL isRemoteMirrorEnabled;

/// 图像增强，默认值为YES
@property(nonatomic) BOOL isSharpnessEnhancementEnabled;

/// 水印，默认值为YES
@property(nonatomic) BOOL isWaterMarkEnabled;

/// 本地渲染设置
@property(strong, nonatomic) TRTCRenderParams *localRenderParams;

/// 开启双路编码，默认值为NO
@property(nonatomic) BOOL isSmallVideoEnabled;

/// 画质偏好低清，默认值为YES
@property(nonatomic) BOOL prefersLowQuality;

/// 开启重力感应模式，默认为NO
@property(nonatomic) BOOL isGSensorEnabled;

/// 自定义视频播放的视频资源
@property(strong, nonatomic) AVAsset *videoAsset;

/// 第三方美颜回调format
+ (NSArray<NSNumber *> *)formats;
+ (NSArray<NSString *> *)formatNames;
@property(nonatomic) TRTCVideoPixelFormat format;
@property(nonatomic, readonly) NSInteger  formatIndex;

/// 画面亮度
@property(nonatomic) CGFloat brightness;
/// 本地是否有能力编解265
@property(assign, nonatomic) BOOL enableHEVCAbility;

@property(nonatomic, readonly) NSInteger subStreamResolutionIndex;

/// 采集分辨率
+ (NSArray<NSValue *> *)captureResolutions;
+ (NSArray<NSString *> *)captureResolutionNames;
@property(nonatomic) NSInteger captureResolutionIndex;

/// 支持的分辨率
+ (NSArray<NSNumber *> *)resolutions;
+ (NSArray<NSNumber *> *)streamTypes;

+ (NSArray<NSString *> *)streamTypeNames;
+ (NSArray<NSString *> *)resolutionNames;
@property(nonatomic, readonly) NSInteger resolutionIndex;

/// 支持的帧数
+ (NSArray<NSString *> *)fpsList;
@property(nonatomic, readonly) NSInteger fpsIndex;
@property(nonatomic, readonly) NSInteger subStreamFpsIndex;

/// 分辨率对应的码率区间
/// @param resolution 分辨率
+ (TRTCBitrateRange *)bitrateRangeOf:(TRTCVideoResolution)resolution scene:(TRTCAppScene)scene;

/// 本地预览镜像
+ (NSArray<NSString *> *)localMirrorTypeNames;

@property(nonatomic, readonly) NSInteger qosPreferenceIndex;

@end

/// 分辨率下对应的码率支持
@interface TRTCBitrateRange : NSObject

/// 最小支持的码率
@property(nonatomic) NSInteger minBitrate;

/// 最大支持的码率
@property(nonatomic) NSInteger maxBitrate;

/// 默认码率
@property(nonatomic) NSInteger defaultBitrate;

/// 调整码率的步长
@property(nonatomic) NSInteger step;

- (instancetype)initWithMin:(NSInteger)min max:(NSInteger)max defaultBitrate:(NSInteger)defaultBitrate step:(NSInteger)step;

@end

NS_ASSUME_NONNULL_END
