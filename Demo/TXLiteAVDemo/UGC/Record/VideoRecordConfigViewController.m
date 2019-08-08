//
//  VideoRecordConfigViewController.m
//  TXLiteAVDemo
//
//  Created by zhangxiang on 2017/9/12.
//  Copyright © 2017年 Tencent. All rights reserved.
//

#import "VideoRecordConfigViewController.h"
#import "TXColor.h"

#ifdef ENABLE_UGC
#import "AppDelegate.h"
#ifndef UGC_SMART
#import "VideoEditViewController.h"
#endif
#import "VideoRecordViewController.h"
#import "VideoPreviewViewController.h"
#endif

@interface VideoRecordConfigViewController ()<UITextFieldDelegate>
@property (weak, nonatomic) IBOutlet UIButton *btn11;
@property (weak, nonatomic) IBOutlet UIButton *btn43;
@property (weak, nonatomic) IBOutlet UIButton *btn169;
@property (weak, nonatomic) IBOutlet UIButton *btnLow;
@property (weak, nonatomic) IBOutlet UIButton *btnMedium;
@property (weak, nonatomic) IBOutlet UIButton *btnHigh;
@property (weak, nonatomic) IBOutlet UIButton *btnCustom;
@property (weak, nonatomic) IBOutlet UIButton *btn360p;
@property (weak, nonatomic) IBOutlet UIButton *btn540p;
@property (weak, nonatomic) IBOutlet UIButton *btn720p;
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
    VideoRecordConfig *_videoConfig;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    _textFieldKbps.delegate = self;
    _textFieldFps.delegate = self;
    _textFieldDuration.delegate = self;
    _videoConfig = [[VideoRecordConfig alloc] init];
    if ([UIDevice currentDevice].systemVersion.floatValue < 11) {
        self.backButtonTop.constant += 19;
    }
    [self setBtn:_btn11 selected:NO];
    [self setBtn:_btn43 selected:NO];
    [self setBtn:_btn169 selected:YES];
    [self setBtn:_btnLow selected:NO];
    [self setBtn:_btnMedium selected:YES];
    [self setBtn:_btnHigh selected:NO];
    [self setBtn:_btnCustom selected:NO];
    [self setBtn:_btnResolution selected:NO];
    [self setBtn:_btn360p selected:NO];
    [self setBtn:_btn540p selected:YES];
    [self setBtn:_btn720p selected:NO];
    [self setView:_viewKbps selected:NO];
    [self setView:_viewFps selected:NO];
    [self setView:_viewDuration selected:NO];
    [self setBtnEnable:NO];
    
    [self onClickMedium:nil];
    
    [_btnResolution setTitleColor:TXColor.grayBorder forState:UIControlStateNormal];
#ifdef HelpBtnUI   
    // SDK Demo的帮助按钮
    HelpBtnConfig(self.helpButton, 视频录制)
    __weak __typeof(self) wself = self;
    self.onTapStart = ^(VideoRecordConfig *configure) {
        VideoRecordViewController *vc = [[VideoRecordViewController alloc] initWithConfigure:configure];
        vc.onRecordCompleted = ^(TXUGCRecordResult *result) {
#ifdef UGC_SMART
            const BOOL enableEdit = NO;
            void (^onEdit)(VideoPreviewViewController *previewVC) = nil;
#else
            const BOOL enableEdit = YES;
            void (^onEdit)(VideoPreviewViewController*) = ^(VideoPreviewViewController *previewVC){
                VideoEditViewController *vc = [[VideoEditViewController alloc] init];
                [vc setVideoPath:result.videoPath];
                [previewVC.navigationController pushViewController:vc animated:YES];
            };
#endif
            VideoPreviewViewController* previewController = [[VideoPreviewViewController alloc]
                                                             initWithCoverImage:result.coverImage
                                                             videoPath:result.videoPath
                                                             renderMode:RENDER_MODE_FILL_EDGE
                                                             showEditButton:enableEdit];
            previewController.onTapEdit = onEdit;
            UINavigationController* nav = [[UINavigationController alloc] initWithRootViewController:previewController];
            [wself presentViewController:nav animated:YES completion:nil];
        };
        [wself.navigationController pushViewController:vc animated:YES];
    };
#else
    [self.helpButton removeFromSuperview];
#endif
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

- (IBAction)onClick11:(id)sender {
    [self setBtn:_btn11 selected:YES];
    [self setBtn:_btn43 selected:NO];
    [self setBtn:_btn169 selected:NO];
    _videoConfig.videoRatio = VIDEO_ASPECT_RATIO_1_1;
}

- (IBAction)onClick43:(id)sender {
    [self setBtn:_btn11 selected:NO];
    [self setBtn:_btn43 selected:YES];
    [self setBtn:_btn169 selected:NO];
    _videoConfig.videoRatio = VIDEO_ASPECT_RATIO_3_4;
}

- (IBAction)onClick169:(id)sender {
    [self setBtn:_btn11 selected:NO];
    [self setBtn:_btn43 selected:NO];
    [self setBtn:_btn169 selected:YES];
    _videoConfig.videoRatio = VIDEO_ASPECT_RATIO_9_16;
}

