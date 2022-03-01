//
//  TRTCSettingsSwitchButtonCell.h
//  TXLiteAVDemo
//
//  Created by origin 李 on 2021/12/22.
//  Copyright © 2021 Tencent. All rights reserved.
//

/*
 * Module:   TRTCSettingsSwitchButtonCell
 *
 * Function: 配置列表Cell，右侧是一个开关和一个播放Button
 *
 */
#import "TRTCSettingsBaseCell.h"
#import <Foundation/Foundation.h>
#import "TRTCCloudDef.h"
#import "TRTCCloud.h"
NS_ASSUME_NONNULL_BEGIN

@interface TRTCSettingsSwitchButtonCell : TRTCSettingsBaseCell

@end

@interface TRTCSettingsSwitchButtonItem : TRTCSettingsBaseItem
@property(strong, nonatomic) TRTCCloud *trtcCloud;
@property(strong, nonatomic) NSMutableArray *audioFrames;
@property(strong, nonatomic) NSTimer  *time;
@property(assign) NSInteger  countNum;

@property(nonatomic) BOOL isOn;
@property(copy, nonatomic, readonly, nullable) void (^switchAction)(BOOL);
@property(copy, nonatomic, readonly, nullable) void (^playAction)(TRTCAudioFrame* customAudioFrame);


- (instancetype)initWithTitle:(NSString *)title isOn:(BOOL)isOn switchAction:(void (^_Nullable)(BOOL))switchAction  playAction:(void (^_Nullable)(TRTCAudioFrame* customAudioFrame))playAction;
/**
 * 获取CustomAudioFrame数据
 */
- (NSArray *)getCustomAudioFrames;
@end


NS_ASSUME_NONNULL_END
