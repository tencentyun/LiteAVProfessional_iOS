//
//  TRTCMixedSoundSettingVC.h
//  TXLiteAVDemo
//
//  Created by origin 李 on 2021/12/23.
//  Copyright © 2021 Tencent. All rights reserved.
//

#import "TRTCEffectSettingsBaseViewController.h"
#import "TRTCCloud.h"
NS_ASSUME_NONNULL_BEGIN

@interface TRTCMixedSoundSettingVC : TRTCEffectSettingsBaseViewController
@property(assign, nonatomic) BOOL enablePublish;
@property(assign, nonatomic) BOOL enablePlayout;
@property(assign, nonatomic) NSInteger publishVolume;
@property(assign, nonatomic) NSInteger playoutVolume;
- (instancetype)initWithTRTCCloud:(TRTCCloud *)trtcCloud;
@end

NS_ASSUME_NONNULL_END
