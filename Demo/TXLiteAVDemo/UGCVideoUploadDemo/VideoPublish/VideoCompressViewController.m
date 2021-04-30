//
//  VideoCompressViewController.m
//  TXLiteAVDemo_Enterprise
//
//  Created by xiang zhang on 2018/3/29.
//  Copyright © 2018年 Tencent. All rights reserved.
//

#import "VideoCompressViewController.h"
#import "VideoCompressPreviewController.h"
#import "TXVideoEditer.h"
#import "ColorMacro.h"
#import "UIView+Additions.h"
#import "AppDelegate.h"
#import "AppLocalized.h"

@interface VideoCompressViewController ()<TXVideoGenerateListener,UITextFieldDelegate>

@end

@implementation VideoCompressViewController
{
    UIButton *_btnNone;
    UIButton *_btn360p;
    UIButton *_btn480p;
    UIButton *_btn540p;
    UIButton *_btn720p;
    UIButton *_generateCannelBtn;
    UIView   *_biterateView;
    UIView   *_generationView;
    UILabel  *_generationTitleLabel;
    UIProgressView *_generateProgressView;
    UITextField *_biterateField;
    NSString * _videoOutputPath;
    AVAssetExportSession *_exportSession;
    dispatch_source_t _timer;
    TXVideoEditer *_videoEditor;
    TXVideoCompressed _compressed;
    BOOL _generating;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.title = @"视频上传";
    UIBarButtonItem *customBackButton = [[UIBarButtonItem alloc] initWithTitle:UGCLocalize(@"UGCVideoJoinDemo.TCVideoEditPrev.back")
                                                                         style:UIBarButtonItemStylePlain
                                                                        target:self
                                                                        action:@selector(goBack)];
    customBackButton.tintColor = UIColorFromRGB(0xffffff);
    self.navigationItem.leftBarButtonItem = customBackButton;
    self.view.backgroundColor = [UIColor blackColor];
    
    int count = 5;
    CGFloat startSpace = 15 * kScaleX;
    CGFloat btnWidth = (self.view.width - startSpace * 2) / count;
    CGFloat btnHeight = 40 * kScaleY;
    
    _btnNone = [UIButton buttonWithType:UIButtonTypeCustom];
    [_btnNone setFrame:CGRectMake(startSpace, 100 * kScaleY, btnWidth, btnHeight)];
    [_btnNone setTitle:UGCLocalize(@"UGCVideoUploadDemo.VideoCompress.thereisno") forState:UIControlStateNormal];
    [_btnNone addTarget:self action:@selector(click:) forControlEvents:UIControlEventTouchUpInside];
    _btnNone.tag = 0;
    [self.view addSubview:_btnNone];
    
    _btn360p = [UIButton buttonWithType:UIButtonTypeCustom];
    [_btn360p setFrame:CGRectMake(startSpace + btnWidth, _btnNone.y, btnWidth, btnHeight)];
    [_btn360p setTitle:@"360p" forState:UIControlStateNormal];
    [_btn360p addTarget:self action:@selector(click:) forControlEvents:UIControlEventTouchUpInside];
    _btn360p.tag = 1;
    [self.view addSubview:_btn360p];
    
    _btn480p = [UIButton buttonWithType:UIButtonTypeCustom];
    [_btn480p setTitle:@"480p" forState:UIControlStateNormal];
    [_btn480p setFrame:CGRectMake(startSpace + btnWidth * 2,_btnNone.y, btnWidth, btnHeight)];
    [_btn480p addTarget:self action:@selector(click:) forControlEvents:UIControlEventTouchUpInside];
    _btn480p.tag = 2;
    [self.view addSubview:_btn480p];
    
    _btn540p = [UIButton buttonWithType:UIButtonTypeCustom];
    [_btn540p setTitle:@"540p" forState:UIControlStateNormal];
    [_btn540p setFrame:CGRectMake(startSpace + btnWidth * 3, _btnNone.y, btnWidth, btnHeight)];
    [_btn540p addTarget:self action:@selector(click:) forControlEvents:UIControlEventTouchUpInside];
    _btn540p.tag = 3;
    [self.view addSubview:_btn540p];
    
    _btn720p = [UIButton buttonWithType:UIButtonTypeCustom];
    [_btn720p setTitle:@"720p" forState:UIControlStateNormal];
    [_btn720p setFrame:CGRectMake(startSpace + btnWidth * 4, _btnNone.y, btnWidth, btnHeight)];
    [_btn720p addTarget:self action:@selector(click:) forControlEvents:UIControlEventTouchUpInside];
    _btn720p.tag = 4;
    [self.view addSubview:_btn720p];
    
    [self setBtn:_btnNone selected:YES];
    [self setBtn:_btn360p selected:NO];
    [self setBtn:_btn480p selected:NO];
    [self setBtn:_btn540p selected:NO];
    [self setBtn:_btn720p selected:NO];
    
    _biterateView = [[UIView alloc] initWithFrame:CGRectMake(15 * kScaleX, _btnNone.bottom + 50 * kScaleY, self.view.width - 30 * kScaleX, 40 * kScaleY)];
    [self.view addSubview:_biterateView];
    [self setView:_biterateView selected:YES];
    
    UILabel *biterateLabel = [[UILabel alloc] initWithFrame:CGRectMake(15 * kScaleX, 0, 120, _biterateView.height)];
    biterateLabel.text = UGCLocalize(@"UGCVideoUploadDemo.VideoCompress.kbps");
    biterateLabel.textColor = [UIColor grayColor];
    [_biterateView addSubview:biterateLabel];
    
    _biterateField = [[UITextField alloc] initWithFrame:CGRectMake(biterateLabel.right + 15 * kScaleX, 0, _biterateView.width - biterateLabel.right - 30 * kScaleX, _biterateView.height)];
    _biterateField.delegate = self;
    _biterateField.placeholder = @"600 ~ 4800";
    [_biterateField setValue:[UIColor grayColor] forKeyPath:@"placeholderLabel.textColor"];
    _biterateField.textColor = [UIColor whiteColor];
    _biterateField.textAlignment = NSTextAlignmentRight;
    _biterateField.returnKeyType = UIReturnKeyDone;
    [_biterateView addSubview:_biterateField];

    [self.view addSubview:_biterateView];
    
    UIButton *confirmBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [confirmBtn setFrame:CGRectMake(15 * kScaleX, self.view.height - 44 - 15 * kScaleY, self.view.width - 30 * kScaleX, 40 * kScaleY)];
    [confirmBtn setTitle:UGCLocalize(@"UGCKit.UGCKitWrapper.determine") forState:UIControlStateNormal];
    [confirmBtn setBackgroundColor:UIColorFromRGB(0x0BC59C)];
    [confirmBtn addTarget:self action:@selector(confirm) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:confirmBtn];
    
    [self initGeneratingView];
    
    TXPreviewParam *param = [[TXPreviewParam alloc] init];
    param.videoView = [UIView new];
    _videoEditor = [[TXVideoEditer alloc] initWithPreview:param];
    _videoEditor.generateDelegate = self;
    [_videoEditor setVideoAsset:_videoAsset];
    _videoOutputPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"outputCut.mp4"];
    
    _compressed = -1;
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center addObserver:self selector:@selector(onAppWillResignActive:) name:UIApplicationWillResignActiveNotification object:nil];
    HelpBtnUI(视频上传)
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)initGeneratingView
{
    /*用作生成时的提示浮层*/
    _generationView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.width, self.view.height + 64)];
    _generationView.backgroundColor = UIColor.blackColor;
    _generationView.alpha = 0.9f;
    _generationView.hidden = YES;
    
    _generateProgressView = [UIProgressView new];
    _generateProgressView.center = CGPointMake(_generationView.width / 2, _generationView.height / 2);
    _generateProgressView.bounds = CGRectMake(0, 0, 225, 20);
    _generateProgressView.progressTintColor = UIColorFromRGB(0x0accac);
    [_generateProgressView setTrackImage:[UIImage imageNamed:@"slide_bar_small"]];

    _generationTitleLabel = [UILabel new];
    _generationTitleLabel.font = [UIFont systemFontOfSize:14];
    _generationTitleLabel.text = UGCLocalize(@"UGCVideoUploadDemo.VideoCompress.videogeneration");
    _generationTitleLabel.textColor = UIColor.whiteColor;
    _generationTitleLabel.textAlignment = NSTextAlignmentCenter;
    _generationTitleLabel.frame = CGRectMake(0, _generateProgressView.y - 34, _generationView.width, 14);
    
    _generateCannelBtn = [UIButton new];
    [_generateCannelBtn setImage:[UIImage imageNamed:@"cancel"] forState:UIControlStateNormal];
    _generateCannelBtn.frame = CGRectMake(_generateProgressView.right + 15, _generationTitleLabel.bottom + 10, 20, 20);
    [_generateCannelBtn addTarget:self action:@selector(onGenerateCancelBtnClicked:) forControlEvents:UIControlEventTouchUpInside];
    
    [_generationView addSubview:_generationTitleLabel];
    [_generationView addSubview:_generateProgressView];
    [_generationView addSubview:_generateCannelBtn];
    [self.view addSubview:_generationView];
    _generateProgressView.progress = 0.f;
}

