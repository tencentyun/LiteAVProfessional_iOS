//
//  UGCVideoEditWrapper.h
//  TXLiteAVDemo
//
//  Created by abyyxwang on 2020/4/22.
//  Copyright © 2020 Tencent. All rights reserved.
//

#import "UGCKitWrapper.h"

NS_ASSUME_NONNULL_BEGIN

@interface UGCVideoEditWrapper : UGCKitWrapper

- (void)showEditViewController:(UGCKitResult *)result
              rotation:(TCEditRotation)rotation
inNavigationController:(UINavigationController *)nav
              backMode:(TCBackMode)backMode;
- (void)showEditEntryControllerWithType:(UGCKitMediaType)type;

@end

NS_ASSUME_NONNULL_END
