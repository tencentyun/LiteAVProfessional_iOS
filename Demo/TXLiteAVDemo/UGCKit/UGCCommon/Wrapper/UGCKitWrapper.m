//  Copyright © 2019 Tencent. All rights reserved.

#import "UGCKitWrapper.h"

#import <CoreServices/CoreServices.h>
#import "VideoCompressViewController.h"

#import "MBProgressHUD.h"
#import "TXUGCPublish.h"
#import "PhotoUtil.h"
#import "TXLiteAVSDKHeader.h"
#import "VideoPreviewViewController.h"
#import "VideoJoinerController.h"
#import "SuperPlayer.h"
#import "VideoRecordConfigViewController.h"

typedef UINavigationController TCNavigationController;

typedef NS_ENUM(NSInteger, TCVideoAction) {
    TCVideoActionCancel,
    TCVideoActionSave,
    TCVideoActionSaveWithTwoPass,
    TCVideoActionSaveGIF
};

@interface UGCKitWrapper () <TXVideoPublishListener> {
    UGCKitTheme   *_theme;
    MBProgressHUD *_videoPublishHUD;
    TXUGCPublish  *_videoPublish;
    NSString      *_videoPublishPath;
}
@property (assign, nonatomic) TCVideoAction actionAfterSave;
@property (weak, nonatomic) UIViewController *viewController;
@end

@implementation UGCKitWrapper
- (instancetype)initWithViewController:(UIViewController *)viewController theme:(UGCKitTheme *)theme
{
    if (self = [super init]) {
        _viewController = viewController;
        _theme = theme ?: [[UGCKitTheme alloc] init];

        UIColor *cyanColor = [UIColor colorWithRed:11.f/255.f
                                             green:204.f/255.f
                                              blue:172.f/255.f
                                             alpha:1.0];
        _theme.beautyPanelSelectionColor = cyanColor;
        _theme.nextIcon = [UIImage imageNamed: @"nextIcon"];
        _theme.beautyPanelMenuSelectionBackgroundImage = [UIImage imageNamed:@"beauty_selection_bg"];
        _theme.recordButtonTapModeIcon = [UIImage imageNamed:@"start_record"];
        _theme.recordButtonPauseInnerIcon = [UIImage imageNamed:@"start_record"];
        _theme.editCutSliderLeftIcon = [UIImage imageNamed:@"left"];
        _theme.editCutSliderRightIcon = [UIImage imageNamed:@"right"];
        _theme.editMusicSliderLeftIcon = [UIImage imageNamed:@"audio_left"];
        _theme.editMusicSliderRightIcon = [UIImage imageNamed:@"audio_right"];
        _theme.editMusicSliderBorderColor = _theme.editCutSliderBorderColor = cyanColor;
        _theme.sliderThumbImage = [UIImage imageNamed:@"slider"];
        _theme.sliderValueColor = _theme.beautyPanelSelectionColor;
        _theme.progressColor = cyanColor;
        _theme.sliderMinColor = cyanColor;
        _theme.editFilterSelectionIcon = [UIImage imageNamed:@"editFilterSelectionIcon"];
        _theme.confirmIcon = [UIImage imageNamed:@"confirmIcon"];
        _theme.confirmHighlightedIcon = [UIImage imageNamed:@"confirmHighlightedIcon"];
        _theme.editTimelineIndicatorIcon = [UIImage imageNamed:@"editTimelineIndicatorIcon"];
    }
    return self;
}

- (NSString *)_titleForAction:(TCVideoAction)action {
    switch (action) {
        case TCVideoActionCancel:
            return NSLocalizedString(@"取消", nil);
            break;
        case TCVideoActionSave:
            return NSLocalizedString(@"普通模式", nil);
            break;
        case TCVideoActionSaveWithTwoPass:
            return NSLocalizedString(@"质量优化模式", nil);
            break;
        case TCVideoActionSaveGIF:
            return NSLocalizedString(@"转换为 GIF", nil);
            break;
        default:
            break;
    }
    return @"";
}

