//
//  V2LiveUtils.m
//  TXLiteAVDemo
//
//  Created by coddyliu on 2020/12/10.
//  Copyright © 2020 Tencent. All rights reserved.
//

#import "V2LiveUtils.h"
#define DefaultUserId @"27eb683b73944771ce62fbddab2849a4"

@implementation V2LiveUtils

+ (NSMutableDictionary *)parseURLParametersAndLowercaseKey:(NSString *)url {
    NSMutableDictionary *params  = [self parseURLParameters:url];
    NSArray *            allKeys = params.allKeys;
    for (NSString *key in allKeys) {
        id value                    = params[key];
        params[key.lowercaseString] = value;
    }
    return params;
}

+ (BOOL)isRTMPUrl:(NSString *)url {
    return [url hasPrefix:@"rtmp://"] || [url hasPrefix:@"http"];
}

+ (BOOL)isWebrtcUrl:(NSString *)url {
    return [url hasPrefix:@"webrtc://"];
}

+ (BOOL)isTRTCUrl:(NSString *)url {
    return [url hasPrefix:@"trtc://"];
}

+ (NSMutableDictionary *)parseURLParameters:(NSString *)url {
    NSRange range = [url rangeOfString:@"?"];
    if (range.location == NSNotFound) return nil;

    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    if (url.length <= range.location + 1) return nil;
    if ([url hasPrefix:@"trtc://"]) {
        ///解析roomId
        NSString *prefix           = [url substringToIndex:range.location];
        NSArray * prefixComponents = nil;
        if ([prefix containsString:@"/push/"]) {
            prefixComponents = [prefix componentsSeparatedByString:@"/push/"];
        } else if ([prefix containsString:@"/play/"]) {
            prefixComponents = [prefix componentsSeparatedByString:@"/play/"];
        } else if ([prefix containsString:@"/rtcplay/"]) {
            prefixComponents = [prefix componentsSeparatedByString:@"/rtcplay/"];
        }
        if (prefixComponents.count == 2) {
            parameters[@"strroomid"] = prefixComponents.lastObject;
        }
    }
    NSString *parametersString = [url substringFromIndex:range.location + 1];
    NSArray * urlComponents    = [parametersString componentsSeparatedByString:@"&"];

    for (NSString *keyValuePair in urlComponents) {
        NSArray * pairComponents = [keyValuePair componentsSeparatedByString:@"="];
        NSString *key            = pairComponents.firstObject;
        NSString *value          = pairComponents.lastObject;
        if (key && value) {
            [parameters setValue:value forKey:key];
        }
    }
    return parameters;
}

@end
