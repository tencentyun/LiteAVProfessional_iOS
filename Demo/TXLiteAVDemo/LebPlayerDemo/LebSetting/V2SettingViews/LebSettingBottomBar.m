//
//  LebTRTCSettingBar.m
//  TXLiteAVDemo_Enterprise
//
//  Created by jiruizhang on 2020/12/3.
//  Copyright © 2020 Tencent. All rights reserved.
//

#import "LebSettingBottomBar.h"

@interface LebSettingBottomBar ()
@property (nonatomic, copy) NSArray<UIButton *> *itemBtns;

@end

@implementation LebSettingBottomBar

+ (LebSettingBottomBar *)createInstance:(NSArray<NSNumber *> *)items {
    LebSettingBottomBar *bar = [[LebSettingBottomBar alloc] init];
    
    NSMutableArray<UIButton *> *mItemBtns = [[NSMutableArray alloc] init];
    for (NSNumber *item in items) {
        UIButton *btn = [LebSettingBottomBar createItemButton:[item integerValue] target:bar];
        [bar addArrangedSubview:btn];
        [mItemBtns addObject:btn];
    }
    bar.itemBtns = mItemBtns;
    
    bar.alignment = UIStackViewAlignmentFill;
    bar.distribution = UIStackViewDistributionFillEqually;
    
    return bar;
}

- (void)updateItem:(LebTRTCSettingBarItemType)type value:(NSInteger)value {
    for (UIButton *btn in self.itemBtns) {
        if (btn.tag == type) {
            switch (type) {
                case LebTRTCSettingBarItemTypeLog: {
                    UIImage *img = [UIImage imageNamed:(value == 0) ? @"log_b2" : @"log_b"];
                    [btn setImage:img forState:UIControlStateNormal];
                    break;
                }
                case LebTRTCSettingBarItemTypeMuteAudio: {
                    UIImage *img = [UIImage imageNamed:(value == 0) ? @"mute_b" : @"mute_b2"];
                    [btn setImage:img forState:UIControlStateNormal];
                    break;
                }
                case LebTRTCSettingBarItemTypeCamera: {
                    UIImage *img = [UIImage imageNamed:(value == 0) ? @"camera_b2" : @"camera_b"];
                    [btn setImage:img forState:UIControlStateNormal];
                    break;
                }
                case LebTRTCSettingBarItemTypeMuteVideo: {
                    UIImage *img = [UIImage imageNamed:(value == 0) ? @"rtc_remote_video_on" : @"rtc_remote_video_off"];
                    [btn setImage:img forState:UIControlStateNormal];
                    break;
                }
                case LebTRTCSettingBarItemTypeStart: {
                    UIImage *img = [UIImage imageNamed:(value == 0) ? @"start2" : @"stop2"];
                    [btn setImage:img forState:UIControlStateNormal];                }
                default:
                    break;
            }
            
            break;
        }
    }
}

+ (UIButton *)createItemButton:(LebTRTCSettingBarItemType)type target:(id)target {
    UIButton *btn = [[UIButton alloc] init];
    NSString *imgName = @"";
    switch (type) {
        case LebTRTCSettingBarItemTypeLog:
            imgName = @"log_b";
            break;
        case LebTRTCSettingBarItemTypeBeauty:
            imgName = @"beauty_b";
            break;
        case LebTRTCSettingBarItemTypeCamera:
            imgName = @"camera_b";
            break;
        case LebTRTCSettingBarItemTypeMuteAudio:
            imgName = @"mute_b";
            break;
        case LebTRTCSettingBarItemTypeLocalRotation:
            imgName = @"landscape";
            break;
        case LebTRTCSettingBarItemTypeBGM:
            imgName = @"music";
            break;
        case LebTRTCSettingBarItemTypeFeature:
            imgName = @"set_b";
            break;
        case LebTRTCSettingBarItemTypeMuteVideo:
            imgName = @"rtc_remote_video_on";
            break;
        case LebTRTCSettingBarItemTypeStart:
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
    if (self.delegate && [self.delegate respondsToSelector:@selector(LebSettingBottomBarDidSelectItem:)]) {
        LebTRTCSettingBarItemType type = btn.tag;
        [self.delegate LebSettingBottomBarDidSelectItem:type];
    }
}

@end
