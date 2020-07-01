//
//  UGCRecordWraper.h
//  TXLiteAVDemo_Enterprise
//
//  Created by abyyxwang on 2020/4/22.
//  Copyright © 2020 Tencent. All rights reserved.
//

#import "UGCKitWrapper.h"

NS_ASSUME_NONNULL_BEGIN

@interface UGCRecordWrapper : UGCKitWrapper

- (void)showRecordViewControllerWithConfig:(UGCKitRecordConfig *)config;
- (void)showRecordEntryController;

@end

NS_ASSUME_NONNULL_END