- (IBAction)onClickLow:(id)sender {
    [self setBtn:_btnLow selected:YES];
    [self setBtn:_btnMedium selected:NO];
    [self setBtn:_btnHigh selected:NO];
    [self setBtn:_btnCustom selected:NO];
    _videoConfig.bps = 2400;
    _videoConfig.fps = 30;
    _videoConfig.gop = 3;
    _textFieldKbps.text = [@(_videoConfig.bps) stringValue];
    _textFieldFps.text = [@(_videoConfig.fps) stringValue];
    _textFieldDuration.text = [@(_videoConfig.gop) stringValue];
    [self setBtnEnable:NO];
    [self onClick360:nil];
}

- (IBAction)onClickMedium:(id)sender {
    [self setBtn:_btnLow selected:NO];
    [self setBtn:_btnMedium selected:YES];
    [self setBtn:_btnHigh selected:NO];
    [self setBtn:_btnCustom selected:NO];
    [self setView:_viewKbps selected:NO];
    [self setView:_viewFps selected:NO];
    [self setView:_viewDuration selected:NO];
    [self setBtnEnable:NO];
    [self onClick540:nil];
    _videoConfig.bps = 6500;
    _videoConfig.fps = 30;
    _videoConfig.gop = 3;
    _textFieldKbps.text = [@(_videoConfig.bps) stringValue];
    _textFieldFps.text = [@(_videoConfig.fps) stringValue];
    _textFieldDuration.text = [@(_videoConfig.gop) stringValue];
}

- (IBAction)onClickHigh:(id)sender {
    [self setBtn:_btnLow selected:NO];
    [self setBtn:_btnMedium selected:NO];
    [self setBtn:_btnHigh selected:YES];
    [self setBtn:_btnCustom selected:NO];
    [self setView:_viewKbps selected:NO];
    [self setView:_viewFps selected:NO];
    [self setView:_viewDuration selected:NO];
    [self setBtnEnable:NO];
    [self onclick720:nil];
    _videoConfig.bps = 9600;
    _videoConfig.fps = 30;
    _videoConfig.gop = 3;
    _textFieldKbps.text = [@(_videoConfig.bps) stringValue];
    _textFieldFps.text = [@(_videoConfig.fps) stringValue];
    _textFieldDuration.text = [@(_videoConfig.gop) stringValue];
}

- (IBAction)onclickCustom:(id)sender {
    [self setBtn:_btnLow selected:NO];
    [self setBtn:_btnMedium selected:NO];
    [self setBtn:_btnHigh selected:NO];
    [self setBtn:_btnCustom selected:YES];
    [self setBtn:_btn360p selected:NO];
    [self setBtn:_btn540p selected:YES];
    [self setBtn:_btn720p selected:NO];
    [self setView:_viewKbps selected:YES];
    [self setView:_viewFps selected:NO];
    [self setView:_viewDuration selected:NO];
    [self setBtnEnable:YES];
    _textFieldKbps.text = @"600 ~ 12000";
    _textFieldFps.text = @"15 ~ 30";
    _textFieldDuration.text = @"1 ~ 10";
    _videoConfig.bps = 2400;
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
}

- (IBAction)onClick360:(id)sender {
    [self setBtn:_btn360p selected:YES];
    [self setBtn:_btn540p selected:NO];
    [self setBtn:_btn720p selected:NO];
    _videoConfig.videoResolution = VIDEO_RESOLUTION_360_640;
}

- (IBAction)onClick540:(id)sender {
    [self setBtn:_btn360p selected:NO];
    [self setBtn:_btn540p selected:YES];
    [self setBtn:_btn720p selected:NO];    _videoConfig.videoResolution = VIDEO_RESOLUTION_540_960;
}

- (IBAction)onclick720:(id)sender {
    [self setBtn:_btn360p selected:NO];
    [self setBtn:_btn540p selected:NO];
    [self setBtn:_btn720p selected:YES];
    _videoConfig.videoResolution = VIDEO_RESOLUTION_720_1280;
}

- (IBAction)onClickAEC:(UISwitch *)sender {
    _videoConfig.enableAEC = sender.isOn;
    NSString *titie = sender.on ? @"开启回声消除，可以录制人声，BGM，人声+BGM （注意：录制中开启回声消除，BGM的播放模式是手机通话模式，这个模式下系统静音会失效，而视频播放预览走的是媒体播放模式，播放模式的不同会导致录制和预览在相同系统音量下播放声音大小有一定区别）" : @"关闭回声消除，可以录制人声、BGM，耳机模式下可以录制人声 + BGM ，外放模式下不能录制人声+BGM";
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"温馨提示" message:titie delegate:sender cancelButtonTitle:@"知道了" otherButtonTitles:nil, nil];
    [alert show];
}

- (IBAction)onClick1080P:(UISwitch *)sender {
    if (sender.isOn) {
        _videoConfig.bps = 9600;
        _videoConfig.fps = 30;
        _videoConfig.gop = 3;
        _videoConfig.videoResolution = VIDEO_RESOLUTION_1080_1920;
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
    _videoConfig.bps = [_textFieldKbps.text intValue];
    _videoConfig.fps = [_textFieldFps.text intValue];
    _videoConfig.gop = [_textFieldDuration.text intValue];
    [_textFieldKbps resignFirstResponder];
    [_textFieldFps resignFirstResponder];
    [_textFieldDuration resignFirstResponder];
    return YES;
}

@end
　
