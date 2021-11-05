//
//  VideoComposeCell.m
//  TCLVBIMDemo
//
//  Created by annidyfeng on 2017/4/19.
//  Copyright © 2017年 tencent. All rights reserved.
//

#import "VideoJoinerCell.h"
#import "TXLiteAVSDKHeader.h"

@implementation VideoJoinerCellModel


@end

@implementation VideoJoinerCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
    
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
    [super setEditing:editing animated:animated];
    [self changeOrderControlColor];
}

- (void)setEditing:(BOOL)editing {
    [super setEditing:editing];
    [self changeOrderControlColor];
}

-(void)changeOrderControlColor {
    for (UIView* subView in self.subviews) {
        if ([[subView.classForCoder description] isEqualToString:@"UITableViewCellReorderControl"]) {
            for (UIView *subViewB in subView.subviews) {
                if ([subViewB isKindOfClass:[UIImageView classForCoder]]) {
                    UIImageView* imageView = (UIImageView*)subViewB;
                    if (imageView) {
                        UIImage* image = [imageView.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
                        imageView.image = image;
                        imageView.tintColor = [UIColor whiteColor];
                    }
                    break;
                }
            }
            break;
        }
    }
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)setModel:(VideoJoinerCellModel *)model {
    _model = model;
    self.backgroundColor = UIColor.blackColor;
    self.name.text = [model.videoPath lastPathComponent];
    if (self.name.text.length == 0) {
        if ([model.videoAsset respondsToSelector:@selector(URL)]) {
            self.name.text = [(AVURLAsset *)model.videoAsset URL].lastPathComponent;
        }
    }
    self.cover.image = model.cover;
    self.duration.text = [self time2str:model.duration];
    self.resolution.text = [NSString stringWithFormat:@"%d*%d",model.width,model.height];
}

- (NSString *)time2str:(int)time {
    int m = time / 60;
    int s = time % 60;
    
    return [NSString stringWithFormat:@"%d:%.2d", m, s];
}
@end