- (UIAlertAction *)_alertActionForAction:(TCVideoAction)action
                          editController:(UGCKitEditViewController *)editViewController
                             finishBlock:(void(^)(BOOL))finish {
    __strong __typeof(self) wself = self;
    __weak UGCKitEditViewController *weakEditController = editViewController;
    UIAlertActionStyle style = action == TCVideoActionCancel ? UIAlertActionStyleCancel :
                                                               UIAlertActionStyleDefault;
    return [UIAlertAction actionWithTitle:[self _titleForAction:action]
                                    style:style
                                  handler:^(UIAlertAction * _Nonnull _) {
        __strong __typeof(wself) self = wself; if (!self) return;
        self.actionAfterSave = action;
        weakEditController.generateMode = (action == TCVideoActionSaveWithTwoPass) ?
                                          UGCKitGenerateModeTwoPass : UGCKitGenerateModeDefault;
        finish(action != TCVideoActionCancel);
    }];
}

#pragma mark - View Controller Navigation
- (void)showRecordViewControllerWithConfig:(UGCKitRecordConfig *)config  {
    UGCKitRecordViewController *videoRecord = [[UGCKitRecordViewController alloc] initWithConfig:config
                                                                                           theme:_theme];
    __weak __typeof(self) wself = self;
    videoRecord.completion = ^(UGCKitResult *result) {
        if (result && result.code == 0 && !result.cancelled) {
            [wself showVideoPreview:result
               navigationController:wself.viewController.navigationController
                         fromRecord:YES];
        } else {
            [wself.viewController.navigationController popViewControllerAnimated:YES];
        }
    };
    [_viewController.navigationController pushViewController:videoRecord animated:YES];
}

- (void)showEditFinishOptionsWithResult:(UGCKitResult *)result
                         editController:(UGCKitEditViewController *)editViewController
                           finishBloack:(void(^)(BOOL shouldGenerate))finish {
    UIAlertController *controller = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"请选择压缩模式", nil)
                                                                        message:nil
                                                                 preferredStyle:UIAlertControllerStyleActionSheet];
    [controller addAction:[self _alertActionForAction:TCVideoActionSave
                                       editController:editViewController
                                          finishBlock:finish]];
    [controller addAction:[self _alertActionForAction:TCVideoActionSaveWithTwoPass
                                          editController:editViewController
                                          finishBlock:finish]];
    [controller addAction:[self _alertActionForAction:TCVideoActionSaveGIF
                                          editController:editViewController
                                          finishBlock:finish]];
    [controller addAction:[self _alertActionForAction:TCVideoActionCancel
                                          editController:editViewController
                                          finishBlock:finish]];

    [editViewController presentViewController:controller animated:YES completion:nil];
}


- (void)showEditViewController:(UGCKitResult *)result
                      rotation:(TCEditRotation)rotation
        inNavigationController:(UINavigationController *)nav
                      backMode:(TCBackMode)backMode {
    UGCKitMedia *media = result.media;
    UGCKitEditConfig *config = [[UGCKitEditConfig alloc] init];
    config.rotation = (TCEditRotation)(rotation / 90);

    UIImage *tailWatermarkImage = [UIImage imageNamed:@"tcloud_logo"];
    TXVideoInfo *info = [TXVideoInfoReader getVideoInfoWithAsset:media.videoAsset];
    float w = 0.15;
    float x = (1.0 - w) / 2.0;
    float width = w * info.width;
    float height = width * tailWatermarkImage.size.height / tailWatermarkImage.size.width;
    float y = (info.height - height) / 2 / info.height;
    config.tailWatermark = [UGCKitWatermark watermarkWithImage:tailWatermarkImage
                                                     frame:CGRectMake(x, y, w, 0)
                                                  duration:2];
    if (media.videoAsset == nil) {
        [self showAlert:@"提示" message:@"视屏资源文件有误,请重试"];
        return;
    }
    __weak __typeof(self) wself = self;
    UGCKitEditViewController *vc = [[UGCKitEditViewController alloc] initWithMedia:media
                                                                            config:config
                                                                             theme:_theme];
    __weak UGCKitEditViewController *weakEditController = vc;
    __weak UINavigationController *weakNav = nav;
    vc.onTapNextButton = ^(void (^finish)(BOOL)) {
        [wself showEditFinishOptionsWithResult:result
                                editController:weakEditController
                                  finishBloack:finish];
    };

    vc.completion = ^(UGCKitResult *result) {
        __strong __typeof(wself) self = wself; if (self == nil) { return; }
        if (result.cancelled) {
            if (backMode == TCBackModePop)  {
                [weakNav popViewControllerAnimated:YES];
            } else {
                [self->_viewController dismissViewControllerAnimated:YES completion:nil];
            }
        } else {
            if (result.code == 0) {
                switch(self.actionAfterSave) {
                    case TCVideoActionSave: case TCVideoActionSaveWithTwoPass:
                        [wself showVideoPreview:result
                           navigationController:weakNav
                                     fromRecord:NO];
                        break;
                    case TCVideoActionSaveGIF: {
                        NSString *tempPath =
                        [NSTemporaryDirectory() stringByAppendingPathComponent:@"outputCut.gif"];
                        [wself _convertVideo:result.media.videoAsset
                                 toGIFAtPath:tempPath
                              editController:weakEditController];
                    }   break;
                    default:
                        break;
                }
            } else {
                [self showAlert:@"生成失败" message:result.info[NSLocalizedDescriptionKey]];
            }
        }
        [[NSUserDefaults standardUserDefaults] setObject:nil forKey:CACHE_PATH_LIST];
    };
    [nav pushViewController:vc animated:YES];
}

