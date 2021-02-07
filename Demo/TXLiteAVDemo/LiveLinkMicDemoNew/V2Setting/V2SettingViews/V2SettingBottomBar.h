//
//  V2TRTCSettingBar.h
//  TXLiteAVDemo_Enterprise
//
//  Created by jiruizhang on 2020/12/3.
//  Copyright © 2020 Tencent. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, V2TRTCSettingBarItemType) {
    V2TRTCSettingBarItemTypeLog        = 0,
    V2TRTCSettingBarItemTypeBeauty     = 1,
    V2TRTCSettingBarItemTypeCamera     = 2,
    V2TRTCSettingBarItemTypeMuteAudio  = 3,
    V2TRTCSettingBarItemTypeLocalRotation = 4,
    V2TRTCSettingBarItemTypeBGM        = 5,
    V2TRTCSettingBarItemTypeFeature    = 6,
    V2TRTCSettingBarItemTypeMuteVideo  = 7,
    V2TRTCSettingBarItemTypeStart      = 8
};

@protocol V2SettingBottomBarDelegate <NSObject>

- (void)v2SettingBottomBarDidSelectItem:(V2TRTCSettingBarItemType)type;

@end

@interface V2SettingBottomBar : UIStackView
@property (nonatomic, weak) id<V2SettingBottomBarDelegate> delegate;

+ (V2SettingBottomBar *)createInstance:(NSArray<NSNumber *> *)items;
- (void)updateItem:(V2TRTCSettingBarItemType)type value:(NSInteger)value;

@end

NS_ASSUME_NONNULL_END
