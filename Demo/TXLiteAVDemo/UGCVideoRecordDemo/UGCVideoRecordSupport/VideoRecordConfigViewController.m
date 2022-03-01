//
//  VideoRecordConfigViewController.m
//  TXLiteAVDemo
//
//  Created by zhangxiang on 2017/9/12.
//  Copyright © 2017年 Tencent. All rights reserved.
//

#import "VideoRecordConfigViewController.h"
#import "TXColor.h"
#import "AppLocalized.h"

#ifdef ENABLE_UGC
#import "AppDelegate.h"
#import "VideoPreviewViewController.h"
#endif

@interface VideoRecordConfigViewController ()<UITextFieldDelegate>
@property (strong, nonatomic) IBOutletCollection(UIButton) NSArray<UIButton*> *ratioButtons;
@property (weak, nonatomic) IBOutlet UIButton *btnLow;
@property (weak, nonatomic) IBOutlet UIButton *btnMedium;
@property (weak, nonatomic) IBOutlet UIButton *btnHigh;
@property (weak, nonatomic) IBOutlet UIButton *btnCustom;
@property (weak, nonatomic) IBOutlet UIButton *btnBluelight;
@property (weak, nonatomic) IBOutlet UIButton *btn360p;
@property (weak, nonatomic) IBOutlet UIButton *btn540p;
@property (weak, nonatomic) IBOutlet UIButton *btn720p;
@property (weak, nonatomic) IBOutlet UIButton *btn1080p;
@property (weak, nonatomic) IBOutlet UITextField *textFieldKbps;
@property (weak, nonatomic) IBOutlet UITextField *textFieldFps;
@property (weak, nonatomic) IBOutlet UITextField *textFieldDuration;
@property (weak, nonatomic) IBOutlet UIButton *btnResolution;
@property (weak, nonatomic) IBOutlet UIView *viewKbps;
@property (weak, nonatomic) IBOutlet UIView *viewFps;
@property (weak, nonatomic) IBOutlet UIView *viewDuration;
@property (weak, nonatomic) IBOutlet UIButton *helpButton;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *backButtonTop;
@end

@implementation VideoRecordConfigViewController
{
    UGCKitRecordConfig *_videoConfig;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    _textFieldKbps.delegate = self;
    _textFieldFps.delegate = self;
    _textFieldDuration.delegate = self;
    _videoConfig = [[UGCKitRecordConfig alloc] init];
    if ([UIDevice currentDevice].systemVersion.floatValue < 11) {
        self.backButtonTop.constant += 19;
    }

    _videoConfig.ratio = VIDEO_ASPECT_RATIO_9_16;
    TXVideoAspectRatio ratios[] = {
        VIDEO_ASPECT_RATIO_1_1, VIDEO_ASPECT_RATIO_3_4,
        VIDEO_ASPECT_RATIO_4_3, VIDEO_ASPECT_RATIO_9_16,
        VIDEO_ASPECT_RATIO_16_9};
    for (NSInteger idx = 0; idx < self.ratioButtons.count; ++idx) {
        UIButton *btn = self.ratioButtons[idx];
        btn.tag = ratios[idx];
        if (btn.tag == _videoConfig.ratio) {
            [self setBtn:btn selected:YES];
        } else {
            [self setBtn:btn selected:NO];
        }
    };

    [self setBtn:_btnLow selected:NO];
    [self setBtn:_btnMedium selected:YES];
    [self setBtn:_btnHigh selected:NO];
    [self setBtn:_btnCustom selected:NO];
    [self setBtn:_btnResolution selected:NO];
    [self setBtn:_btn360p selected:NO];
    [self setBtn:_btn540p selected:YES];
    [self setBtn:_btn720p selected:NO];
    [self setBtn:_btn1080p selected:NO];
    [self setView:_viewKbps selected:NO];
    [self setView:_viewFps selected:NO];
    [self setView:_viewDuration selected:NO];
    [self setBtnEnable:NO];
    
    [self onClickMedium:nil];
    
    [_btnResolution setTitleColor:TXColor.grayBorder forState:UIControlStateNormal];
#ifdef HelpBtnUI   
    // SDK Demo的帮助按钮
    HelpBtnConfig(self.helpButton, 视频录制)
#else
    [self.helpButton removeFromSuperview];
#endif
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self refreshRatioBtns];
}

- (void)refreshRatioBtns
{
    for (NSInteger idx = 0; idx < self.ratioButtons.count; ++idx) {
        UIButton *btn = self.ratioButtons[idx];
        if (btn.tag == _videoConfig.ratio) {
            [self setBtn:btn selected:YES];
        } else {
            [self setBtn:btn selected:NO];
        }
    };
}

