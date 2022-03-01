//
//  LebTRTCSettingBar.h
//  TXLiteAVDemo_Enterprise
//
//  Created by jiruizhang on 2020/12/3.
//  Copyright © 2020 Tencent. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, LebTRTCSettingBarItemType) {
    LebTRTCSettingBarItemTypeLog           = 0,
    LebTRTCSettingBarItemTypeBeauty        = 1,
    LebTRTCSettingBarItemTypeCamera        = 2,
    LebTRTCSettingBarItemTypeMuteAudio     = 3,
    LebTRTCSettingBarItemTypeLocalRotation = 4,
    LebTRTCSettingBarItemTypeBGM           = 5,
    LebTRTCSettingBarItemTypeFeature       = 6,
    LebTRTCSettingBarItemTypeMuteVideo     = 7,
    LebTRTCSettingBarItemTypeStart         = 8
};

@protocol LebSettingBottomBarDelegate <NSObject>

- (void)LebSettingBottomBarDidSelectItem:(LebTRTCSettingBarItemType)type;

@end

@interface                                                 LebSettingBottomBar : UIStackView
@property(nonatomic, weak) id<LebSettingBottomBarDelegate> delegate;

+ (LebSettingBottomBar *)createInstance:(NSArray<NSNumber *> *)items;
- (void)updateItem:(LebTRTCSettingBarItemType)type value:(NSInteger)value;

@end

NS_ASSUME_NONNULL_END
