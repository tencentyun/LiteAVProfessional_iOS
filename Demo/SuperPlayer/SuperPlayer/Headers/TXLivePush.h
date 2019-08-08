//
//  TXLivePush.h
//  LiteAV
//
//  Created by alderzhang on 2017/5/24.
//  Copyright © 2017年 Tencent. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <VideoToolbox/VideoToolbox.h>
#if TARGET_OS_IPHONE
#import <ReplayKit/ReplayKit.h>
#endif
#import "TXLivePushConfig.h"
#import "TXLivePushListener.h"
#import "TXVideoCustomProcessDelegate.h"
#import "TXAudioCustomProcessDelegate.h"
#import "TXLiveRecordListener.h"
#import "TXLiveSDKTypeDef.h"
#import <AVFoundation/AVFoundation.h>

///推流器
@interface TXLivePush : NSObject
///推流参数配置
///@see TXLivePushConfig
@property(nonatomic, copy) TXLivePushConfig *config;

///推流回调
///@see TXLivePushListener;
@property(nonatomic, weak) id <TXLivePushListener> delegate;

///视频自定义处理回调
///@see TXVideoCustomProcessDelegate
@property(nonatomic, weak) id <TXVideoCustomProcessDelegate> videoProcessDelegate;

///音频自定义处理回调
///@see TXAudioCustomProcessDelegate
@property(nonatomic, weak) id <TXAudioCustomProcessDelegate> audioProcessDelegate;

///推流端录制回调
///@see TXLiveRecordListener
@property (nonatomic, weak) id<TXLiveRecordListener>   recordDelegate;

///当前推流URL
@property(nonatomic, readonly) NSString *rtmpURL;

///当前是否为前置摄像头
@property(nonatomic, readonly) BOOL frontCamera;

/**
 初始化推流器
 @param config 推流参数配置
 */
- (id)initWithConfig:(TXLivePushConfig *)config;

/**
 启动到指定URL地址推流
 @param rtmpURL 推流地址
 @return 0:启动成功   -1:出错
 */
- (int)startPush:(NSString *)rtmpURL;

/**
停止推流
 */
- (void)stopPush;


/**
 后台推送默认数据，在切后台或打断场合需要调用
 当从前台切到后台的时候，调用pausePush会推配置里设置的图片(TXLivePushConfig.pauseImg)
 
 pauseImg  设置后台推流的默认图片，不设置为默认黑色背景
 pauseFps  设置后台推流帧率，最小值为5，最大值为20，默认10
 pauseTime 设置后台推流持续时长，单位秒，默认300秒
 具体使用方式请参考demo里面的示例
 @note 暂停推流，后台视频发送TXLivePushConfig里面设置的图像，音频会继续录制声音发送, 如果不需要录制声音，需要再调下setMute接口
 */
- (void)pausePush;

///恢复推流, 当从后台回到前台的时候，调用resumePush恢复推送camera采集的数据
- (void)resumePush;


/**
 是否正常推流
 @return YES: 推流中，NO: 没有推流
 */
- (bool)isPublishing;

/**
 *视频录制
 *开始录制短视频，开始推流后才能启动录制
 @note 1,录制过程中请勿动态切换分辨率和软硬编，可能导致生成的视频异常
       2,目前仅支持 企业版 和 Professional SDK版本，其他版本调用无效
 @param videoPath 视频录制后存储路径
 @return
 返回值 | 涵义
 ------|------
  0    | 成功
 -1    | videoPath 为nil
 -2    | 上次录制未结束，请先stopRecord
 -3    | 推流未开始

 */
-(int) startRecord:(NSString *)videoPath;

/**
 结束录制短视频，停止推流后，如果视频还在录制中，SDK内部会自动结束录制
 @return 0: 成功 -1:不存在录制任务；
 */
-(int) stopRecord;

/**
 开始推流画面的预览
 @param view 预览控件所在的父控件
 @return 0 (异步处理，返回总是0)
 */
- (int)startPreview:(TXView *)view;

/**
 停止预览
 */
- (void)stopPreview;

/**
 切换前后摄像头
 */
