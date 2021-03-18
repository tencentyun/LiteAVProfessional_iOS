#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "V2TXLivePusher.h"

NS_ASSUME_NONNULL_BEGIN
typedef NS_ENUM(NSInteger, TRTCVideoQosPreference)
{
    TRTCVideoQosPreferenceSmooth = 1,      ///< 弱网下保流畅
    TRTCVideoQosPreferenceClear  = 2,      ///< 弱网下保清晰，默认值
};

typedef NS_ENUM(NSInteger, TRTCSystemVolumeType) {
    TRTCSystemVolumeTypeAuto             = 0,    
    TRTCSystemVolumeTypeMedia            = 1,
    TRTCSystemVolumeTypeVOIP             = 2,
};
typedef NS_ENUM(NSInteger, TRTCAudioRoute) {
    TRTCAudioModeSpeakerphone  =   0,   ///< 扬声器
    TRTCAudioModeEarpiece      =   1,   ///< 听筒
};

/// 分辨率下对应的码率支持
@interface V2BitrateRange : NSObject

/// 最小支持的码率
@property (nonatomic) NSInteger minBitrate;

/// 最大支持的码率
@property (nonatomic) NSInteger maxBitrate;

/// 默认码率
@property (nonatomic) NSInteger defaultBitrate;

/// 调整码率的步长
@property (nonatomic) NSInteger step;

- (instancetype)initWithMin:(NSInteger)min max:(NSInteger)max defaultBitrate:(NSInteger)defaultBitrate step:(NSInteger)step;

@end


@interface V2PusherSettingModel : NSObject
@property (nonatomic, strong) V2TXLivePusher *pusher;

- (instancetype)initWithPusher:(V2TXLivePusher *)pusher NS_DESIGNATED_INITIALIZER;

- (instancetype)init NS_UNAVAILABLE;

#pragma mark - Video Functions

/// 设置视频采集
@property (nonatomic, assign) BOOL videoEnabled;

/// 设置视频推送
@property (nonatomic, assign) BOOL isVideoMuted;

/// 设置分辨率
@property (nonatomic, assign) V2TXLiveVideoResolution videoResolution;

/// 设置画面方向
@property (nonatomic, assign) V2TXLiveVideoResolutionMode resolutionMode;

/// 设置本地镜像
@property (nonatomic, assign) V2TXLiveMirrorType localMirrorType;

/// 设置远程镜像
@property (nonatomic, assign) BOOL isRemoteMirrorEnabled;

/// 设置视频水印
/// @param image 水印图片，必须使用透明底的png格式图片
/// @param rect 水印位置，x, y, width, height取值范围都是0 - 1
/// @note 如果当前分辨率为540 x 960, 设置rect为(0.1, 0.1, 0.2, 0)，
///       那水印图片的出现位置在(540 * 0.1, 960 * 0.1) = (54, 96),
///       宽度为540 * 0.2 = 108, 高度自动计算
- (void)setWaterMark:(UIImage * _Nullable)image inRect:(CGRect)rect;

- (void)snapshot;

+ (NSArray<NSNumber *> *)resolutions;
+ (NSArray<NSString *> *)resolutionNames;
+ (V2BitrateRange *)bitrateRangeOf:(V2TXLiveVideoResolution)resolution;

+ (NSArray<NSString *> *)fpsList;

#pragma mark - Audio Functions

/// 是否开启麦克风
@property (nonatomic, assign) BOOL startMicphone;

/// 是否静音
@property (nonatomic, assign) BOOL isAudioMuted;

/// 采集音量
@property (nonatomic, assign) NSInteger captureVolume;

/// 设置音量类型
@property (nonatomic, assign) TRTCSystemVolumeType volumeType;

/// 设置耳返
@property (nonatomic, assign) BOOL isEarMonitoringEnabled;

/// 开启音量提示，默认NO
@property (nonatomic, assign) BOOL isEnableVolumeEvaluation;

#pragma mark -

- (void)saveConfig;

- (void)applyConfig;

@end

NS_ASSUME_NONNULL_END
