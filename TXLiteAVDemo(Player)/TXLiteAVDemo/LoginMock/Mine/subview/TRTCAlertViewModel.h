//
//  TRTCAlertViewModel.h
//  TXLiteAVDemo_Enterprise
//
//  Created by peterwtma on 2021/8/5.
//  Copyright © 2021 Tencent. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface AvatarModel : NSObject
@property (nonatomic, strong) NSString *url;
- (instancetype)initWithUrl:(NSString*)url;
@end

@interface TRTCAlertViewModel : NSObject
@property (nonatomic, strong) AvatarModel *currentSelectAvatarModel;
@property (nonatomic, strong) NSArray *avatarListDataSource;

- (void)setUserAvatar:(NSString*)avatarUrl;
@end

NS_ASSUME_NONNULL_END
