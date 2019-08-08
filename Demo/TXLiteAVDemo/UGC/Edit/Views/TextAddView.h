//
//  TextAddView.h
//  DeviceManageIOSApp
//
//  Created by rushanting on 2017/5/18.
//  Copyright © 2017年 tencent. All rights reserved.
//

#import <UIKit/UIKit.h>
/**
 视频编辑字幕添加view
 */

@protocol TextAddViewDelegate <NSObject>

- (void)onAddTextBtnClicked;

@end

@interface TextAddView : UIView

@property (nonatomic, weak) id<TextAddViewDelegate> delegate;

- (void)setEdited:(BOOL)isEdited;

@end
