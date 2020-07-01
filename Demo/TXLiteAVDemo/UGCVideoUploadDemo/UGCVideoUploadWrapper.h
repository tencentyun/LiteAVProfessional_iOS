//
//  UGCVideoUploadWrapper.h
//  TXLiteAVDemo
//
//  Created by abyyxwang on 2020/4/22.
//  Copyright © 2020 Tencent. All rights reserved.
//

#import "UGCKitWrapper.h"

NS_ASSUME_NONNULL_BEGIN

@interface UGCVideoUploadWrapper : UGCKitWrapper
- (void)showVideoUploader:(UGCKitResult *)result
inNavigationController:(UINavigationController *)navigationController;
- (void)showVideoUploadEntryController;
@end

NS_ASSUME_NONNULL_END
