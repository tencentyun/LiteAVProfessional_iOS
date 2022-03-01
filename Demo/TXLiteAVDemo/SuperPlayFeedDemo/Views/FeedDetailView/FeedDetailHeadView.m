//
//  FeedDetailHeadView.m
//  TXLiteAVDemo
//
//  Created by 路鹏 on 2021/10/29.
//  Copyright © 2021 Tencent. All rights reserved.
//

#import "FeedDetailHeadView.h"
#import <Masonry/Masonry.h>
#import <SDWebImage/UIImageView+WebCache.h>

@interface FeedDetailHeadView()

@property (nonatomic, strong) UIImageView *headImageView;

@property (nonatomic, strong) UILabel     *videoNameLabel;

@property (nonatomic, strong) UILabel     *videoSubTitleLabel;

@property (nonatomic, strong) UILabel     *videoDesLabel;

@end

@implementation FeedDetailHeadView

- (instancetype)init {
    if (self = [super init]) {
        
        self.backgroundColor = [UIColor colorWithRed:14.0/255.0 green:24.0/255.0 blue:47.0/255.0 alpha:1.0];
        
        [self addSubview:self.headImageView];
        [self addSubview:self.videoNameLabel];
        [self addSubview:self.videoSubTitleLabel];
        [self addSubview:self.videoDesLabel];
    }
    return self;
}

- (void)layoutChildViewsWithsubLableHeight:(CGFloat)subHeight {
    [self.headImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self).offset(16);
        make.top.equalTo(self).offset(8);
        make.width.mas_equalTo(40);
        make.height.mas_equalTo(40);
    }];
    
    [self.videoNameLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self).offset(8 + 40 + 16);
        make.top.equalTo(self).offset(8);
        make.right.equalTo(self);
        make.height.mas_equalTo(20);
    }];
    
    [self.videoSubTitleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self).offset(8 + 40 + 16);
        make.top.equalTo(self).offset(8 + 20 + 6);
        make.right.equalTo(self);
        make.height.mas_equalTo(subHeight);
    }];
    
    [self.videoDesLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self).offset(16);
        make.bottom.equalTo(self).offset(-2);
        make.right.equalTo(self).offset(-16);
        make.top.equalTo(self).offset(36 + subHeight);
    }];
}

#pragma mark - Public Method
- (void)setHeadModel:(FeedHeadModel *)model subLableHeight:(CGFloat)subHeight {
    
    [self layoutChildViewsWithsubLableHeight:subHeight];
    
    NSURL *url = [NSURL URLWithString:model.headImageUrl];
    [self.headImageView sd_setImageWithURL:url placeholderImage:[UIImage imageNamed:@"img_video_loading"]];
    
    self.videoNameLabel.text = model.videoNameStr;
    
    self.videoSubTitleLabel.text = model.videoSubTitleStr;
    
    self.videoDesLabel.text = model.videoDesStr;
}

#pragma mark - 懒加载
- (UIImageView *)headImageView {
    if (!_headImageView) {
        _headImageView = [UIImageView new];
        _headImageView.layer.cornerRadius = 20;
        _headImageView.layer.masksToBounds = YES;
    }
    return _headImageView;
}

- (UILabel *)videoNameLabel {
    if (!_videoNameLabel) {
        _videoNameLabel = [UILabel new];
        _videoNameLabel.font = [UIFont systemFontOfSize:16];
        _videoNameLabel.textAlignment = NSTextAlignmentLeft;
        _videoNameLabel.textColor = [UIColor colorWithRed:255/255.0 green:255/255.0 blue:255/255.0 alpha:1/1.0];
    }
    return _videoNameLabel;
}

- (UILabel *)videoSubTitleLabel {
    if (!_videoSubTitleLabel) {
        _videoSubTitleLabel = [UILabel new];
        _videoSubTitleLabel.font = [UIFont systemFontOfSize:14];
        _videoSubTitleLabel.textAlignment = NSTextAlignmentLeft;
        _videoSubTitleLabel.textColor = [UIColor colorWithRed:255/255.0 green:255/255.0 blue:255/255.0 alpha:1/1.0];
        _videoSubTitleLabel.numberOfLines = 0;
    }
    return _videoSubTitleLabel;
}

- (UILabel *)videoDesLabel {
    if (!_videoDesLabel) {
        _videoDesLabel = [UILabel new];
        _videoDesLabel.font = [UIFont systemFontOfSize:14];
        _videoDesLabel.textAlignment = NSTextAlignmentLeft;
        _videoDesLabel.textColor = [UIColor colorWithRed:255/255.0 green:255/255.0 blue:255/255.0 alpha:1/1.0];
        _videoDesLabel.numberOfLines = 0;
    }
    return _videoDesLabel;
}

@end
