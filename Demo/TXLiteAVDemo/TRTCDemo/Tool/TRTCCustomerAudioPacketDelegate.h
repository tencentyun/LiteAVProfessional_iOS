//
//  TRTCCustomerAudioPacketDelegate.h
//  TXLiteAVDemo
//
//  Created by guanyifeng on 2021/7/12.
//  Copyright © 2021 Tencent. All rights reserved.
//

#ifndef TRTCCustomerAudioPacketDelegate_h
#define TRTCCustomerAudioPacketDelegate_h

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
/**
 * DEMO使用，用于测试网络层回调
 */
@protocol RecvAudioMsgDelegate
- (void)onRecvAudioMsg:(NSString *)userId msg:(NSString *)msg;
@end

@interface TRTCCustomerAudioPacketDeleagate: NSObject

@property (atomic, nullable) NSData *bindToAudioPkgMsg;
@property(nonatomic, weak)id<RecvAudioMsgDelegate> delegate;

+ (instancetype)new  __attribute__((unavailable("Use +sharedInstance instead")));
- (instancetype)init __attribute__((unavailable("Use +sharedInstance instead")));

+ (instancetype)sharedInstance;

- (void *)getAudioPacketDelegate;
- (void)bindMsgToAudioPkg:(NSString *)message;

@end

NS_ASSUME_NONNULL_END

#endif /* TRTCCustomerAudioPacketDelegate_h */
