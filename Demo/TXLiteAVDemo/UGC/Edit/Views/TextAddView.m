//
//  TextAddView.m
//  DeviceManageIOSApp
//
//  Created by rushanting on 2017/5/18.
//  Copyright © 2017年 tencent. All rights reserved.
//

#import "TextAddView.h"
#import "UIView+Additions.h"
#import "TXColor.h"

@implementation TextAddView
{
    UILabel*  _titleLabel;
    UIButton* _textAddButton;
}

- (id)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        _titleLabel = [UILabel new];
        _titleLabel.textColor = TXColor.gray;
        _titleLabel.textAlignment = NSTextAlignmentCenter;
        _titleLabel.text = @"文字效果";
        
        _textAddButton = [UIButton new];
        [_textAddButton setImage:[UIImage imageNamed:@"text_add"] forState:UIControlStateNormal];
        _textAddButton.backgroundColor = TXColor.black;
        [_textAddButton setTitle:@"添加普通字幕/气泡字幕" forState:UIControlStateNormal];
        _textAddButton.titleLabel.font = [UIFont systemFontOfSize:16];
        _textAddButton.titleEdgeInsets = UIEdgeInsetsMake(0, 10, 0, 0);
        [_textAddButton addTarget:self action:@selector(onTextAddBtnClicked:) forControlEvents:UIControlEventTouchUpInside];
        
        _textAddButton.imageEdgeInsets = UIEdgeInsetsMake(0, -5, 0, 0);
        
        
        [self addSubview:_titleLabel];
        [self addSubview:_textAddButton];
    }
         
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    _titleLabel.frame = CGRectMake(0, 0, self.width, 14);
    _textAddButton.frame = CGRectMake(15, _titleLabel.bottom + 25, self.width - 30, 50);
}

- (void)setEdited:(BOOL)isEdited
{
    if (!isEdited) {
        [_textAddButton setImage:[UIImage imageNamed:@"text_add"] forState:UIControlStateNormal];
        [_textAddButton setTitle:@"添加普通字幕/气泡字幕" forState:UIControlStateNormal];
    }
    else {
        [_textAddButton setImage:[UIImage imageNamed:@"type"] forState:UIControlStateNormal];
        [_textAddButton setTitle:@"编辑普通字幕/气泡字幕" forState:UIControlStateNormal];
    }
}

- (void)onTextAddBtnClicked:(UIButton*)sender
{
    [self.delegate onAddTextBtnClicked];
}

@end