- (int)switchCamera;

#if TARGET_OS_MAC && !TARGET_OS_IPHONE
- (void)selectCamera:(AVCaptureDevice *)camera;
#endif

/** 设置镜像
 @param isMirror YES：播放端看到的是镜像画面   NO：播放端看到的是非镜像画面
 @note 推流端前置摄像头默认看到的是镜像画面，后置摄像头默认看到的是非镜像画面
 */
- (void)setMirror:(BOOL)isMirror;


/**
 设置美颜 和 美白 效果级别
 @param beautyStyle TX_Enum_Type_BeautyStyle
 @param beautyLevel     : 美颜级别取值范围 0 ~ 9； 0 表示关闭 1 ~ 9值越大 效果越明显。
 @param whitenessLevel  : 美白级别取值范围 0 ~ 9； 0 表示关闭 1 ~ 9值越大 效果越明显。
 @param ruddinessLevel  : 红润级别取值范围 0 ~ 9； 0 表示关闭 1 ~ 9值越大 效果越明显。
 @see TX_Enum_Type_BeautyStyle
*/
- (void)setBeautyStyle:(TX_Enum_Type_BeautyStyle)beautyStyle beautyLevel:(float)beautyLevel whitenessLevel:(float)whitenessLevel ruddinessLevel:(float)ruddinessLevel;

/**
 设置大眼级别（企业版有效，其它版本设置此参数无效）
 @param eyeScaleLevel 大眼级别取值范围 0 ~ 9； 0 表示关闭 1 ~ 9值越大 效果越明显。
 */
- (void)setEyeScaleLevel:(float)eyeScaleLevel;

/**设置瘦脸级别（企业版有效，其它版本设置此参数无效）
 @param faceScaleLevel 瘦脸级别取值范围 0 ~ 9； 0 表示关闭 1 ~ 9值越大 效果越明显。
 */
- (void)setFaceScaleLevel:(float)faceScaleLevel;

/**
 设置指定素材滤镜特效
 @param image 指定素材，即颜色查找表图片。
 @note 一定要用png格式！！！demo用到的滤镜查找表图片位于TXLiteAVDemo/Resource/Beauty/filter/FilterResource.bundle中
 */
- (void)setFilter:(TXImage *)image;

/**
 设置滤镜效果程度
 @param specialValue 从0到1，越大滤镜效果越明显，默认取值0.5
 */
- (void)setSpecialRatio:(float)specialValue;


/**
 设置V脸（企业版有效，其它版本设置此参数无效）
 @param faceVLevel V脸级别取值范围 0 ~ 9； 0 表示关闭 1 ~ 9值越大 效果越明显。
 */
- (void)setFaceVLevel:(float)faceVLevel;

/**
 设置下巴拉伸或收缩（企业版有效，其它版本设置此参数无效）
 @param chinLevel 下巴拉伸或收缩级别取值范围 -9 ~ 9； 0 表示关闭 -9收缩 ~ 9拉伸。
 */
- (void)setChinLevel:(float)chinLevel;

/**
 设置短脸（企业版有效，其它版本设置此参数无效）
 @param faceShortlevel 短脸级别取值范围 0 ~ 9； 0 表示关闭 1 ~ 9值越大 效果越明显。
 */
- (void)setFaceShortLevel:(float)faceShortlevel;

/**
 设置瘦鼻（企业版有效，其它版本设置此参数无效）
 @param noseSlimLevel 瘦鼻级别取值范围 0 ~ 9； 0 表示关闭 1 ~ 9值越大 效果越明显。
 */
- (void)setNoseSlimLevel:(float)noseSlimLevel;



/**
 打开闪关灯。
 @param bEnable YES: 打开 NO: 关闭
 @return YES: 打开成功 NO: 打开失败
 */
- (BOOL)toggleTorch:(BOOL)bEnable;

