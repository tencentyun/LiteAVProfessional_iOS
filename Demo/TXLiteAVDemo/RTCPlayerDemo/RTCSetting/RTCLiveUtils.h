//
//  RTCLiveUtils.h
//  TXLiteAVDemo
//
//  Created by adams on 2021/7/22.
//  Copyright © 2021 Tencent. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface RTCLiveUtils : NSObject
+ (BOOL)isRTMPUrl:(NSString *)url;
+ (BOOL)isWebrtcUrl:(NSString *)url;
+ (BOOL)isTRTCUrl:(NSString *)url;
+ (NSMutableDictionary *)parseURLParametersAndLowercaseKey:(NSString *)url;
+ (NSMutableDictionary *)parseURLParameters:(NSString *)url;
@end

NS_ASSUME_NONNULL_END