- (void)showVideoPreview:(UGCKitResult *)result
    navigationController:(UINavigationController *)navigationController
              fromRecord:(BOOL)fromRecord {
    TXVideoInfo *videoInfo = [TXVideoInfoReader getVideoInfo:result.media.videoPath];
    VideoPreviewViewController* controller =
        [[VideoPreviewViewController alloc] initWithCoverImage:videoInfo.coverImage
                                                     videoPath:result.media.videoPath
                                                    renderMode:RENDER_MODE_FILL_EDGE
                                                showEditButton:fromRecord];
    if (fromRecord) {
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:controller];
        nav.modalPresentationStyle = UIModalPresentationFullScreen;
        __weak __typeof(self) wself = self;
        __weak UINavigationController *weakNav = nav;
        controller.onTapEdit = ^(VideoPreviewViewController *previewController) {
            [wself showEditViewController:result
                                 rotation:TCEditRotation0
                   inNavigationController:weakNav
                                 backMode:TCBackModePop];
        };
        [navigationController presentViewController:nav
                                                               animated:YES
                                                             completion:nil];
    } else {
        [navigationController pushViewController:controller
                                                            animated:YES];
    }
}

#pragma mark - Util
-(void)_convertVideo:(AVAsset *)asset
         toGIFAtPath:(NSString *)outputPath
      editController:(UGCKitEditViewController *)editController  {
    CFURLRef url = CFURLCreateWithFileSystemPath (kCFAllocatorDefault,
                                                  (CFStringRef)outputPath,
                                                  kCFURLPOSIXPathStyle,
                                                  false);


    __block int picCount = 20;
    __weak __typeof(self) wself = self;
    NSMutableArray *picArr = [NSMutableArray arrayWithCapacity:picCount];

    MBProgressHUD *hud = [MBProgressHUD HUDForView:editController.view];
    if (!hud) {
        hud = [MBProgressHUD showHUDAddedTo:editController.view animated:YES];
    }
    hud.label.text = NSLocalizedString(@"GIF 生成中", nil);
    hud.mode = MBProgressHUDModeIndeterminate;
    [hud showAnimated:YES];

    CGImageDestinationRef destination = CGImageDestinationCreateWithURL(url,
                                                                        kUTTypeGIF,
                                                                        picArr.count,
                                                                        NULL);
    CFRelease(url);

    //设置gif的信息,播放间隔时间,基本数据,和delay时间
    NSDictionary *frameProperties = @{
        (NSString *)kCGImagePropertyGIFDictionary: @{
                (NSString *)kCGImagePropertyGIFDelayTime: @(0.001f)
        }
    };

    //设置gif信息
    NSDictionary *gifProperties = @{
        (NSString *)kCGImagePropertyGIFDictionary: @{
                (NSString*)kCGImagePropertyGIFHasGlobalColorMap: @YES,
                (NSString *)kCGImagePropertyColorModel: (NSString *)kCGImagePropertyColorModelRGB,
                (NSString*)kCGImagePropertyDepth: @8,
                (NSString *)kCGImagePropertyGIFLoopCount: @0
        }
    };
    CGImageDestinationSetProperties(destination, (__bridge CFDictionaryRef)gifProperties);

    [TXVideoInfoReader getSampleImages:picCount videoAsset:asset progress:^BOOL(int number, UIImage *image) {
        if (image == nil){
            picCount--;
        }else{
            CGImageDestinationAddImage(destination,
                                       image.CGImage,
                                       (__bridge CFDictionaryRef)frameProperties);
            [picArr addObject:image];
        }
        if (picArr.count >= picCount) {
            //合成gif
            CGImageDestinationFinalize(destination);
            CFRelease(destination);

            NSData *data = [NSData dataWithContentsOfFile:outputPath];
            [PhotoUtil saveDataToAlbum:data
                            completion:^(BOOL success, NSError * _Nullable error) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [hud hideAnimated:YES];
                    UIAlertController *alertController = nil;
                    if (success) {
                        alertController = [wself _alertWithTitle:NSLocalizedString(@"GIF 生成成功，已经保存到系统相册，请前往系统相册查看", nil)
                                                         message:nil];
                    } else {
                        alertController = [wself _alertWithTitle:NSLocalizedString(@"GIF 保存失败", nil)
                                                         message:nil];
                    }
                    [editController presentViewController:alertController
                                                 animated:YES
                                               completion:nil];
                });
            }];
        }
        return YES;
    }];
}

