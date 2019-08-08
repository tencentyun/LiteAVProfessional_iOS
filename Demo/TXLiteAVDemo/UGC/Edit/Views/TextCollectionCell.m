//
//  TextCollectionCell.m
//  DeviceManageIOSApp
//
//  Created by rushanting on 2017/5/22.
//  Copyright © 2017年 tencent. All rights reserved.
//

#import "TextCollectionCell.h"
#import "TXColor.h"
#import "UIView+Additions.h"


@implementation TextCollectionCell


- (id)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        self.layer.borderWidth = 1;
        self.layer.borderColor = TXColor.gray.CGColor;
        self.backgroundColor = UIColor.clearColor;
        _textLabel = [UILabel new];
        _textLabel.text = @"点击添加文字";
        _textLabel.font = [UIFont systemFontOfSize:9];
        _textLabel.textAlignment = NSTextAlignmentCenter;
        _textLabel.textColor = UIColor.whiteColor;
        _textLabel.numberOfLines = 2;
        [self.contentView addSubview:_textLabel];
    }
    
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    _textLabel.frame = CGRectMake(5, 6, self.contentView.width - 10, self.contentView.height - 14);
}

- (void)setSelected:(BOOL)selected
{
    if (!selected) {
        _textLabel.textColor = UIColor.whiteColor;
        self.layer.borderColor = TXColor.gray.CGColor;
    } else {
        _textLabel.textColor = TXColor.cyan;
        self.layer.borderWidth = 1;
        self.layer.borderColor = TXColor.cyan.CGColor;
    }
}

@end


@implementation PasterCollectionCell

- (id)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        self.layer.borderWidth = 1;
        self.layer.borderColor = TXColor.gray.CGColor;
        self.backgroundColor = UIColor.clearColor;
        _imageView = [UIImageView new];
        [self.contentView addSubview:_imageView];
    }
    
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    _imageView.frame = CGRectMake(5, 6, self.contentView.width - 10, self.contentView.height - 14);
}
@end
