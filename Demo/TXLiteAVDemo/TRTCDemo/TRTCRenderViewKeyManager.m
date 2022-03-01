/*
 * Module:   TRTCRenderViewKeyManager
 *
 * Function:  由于现今 TRTC 已支持字符串房间号、子房间、主流、辅流、大流、小流，同一 userId 可能会对应多个视频流
   因此将 TRTCRenderViewKey 用于区分渲染窗口的对象，供 Demo 层使用，
 *            请确保使用getHash返回的字符窜作为字典的键
 */

#import "TRTCRenderViewKeyManager.h"

@implementation TRTCRenderViewKey
- (instancetype)initWithUid:(NSString *)userId roomId:(NSInteger)roomId strRoomId:(nullable NSString *)strRoomId mainRoom:(BOOL)isMainRoom mainStream:(BOOL)isMainStream {
    self = [super init];
    if (self) {
        _userId       = userId;
        _roomId       = roomId;
        _strRoomId    = strRoomId;
        _isMainRoom   = isMainRoom;
        _isMainStream = isMainStream;
    }
    return self;
}

- (NSString *)getString {
    return [NSString stringWithFormat:@"%d-%d-%@-%ld-%@", (int)self.isMainRoom, (int)self.isMainStream, self.userId, self.roomId, self.strRoomId];
}

- (NSString *)getHash {
    return [@([self hash]) stringValue];
}

@end

@interface                                                                        TRTCRenderViewKeymanager ()
@property(atomic, readonly) NSMutableDictionary<NSString *, TRTCRenderViewKey *> *renderViewKeys;
@end

@implementation TRTCRenderViewKeymanager

- (TRTCRenderViewKey *)getRenderViewKeyWithUid:(NSString *)userId roomId:(NSInteger)roomId strRoomId:(nullable NSString *)strRoomId mainRoom:(BOOL)isMainRoom mainStream:(BOOL)isMainStream {
    if (!_renderViewKeys) {
        _renderViewKeys = [[NSMutableDictionary alloc] initWithCapacity:6];
    }
    for (TRTCRenderViewKey *key in [_renderViewKeys allValues]) {
        if (([key.userId isEqualToString:userId]) && (roomId == 0 || key.roomId == roomId) && (strRoomId.length == 0 || [key.strRoomId isEqualToString:strRoomId]) && (isMainRoom == key.isMainRoom) &&
            (isMainStream == key.isMainStream)) {
            //如果已经有等价的key则直接返回
            return key;
        }
    }
    TRTCRenderViewKey *key = [[TRTCRenderViewKey alloc] initWithUid:userId roomId:roomId strRoomId:strRoomId mainRoom:isMainRoom mainStream:isMainStream];
    [_renderViewKeys setObject:key forKey:[key getHash]];
    return key;
}

- (TRTCRenderViewKey *)getRenderViewKeyFromHash:(NSString *)string {
    return [_renderViewKeys objectForKey:string];
}

//返回被删除的列表
- (nullable NSArray<NSString *> *)unRegisterViewKey:(NSString *)userId roomId:(NSInteger)roomId strRoomId:(nullable NSString *)strRoomId {
    if (!_renderViewKeys) return nil;
    NSArray<TRTCRenderViewKey *> *keys            = [self remoteRenderKeysFromUserId:userId roomId:roomId strRoomId:strRoomId];
    NSMutableArray<NSString *> *  keysToBeDeleted = [[NSMutableArray alloc] initWithCapacity:2];

    for (TRTCRenderViewKey *key in keys) {
        //找到该用户的所有渲染key
        [keysToBeDeleted addObject:[key getHash]];
    }
    //删除
    if ([keysToBeDeleted count] > 0) {
        [_renderViewKeys removeObjectsForKeys:keysToBeDeleted];
    }
    return keysToBeDeleted;
}

- (nullable NSArray<TRTCRenderViewKey *> *)allRemoteRenderKeys {
    if (!_renderViewKeys) return nil;
    return [_renderViewKeys allValues];
}

- (nullable NSArray<TRTCRenderViewKey *> *)remoteRenderKeysFromUserId:(NSString *)userId roomId:(NSInteger)roomId strRoomId:(NSString *)strRoomId {
    if (!_renderViewKeys) return nil;
    NSMutableArray<TRTCRenderViewKey *> *result = [[NSMutableArray alloc] initWithCapacity:2];

    for (TRTCRenderViewKey *key in [_renderViewKeys allValues]) {
        //找到该用户的所有渲染key
        if (([key.userId isEqualToString:userId]) && (roomId == 0 || key.roomId == roomId) && (strRoomId.length == 0 || [key.strRoomId isEqualToString:strRoomId])) {
            [result addObject:key];
        }
    }

    return result;
}

@end