#pragma mark - Video Uploader
- (void)showVideoUploader:(UGCKitResult *)result
   inNavigationController:(UINavigationController *)navigationController
{
    VideoCompressViewController *viewController = [[VideoCompressViewController alloc] init];
    viewController.videoAsset = [result.media videoAsset];
    [navigationController pushViewController:viewController animated:YES];
}

#pragma mark - Video Combine
- (void)showCombineViewController:(NSArray<AVAsset *> *)assets
           inNavigationController:(UINavigationController *)navigationController {
    VideoJoinerController *vc = [VideoJoinerController new];
    vc.videoAssertList = assets;
    [navigationController pushViewController:vc animated:YES];
}

#pragma mark - Alerting
- (UIAlertController *)_alertWithTitle:(NSString *)title message:(NSString *)message {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title
                                                                             message:message
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"确定", nil)
                                                        style:UIAlertActionStyleCancel
                                                      handler:nil]];
    return alertController;
}
- (void)showAlert:(NSString *)title message:(NSString *)message {
    UIAlertController *alertController = [self _alertWithTitle:title message:message];
    [_viewController presentViewController:alertController animated:YES completion:nil];
}

#pragma mark - Entry
- (void)_showVideoCutView:(UGCKitResult *)result
   inNavigationController:(UINavigationController *)nav {
    UGCKitCutViewController *vc = [[UGCKitCutViewController alloc] initWithMedia:result.media
                                                                           theme:self.theme];
    __weak __typeof(self) wself = self;
    vc.completion = ^(UGCKitResult *result, int rotation) {
        if ([result isCancelled]) {
            [wself.viewController dismissViewControllerAnimated:YES completion:nil];
        } else {
            [wself showEditViewController:result
                                 rotation:rotation
                   inNavigationController:nav
                                 backMode:TCBackModePop];
        }
    };
    [nav pushViewController:vc animated:YES];
}

- (void)showEditEntryControllerWithType:(UGCKitMediaType)type;
{
    UGCKitMediaPickerConfig *config = [[UGCKitMediaPickerConfig alloc] init];
    config.mediaType = type;
    config.minItemCount = (type == UGCKitMediaTypePhoto ? 3 : 1);
    config.maxItemCount = NSUIntegerMax;
    UGCKitMediaPickerViewController *imagePickerController =
        [[UGCKitMediaPickerViewController alloc] initWithConfig:config theme:self.theme];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:imagePickerController];
    nav.modalPresentationStyle = UIModalPresentationFullScreen;
    __weak __typeof(self) wself = self;
    imagePickerController.completion = ^(UGCKitResult *result) {
        if (!result.cancelled && result.code == 0) {
            [wself.viewController dismissViewControllerAnimated:YES completion:^{
                [wself _showVideoCutView:result inNavigationController:wself.viewController.navigationController];
            }];
        } else {
            NSLog(@"isCancelled: %c, failed: %@",
                  result.cancelled ? 'y' : 'n',
                  result.info[NSLocalizedDescriptionKey]);
            [wself.viewController dismissViewControllerAnimated:YES completion:^{
                if (result.code != 0) {
                    [self showAlert:@"操作失败"
                            message:result.info[NSLocalizedDescriptionKey]];
                }
            }];
        }
    };
    [self _hideSuperPlayer];
    [self.viewController presentViewController:nav animated:YES completion:NULL];
}

