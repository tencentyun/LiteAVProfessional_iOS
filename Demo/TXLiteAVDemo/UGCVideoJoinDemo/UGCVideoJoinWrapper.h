//
//  UGCVideoJoinWrapper.h
//  TXLiteAVDemo_Enterprise
//
//  Created by abyyxwang on 2020/4/22.
//  Copyright © 2020 Tencent. All rights reserved.
//

#import "UGCKitWrapper.h"

NS_ASSUME_NONNULL_BEGIN

@interface UGCVideoJoinWrapper : UGCKitWrapper

- (void)showCombineViewController:(NSArray<AVAsset *> *)assets
inNavigationController:(UINavigationController *)navigationController;
- (void)showVideoJoinEntryController;

@end

NS_ASSUME_NONNULL_END
