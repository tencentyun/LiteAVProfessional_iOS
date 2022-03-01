//
//  CameraStartPushAlertView.m
//  TXLiteAVDemo
//
//  Created by adams on 2021/7/20.
//  Copyright © 2021 Tencent. All rights reserved.
//

#import "CameraStartPushAlertView.h"

#import <Masonry.h>

#import "AppLocalized.h"
#import "ColorMacro.h"

@interface                                  CameraStartPushAlertView ()
@property(nonatomic, strong) UIView *       containerView;
@property(nonatomic, strong) UILabel *      titleLabel;
@property(nonatomic, strong) UIButton *     rtmpBtn;
@property(nonatomic, strong) UIButton *     rtcBtn;
@property(nonatomic, strong) UITextView *   descView;
@property(nonatomic, strong) UIButton *     generateBtn;
@property(nonatomic, copy) GenerateCallback generateCallback;
@property(nonatomic, assign) PushType       pushType;
@end

@implementation CameraStartPushAlertView

#pragma mark - lazy property

- (UIView *)containerView {
    if (!_containerView) {
        _containerView                 = [[UIView alloc] initWithFrame:CGRectZero];
        _containerView.backgroundColor = UIColor.clearColor;
    }
    return _containerView;
}

- (UILabel *)titleLabel {
    if (!_titleLabel) {
        _titleLabel                           = [[UILabel alloc] initWithFrame:CGRectZero];
        _titleLabel.text                      = V2Localize(@"MLVB.CameraStartPush.ChoosePushProtocol");
        _titleLabel.font                      = [UIFont fontWithName:@"PingFangSC-Semibold" size:18];
        _titleLabel.adjustsFontSizeToFitWidth = true;
        _titleLabel.textAlignment             = NSTextAlignmentCenter;
        _titleLabel.textColor                 = UIColor.whiteColor;
    }
    return _titleLabel;
}