-(void)onGenerateCancelBtnClicked:(UIButton *)btn{
    _generationView.hidden = YES;
    _generateProgressView.progress = 0;
    _generating = NO;
    [_videoEditor cancelGenerate];
    if(_timer) dispatch_cancel(_timer);
    if(_exportSession) {
        [_exportSession cancelExport];
        _exportSession = nil;
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:NO];
}

-(void)goBack{
    [self.navigationController popViewControllerAnimated:YES];
}

-(void)confirm{
    _generationView.hidden = NO;
    if (_compressed >= 0 || _biterateField.text.length > 0) {
        int bitrate = [_biterateField.text intValue];
        if (bitrate > 0) {
            [_videoEditor setVideoBitrate:MAX(600, MIN(4800, bitrate))];
        }
        _generating = YES;
        [_videoEditor generateVideo:_compressed >= 0 ? _compressed : VIDEO_COMPRESSED_720P  videoOutputPath:_videoOutputPath];
    }else{
        _exportSession = [[AVAssetExportSession alloc] initWithAsset:_videoAsset presetName:AVAssetExportPresetHighestQuality];
        NSFileManager *manager = [NSFileManager defaultManager];
        NSError *error;
        if ([manager fileExistsAtPath:_videoOutputPath]) {
            BOOL success = [manager removeItemAtPath:_videoOutputPath error:&error];
            if (success) {
                NSLog(@"Already exist. Removed!");
            }
        }
        NSURL *outputURL = [NSURL fileURLWithPath:_videoOutputPath];
        _exportSession.outputURL = outputURL;
        _exportSession.outputFileType = AVFileTypeMPEG4;
        [_exportSession exportAsynchronouslyWithCompletionHandler:^{
            dispatch_cancel(_timer);
            if(_exportSession.status == AVAssetExportSessionStatusCompleted){
                dispatch_async(dispatch_get_main_queue(), ^(void) {
                    _generationView.hidden = YES;
                    _generateProgressView.progress = 0;
                    VideoCompressPreviewController *vc = [[VideoCompressPreviewController alloc] init];
                    vc.videoPath = _videoOutputPath;
                    [self.navigationController pushViewController:vc animated:YES];
                });
            }else if(_exportSession.status == AVAssetExportSessionStatusFailed){
                dispatch_async(dispatch_get_main_queue(), ^(void) {
                    //系统函数导出失败，通过videoEditor导出
                    _generateProgressView.progress = 0;
                    _generating = YES;
                    [_videoEditor generateVideo:VIDEO_COMPRESSED_720P  videoOutputPath:_videoOutputPath];
                });
            }
        }];
        _timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_main_queue());
        dispatch_source_set_timer(_timer, DISPATCH_TIME_NOW, 0.1 * NSEC_PER_SEC, 0);
        dispatch_source_set_event_handler(_timer, ^{
            _generateProgressView.progress = _exportSession.progress;
        });
        dispatch_resume(_timer);
    }
}