/**
 设置本地视频方向
 @param rotation  取值为 0 , 90, 180, 270（其他值无效） 表示推流端本地视频向右旋转的角度
 @note 横竖屏推流,activty旋转可能会改变本地视频流方向，可以设置此参数让本地视频回到正方向，具体请参考demo设置，如果demo里面的设置满足不了您的业务需求，请自行setRenderRotation到自己想要的方向（tips：推流端setRenderRotation不会改变观众端的视频方向）
 */
- (void)setRenderRotation:(int)rotation;


/**
 设置静音
 @param bEnable YES: 静音 NO:关闭静音
 */
- (void)setMute:(BOOL)bEnable;

/**
 发送客户自定义的音频PCM数据
 @param data 要发送的PCM数据
 @param len 数据长度
 @note 目前SDK只支持16位采样的PCM编码；如果是单声道，请保证传入的PCM长度为2048；如果是双声道，请保证传入的PCM长度为4096
 */
- (void)sendCustomPCMData:(unsigned char *)data len:(unsigned int)len;

/**
  发送自定义的SampleBuffer,内部有简单的帧率控制,发太快会自动丢帧;超时则会重发最后一帧
  @param sampleBuffer 要发送的视频sampleBuffer
  @note autoSampleBufferSize优先级高于sampleBufferSize @see TXLivePushConfig
  @property sampleBufferSize，设置输出分辨率，如果此分辨率不等于sampleBuffer中数据分辨率则会对视频数据做缩放
  @property autoSampleBufferSize，输出分辨率等于输入分辨率，即sampleBuffer中数据的实际分辨率
 */
- (void)sendVideoSampleBuffer:(CMSampleBufferRef)sampleBuffer;

#if TARGET_OS_IPHONE
/**
 Replaykit发送自定义音频包
 @prama sampleBuffer 声音sampleBuffer
 @prama sampleBufferType  RPSampleBufferTypeAudioApp or RPSampleBufferTypeAudioMic,
 @note 当两种声音都发送时，内部做混音；否则只发送一路声音
 */
- (void)sendAudioSampleBuffer:(CMSampleBufferRef)sampleBuffer withType:(RPSampleBufferType)sampleBufferType;
#endif

/**
 Replaykit发送静音包，在InApp类型录制切后台场合时需要调用。系统屏幕录制不需要
 @param muted YES: 静音 NO:关闭静音
 */
- (void)setSendAudioSampleBufferMuted:(BOOL)muted;

/**
 调用手动对焦功能
 @param touchPoint 为传入的对焦点位置
 @note 早期SDK版本手动对焦功能是由SDK内部触发，现在把手动对焦的接口开放出来，客户可以根据自己需求触发 ,如果客户调用这个接口，SDK内部触发对焦的逻辑将会停止，避免重复触发对焦逻辑
 */
- (void)setFocusPosition:(CGPoint)touchPoint;

/**
调整焦距
@param distance 焦距大小, 取值范围 1~5
@note 当为1的时候为最远视角（正常镜头），当为5的时候为最近视角（放大镜头），这里最大值推荐为5，超过5后视频数据会变得模糊不清
*/
- (void)setZoom:(CGFloat)distance;

/**
 播放背景音乐, 用于混音处理，背景音与Mic采集到的人声混合
 @param path 本地音乐文件路径
 @return YES:成功 NO:失败
 */
- (BOOL)playBGM:(NSString *)path;

/**
 播放背景音乐
 @param path 本地音乐文件路径
 @param beginNotify 音乐播放开始的回调通知
 @param progressNotify 音乐播放的进度通知，单位毫秒
 @param completeNotify 音乐播放结束的回调通知
 @return YES:成功 NO:失败

 */
- (BOOL)   playBGM:(NSString *)path
   withBeginNotify:(void (^)(NSInteger errCode))beginNotify
withProgressNotify:(void (^)(NSInteger progressMS, NSInteger durationMS))progressNotify
 andCompleteNotify:(void (^)(NSInteger errCode))completeNotify;

/**
 停止播放背景音乐
 @return YES:成功 NO:失败
 */
- (BOOL)stopBGM;

/**
 暂停播放背景音乐
 @return YES:成功 NO:失败
 */
- (BOOL)pauseBGM;

/**
 继续播放背景音乐
 @return YES:成功 NO:失败
 */
