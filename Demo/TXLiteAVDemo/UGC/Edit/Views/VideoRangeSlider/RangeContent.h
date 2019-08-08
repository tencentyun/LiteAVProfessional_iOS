//
//  VideoRangeContent.h
//  SAVideoRangeSliderExample
//
//  Created by annidyfeng on 2017/4/18.
//  Copyright © 2017年 Andrei Solovjev. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "VideoRangeConst.h"


/*用来辅僵定制外观*/
@interface RangeContentConfig : NSObject
@property (nonatomic) NSInteger pinWidth;
@property (nonatomic) NSInteger thumbHeight;
@property (nonatomic) NSInteger borderHeight;
@property (nonatomic) UIImage*  leftPinImage;
@property (nonatomic) UIImage*  centerPinImage;
@property (nonatomic) UIImage*  rightPigImage;
@property (nonatomic) UIImage*  leftCorverImage;
@property (nonatomic) UIImage*  rightCoverImage;
@end




@protocol RangeContentDelegate;

@interface RangeContent : UIView

@property (nonatomic, weak) id<RangeContentDelegate> delegate;

@property (nonatomic) CGFloat   leftPinCenterX;     //左拉条位置
@property (nonatomic) CGFloat   centerPinCenterX;   //中间滑块位置
@property (nonatomic) CGFloat   rightPinCenterX;    //右拉条位置

@property (nonatomic) UIImageView   *leftPin;       //左拉条
@property (nonatomic) UIImageView   *centerPin;     //中滑块
@property (nonatomic) UIImageView   *rightPin;      //右拉条
@property (nonatomic) UIView        *topBorder;     //上边
@property (nonatomic) UIView        *bottomBorder;  //下边
@property (nonatomic) UIImageView   *middleLine;    //中线
@property (nonatomic) UIImageView   *centerCover;
@property (nonatomic) UIImageView   *leftCover;     //左拉覆盖
@property (nonatomic) UIImageView   *rightCover;    //右拉覆盖

@property (nonatomic, copy) NSArray<UIImageView *>       *imageViewList;
@property (nonatomic, copy) NSArray       *imageList;   //显示图列表

@property (nonatomic, readonly) CGFloat pinWidth;    //拉条大小
@property (nonatomic, readonly) CGFloat imageWidth;
@property (nonatomic, readonly) CGFloat imageListWidth;

@property (nonatomic, readonly) CGFloat leftScale;  //左拉条的位置比例
@property (nonatomic, readonly) CGFloat rightScale; //右拉条的位置比例
@property (nonatomic, readonly) CGFloat centerScale; //中间拉条的位置比例

- (instancetype)initWithImageList:(NSArray *)images;
- (instancetype)initWithImageList:(NSArray *)images config:(RangeContentConfig*)config;

@end


@protocol RangeContentDelegate <NSObject>

@optional
- (void)onRangeLeftChangeBegin:(RangeContent*)sender;
- (void)onRangeLeftChanged:(RangeContent *)sender;
- (void)onRangeLeftChangeEnded:(RangeContent *)sender;
- (void)onRangeCenterChangeBegin:(RangeContent*)sender;
- (void)onRangeCenterChanged:(RangeContent *)sender;
- (void)onRangeCenterChangeEnded:(RangeContent *)sender;
- (void)onRangeRightChangeBegin:(RangeContent*)sender;
- (void)onRangeRightChanged:(RangeContent *)sender;
- (void)onRangeRightChangeEnded:(RangeContent *)sender;
- (void)onRangeLeftAndRightChanged:(RangeContent *)sender;
@end
