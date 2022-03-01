//
//  TRTCCustomAudioPacketDelegate.m
//  TXLiteAVDemo
//
//  Created by guanyifeng on 2021/7/12.
//  Copyright © 2021 Tencent. All rights reserved.
//

#import "TRTCCustomerAudioPacketDelegate.h"
#include "ITRTCAudioPacketListener.h"

/**
 * DEMO使用，用于测试网络层回调
 */
static TRTCCustomerAudioPacketDeleagate *s_Delegate = nil;

class TRTCCustomerAudioPkgListener : public liteav::ITRTCAudioPacketListener {
public:
    /*网络层接收到音频数据包*/
    bool onRecvAudioPacket(liteav::TRTCAudioPacket &data) {
        auto extraBuff = data.extraData;
        if (extraBuff) {
            NSString *userId = [NSString stringWithUTF8String:(char *)data.userId];
            NSString *msg = [NSString stringWithUTF8String:(char *)extraBuff->cdata()];
            if (s_Delegate.delegate) {
                [s_Delegate.delegate onRecvAudioMsg:userId msg:msg];
            }
        }
        return true;
    }
    /*网络层即将发送的音频数据包*/
    bool onSendAudioPacket(liteav::TRTCAudioPacket &data) {
        auto extraBuffer = data.extraData;
        NSData* msg = [s_Delegate.bindToAudioPkgMsg mutableCopy];
        s_Delegate.bindToAudioPkgMsg = nil;
        if (extraBuffer) {
            size_t len = [msg length];
            if (len != 0) {
                extraBuffer->SetSize(len);
                memcpy(extraBuffer->data(), [msg bytes], len);
            }
        }
        return true;
    }
};


@interface TRTCCustomerAudioPacketDeleagate()
{
    TRTCCustomerAudioPkgListener _listener;
}
@end

@implementation TRTCCustomerAudioPacketDeleagate

+ (instancetype)sharedInstance {
    static dispatch_once_t predicate;
    dispatch_once(&predicate, ^{
        s_Delegate = [[TRTCCustomerAudioPacketDeleagate alloc] initPrivate];
    });
    return s_Delegate;
}

- (instancetype)initPrivate {
    self = [super init];
    if (nil != self) {
    }
    return self;
}


- (void *)getAudioPacketDelegate {
    return &_listener;
}

- (void)bindMsgToAudioPkg:(NSString *)message {
    NSData * _Nullable data = [message dataUsingEncoding:NSUTF8StringEncoding];
    if (data != nil) {
        self.bindToAudioPkgMsg = data;
    }
}

@end
