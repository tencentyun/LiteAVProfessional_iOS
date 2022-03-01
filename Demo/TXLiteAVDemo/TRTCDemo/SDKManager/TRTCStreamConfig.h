//
//  TRTCStreamConfig.h
//  TXLiteAVDemo
//
//  Created by LiuXiaoya on 2019/12/9.
//  Copyright © 2019 Tencent. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "TRTCCloudDef.h"

NS_ASSUME_NONNULL_BEGIN

@interface TRTCStreamConfig : NSObject

/// 云端混流模式，默认为 Unknown
@property(nonatomic) TRTCTranscodingConfigMode mixMode;

/// 云端混流背景图ID
@property(nonatomic, copy, nullable) NSString *backgroundImage;

/// 自定义流ID
@property(nonatomic, copy, nullable) NSString *streamId;

@end

NS_ASSUME_NONNULL_END
