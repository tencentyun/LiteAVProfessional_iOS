//
//  V2TRTCSettingBar.m
//  TXLiteAVDemo_Enterprise
//
//  Created by jiruizhang on 2020/12/3.
//  Copyright © 2020 Tencent. All rights reserved.
//

#import "V2SettingBottomBar.h"

@interface V2SettingBottomBar ()
@property (nonatomic, copy) NSArray<UIButton *> *itemBtns;

@end

@implementation V2SettingBottomBar

+ (V2SettingBottomBar *)createInstance:(NSArray<NSNumber *> *)items {
    V2SettingBottomBar *bar = [[V2SettingBottomBar alloc] init];
    
    NSMutableArray<UIButton *> *mItemBtns = [[NSMutableArray alloc] init];
    for (NSNumber *item in items) {
        UIButton *btn = [V2SettingBottomBar createItemButton:[item integerValue] target:bar];
        [bar addArrangedSubview:btn];
        [mItemBtns addObject:btn];
    }
    bar.itemBtns = mItemBtns;
    
    bar.alignment = UIStackViewAlignmentFill;
    bar.distribution = UIStackViewDistributionFillEqually;
    
    return bar;
}

- (void)updateItem:(V2TRTCSettingBarItemType)type value:(NSInteger)value {
    for (UIButton *btn in self.itemBtns) {
        if (btn.tag == type) {
            switch (type) {
                case V2TRTCSettingBarItemTypeLog: {
                    UIImage *img = [UIImage imageNamed:(value == 0) ? @"log_b2" : @"log_b"];
                    [btn setImage:img forState:UIControlStateNormal];
                    break;
                }
                case V2TRTCSettingBarItemTypeMuteAudio: {
                    UIImage *img = [UIImage imageNamed:(value == 0) ? @"mute_b" : @"mute_b2"];
                    [btn setImage:img forState:UIControlStateNormal];
                    break;
                }
                case V2TRTCSettingBarItemTypeCamera: {
                    UIImage *img = [UIImage imageNamed:(value == 0) ? @"camera_b2" : @"camera_b"];
                    [btn setImage:img forState:UIControlStateNormal];
                    break;
                }
                case V2TRTCSettingBarItemTypeMuteVideo: {
                    UIImage *img = [UIImage imageNamed:(value == 0) ? @"rtc_remote_video_on" : @"rtc_remote_video_off"];
                    [btn setImage:img forState:UIControlStateNormal];
                    break;
                }
                case V2TRTCSettingBarItemTypeStart: {
                    UIImage *img = [UIImage imageNamed:(value == 0) ? @"start2" : @"stop2"];
                    [btn setImage:img forState:UIControlStateNormal];                }
                default:
                    break;
            }
            
            break;
        }
    }
}

+ (UIButton *)createItemButton:(V2TRTCSettingBarItemType)type target:(id)target {
    UIButton *btn = [[UIButton alloc] init];
    NSString *imgName = @"";
    switch (type) {
        case V2TRTCSettingBarItemTypeLog:
            imgName = @"log_b";
            break;
        case V2TRTCSettingBarItemTypeBeauty:
            imgName = @"beauty_b";
            break;
        case V2TRTCSettingBarItemTypeCamera:
            imgName = @"camera_b";
            break;
        case V2TRTCSettingBarItemTypeMuteAudio:
            imgName = @"mute_b";
            break;
        case V2TRTCSettingBarItemTypeLocalRotation:
            imgName = @"landscape";
            break;
        case V2TRTCSettingBarItemTypeBGM:
            imgName = @"music";
            break;
        case V2TRTCSettingBarItemTypeFeature:
            imgName = @"set_b";
            break;
        case V2TRTCSettingBarItemTypeMuteVideo:
            imgName = @"rtc_remote_video_on";
            break;
        case V2TRTCSettingBarItemTypeStart:
            imgName = @"stop2";
            break;
        default:
            break;
    }
    [btn setImage:[UIImage imageNamed:imgName] forState:UIControlStateNormal];
    btn.tag = type;
    [btn addTarget:target action:@selector(handleBtnClick:) forControlEvents:UIControlEventTouchUpInside];
    btn.imageView.contentMode = UIViewContentModeScaleAspectFit;
    
    return btn;
}

- (void)handleBtnClick:(UIButton *)btn {
    if (self.delegate && [self.delegate respondsToSelector:@selector(v2SettingBottomBarDidSelectItem:)]) {
        V2TRTCSettingBarItemType type = btn.tag;
        [self.delegate v2SettingBottomBarDidSelectItem:type];
    }
}

@end