-(void)click:(UIButton *)btn
{
    switch (btn.tag) {
        case 0:
        {
            [self setBtn:_btnNone selected:YES];
            [self setBtn:_btn360p selected:NO];
            [self setBtn:_btn480p selected:NO];
            [self setBtn:_btn540p selected:NO];
            [self setBtn:_btn720p selected:NO];
            _compressed = -1;
        }
            break;
        case 1:
        {
            [self setBtn:_btnNone selected:NO];
            [self setBtn:_btn360p selected:YES];
            [self setBtn:_btn480p selected:NO];
            [self setBtn:_btn540p selected:NO];
            [self setBtn:_btn720p selected:NO];
            _compressed = VIDEO_COMPRESSED_360P;
        }
            break;
        case 2:
        {
            [self setBtn:_btnNone selected:NO];
            [self setBtn:_btn360p selected:NO];
            [self setBtn:_btn480p selected:YES];
            [self setBtn:_btn540p selected:NO];
            [self setBtn:_btn720p selected:NO];
            _compressed = VIDEO_COMPRESSED_480P;
        }
            break;
        case 3:
        {
            [self setBtn:_btnNone selected:NO];
            [self setBtn:_btn360p selected:NO];
            [self setBtn:_btn480p selected:NO];
            [self setBtn:_btn540p selected:YES];
            [self setBtn:_btn720p selected:NO];
            _compressed = VIDEO_COMPRESSED_540P;
        }
            break;
        case 4:
        {
            [self setBtn:_btnNone selected:NO];
            [self setBtn:_btn360p selected:NO];
            [self setBtn:_btn480p selected:NO];
            [self setBtn:_btn540p selected:NO];
            [self setBtn:_btn720p selected:YES];
            _compressed = VIDEO_COMPRESSED_720P;
        }
            break;
        default:
            break;
    }
}

