//
//  PasterAddView.h
//  TXLiteAVDemo
//
//  Created by lijie on 2017/10/26.
//  Copyright © 2017年 Tencent. All rights reserved.
//

#import <UIKit/UIKit.h>

/**
 视频编辑贴图添加view
 */

@protocol PasterAddViewDelegate <NSObject>

- (void)onAddPasterBtnClicked;

@end

@interface PasterAddView : UIView

@property (nonatomic, weak) id<PasterAddViewDelegate> delegate;

- (void)setEdited:(BOOL)isEdited;

@end
