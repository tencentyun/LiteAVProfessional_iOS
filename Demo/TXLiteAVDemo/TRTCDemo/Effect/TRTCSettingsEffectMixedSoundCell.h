//
//  TRTCSettingsEffectMixedSoundCell.h
//  TXLiteAVDemo
//
//  Created by origin 李 on 2021/12/23.
//  Copyright © 2021 Tencent. All rights reserved.
//

#import "TRTCSettingsBaseCell.h"
#import "TRTCCloud.h"
#import "TRTCMixedSoundSettingVC.h"
NS_ASSUME_NONNULL_BEGIN

@interface TRTCSettingsEffectMixedSoundCell : TRTCSettingsBaseCell

@end
NS_ASSUME_NONNULL_END

NS_ASSUME_NONNULL_BEGIN
@interface TRTCSettingsEffectMixedSoundItem : TRTCSettingsBaseItem
@property(weak, nonatomic) TRTCMixedSoundSettingVC *settingPage;
@property(copy, nonatomic, readonly, nullable) void (^playAction)(void);
@property (strong, nonatomic) TRTCCloud *trtcCloud;
- (instancetype)initWithTRTCCloud:(TRTCCloud *)trtcCloud playAction:(void (^_Nullable)(void))playAction;

@end
NS_ASSUME_NONNULL_END
