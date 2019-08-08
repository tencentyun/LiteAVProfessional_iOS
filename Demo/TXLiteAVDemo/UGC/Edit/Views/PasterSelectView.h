//
//  PasterSelectView.h
//  TXLiteAVDemo
//
//  Created by xiang zhang on 2017/10/31.
//  Copyright © 2017年 Tencent. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger,PasterType)
{
    PasterType_Qipao,
    PasterType_Animate,
    PasterType_static,
};

@interface PasterQipaoInfo : NSObject
@property(nonatomic,strong) UIImage *image;
@property(nonatomic,strong) UIImage *iconImage;
@property(nonatomic,assign) CGFloat width;
@property(nonatomic,assign) CGFloat height;
@property(nonatomic,assign) CGFloat textTop;
@property(nonatomic,assign) CGFloat textLeft;
@property(nonatomic,assign) CGFloat textRight;
@property(nonatomic,assign) CGFloat textBottom;
@end

@interface PasterAnimateInfo : NSObject
@property(nonatomic,strong) NSString *path;
@property(nonatomic,strong) UIImage *iconImage;
@property(nonatomic,strong) NSArray *imageList;
@property(nonatomic,assign) CGFloat duration;   //s
@property(nonatomic,assign) CGFloat width;
@property(nonatomic,assign) CGFloat height;
@end

@interface PasterStaticInfo : NSObject
@property(nonatomic,strong) UIImage *image;
@property(nonatomic,strong) UIImage *iconImage;
@property(nonatomic,assign) CGFloat width;
@property(nonatomic,assign) CGFloat height;
@end

@protocol PasterSelectViewDelegate <NSObject>
@optional
- (void)onPasterQipaoSelect:(PasterQipaoInfo *)info;

@optional
- (void)onPasterAnimateSelect:(PasterAnimateInfo *)info;

@optional
- (void)onPasterStaticSelect:(PasterStaticInfo *)info;

@end


@interface PasterSelectView : UIView 
@property(nonatomic,weak) id <PasterSelectViewDelegate> delegate;

- (instancetype) initWithFrame:(CGRect)frame
                    pasterType:(PasterType)pasterType
                     boundPath:(NSString *)boundPath;
@end
