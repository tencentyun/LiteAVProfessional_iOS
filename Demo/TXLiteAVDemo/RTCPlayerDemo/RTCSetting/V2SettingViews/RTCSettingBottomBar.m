//
//  RTCTRTCSettingBar.m
//  TXLiteAVDemo_Enterprise
//
//  Created by jiruizhang on 2020/12/3.
//  Copyright © 2020 Tencent. All rights reserved.
//

#import "RTCSettingBottomBar.h"

@interface                                      RTCSettingBottomBar ()
@property(nonatomic, copy) NSArray<UIButton *> *itemBtns;
@end

@implementation RTCSettingBottomBar

+ (RTCSettingBottomBar *)createInstance:(NSArray<NSNumber *> *)items {
    RTCSettingBottomBar *bar = [[RTCSettingBottomBar alloc] init];

    NSMutableArray<UIButton *> *mItemBtns = [[NSMutableArray alloc] init];
    for (NSNumber *item in items) {
        UIButton *btn = [RTCSettingBottomBar createItemButton:[item integerValue] target:bar];
        [bar addArrangedSubview:btn];
        [mItemBtns addObject:btn];
    }
    bar.itemBtns = mItemBtns;

    bar.alignment    = UIStackViewAlignmentFill;
    bar.distribution = UIStackViewDistributionFillEqually;

    return bar;
}

- (void)updateItem:(RTCSettingBarItemType)type value:(NSInteger)value {
    for (UIButton *btn in self.itemBtns) {
        if (btn.tag == type) {
            switch (type) {
                case RTCSettingBarItemTypeLog: {
                    UIImage *img = [UIImage imageNamed:(value == 0) ? @"log_b2" : @"log_b"];
                    [btn setImage:img forState:UIControlStateNormal];
                    break;
                }
                case RTCSettingBarItemTypeMuteAudio: {
                    UIImage *img = [UIImage imageNamed:(value == 0) ? @"mute_b" : @"mute_b2"];
                    [btn setImage:img forState:UIControlStateNormal];
                    break;
                }
                case RTCSettingBarItemTypeCamera: {
                    UIImage *img = [UIImage imageNamed:(value == 0) ? @"camera_b2" : @"camera_b"];
                    [btn setImage:img forState:UIControlStateNormal];
                    break;
                }
                case RTCSettingBarItemTypeMuteVideo: {
                    UIImage *img = [UIImage imageNamed:(value == 0) ? @"rtc_remote_video_on" : @"rtc_remote_video_off"];
                    [btn setImage:img forState:UIControlStateNormal];
                    break;
                }
                case RTCSettingBarItemTypeStart: {
                    UIImage *img = [UIImage imageNamed:(value == 0) ? @"start2" : @"stop2"];
                    [btn setImage:img forState:UIControlStateNormal];
                }
                default:
                    break;
            }

            break;
        }
    }
}

+ (UIButton *)createItemButton:(RTCSettingBarItemType)type target:(id)target {
    UIButton *btn     = [[UIButton alloc] init];
    NSString *imgName = @"";
    switch (type) {
        case RTCSettingBarItemTypeLog:
            imgName = @"log_b";
            break;
        case RTCSettingBarItemTypeBeauty:
            imgName = @"beauty_b";
            break;
        case RTCSettingBarItemTypeCamera:
            imgName = @"camera_b";
            break;
        case RTCSettingBarItemTypeMuteAudio:
            imgName = @"mute_b";
            break;
        case RTCSettingBarItemTypeLocalRotation:
            imgName = @"landscape";
            break;
        case RTCSettingBarItemTypeBGM:
            imgName = @"music";
            break;
        case RTCSettingBarItemTypeFeature:
            imgName = @"set_b";
            break;
        case RTCSettingBarItemTypeMuteVideo:
            imgName = @"rtc_remote_video_on";
            break;
        case RTCSettingBarItemTypeStart:
            imgName = @"stop2";
            break;
        default:
            break;
    }
    [btn setImage:[UIImage imageNamed:imgName] forState:UIControlStateNormal];
    btn.tag = type;
    [btn addTarget:target action:@selector(handRTCtnClick:) forControlEvents:UIControlEventTouchUpInside];
    btn.imageView.contentMode = UIViewContentModeScaleAspectFit;

    return btn;
}

- (void)handRTCtnClick:(UIButton *)btn {
    if (self.delegate && [self.delegate respondsToSelector:@selector(RTCSettingBottomBarDidSelectItem:)]) {
        RTCSettingBarItemType type = btn.tag;
        [self.delegate RTCSettingBottomBarDidSelectItem:type];
    }
}

@end
