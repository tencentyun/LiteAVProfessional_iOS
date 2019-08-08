//
//  ImageUploadViewController.m
//  TXLiteAVDemo
//
//  Created by lijie on 2019/4/17.
//  Copyright © 2019年 Tencent. All rights reserved.
//

#import "ImageUploadViewController.h"
#import "ColorMacro.h"
#import "UIView+Additions.h"
#import "AppDelegate.h"
#import "TCHttpUtil.h"
#import "TXUGCPublish.h"

@interface ImageUploadViewController() <TXMediaPublishListener>

@end

@implementation ImageUploadViewController
{
    NSString * _imageOutputPath;
    TXUGCPublish *_imagePublish;
    UIImageView *_imageView;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"图片上传";
    UIBarButtonItem *customBackButton = [[UIBarButtonItem alloc] initWithTitle:@"返回"
                                                                         style:UIBarButtonItemStylePlain
                                                                        target:self
                                                                        action:@selector(goBack)];
    customBackButton.tintColor = UIColorFromRGB(0xffffff);
    self.navigationItem.leftBarButtonItem = customBackButton;
    self.view.backgroundColor = [UIColor blackColor];

    UIButton *confirmBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [confirmBtn setFrame:CGRectMake(15 * kScaleX, self.view.height - 44 - 15 * kScaleY, self.view.width - 30 * kScaleX, 40 * kScaleY)];
    [confirmBtn setTitle:@"确定" forState:UIControlStateNormal];
    [confirmBtn setBackgroundColor:UIColorFromRGB(0x0BC59C)];
    [confirmBtn addTarget:self action:@selector(confirm) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:confirmBtn];
    
    _imageView = [[UIImageView alloc] initWithFrame:CGRectMake(10 * kScaleX, 40 * kScaleY, self.view.width - 20 * kScaleX, self.view.height - 100 * kScaleY)];
    [self.view addSubview:_imageView];
    if ([_images count] > 0) {
        [_imageView setImage:_images[0]];
    }
    
    _imageOutputPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"output.jpeg"];
    _imagePublish = [[TXUGCPublish alloc] initWithUserID:@"customID"];
    _imagePublish.mediaDelegate = self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)goBack {
    [self dismissViewControllerAnimated:YES completion:^{
        //to do
    }];
}

- (void)confirm {
    if ([_images count] == 0) {
        return;
    }
    
    UIImage *img = _images[0];
    [UIImageJPEGRepresentation(img, 0) writeToFile:_imageOutputPath atomically:YES];
    
    [self publish:_imageOutputPath];
}

- (void)publish:(NSString *)imagePath {
    __weak __typeof(self) weakSelf = self;
    [TCHttpUtil asyncSendHttpRequest:@"api/v1/misc/upload/signature" httpServerAddr:kHttpUGCServerAddr HTTPMethod:@"GET" param:nil handler:^(int result, NSDictionary *resultDict) {
        __strong __typeof(weakSelf) self = weakSelf;
        if (self == nil) {
            return;
        }
        
        if (result == 0 && resultDict){
            NSDictionary *dataDict = resultDict[@"data"];
            if (dataDict && imagePath) {
                TXMediaPublishParam *publishParam = [[TXMediaPublishParam alloc] init];
                publishParam.signature  = dataDict[@"signature"];
                publishParam.mediaPath  = imagePath;
                publishParam.fileName   = @"testname";
                
                [self->_imagePublish publishMedia:publishParam];
            }
        } else{
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"图片上传失败"
                                                                message:[NSString stringWithFormat:@"错误码：%d",result]
                                                               delegate:self
                                                      cancelButtonTitle:@"知道了"
                                                      otherButtonTitles:nil, nil];
            [alertView show];
        }
    }];
}

#pragma mark - TXMediaPublishListener

- (void)onMediaPublishProgress:(NSInteger)uploadBytes totalBytes: (NSInteger)totalBytes {
    NSLog(@"onMediaPublishProgress: uploadBytes[%ld] totalBytes[%ld]", uploadBytes, totalBytes);
}

- (void)onMediaPublishComplete:(TXMediaPublishResult*)result {
    if (result.retCode == 0) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"图片上传成功"
                                                            message:[NSString stringWithFormat:@"错误码：%d",result.retCode]
                                                           delegate:self
                                                  cancelButtonTitle:@"知道了"
                                                  otherButtonTitles:nil, nil];
        [alertView show];
    } else {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"图片上传失败"
                                                            message:[NSString stringWithFormat:@"错误码：%d",result.retCode]
                                                           delegate:self
                                                  cancelButtonTitle:@"知道了"
                                                  otherButtonTitles:nil, nil];
        [alertView show];
    }
    
    [self goBack];
}

- (void)onMediaPublishEvent:(NSDictionary*)evt {
    
}

@end