- (UIButton *)rtmpBtn {
    if (!_rtmpBtn) {
        _rtmpBtn = [[UIButton alloc] initWithFrame:CGRectZero];
        [_rtmpBtn setTitle:@"RTMP" forState:UIControlStateNormal];
        [_rtmpBtn setImage:[UIImage imageNamed:@"checkbox_nor"] forState:UIControlStateNormal];
        [_rtmpBtn setImage:[UIImage imageNamed:@"checkbox_sel"] forState:UIControlStateSelected];
        [_rtmpBtn setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
        [_rtmpBtn setImageEdgeInsets:UIEdgeInsetsMake(0, -10, 0, 0)];
        _rtmpBtn.selected                             = YES;
        _rtmpBtn.titleLabel.font                      = [UIFont fontWithName:@"PingFangSC-Semibold" size:16];
        _rtmpBtn.titleLabel.adjustsFontSizeToFitWidth = YES;
        [_rtmpBtn addTarget:self action:@selector(rtmpBtnClick:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _rtmpBtn;
}

- (UIButton *)rtcBtn {
    if (!_rtcBtn) {
        _rtcBtn = [[UIButton alloc] initWithFrame:CGRectZero];
        [_rtcBtn setTitle:@"RTC" forState:UIControlStateNormal];
        [_rtcBtn setImage:[UIImage imageNamed:@"checkbox_nor"] forState:UIControlStateNormal];
        [_rtcBtn setImage:[UIImage imageNamed:@"checkbox_sel"] forState:UIControlStateSelected];
        [_rtcBtn setImageEdgeInsets:UIEdgeInsetsMake(0, -10, 0, 0)];
        [_rtcBtn setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
        _rtcBtn.titleLabel.font                      = [UIFont fontWithName:@"PingFangSC-Semibold" size:16];
        _rtcBtn.titleLabel.adjustsFontSizeToFitWidth = YES;
        [_rtcBtn addTarget:self action:@selector(rtcBtnClick:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _rtcBtn;
}

- (UITextView *)descView {
    if (!_descView) {
        _descView                   = [[UITextView alloc] initWithFrame:CGRectZero];
        _descView.text              = @"RTC协议为腾讯云自研实时音视频协议,超低延迟、抗弱网能力强,全球覆盖适用于电商秒杀,体育赛事等多个场景,更多细节详见:https://cloud.tencent.com/document/product/454/56598";
        _descView.dataDetectorTypes = UIDataDetectorTypeLink;
        _descView.textColor         = UIColorFromRGB(0x7699A5);
        _descView.textAlignment     = NSTextAlignmentLeft;
        [_descView setEditable:false];
        [_descView setSelectable:true];
        _descView.showsVerticalScrollIndicator = false;
        _descView.backgroundColor              = UIColor.clearColor;
    }
    return _descView;
}

- (UIButton *)generateBtn {
    if (!_generateBtn) {
        _generateBtn = [[UIButton alloc] initWithFrame:CGRectZero];
        [_generateBtn setTitle:V2Localize(@"MLVB.CameraStartPush.Generate") forState:UIControlStateNormal];
        _generateBtn.titleLabel.font                      = [UIFont fontWithName:@"PingFangSC-Semibold" size:16];
        _generateBtn.titleLabel.adjustsFontSizeToFitWidth = true;
        _generateBtn.titleLabel.numberOfLines             = 2;
        _generateBtn.titleLabel.textAlignment             = NSTextAlignmentCenter;
        [_generateBtn addTarget:self action:@selector(generateBtnClick:) forControlEvents:UIControlEventTouchUpInside];
        _generateBtn.layer.cornerRadius = 2;
        _generateBtn.backgroundColor    = UIColorFromRGB(0x0062E3);
    }
    return _generateBtn;
}

#pragma mark setter
- (void)setPushType:(PushType)pushType {
    _pushType = pushType;
    switch (pushType) {
        case RTMP: {
            _rtmpBtn.selected = true;
            _rtcBtn.selected  = false;
            break;
        }
        case RTC: {
            _rtmpBtn.selected = false;
            _rtcBtn.selected  = true;
            break;
        }
        default:
            break;
    }
}

#pragma mark - init
- (instancetype)initWithFrame:(CGRect)frame generateCallback:(GenerateCallback)callback {
    if (self = [super initWithFrame:frame]) {
        self.generateCallback = callback;
        [self setupView];
        self.pushType = RTMP;
    }
    return self;
}

- (void)setupView {
    self.containerView.backgroundColor   = UIColorFromRGB(0x18182E);
    self.containerView.layer.borderColor = UIColorFromRGB(0x20206A).CGColor;
    self.containerView.layer.borderWidth = 1;

    [self addSubview:self.containerView];

    [self.containerView addSubview:self.titleLabel];

    UIView *btnContainerView         = [[UIView alloc] initWithFrame:CGRectZero];
    btnContainerView.backgroundColor = UIColor.clearColor;
    [self.containerView addSubview:btnContainerView];
    [btnContainerView addSubview:self.rtmpBtn];
    [btnContainerView addSubview:self.rtcBtn];

    [self.containerView addSubview:self.descView];
    [self.containerView addSubview:self.generateBtn];

    [self.containerView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.mas_centerX);
        make.centerY.equalTo(self.mas_centerY);
        make.size.mas_equalTo(CGSizeMake(305, 240));
    }];

    [self.titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.containerView.mas_left).offset(10);
        make.right.equalTo(self.containerView.mas_right).offset(-10);
        make.top.equalTo(self.containerView.mas_top).offset(10);
    }];

    [btnContainerView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.containerView.mas_centerX);
        make.top.equalTo(self.titleLabel.mas_bottom).offset(26);
    }];

    [self.rtmpBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(btnContainerView.mas_left);
        make.top.equalTo(btnContainerView.mas_top);
        make.bottom.equalTo(btnContainerView.mas_bottom);
        make.width.mas_equalTo(90);
    }];

    [self.rtcBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(btnContainerView.mas_top);
        make.bottom.equalTo(btnContainerView.mas_bottom);
        make.right.equalTo(btnContainerView.mas_right);
        make.left.equalTo(self.rtmpBtn.mas_right).offset(30);
        make.width.mas_equalTo(90);
    }];

    [self.descView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(btnContainerView.mas_bottom).offset(10);
        make.left.equalTo(self.containerView.mas_left).offset(11);
        make.right.equalTo(self.containerView.mas_right).offset(-11);
        make.height.mas_equalTo(68);
    }];

    [self.generateBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.containerView.mas_centerX);
        make.top.equalTo(self.descView.mas_bottom).offset(18);
        make.width.mas_equalTo(143);
        make.bottom.equalTo(self.containerView.mas_bottom).offset(-19);
    }];
}

#pragma mark - public method
- (void)show {
    [UIView animateWithDuration:0.35
                     animations:^{
                         self.alpha = 1;
                     }];
}

- (void)hide {
    [UIView animateWithDuration:0.35
                     animations:^{
                         self.alpha = 0;
                     }];
}

#pragma mark - Event
- (void)generateBtnClick:(UIButton *)sender {
    if (self.generateCallback) {
        self.generateCallback(self.pushType);
        [self hide];
    }
}

- (void)rtmpBtnClick:(UIButton *)sender {
    self.pushType = RTMP;
}

- (void)rtcBtnClick:(UIButton *)sender {
    self.pushType = RTC;
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    UITouch *touch  = [touches.allObjects lastObject];
    BOOL     result = [touch.view isDescendantOfView:self.containerView];
    if (!result) {
        [self hide];
    }
}

@end