-(void)setBtn:(UIButton *)btn selected:(BOOL)selected
{
    if (selected) {
        [btn setTitleColor:TXColor.cyan forState:UIControlStateNormal];
        btn.layer.borderWidth = 0.5;
        btn.layer.borderColor = TXColor.cyan.CGColor;
    }else{
        [btn setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
        btn.layer.borderWidth = 0.5;
        btn.layer.borderColor = TXColor.grayBorder.CGColor;
    }
}
-(void)setView:(UIView *)view selected:(BOOL)selected
{
    if (selected) {
        view.layer.borderWidth = 0.5;
        view.layer.borderColor = TXColor.cyan.CGColor;
    }else{
        view.layer.borderWidth = 0.5;
        view.layer.borderColor = TXColor.grayBorder.CGColor;
    }
}

- (IBAction)popBack:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)onClickRatioButton:(id)sender {
    for (NSUInteger idx = 0; idx < self.ratioButtons.count; ++idx) {
        UIButton *btn = self.ratioButtons[idx];
        if (sender == btn) {
            [self setBtn:btn selected:YES];
            _videoConfig.ratio = btn.tag;
        } else {
            [self setBtn:btn selected:NO];
        }
    }
}

- (IBAction)onClickLow:(id)sender {
    [self setBtn:_btnLow selected:YES];
    [self setBtn:_btnMedium selected:NO];
    [self setBtn:_btnHigh selected:NO];
    [self setBtn:_btnBluelight selected:NO];
    [self setBtn:_btnCustom selected:NO];
    _videoConfig.videoBitrate = 2400;
    _videoConfig.fps = 30;
    _videoConfig.gop = 3;
    _textFieldKbps.text = [@(_videoConfig.videoBitrate) stringValue];
    _textFieldFps.text = [@(_videoConfig.fps) stringValue];
    _textFieldDuration.text = [@(_videoConfig.gop) stringValue];
    [self setBtnEnable:NO];
    [self onClick360:nil];
}

- (IBAction)onClickMedium:(id)sender {
    [self setBtn:_btnLow selected:NO];
    [self setBtn:_btnMedium selected:YES];
    [self setBtn:_btnHigh selected:NO];
    [self setBtn:_btnBluelight selected:NO];
    [self setBtn:_btnCustom selected:NO];
    [self setView:_viewKbps selected:NO];
    [self setView:_viewFps selected:NO];
    [self setView:_viewDuration selected:NO];
    [self setBtnEnable:NO];
    [self onClick540:nil];
    _videoConfig.videoBitrate = 6500;
    _videoConfig.fps = 30;
    _videoConfig.gop = 3;
    _textFieldKbps.text = [@(_videoConfig.videoBitrate) stringValue];
    _textFieldFps.text = [@(_videoConfig.fps) stringValue];
    _textFieldDuration.text = [@(_videoConfig.gop) stringValue];
}

- (IBAction)onClickHigh:(id)sender {
    [self setBtn:_btnLow selected:NO];
    [self setBtn:_btnMedium selected:NO];
    [self setBtn:_btnHigh selected:YES];
    [self setBtn:_btnBluelight selected:NO];
    [self setBtn:_btnCustom selected:NO];
    [self setView:_viewKbps selected:NO];
    [self setView:_viewFps selected:NO];
    [self setView:_viewDuration selected:NO];
    [self setBtnEnable:NO];
    [self onclick720:nil];
    _videoConfig.videoBitrate = 9600;
    _videoConfig.fps = 30;
    _videoConfig.gop = 3;
    _textFieldKbps.text = [@(_videoConfig.videoBitrate) stringValue];
    _textFieldFps.text = [@(_videoConfig.fps) stringValue];
    _textFieldDuration.text = [@(_videoConfig.gop) stringValue];
}

- (IBAction)onClickBlueLight:(id)sender {
    [self setBtn:_btnLow selected:NO];
    [self setBtn:_btnMedium selected:NO];
    [self setBtn:_btnHigh selected:NO];
    [self setBtn:_btnBluelight selected:YES];
    [self setBtn:_btnCustom selected:NO];
    [self setView:_viewKbps selected:NO];
    [self setView:_viewFps selected:NO];
    [self setView:_viewDuration selected:NO];
    [self setBtnEnable:NO];
    [self onclick1080:nil];
    _videoConfig.videoBitrate = 13000;
    _videoConfig.fps = 30;
    _videoConfig.gop = 3;
    _textFieldKbps.text = [@(_videoConfig.videoBitrate) stringValue];
    _textFieldFps.text = [@(_videoConfig.fps) stringValue];
    _textFieldDuration.text = [@(_videoConfig.gop) stringValue];
}


