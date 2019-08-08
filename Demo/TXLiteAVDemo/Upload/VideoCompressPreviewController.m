//
//  VideoCompressPreviewController.m
//  TXLiteAVDemo
//
//  Created by xiang zhang on 2018/3/30.
//  Copyright © 2018年 Tencent. All rights reserved.
//

#import "VideoCompressPreviewController.h"
#import "MoviePlayerViewController.h"
#import "TXVideoEditer.h"
#import "TXUGCPublish.h"
#import "ColorMacro.h"
#import "UIView+Additions.h"
#import "TCHttpUtil.h"

@interface VideoCompressPreviewController ()<TXVideoPreviewListener,TXVideoPublishListener,UITextFieldDelegate>

@end

@implementation VideoCompressPreviewController
{
    UIView *_videoPreview;
    UITextField *_videoTitleField;
    UIImageView *_videoCover;
    UIImage *_coverImage;
    UIView * _generationView;
    UIProgressView *_generateProgressView;
    UILabel *_generationTitleLabel;
    UIButton *_generateCannelBtn;
    TXVideoEditer *_videoEditer;
    TXVideoInfo *_videoInfo;
    TXUGCPublish *_videoPublish;
    BOOL _cancelPublish;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"预览";
    UIBarButtonItem *customBackButton = [[UIBarButtonItem alloc] initWithTitle:@"返回"
                                                                         style:UIBarButtonItemStylePlain
                                                                        target:self
                                                                        action:@selector(goBack)];
    customBackButton.tintColor = UIColorFromRGB(0xffffff);
    self.navigationItem.leftBarButtonItem = customBackButton;
    self.view.backgroundColor = [UIColor blackColor];
    
    _videoInfo = [TXVideoInfoReader getVideoInfo:_videoPath];
    CGFloat top = [UIApplication sharedApplication].statusBarFrame.size.height + self.navigationController.navigationBar.height;
    _videoPreview = [[UIView alloc] initWithFrame:CGRectMake(0, top, self.view.width, 200 * kScaleY)];
    _videoPreview.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    TXPreviewParam *param = [[TXPreviewParam alloc] init];
    param.videoView = _videoPreview;
    param.renderMode = PREVIEW_RENDER_MODE_FILL_EDGE;
    _videoEditer = [[TXVideoEditer alloc] initWithPreview:param];
    _videoEditer.previewDelegate = self;
    [_videoEditer setVideoPath:_videoPath];
    
    UILabel *titieLabel = [[UILabel alloc] initWithFrame:CGRectMake(15 * kScaleX, _videoPreview.bottom + 10 * kScaleY, 80 * kScaleX, 40 * kScaleY)];
    titieLabel.text = @"标题：";
    titieLabel.textColor = [UIColor whiteColor];
    _videoTitleField = [[UITextField alloc] initWithFrame:CGRectMake(titieLabel.right + 10 * kScaleX, titieLabel.y, self.view.width - titieLabel.right - 30 * kScaleX, titieLabel.height)];
    _videoTitleField.textColor = [UIColor whiteColor];
    _videoTitleField.placeholder = @"设置标题...";
//    _videoTitleField.placeholder = [NSString stringWithFormat:@"当前视频码率：%d",[TXVideoInfoReader getVideoInfo:_videoPath].bitrate];
    [_videoTitleField setValue:[UIColor grayColor] forKeyPath:@"placeholderLabel.textColor"];
    _videoTitleField.delegate = self;
    _videoTitleField.returnKeyType = UIReturnKeyDone;
    
    UILabel *coverLabel = [[UILabel alloc] initWithFrame:CGRectMake(15 * kScaleX, _videoPreview.bottom + 120 * kScaleY, 80 * kScaleX, 40 * kScaleY)];
    coverLabel.text = @"封面：";
    coverLabel.textColor = [UIColor whiteColor];
    _videoCover = [[UIImageView alloc] initWithFrame:CGRectMake(titieLabel.right + 10 * kScaleX, titieLabel.bottom + 10 * kScaleY, self.view.width - coverLabel.right - 50 * kScaleX , 200 * kScaleY)];
    _videoCover.contentMode = UIViewContentModeScaleAspectFit;
    _coverImage = _videoInfo.coverImage;
    [_videoCover setImage:_coverImage];
    
    UIButton *publishBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [publishBtn setFrame:CGRectMake(15 * kScaleX, self.view.height - 44 - 15 * kScaleY, self.view.width - 30 * kScaleX, 40 * kScaleY)];
    [publishBtn setTitle:@"发布" forState:UIControlStateNormal];
    [publishBtn setBackgroundColor:UIColorFromRGB(0x0BC59C)];
    [publishBtn addTarget:self action:@selector(publish) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:publishBtn];
    
    [self.view addSubview:_videoPreview];
    [self.view addSubview:titieLabel];
    [self.view addSubview:_videoTitleField];
    [self.view addSubview:coverLabel];
    [self.view addSubview:_videoCover];
    [self.view addSubview:publishBtn];
    [self initGeneratingView];
    
    _videoPublish = [[TXUGCPublish alloc] initWithUserID:@"customID"];
    _videoPublish.delegate = self;
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
    //_generateProgressView.trackTintColor = UIColor.whiteColor;
    //_generateProgressView.transform = CGAffineTransformMakeScale(1.0, 2.0);
    
    _generationTitleLabel = [UILabel new];
    _generationTitleLabel.font = [UIFont systemFontOfSize:14];
    _generationTitleLabel.text = @"视频上传中";
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

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
     self.navigationController.navigationBar.hidden = NO;
    [_videoEditer startPlayFromTime:0 toTime:_videoInfo.duration];
}

