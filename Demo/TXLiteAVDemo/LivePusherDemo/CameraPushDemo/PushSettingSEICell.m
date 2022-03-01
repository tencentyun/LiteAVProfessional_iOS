//
//  PushSettingSEICell.m
//  TXLiteAVDemo
//
//  Created by leiran on 2021/10/12.
//  Copyright © 2021 Tencent. All rights reserved.
//

#import "PushSettingSEICell.h"
#import "AppLocalized.h"
#import "Masonry.h"
#import "UIImage+Additions.h"
#import "ColorMacro.h"
#import "MBProgressHUD.h"

@interface PushSettingSEICell() <UITextFieldDelegate>
@property(strong, nonatomic) UILabel *titleLabel;
@property(strong, nonatomic) UILabel *dataLabel;
@property(strong, nonatomic) UITextField *typeText;
@property(strong, nonatomic) UITextField *messageText;
@property(strong, nonatomic) UIButton *sendButton;

@end

@implementation PushSettingSEICell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self setupUI];
    }
    return self;
}

- (void)setupUI {

    CGFloat fontSize = 15;

    self.titleLabel = ({
        UILabel *label = [self createTitleLabel];
        label.font = [UIFont systemFontOfSize:fontSize];
        label.text = LivePlayerLocalize(@"LivePusherDemo.PushSetting.seipayloadtype");
        CGFloat width = [label.text boundingRectWithSize:CGSizeMake(1000, 20) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:fontSize]} context:nil].size.width;
        [self.contentView addSubview:label];
        [label mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self.contentView).offset(12);
            make.top.bottom.equalTo(self.contentView);
            make.width.mas_equalTo(width + 2);
        }];
        label;
    });

    self.typeText = ({
        UITextField *textF = [self createTextFieldWithDelegate:self];
        [self.contentView addSubview:textF];
        textF.keyboardType = UIKeyboardTypeNumberPad;
        [textF mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerY.equalTo(self.contentView);
            make.left.equalTo(self.titleLabel.mas_right);
            make.width.mas_equalTo(44);
            make.height.mas_equalTo(32);
        }];
        textF;
    });
    
    self.dataLabel = ({
        UILabel *label = [self createTitleLabel];
        label.text = LivePlayerLocalize(@"LivePusherDemo.PushSetting.seidata");
        label.font = [UIFont systemFontOfSize:fontSize];
        CGFloat width = [label.text boundingRectWithSize:CGSizeMake(1000, 20) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:fontSize]} context:nil].size.width;
        [self.contentView addSubview:label];
        [label mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self.typeText.mas_right).offset(5);
            make.top.bottom.equalTo(self.contentView);
            make.width.mas_equalTo(width + 2);
        }];
        label;
    });
    
    self.sendButton = ({
        UIButton *btn = [self createCellButtonWithTitle:LivePlayerLocalize(@"LivePusherDemo.CameraPush.send")];
        [btn addTarget:self action:@selector(onClickSendButton:) forControlEvents:UIControlEventTouchUpInside];
        [self.contentView addSubview:btn];
        [btn mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerY.equalTo(self.contentView);
            make.right.equalTo(self.contentView.mas_right).offset(-12);
            make.height.mas_equalTo(30);
            make.width.mas_equalTo(60);
        }];
        btn;
    });
    
    self.messageText = ({
        UITextField *textF = [self createTextFieldWithDelegate:self];
        [self.contentView addSubview:textF];
        [textF mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerY.equalTo(self.contentView);
            make.trailing.equalTo(self.sendButton.mas_leading).offset(-5);
            make.left.equalTo(self.dataLabel.mas_right);
            make.height.equalTo(self.typeText);
        }];
        textF;
    });

}

///

- (UILabel *)createTitleLabel {
    UILabel *label  = [[UILabel alloc] init];
    label.font      = [UIFont systemFontOfSize:15 weight:UIFontWeightMedium];
    return label;
}

- (UIButton *)createCellButtonWithTitle:(NSString *)title {
    UIButton *button         = [UIButton buttonWithType:UIButtonTypeCustom];
    button.contentEdgeInsets = UIEdgeInsetsMake(0, 10, 0, 10);

    [button setTitle:title forState:UIControlStateNormal];
    button.titleLabel.font = [UIFont systemFontOfSize:15];
    [button setBackgroundImage:[[UIImage imageWithColor:UIColorFromRGB(0x2364db) size:CGSizeMake(10, 10) cornerRadius:4] stretchableImageWithLeftCapWidth:5 topCapHeight:5]
                    forState:UIControlStateNormal];
    [button setBackgroundImage:[[UIImage imageWithColor:UIColorFromRGB(0x1C3496) size:CGSizeMake(10, 10) cornerRadius:4] stretchableImageWithLeftCapWidth:5 topCapHeight:5]
                    forState:UIControlStateHighlighted];

    [button mas_makeConstraints:^(MASConstraintMaker *make) {
        make.height.mas_equalTo(30);
    }];
    return button;
}

- (UITextField *)createTextFieldWithDelegate:(id<UITextFieldDelegate>)delegate {
    UITextField *textField    = [[UITextField alloc] init];
    textField.borderStyle     = UITextBorderStyleRoundedRect;
    textField.backgroundColor = UIColorFromRGB(0x0D2C5B);
    textField.textColor       = UIColorFromRGB(0x939393);
    textField.font            = [UIFont systemFontOfSize:15];
    textField.delegate        = delegate;
    return textField;
}

- (void)setSEIPayloadType:(NSInteger)type msg:(NSString *)msg {
    self.typeText.text = [NSString stringWithFormat:@"%ld", type];
    self.messageText.text = msg;
}

#pragma mark - action

- (void)onClickSendButton:(UIButton *)btn {
    
    [self endEditing:YES];
    NSInteger type = [self.typeText.text integerValue];
    if ([self.delegate respondsToSelector:@selector(onSend:seiMessagePayloadType:msg:)]) {
        [self.delegate onSend:self seiMessagePayloadType:(int)type msg:self.messageText.text];
    }
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

@end
