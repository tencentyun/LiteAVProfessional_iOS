//
//  TXProgressSlideGuideView.m
//  TXLiteAVDemo_Enterprise
//
//  Created by 路鹏 on 2021/8/30.
//  Copyright © 2021 Tencent. All rights reserved.
//

#import "TXProgressSlideGuideView.h"
#import <Masonry/Masonry.h>

@interface TXProgressSlideGuideView()

@property (nonatomic, strong) UIImageView  *progressImageView;

@property (nonatomic, strong) UILabel      *describeLabel;

@property (nonatomic, strong) UIButton     *knowBtn;

@end

@implementation TXProgressSlideGuideView

- (instancetype)init {
    if (self = [super init]) {
        self.backgroundColor = [UIColor colorWithRed:0/255.0 green:0/255.0 blue:0/255.0 alpha:0.596017263986014/1.0];
        [self addSubview:self.progressImageView];
        [self addSubview:self.describeLabel];
        [self addSubview:self.knowBtn];
        
        [self.progressImageView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.width.mas_equalTo(200);
            make.height.mas_equalTo(82);
            make.centerX.equalTo(self);
            make.bottom.equalTo(self).offset(-40);
        }];
        
        [self.knowBtn mas_makeConstraints:^(MASConstraintMaker *make) {
            make.width.mas_equalTo(94);
            make.height.mas_equalTo(40);
            make.centerX.equalTo(self);
            make.bottom.equalTo(self).offset(-192);
        }];
        
        [self.describeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self);
            make.right.equalTo(self);
            make.height.mas_equalTo(22);
            make.centerX.equalTo(self);
            make.bottom.equalTo(self.knowBtn).offset(55);
        }];
    }
    return self;
}

- (void)knowClick {
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"isShowedGuideView"];
    if (_progressSlideViewHidden) {
        _progressSlideViewHidden(YES);
        
    }
}

#pragma mark - 懒加载

- (UIImageView *)progressImageView {
    if (!_progressImageView) {
        _progressImageView = [UIImageView new];
        _progressImageView.image = [UIImage imageNamed:@"progressSlide.png"];
        _progressImageView.contentMode = UIViewContentModeBottom;
        _progressImageView.clipsToBounds = YES;
    }
    return _progressImageView;
}

- (UILabel *)describeLabel {
    if (!_describeLabel) {
        _describeLabel = [UILabel new];
        _describeLabel.text = @"拖拽进度条快速查看视频";
        _describeLabel.textAlignment = NSTextAlignmentCenter;
        _describeLabel.font = [UIFont fontWithName:@"PingFangSC" size:16];
        _describeLabel.textColor = [UIColor colorWithRed:255.0/255.0 green:255.0/255.0 blue:255.0/255.0 alpha:1.0];
    }
    return _describeLabel;
}

- (UIButton *)knowBtn {
    if (!_knowBtn) {
        _knowBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_knowBtn setTitle:@"知道了" forState:UIControlStateNormal];
        [_knowBtn setTitleColor:[UIColor colorWithRed:255.0/255.0 green:255.0/255.0 blue:255.0/255.0 alpha:1.0] forState:UIControlStateNormal];
        [_knowBtn addTarget:self action:@selector(knowClick) forControlEvents:UIControlEventTouchUpInside];
        _knowBtn.layer.cornerRadius = 20;
        _knowBtn.layer.borderColor = [UIColor colorWithRed:255.0/255.0 green:255.0/255.0 blue:255.0/255.0 alpha:1.0].CGColor;
        _knowBtn.layer.borderWidth = 1;
        _knowBtn.layer.masksToBounds = YES;
    }
    return _knowBtn;
}

@end