-(void)setBtn:(UIButton *)btn selected:(BOOL)selected
{
    if (selected) {
        [btn setTitleColor:UIColorFromRGB(0x0ACCAC) forState:UIControlStateNormal];
        btn.layer.borderWidth = 0.5;
        btn.layer.borderColor = UIColorFromRGB(0x0ACCAC).CGColor;
    }else{
        [btn setTitleColor:UIColorFromRGB(0xFFFFFF) forState:UIControlStateNormal];
        btn.layer.borderWidth = 0.5;
        btn.layer.borderColor = UIColorFromRGB(0x999999).CGColor;
    }
}

-(void)setView:(UIView *)view selected:(BOOL)selected
{
    if (selected) {
        view.layer.borderWidth = 0.5;
        view.layer.borderColor = UIColorFromRGB(0x0ACCAC).CGColor;
    }else{
        view.layer.borderWidth = 0.5;
        view.layer.borderColor = UIColorFromRGB(0x999999).CGColor;
    }
}

#pragma mark TXVideoGenerateListener
-(void) onGenerateProgress:(float)progress
{
    _generateProgressView.progress = progress;
}

-(void) onGenerateComplete:(TXGenerateResult *)result
{
    _generating = NO;
    _generationView.hidden = YES;
    _generateProgressView.progress = 0;
    if (result.retCode == GENERATE_RESULT_OK){
        VideoCompressPreviewController *vc = [[VideoCompressPreviewController alloc] init];
        vc.videoPath = _videoOutputPath;
        [self.navigationController pushViewController:vc animated:YES];
    }
    else {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:UGCLocalize(@"UGCVideoUploadDemo.VideoCompress.videogenerationerror")
                                                            message:
                                  LocalizeReplace(UGCLocalize(@"UGCVideoJoinDemo.TCVideoEditPrev.errorcodexxerrormsgyy"), [NSString stringWithFormat:@"%ld",(long)result.retCode], [NSString stringWithFormat:@"%@",result.descMsg])
                                                           delegate:self
                                                  cancelButtonTitle: UGCLocalize(@"UGCVideoRecordDemo.VideoRecordConfig.knowed")
                                                  otherButtonTitles:nil, nil];
        [alertView show];
    }
}

- (void)onAppWillResignActive:(NSNotification*)notification {
    if (_generating) {
        [_videoEditor cancelGenerate];
        _generating = NO;    
        _generateProgressView.progress = 0;
        _generationView.hidden = YES;
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:UGCLocalize(@"UGCVideoUploadDemo.VideoCompress.videogenerationstop")
                                                            message:UGCLocalize(@"UGCVideoUploadDemo.VideoCompress.zipingshouldinfront")
                                                           delegate:self
                                                  cancelButtonTitle:UGCLocalize(@"UGCVideoRecordDemo.VideoRecordConfig.knowed")
                                                  otherButtonTitles:nil, nil];
        [alertView show];
    }
}

#pragma mark UITextFieldDelegate
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

@end
