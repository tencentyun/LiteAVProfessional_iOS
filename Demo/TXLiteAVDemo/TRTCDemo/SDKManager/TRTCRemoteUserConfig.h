/*
* Module:   TRTCRemoteUserConfig
*
* Function: 保存对远端用户的设置项
*
*    1. 对象无需保存到本地
*
*/

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class TRTCRenderParams;

@interface TRTCRemoteUserConfig : NSObject

//- (instancetype)initWithRoomId:(NSString *)roomId NS_DESIGNATED_INITIALIZER;

//- (instancetype)init NS_UNAVAILABLE;

/// 房间ID
//@property (copy, nonatomic) NSString *roomId;

/// 远端视频开启，默认值为YES
@property (nonatomic) BOOL isSubStream;

/// 远端视频开启，默认值为YES
@property (nonatomic) BOOL isVideoEnabled;

/// 远端音频开启，默认值为YES
@property (nonatomic) BOOL isAudioEnabled;

/// 静音远端视频，默认值为NO
@property (nonatomic) BOOL isVideoMuted;

/// 静音远端音频，默认值为NO
@property (nonatomic) BOOL isAudioMuted;

/// 远端渲染设置
@property (strong, nonatomic) TRTCRenderParams *renderParams;

/// 远端音量，默认值为100
@property (nonatomic) NSInteger volume;

@end

NS_ASSUME_NONNULL_END