- (void)showVideoJoinEntryController {
    UGCKitMediaPickerConfig *config = [[UGCKitMediaPickerConfig alloc] init];
    config.mediaType = UGCKitMediaTypeVideo;
    config.maxItemCount = NSUIntegerMax;
    config.combineVideos = NO;
    UGCKitMediaPickerViewController *imagePickerController =
        [[UGCKitMediaPickerViewController alloc] initWithConfig:config theme:self.theme];
    __weak UGCKitMediaPickerViewController *weakPicker = imagePickerController;
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:imagePickerController];
    nav.modalPresentationStyle = UIModalPresentationFullScreen;
    __weak UINavigationController *weakNav = nav;
    __weak __typeof(self) wself = self;
    imagePickerController.completion = ^(UGCKitResult *result) {
        if (!result.cancelled && result.code == 0) {
            [wself showCombineViewController: weakPicker.exportedAssets
                                  inNavigationController:weakNav];
        } else {
            NSLog(@"isCancelled: %c, failed: %@",
                  result.cancelled ? 'y' : 'n',
                  result.info[NSLocalizedDescriptionKey]);
            [wself.viewController dismissViewControllerAnimated:YES completion:nil];
        }
    };
    [self _hideSuperPlayer];
    [self.viewController presentViewController:nav animated:YES completion:NULL];
}

- (void)showVideoUploadEntryController
{
    UGCKitMediaPickerConfig *config = [[UGCKitMediaPickerConfig alloc] init];
    config.mediaType = UGCKitMediaTypeVideo;
    config.minItemCount = 1;
    config.maxItemCount = 1;
    UGCKitMediaPickerViewController *imagePickerController =
        [[UGCKitMediaPickerViewController alloc] initWithConfig:config theme:self.theme];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:imagePickerController];
    nav.modalPresentationStyle = UIModalPresentationFullScreen;
    __weak __typeof(self) wself = self;
    __weak UINavigationController *navigationController = self.viewController.navigationController;
    imagePickerController.completion = ^(UGCKitResult *result) {
        if (!result.cancelled && result.code == 0) {
            [wself.viewController dismissViewControllerAnimated:YES completion:^{
                [wself showVideoUploader:result inNavigationController:navigationController];
            }];
        } else {
            NSLog(@"isCancelled: %c, failed: %@",
                  result.cancelled ? 'y' : 'n',
                  result.info[NSLocalizedDescriptionKey]);
            [wself.viewController dismissViewControllerAnimated:YES completion:^{
                if (!result.cancelled) {
                    [self showAlert:@"视频上传" message:result.info[NSLocalizedDescriptionKey]];
                }
            }];
        }
    };
    [self _hideSuperPlayer];
    [self.viewController presentViewController:nav animated:YES completion:NULL];
}

- (void)showRecordEntryController {
    VideoRecordConfigViewController *configViewController = [[VideoRecordConfigViewController alloc] init];
    __weak __typeof(self) wself = self;
    configViewController.onTapStart = ^(UGCKitRecordConfig *config) {
        [wself showRecordViewControllerWithConfig:config];
    };
    [self _hideSuperPlayer];
    [self.viewController.navigationController pushViewController:configViewController
                                                        animated:YES];
}

- (void)_hideSuperPlayer {
    if (SuperPlayerWindowShared.isShowing) {
        [SuperPlayerWindowShared hide];
        [SuperPlayerWindowShared.superPlayer resetPlayer];
        SuperPlayerWindowShared.backController = nil;
    }
}

@end