- (void)goBack
{
    [_videoEditer stopPlay];
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)publish {
    _cancelPublish = NO;
    _generationView.hidden = NO;
    [_videoEditer stopPlay];
    [TCHttpUtil asyncSendHttpRequest:@"api/v1/misc/upload/signature" httpServerAddr:kHttpUGCServerAddr HTTPMethod:@"GET" param:nil handler:^(int result, NSDictionary *resultDict) {
        if (result == 0 && resultDict){
            NSDictionary *dataDict = resultDict[@"data"];
            if (dataDict && _videoPublish) {
                TXPublishParam *publishParam = [[TXPublishParam alloc] init];
                publishParam.signature  = dataDict[@"signature"];
                publishParam.coverPath = [self getCoverPath:_coverImage];
                publishParam.videoPath  = _videoPath;
                publishParam.fileName   = _videoTitleField.text;
                if (!_cancelPublish) {
                    [_videoPublish publishVideo:publishParam];
                }
            }
        }else{
            _generationView.hidden = YES;
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"视频上传失败"
                                                                message:[NSString stringWithFormat:@"错误码：%d",result]
                                                               delegate:self
                                                      cancelButtonTitle:@"知道了"
                                                      otherButtonTitles:nil, nil];
            [alertView show];
        }
    }];
}

-(void)onGenerateCancelBtnClicked:(UIButton *)btn
{
    _cancelPublish = YES;
    _generationView.hidden = YES;
    _generateProgressView.progress = 0;
    
    //在分片上传的过程中，canclePublish 会取消下个上传的分片，当前正在上传的分片暂时无法取消，当视频比较短，只有一个分片正在上传的时候，canclePublish会无法生效
    [_videoPublish canclePublish];
    [_videoEditer startPlayFromTime:0 toTime:_videoInfo.duration];
}

#pragma mark TXVideoPreviewListener
-(void) onPreviewProgress:(CGFloat)time
{
    //to do
}

-(void) onPreviewFinished
{
     [_videoEditer startPlayFromTime:0 toTime:_videoInfo.duration];
}

#pragma mark TXVideoPublishListener
-(void) onPublishProgress:(NSInteger)uploadBytes totalBytes: (NSInteger)totalBytes
{
    if (!_cancelPublish) {
        _generateProgressView.progress = (float)uploadBytes / totalBytes;
    }
}

-(void) onPublishComplete:(TXPublishResult*)result
{
    if(!_cancelPublish){
        if(result.retCode == 0){
            //同步给业务server
            NSString *videoUrl = result.videoURL;
            [TCHttpUtil asyncSendHttpRequest:[NSString stringWithFormat:@"api/v1/resource/videos/%@",result.videoId] httpServerAddr:kHttpUGCServerAddr HTTPMethod:@"PUT" param:nil handler:^(int result, NSDictionary *resultDict) {
                MoviePlayerViewController *vc = [MoviePlayerViewController new];
                vc.videoURL = videoUrl;
                [self.navigationController pushViewController:vc animated:YES];
                _generationView.hidden = YES;
                _generateProgressView.progress = 0;
            }];
        }else{
            _generationView.hidden = YES;
            _generateProgressView.progress = 0;
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"视频上传失败"
                                                                message:[NSString stringWithFormat:@"错误信息：%@",result.descMsg]
                                                               delegate:self
                                                      cancelButtonTitle:@"知道了"
                                                      otherButtonTitles:nil, nil];
            [alertView show];
        }
    }
}

-(void) onPublishEvent:(NSDictionary*)evt
{
    //to do
}

-(NSString *)getCoverPath:(UIImage *)coverImage
{
    UIImage *image = coverImage;
    if (image == nil) {
        return nil;
    }
    
    NSString *coverPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"TXUGC"];
    coverPath = [coverPath stringByAppendingPathComponent:[self getFileNameByTimeNow:@"TXUGC" fileType:@"jpg"]];
    if (coverPath) {
        // 保证目录存在
        [[NSFileManager defaultManager] createDirectoryAtPath:[coverPath stringByDeletingLastPathComponent]
                                  withIntermediateDirectories:YES
                                                   attributes:nil
                                                        error:nil];
        
        [UIImageJPEGRepresentation(image, 1.0) writeToFile:coverPath atomically:YES];
    }
    return coverPath;
}

-(NSString *)getFileNameByTimeNow:(NSString *)type fileType:(NSString *)fileType {
    NSTimeInterval now = [[NSDate date] timeIntervalSince1970];
    NSDateFormatter * formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyyMMdd_HHmmss"];
    NSDate * NowDate = [NSDate dateWithTimeIntervalSince1970:now];
    ;
    NSString * timeStr = [formatter stringFromDate:NowDate];
    NSString *fileName = ((fileType == nil) ||
                          (fileType.length == 0)
                          ) ? [NSString stringWithFormat:@"%@_%@",type,timeStr] : [NSString stringWithFormat:@"%@_%@.%@",type,timeStr,fileType];
    return fileName;
}

#pragma mark UITextFieldDelegate
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

@end