- (BOOL)resumeBGM;

/**
 获取音乐文件总时长，单位毫秒
 @param path 音乐文件路径，如果path为空，那么返回当前正在播放的music时长
 */
- (int)getMusicDuration:(NSString *)path;

/**
 设置麦克风的音量大小，播放背景音乐混音时使用，用来控制麦克风音量大小
 @param volume 音量大小，1为正常音量，建议值为0~2，如果需要调大音量可以设置更大的值
 @return YES:成功 NO:失败
 */
- (BOOL)setMicVolume:(float)volume;

/**
 设置背景音乐的音量大小，播放背景音乐混音时使用，用来控制背景音音量大小
 @param volume 音量大小，1为正常音量，建议值为0~2，如果需要调大背景音量可以设置更大的值
 @return YES:成功 NO:失败
 */
- (BOOL)setBGMVolume:(float)volume;

/**
 设置背景音的变声类型
 @param pitch 音调, 默认值是0.f;范围是 [-1,1];
 @return YES:成功 NO:失败
 */
- (BOOL)setBgmPitch:(float)pitch;

/**
设置视频质量
@param quality            画质类型(标清，高清，超高清)
@param adjustBitrate      动态码率开关
@param adjustResolution   动态切分辨率开关
 */
- (void)setVideoQuality:(TX_Enum_Type_VideoQuality)quality
          adjustBitrate:(BOOL) adjustBitrate
       adjustResolution:(BOOL) adjustResolution;

/**
 设置混响效果
 @param reverbType ：混响类型 ，详见 TXReverbType
 @return YES:成功 NO:失败
 @see TXReverbType
 */
- (BOOL)setReverbType:(TXReverbType)reverbType;

/**
 设置变声类型
 @param voiceChangerType 变声类型, 详见 TXVoiceChangerType
 @return YES:成功 NO:失败
 @see TXVoiceChangerType
 */
- (BOOL)setVoiceChangerType:(TXVoiceChangerType)voiceChangerType;

/**
 设置绿幕文件。仅企业版有效
 @param file 绿幕文件路径。支持mp4; nil 关闭绿幕
 */
- (void)setGreenScreenFile:(NSURL *)file;

/**
 选择动效。仅企业版有效
 @param tmplName 动效名称
 @param tmplDir 动效所在目录
 */
- (void)selectMotionTmpl:(NSString *)tmplName inDir:(NSString *)tmplDir;

/**
 设置动效静音 （企业版有效，其它版本设置此参数无效）
 @param motionMute YES 静音, NO 不静音
 */
- (void)setMotionMute:(BOOL)motionMute;

/**
 设置状态浮层view在渲染view上的边距
 @param margin logView在渲染view上的边距
 */
- (void)setLogViewMargin:(TXEdgeInsets)margin;

/**
 是否显示播放状态统计及事件消息浮层view
 @param isShow YES:显示 NO:隐藏
 */
- (void)showVideoDebugLog:(BOOL)isShow;

/**
 推流截图
 @params snapshotCompletionBlock 截图完成回调
 */
- (void)snapshot:(void (^)(TXImage *))snapshotCompletionBlock;

/**
 发送消息，播放端通过 onPlayEvent(EVT_PLAY_GET_MESSAGE)接收
 @param data 要发送的消息数据
 @note 1. 若您使用过该接口，切换到sendMessageEx接口时会有兼容性问题： sendMessageEx发送消息给旧版本的SDK(5.0及5.0以下)时，消息会无法正确解析，但播放不受影响。
 @note 2. 若您未使用过该接口，请直接使用sendMessageEx
 */
- (void)sendMessage:(NSData *) data;

/**
 发送消息,播放端通过 onPlayEvent(EVT_PLAY_GET_MESSAGE)接收
 @param data 要发送的消息数据
 @note 1. 消息大小不允许超过2K
 @note 2. 该接口发送消息，能够解决旧的sendMessage接口会导致在iOS上无法播放对应的HLS流的问题
 */
- (BOOL)sendMessageEx:(NSData *) data;
@end
