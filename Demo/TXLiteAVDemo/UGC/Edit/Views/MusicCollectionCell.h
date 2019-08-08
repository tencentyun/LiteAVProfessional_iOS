//
//  MusicCollectionCell.h
//  DeviceManageIOSApp
//
//  Created by rushanting on 2017/5/15.
//  Copyright © 2017年 tencent. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@interface MusicInfo : NSObject
@property (nonatomic, strong) AVAsset* fileAsset;
@property (nonatomic, strong) NSString* soneName;
@property (nonatomic, strong) NSString* singerName;
@property (nonatomic, assign) CGFloat duration;
@end

@interface MusicCollectionCell : UICollectionViewCell

@property (nonatomic) UIImageView* iconView;
@property (nonatomic) UILabel*  songNameLabel;
@property (nonatomic) UILabel*  authorNameLabel;
@property (nonatomic) UIButton* deleteBtn;

- (void)setModel:(MusicInfo*)model;

@end
