//
//  MusicCollectionCell.m
//  DeviceManageIOSApp
//
//  Created by rushanting on 2017/5/15.
//  Copyright © 2017年 tencent. All rights reserved.
//

#import "MusicCollectionCell.h"
#import "TXColor.h"
#import "UIView+Additions.h"

@implementation MusicInfo

@end

@implementation MusicCollectionCell

- (id)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        self.backgroundColor = TXColor.black;
        _iconView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"voice_nor"]];
        [self.contentView addSubview:_iconView];
        
        _songNameLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _songNameLabel.text = @"歌名";
        _songNameLabel.textColor = TXColor.gray;
        _songNameLabel.textAlignment = NSTextAlignmentCenter;
        _songNameLabel.font = [UIFont fontWithName:@"PingFangSC-Medium" size:10];
        //_songNameLabel.font = [UIFont systemFontOfSize:10];
        _songNameLabel.numberOfLines = 2;
        _songNameLabel.lineBreakMode = NSLineBreakByWordWrapping;
        [self.contentView addSubview:_songNameLabel];
        
        _authorNameLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _authorNameLabel.textColor = TXColor.darkGray;
        _authorNameLabel.text = @"作者";
        _authorNameLabel.textAlignment = NSTextAlignmentCenter;
        _authorNameLabel.font = [UIFont fontWithName:@"PingFangSC-Medium" size:10];
        //_authorNameLabel.font = [UIFont systemFontOfSize:10];
        [self.contentView addSubview:_authorNameLabel];
        
        _deleteBtn = [UIButton new];
        _deleteBtn.backgroundColor = UIColor.darkGrayColor;
        _deleteBtn.alpha = 0.7;
        [_deleteBtn setImage:[UIImage imageNamed:@"video_record_close"] forState:UIControlStateNormal];
        [self.contentView addSubview:_deleteBtn];
        _deleteBtn.hidden = YES;
    }
    
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    _iconView.center = CGPointMake(self.width / 2, 15 + _iconView.image.size.height / 2);
    
    [_songNameLabel sizeToFit];
    _songNameLabel.frame = CGRectMake(5, _iconView.bottom + 10, self.width - 10, _songNameLabel.height);
    
    [_authorNameLabel sizeToFit];
    _authorNameLabel.frame = CGRectMake(10, self.height - 10 - 10, self.width - 20, 10);
//    _authorNameLabel.frame = CGRectMake(10, _songNameLabel.bottom + 10, self.width - 20, _authorNameLabel.height);
    
    _deleteBtn.frame = CGRectMake(0, 0, 20, 20);
}

- (void)setSelected:(BOOL)selected
{
    //本地音频的按钮
    if (_authorNameLabel.hidden) {
        return;
    }
    
    if (!selected) {
        _iconView.image = [UIImage imageNamed:@"voice_nor"];
        _songNameLabel.textColor = TXColor.gray;
        _authorNameLabel.textColor = TXColor.darkGray;
        self.layer.borderColor = TXColor.black.CGColor;
    } else {
        _iconView.image = [UIImage imageNamed:@"voice_pressed"];
        _songNameLabel.textColor = TXColor.cyan;
        _authorNameLabel.textColor = TXColor.cyan;
        self.layer.borderWidth = 1;
        self.layer.borderColor = TXColor.cyan.CGColor;
    }
}

- (void)setModel:(MusicInfo *)model
{
    _songNameLabel.text = model.soneName;
    _authorNameLabel.text = model.singerName;
    //设段距
    if (_songNameLabel.text.length > 0) {
        NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:_songNameLabel.text];
        NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
        [paragraphStyle setLineSpacing:11];
        [attributedString addAttribute:NSParagraphStyleAttributeName value:paragraphStyle range:NSMakeRange(0, [_songNameLabel.text length])];
        _songNameLabel.attributedText = attributedString;
        _songNameLabel.textAlignment = NSTextAlignmentCenter;
    }
}

#pragma mark - UI event handle

@end
