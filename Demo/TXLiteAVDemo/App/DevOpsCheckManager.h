//
//  DevOpsCheckManager.h
//  TXLiteAVDemo_Enterprise
//
//  Created by jack on 2021/11/8.
//  Copyright © 2021 Tencent. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface DevOpsCheckManager : NSObject

/// 检查蓝盾版本
/// @param userId 当前用户Id，需要检验
+ (void)checkUpdateWithUserId:(NSString *)userId;

@end

NS_ASSUME_NONNULL_END