- (IBAction)onclickCustom:(id)sender {
    [self setBtn:_btnLow selected:NO];
    [self setBtn:_btnMedium selected:NO];
    [self setBtn:_btnHigh selected:NO];
    [self setBtn:_btnBluelight selected:NO];
    [self setBtn:_btnCustom selected:YES];
    [self setBtn:_btn360p selected:NO];
    [self setBtn:_btn540p selected:YES];
    [self setBtn:_btn720p selected:NO];
    [self setBtn:_btn1080p selected:NO];
    [self setView:_viewKbps selected:YES];
    [self setView:_viewFps selected:NO];
    [self setView:_viewDuration selected:NO];
    [self setBtnEnable:YES];
    _textFieldKbps.text = @"600 ~ 12000";
    _textFieldFps.text = @"15 ~ 30";
    _textFieldDuration.text = @"1 ~ 10";
    _videoConfig.videoBitrate = 2400;
    _videoConfig.fps = 20;
    _videoConfig.gop = 3;
}

-(void)setBtnEnable:(BOOL)enabled
{
    _textFieldKbps.enabled = enabled;
    _textFieldFps.enabled = enabled;
    _textFieldDuration.enabled = enabled;
    _btn360p.enabled = enabled;
    _btn540p.enabled = enabled;
    _btn720p.enabled = enabled;
    _btn1080p.enabled = enabled;
}

- (IBAction)onClick360:(id)sender {
    [self setBtn:_btn360p selected:YES];
    [self setBtn:_btn540p selected:NO];
    [self setBtn:_btn720p selected:NO];
    [self setBtn:_btn1080p selected:NO];
    _videoConfig.resolution = VIDEO_RESOLUTION_360_640;
}

- (IBAction)onClick540:(id)sender {
    [self setBtn:_btn360p selected:NO];
    [self setBtn:_btn540p selected:YES];
    [self setBtn:_btn720p selected:NO];
    [self setBtn:_btn1080p selected:NO];
    _videoConfig.resolution = VIDEO_RESOLUTION_540_960;
}

- (IBAction)onclick720:(id)sender {
    [self setBtn:_btn360p selected:NO];
    [self setBtn:_btn540p selected:NO];
    [self setBtn:_btn720p selected:YES];
    [self setBtn:_btn1080p selected:NO];
    _videoConfig.resolution = VIDEO_RESOLUTION_720_1280;
}

- (IBAction)onclick1080:(id)sender {
    [self setBtn:_btn360p selected:NO];
    [self setBtn:_btn540p selected:NO];
    [self setBtn:_btn720p selected:NO];
    [self setBtn:_btn1080p selected:YES];
    _videoConfig.resolution = VIDEO_RESOLUTION_1080_1920;
}

- (IBAction)onClickAEC:(UISwitch *)sender {
    _videoConfig.AECEnabled = sender.isOn;
    NSString *titie = sender.on ? UGCLocalize(@"UGCVideoRecordDemo.VideoRecordConfig.openechocancellation") :
    UGCLocalize(@"UGCVideoRecordDemo.VideoRecordConfig.closeechocancellation");
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:UGCLocalize(@"UGCVideoRecordDemo.VideoRecordConfig.warmreminder") message:titie delegate:sender cancelButtonTitle:UGCLocalize(@"UGCVideoRecordDemo.VideoRecordConfig.knowed") otherButtonTitles:nil, nil];
    [alert show];
}

- (IBAction)onClick1080P:(UISwitch *)sender {
    if (sender.isOn) {
        _videoConfig.videoBitrate = 9600;
        _videoConfig.fps = 30;
        _videoConfig.gop = 3;
        _videoConfig.resolution = VIDEO_RESOLUTION_1080_1920;
    }
}

- (IBAction)startRecord:(id)sender {
    if (self.onTapStart) {
        self.onTapStart(_videoConfig);
    }
}

#pragma mark UITextFieldDelegate
- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    if ([textField isEqual:_textFieldKbps]) {
        [self setView:_viewKbps selected:YES];
        [self setView:_viewFps selected:NO];
        [self setView:_viewDuration selected:NO];
        _textFieldKbps.text = @"";
    }
    else if ([textField isEqual:_textFieldFps]){
        [self setView:_viewKbps selected:NO];
        [self setView:_viewFps selected:YES];
        [self setView:_viewDuration selected:NO];
        _textFieldFps.text = @"";
    }
    else if ([textField isEqual:_textFieldDuration]){
        [self setView:_viewKbps selected:NO];
        [self setView:_viewFps selected:NO];
        [self setView:_viewDuration selected:YES];
        _textFieldDuration.text = @"";
    }
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    _videoConfig.videoBitrate = [_textFieldKbps.text intValue];
    _videoConfig.fps = [_textFieldFps.text intValue];
    _videoConfig.gop = [_textFieldDuration.text intValue];
    [_textFieldKbps resignFirstResponder];
    [_textFieldFps resignFirstResponder];
    [_textFieldDuration resignFirstResponder];
    return YES;
}

@end

