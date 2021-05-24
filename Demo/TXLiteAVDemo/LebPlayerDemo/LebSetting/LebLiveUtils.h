//
//  LebLiveUtils.h
//  TXLiteAVDemo
//
//  Created by coddyliu on 2020/12/10.
//  Copyright © 2020 Tencent. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface LebLiveUtils : NSObject
+ (BOOL)isRTMPUrl:(NSString *)url;
+ (BOOL)isWebrtcUrl:(NSString *)url;
+ (BOOL)isTRTCUrl:(NSString *)url;
+ (NSMutableDictionary *)parseURLParametersAndLowercaseKey:(NSString *)url;
+ (NSMutableDictionary *)parseURLParameters:(NSString *)url;
@end

NS_ASSUME_NONNULL_END
