//
//  PasterAddView.m
//  TXLiteAVDemo
//
//  Created by lijie on 2017/10/26.
//  Copyright © 2017年 Tencent. All rights reserved.
//

#import "PasterAddView.h"
#import "UIView+Additions.h"
#import "TXColor.h"

@implementation PasterAddView
{
    UILabel*  _titleLabel;
    UIButton* _pasterAddButton;
}

- (id)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        _titleLabel = [UILabel new];
        _titleLabel.textColor = TXColor.gray;
        _titleLabel.textAlignment = NSTextAlignmentCenter;
        _titleLabel.text = @"贴图效果";
        
        _pasterAddButton = [UIButton new];
        [_pasterAddButton setImage:[UIImage imageNamed:@"text_add"] forState:UIControlStateNormal];
        _pasterAddButton.backgroundColor = TXColor.black;
        [_pasterAddButton setTitle:@"添加动态贴图/静态贴图" forState:UIControlStateNormal];
        _pasterAddButton.titleLabel.font = [UIFont systemFontOfSize:16];
        _pasterAddButton.titleEdgeInsets = UIEdgeInsetsMake(0, 10, 0, 0);
        [_pasterAddButton addTarget:self action:@selector(onPasterAddBtnClicked:) forControlEvents:UIControlEventTouchUpInside];
        
        _pasterAddButton.imageEdgeInsets = UIEdgeInsetsMake(0, -5, 0, 0);
        
        
        [self addSubview:_titleLabel];
        [self addSubview:_pasterAddButton];
    }
    
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    _titleLabel.frame = CGRectMake(0, 0, self.width, 14);
    _pasterAddButton.frame = CGRectMake(15, _titleLabel.bottom + 25, self.width - 30, 50);
}

- (void)setEdited:(BOOL)isEdited {
    if (!isEdited) {
        [_pasterAddButton setImage:[UIImage imageNamed:@"text_add"] forState:UIControlStateNormal];
        [_pasterAddButton setTitle:@"添加动态贴图/静态贴图" forState:UIControlStateNormal];
    }
    else {
        [_pasterAddButton setImage:[UIImage imageNamed:@"type"] forState:UIControlStateNormal];
        [_pasterAddButton setTitle:@"编辑动态贴图/静态贴图" forState:UIControlStateNormal];
    }
}

- (void)onPasterAddBtnClicked:(UIButton*)sender {
    [self.delegate onAddPasterBtnClicked];
}

@end
