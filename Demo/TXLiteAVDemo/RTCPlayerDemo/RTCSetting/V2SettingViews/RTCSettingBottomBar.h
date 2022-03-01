//
//  RTCTRTCSettingBar.h
//  TXLiteAVDemo_Enterprise
//
//  Created by adams on 2021/7/22.
//  Copyright © 2021 Tencent. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, RTCSettingBarItemType) {
    RTCSettingBarItemTypeLog           = 0,
    RTCSettingBarItemTypeBeauty        = 1,
    RTCSettingBarItemTypeCamera        = 2,
    RTCSettingBarItemTypeMuteAudio     = 3,
    RTCSettingBarItemTypeLocalRotation = 4,
    RTCSettingBarItemTypeBGM           = 5,
    RTCSettingBarItemTypeFeature       = 6,
    RTCSettingBarItemTypeMuteVideo     = 7,
    RTCSettingBarItemTypeStart         = 8
};

@protocol RTCSettingBottomBarDelegate <NSObject>

- (void)RTCSettingBottomBarDidSelectItem:(RTCSettingBarItemType)type;

@end

@interface                                                 RTCSettingBottomBar : UIStackView
@property(nonatomic, weak) id<RTCSettingBottomBarDelegate> delegate;

+ (RTCSettingBottomBar *)createInstance:(NSArray<NSNumber *> *)items;
- (void)updateItem:(RTCSettingBarItemType)type value:(NSInteger)value;

@end

NS_ASSUME_NONNULL_END
