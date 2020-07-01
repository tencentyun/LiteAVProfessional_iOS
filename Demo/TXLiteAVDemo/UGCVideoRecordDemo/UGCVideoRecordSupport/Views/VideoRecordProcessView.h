//
//  VideoRecordProcessView.h
//  TXLiteAVDemo
//
//  Created by zhangxiang on 2017/9/12.
//  Copyright © 2017年 Tencent. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface VideoRecordProcessView : UIView

-(void)update:(CGFloat)progress;

-(void)pause;

-(void)prepareDeletePart;

-(void)cancelDelete;

-(void)comfirmDeletePart;

-(void)deleteAllPart;
@end
