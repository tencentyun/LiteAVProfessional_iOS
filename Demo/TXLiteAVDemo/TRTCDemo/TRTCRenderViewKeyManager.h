/*
 * Module:   TRTCRenderViewKeyManager
 *
 * Function:  由于现今 TRTC 已支持字符串房间号、子房间、主流、辅流、大流、小流，同一 userId 可能会对应多个视频流
              因此将 TRTCRenderViewKey 用于区分渲染窗口的对象，供 Demo 层使用，
 *            请确保使用getHash返回的字符窜作为字典的键
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface                               TRTCRenderViewKey : NSObject
@property(nonatomic, readonly) BOOL      isMainRoom;
@property(nonatomic, readonly) BOOL      isMainStream;
@property(nonatomic, readonly) NSString *userId;
@property(nonatomic, readonly) NSInteger roomId;
@property(nonatomic, readonly) NSString *strRoomId;
- (instancetype)init NS_UNAVAILABLE;
- (NSString *)getHash;
@end

@interface TRTCRenderViewKeymanager : NSObject
//传入参数，获取 TRTCRenderViewKey，如果参数对应的 TRTCRenderViewKey 已存在，则直接返回该实例
- (TRTCRenderViewKey *)getRenderViewKeyWithUid:(NSString *)userId roomId:(NSInteger)roomId strRoomId:(nullable NSString *)strRoomId mainRoom:(BOOL)isMainRoom mainStream:(BOOL)isMainStream;
//通过 hash 码来寻找 TRTCRenderViewKey，找不到则返回 nil
- (nullable TRTCRenderViewKey *)getRenderViewKeyFromHash:(NSString *)string;
//用户退房后，调用此方法来移除该用户的全部 TRTCRenderViewKey，返回移除的 hash 码列表
- (nullable NSArray<NSString *> *)unRegisterViewKey:(NSString *)userId roomId:(NSInteger)roomId strRoomId:(nullable NSString *)strRoomId;
//获取全部的 TRTCRenderViewKey
- (nullable NSArray<TRTCRenderViewKey *> *)allRemoteRenderKeys;
//获取某用户名下的 TRTCRenderViewKey
- (nullable NSArray<TRTCRenderViewKey *> *)remoteRenderKeysFromUserId:(NSString *)userId roomId:(NSInteger)roomId strRoomId:(NSString *)strRoomId;
@end

NS_ASSUME_NONNULL_END
