//
//  VideoEditViewController.m
//  TCLVBIMDemo
//
//  Created by xiang zhang on 2017/4/10.
//  Copyright © 2017年 tencent. All rights reserved.
//

#import "VideoEditViewController.h"
#import "TXLiteAVSDKHeader.h"
#import <MediaPlayer/MPMediaPickerController.h>
#import <MobileCoreServices/UTCoreTypes.h>
#import "VideoPreview.h"
#import "VideoRangeSlider.h"
#import "VideoRangeConst.h"
//#import "TCVideoPublishController.h"
#import "VideoPreviewViewController.h"
#import "UIView+Additions.h"
#import "TXColor.h"
#import "MBProgressHUD.h"
#import "FilterSettingView.h"
#import "BottomTabBar.h"
#import "VideoCutView.h"
#import "MusicMixView.h"
#import "PasterAddView.h"
#import "TextAddView.h"
#import "TimeSelectView.h"
#import "EffectSelectView.h"
#import "VideoTextViewController.h"
#import "VideoPasterViewController.h"
#import "TXCVEFColorPalette.h"
#import "TransitionView.h"
#import "Masonry.h"
#import "AppDelegate.h"
#import "PhotoUtil.h"

static const int ImageSlideFPS = 30;

typedef  NS_ENUM(NSInteger,ActionType)
{
    ActionType_Save,
    ActionType_Publish,
    ActionType_Save_Publish,
};

typedef  NS_ENUM(NSInteger,TimeType)
{
    TimeType_Clear,
    TimeType_Back,
    TimeType_Repeat,
    TimeType_Speed,
};

typedef  NS_ENUM(NSInteger,VideoType)
{
    VideoType_Video,
    VideoType_Picture,
};

@interface VideoEditViewController ()<TXVideoGenerateListener,VideoPreviewDelegate,TXVideoCustomProcessListener, FilterSettingViewDelegate, BottomTabBarDelegate, VideoCutViewDelegate, MusicMixViewDelegate, PasterAddViewDelegate, TextAddViewDelegate, VideoPasterViewControllerDelegate, VideoTextViewControllerDelegate,VideoEffectViewDelegate,TimeSelectViewDelegate,TransitionViewDelegate,MPMediaPickerControllerDelegate, UIActionSheetDelegate, UITabBarDelegate>
@property (strong,nonatomic) VideoPreview   *videoPreview;
@property (strong,nonatomic) TXVideoEditer  *ugcEdit;
@property (assign,nonatomic) CGFloat        duration;
@end

@implementation VideoEditViewController
{
    //裁剪时间
    CGFloat         _leftTime;
    CGFloat         _rightTime;
    
    NSMutableArray  *_cutPathList;
    NSString        *_videoOutputPath;
    NSString        *_gifOutputPath;
    ActionType      _actionType;
    
    //生成时的进度浮层
    UILabel*        _generationTitleLabel;
    UIView*         _generationView;
    UIProgressView* _generateProgressView;
    UIButton*       _generateCannelBtn;
    
    UILabel*        _cutTipsLabel;
    UIColor*        _barTintColor;
    
    BottomTabBar*       _bottomBar;     //底部栏
    UIView*             _accessoryView; //二级工具栏
    VideoCutView*       _videoCutView;  //裁剪
    FilterSettingView*  _filterView;    //滤镜
    MusicMixView*       _musixMixView;  //混音
    
    PasterAddView*      _pasterView;         //贴图
    TextAddView*        _textView;           //字幕
    TimeSelectView*     _timeSelectView;     //时间特效栏
    EffectSelectView*   _effectSelectView;   //动效选择
    TransitionView*     _transitionView;     //转场特效
    
    int                 _effectType;
    TimeType            _timeType;
    
    NSMutableArray<VideoTextInfo*>*   _videoTextInfos;   //保存己添加的字幕
    NSMutableArray<VideoPasterInfo*>* _videoPaterInfos;  //保存己添加的贴纸
    AVURLAsset*   _fileAsset;

    CGFloat _playTime;
    
    NSArray *_videoPreviewConstrains;
    MASViewAttribute *topGuide;   
    MASViewAttribute *bottomGuide;
    MASViewAttribute *leftGuide;
    MASViewAttribute *rightGuide;    
    CGFloat videoPreviewBarHeight;
    CGFloat accessoryToolHeight;
    
    BOOL  _isReverse;
    BOOL  _isBGMLoop;
    BOOL  _isFadeIn;
    BOOL  _isFadeOut;
}



-(instancetype)init
{
    self = [super init];
    if (self) {
        _cutPathList = [NSMutableArray array];
        _videoOutputPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"outputCut.mp4"];
        _gifOutputPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"outputCut.gif"];
        _videoTextInfos = [NSMutableArray new];
        _videoPaterInfos = [NSMutableArray new];
        _effectType = -1;
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.navigationController.navigationBar.translucent  =  NO;
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [_videoCutView stopGetImageList];
}

- (void)dealloc
{
    [_videoPreview removeNotification];
    if (self.removeVideoAfterFinish) {
        [[NSFileManager defaultManager] removeItemAtPath:_videoPath error:nil];
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    if (_videoAsset == nil && _videoPath != nil) {
        NSURL *avUrl = [NSURL fileURLWithPath:_videoPath];
        _videoAsset = [AVAsset assetWithURL:avUrl];
    }
    
    TXVideoInfo *videoMsg = [TXVideoInfoReader getVideoInfoWithAsset:_videoAsset];
    CGFloat duration = videoMsg.duration;
    _rightTime = duration;
    
    videoPreviewBarHeight = 100 * kScaleY;
    UILabel *barTitleLabel = [[UILabel alloc]initWithFrame:CGRectMake(0, 0 , 100, 44)];
    barTitleLabel.backgroundColor = [UIColor clearColor];
    barTitleLabel.font = [UIFont boldSystemFontOfSize:17];
    barTitleLabel.textColor = [UIColor whiteColor];
    barTitleLabel.textAlignment = NSTextAlignmentCenter;
    barTitleLabel.text = @"编辑视频";
    self.navigationItem.titleView = barTitleLabel;
    
    UIBarButtonItem *customBackButton = [[UIBarButtonItem alloc] initWithTitle:@"取消"
                                                                         style:UIBarButtonItemStylePlain
                                                                        target:self
                                                                        action:@selector(goBack)];
    self.navigationItem.leftBarButtonItem = customBackButton;
    
    
    UIBarButtonItem *saveItem = [[UIBarButtonItem alloc] initWithTitle:@"保存"
                                                                 style:UIBarButtonItemStylePlain
                                                                target:self
                                                                action:@selector(goSave)];
    
#ifdef HelpBtnUI
    HelpBtnUI(特效编辑);
    NSMutableArray *items = [self.navigationItem.rightBarButtonItems mutableCopy];
    [items insertObject:saveItem atIndex:0];
    self.navigationItem.rightBarButtonItems = items;
#else
    self.navigationItem.rightBarButtonItems = @[saveItem];
#endif
    
    self.view.backgroundColor = UIColor.blackColor;
    
    UIEdgeInsets insets = UIEdgeInsetsZero;
    id boundaryAttribute = self.view;
    
    topGuide    = self.view.mas_top;
    bottomGuide = self.view.mas_bottom;
    leftGuide   = self.view.mas_left;
    rightGuide  = self.view.mas_right;
    if (@available(iOS 11, *)) {
        boundaryAttribute = self.view.mas_safeAreaLayoutGuide;
        topGuide = self.view.mas_safeAreaLayoutGuideTop;
        bottomGuide = self.view.mas_safeAreaLayoutGuideBottom;
        leftGuide   = self.view.mas_safeAreaLayoutGuideLeft;
        rightGuide  = self.view.mas_safeAreaLayoutGuideRight;
        
        insets = [UIApplication sharedApplication].keyWindow.safeAreaInsets;
        insets.top = 0;
    }
    
    CGRect contentFrame = UIEdgeInsetsInsetRect(self.view.bounds, insets);
    
    CGFloat bottomToolHeight = round(50 * kScaleY);
    accessoryToolHeight = round([UIScreen mainScreen].bounds.size.height >= 667 ? 90 * kScaleY : 80 * kScaleY);
    
    CGRect previewFrame = contentFrame;
    previewFrame.size.height -= (bottomToolHeight + accessoryToolHeight + videoPreviewBarHeight);
    
    _videoPreview = [[VideoPreview alloc] initWithFrame:previewFrame coverImage:nil];
    _videoPreview.delegate = self;
    [self.view addSubview:_videoPreview];
    
    _videoPreviewConstrains = [_videoPreview mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.mas_equalTo(boundaryAttribute).with.insets(UIEdgeInsetsMake(0, 0, bottomToolHeight + accessoryToolHeight + videoPreviewBarHeight, 0));
    }];
    
    _bottomBar = [[BottomTabBar alloc] initWithFrame:CGRectMake(CGRectGetMinX(contentFrame), CGRectGetMaxY(contentFrame) - bottomToolHeight, CGRectGetWidth(contentFrame), bottomToolHeight)];
    _bottomBar.delegate = self;
    _bottomBar.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
    [self.view addSubview:_bottomBar];
    [_bottomBar mas_makeConstraints:^(MASConstraintMaker *make) {
        make.height.equalTo(@(bottomToolHeight));
        make.left.equalTo(leftGuide);
        make.right.equalTo(rightGuide);
        make.bottom.equalTo(bottomGuide);
    }];
    
    CGRect accessoryFrame = contentFrame;
    accessoryFrame.origin.y = _bottomBar.top - accessoryToolHeight;
    accessoryFrame.size.height = accessoryToolHeight;
    _accessoryView = [[UIView alloc] initWithFrame:accessoryFrame];
    _accessoryView.clipsToBounds = YES;
    _accessoryView.backgroundColor = [UIColor clearColor];
    _accessoryView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
    [self.view addSubview:_accessoryView];
    [_accessoryView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.height.equalTo(@(accessoryToolHeight));
        make.left.equalTo(leftGuide);
        make.right.equalTo(rightGuide);
        make.bottom.equalTo(_bottomBar.mas_top);
    }];
    
    
    CGFloat selectViewHeight = [UIScreen mainScreen].bounds.size.height >= 667 ? 90 * kScaleY : 80 * kScaleY;
    _timeSelectView = [[TimeSelectView alloc] initWithFrame:CGRectMake(0, _bottomBar.top -  selectViewHeight, self.view.width, selectViewHeight)];
    _timeSelectView.delegate = self;
    _timeSelectView.hidden = (_videoAsset == nil);
    
    _transitionView = [[TransitionView alloc] initWithFrame:CGRectMake(0, _bottomBar.top -  selectViewHeight, self.view.width, selectViewHeight)];
    _transitionView.delegate = self;
    _transitionView.hidden = (_imageList == nil);
    
    _effectSelectView = [[EffectSelectView alloc] initWithFrame:_timeSelectView.frame];
    _effectSelectView.delegate = self;
    
    _cutTipsLabel = [[UILabel alloc] initWithFrame:_accessoryView.bounds];
    _cutTipsLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _cutTipsLabel.textAlignment = NSTextAlignmentCenter;
    _cutTipsLabel.text = @"请拖拽两侧滑块选择剪裁区域";
    _cutTipsLabel.textColor = [UIColor whiteColor];
    _cutTipsLabel.font = [UIFont systemFontOfSize:16];
    [_accessoryView addSubview:_cutTipsLabel];
    
    TXPreviewParam *param = [[TXPreviewParam alloc] init];
    param.videoView = _videoPreview.renderView;
    param.renderMode = PREVIEW_RENDER_MODE_FILL_EDGE;
    _ugcEdit = [[TXVideoEditer alloc] initWithPreview:param];
    _ugcEdit.generateDelegate = self;
    _ugcEdit.videoProcessDelegate = self;
    _ugcEdit.previewDelegate = _videoPreview;
    
    //    [_ugcEdit setVideoPath:_videoPath];
    //video
    if (_videoAsset != nil) {
        int result = [_ugcEdit setVideoAsset:_videoAsset];
        if (result != 0) {
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"视频读取失败"
                                                                message:result == -1 ? @"视频文件不存在" : @"暂不支持声道数大于2的视频编辑"
                                                               delegate:self
                                                      cancelButtonTitle:@"知道了"
                                                      otherButtonTitles:nil, nil];
            [alertView show];
        }
        [self initVideoCutView:VideoType_Video];
    }
    //image
    if (_imageList != nil) {
        [_ugcEdit setPictureList:_imageList fps:ImageSlideFPS];
        [self onVideoTransitionLefRightSlipping];
    }
    [self addWaterMark:videoMsg];   
}

- (void)addWaterMark:(TXVideoInfo *)videoMsg {
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0), ^{
        CGFloat videoWidth, videoHeight;
        if (videoMsg.angle / 90 % 2 == 0) {
            videoWidth = videoMsg.width;
            videoHeight = videoMsg.height;
        } else {
            videoWidth = videoMsg.height;
            videoHeight = videoMsg.width;
        }
        
        //图片编辑，视频宽高默认设置为720 * 1280
        if (videoWidth == 0 || videoHeight == 0) {
            videoWidth = 720;
            videoHeight = 1280;
        }
        
        UIImage *cloud = [UIImage imageNamed:@"tcloud_symbol"];
        CGFloat imageWidth;
        if (videoWidth > videoHeight) {
            imageWidth = 0.08*videoHeight;
        } else {
            imageWidth = 0.08*videoWidth;
        }
        CGFloat imageHeight = imageWidth / cloud.size.width * cloud.size.height;
        
        NSDictionary *textAttribute = @{NSFontAttributeName:[UIFont boldSystemFontOfSize:imageHeight],
                                        NSForegroundColorAttributeName:[UIColor whiteColor]};
        CGSize textSize = [@"腾讯云" sizeWithAttributes:textAttribute];
        CGSize canvasSize = CGSizeMake(ceil(imageWidth + textSize.width), ceil(MAX(imageHeight,textSize.height) + imageWidth* 0.05));
        UIGraphicsBeginImageContext(canvasSize);
        [cloud drawInRect:CGRectMake(0, (canvasSize.height - imageHeight) / 2, imageWidth, imageHeight)];
        [@"腾讯云" drawAtPoint:CGPointMake(imageWidth*1.05, (canvasSize.height - textSize.height) / 2)
             withAttributes:textAttribute];
        UIImage *waterimage = UIGraphicsGetImageFromCurrentImageContext(); //[UIImage imageNamed:@"watermark"];
        UIGraphicsEndImageContext();
        
        [_ugcEdit setWaterMark:waterimage normalizationFrame:CGRectMake(0.01, 0.01, canvasSize.width / videoWidth, 0)];
        
        UIImage *tailWaterimage = [UIImage imageNamed:@"tcloud_logo"];
        float w = 0.15;
        float x = (1.0 - w) / 2.0;
        float width = w * videoWidth;
        float height = width * tailWaterimage.size.height / tailWaterimage.size.width;
        float y = (videoHeight - height) / 2 / videoHeight;
        [_ugcEdit setTailWaterMark:tailWaterimage normalizationFrame:CGRectMake(x,y,w,0) duration:2];
    });
}

- (void)initVideoCutView:(VideoType)type
{
    CGRect frame = _accessoryView.frame;
    frame.origin.y -= videoPreviewBarHeight;
    frame.size.height = videoPreviewBarHeight;
    BOOL flag = NO;
    if (type == VideoType_Video) {
        if(_videoCutView) [_videoCutView removeFromSuperview];
        _videoCutView = [[VideoCutView alloc] initWithFrame:frame videoPath:_videoPath orVideoAsset:_videoAsset];
        flag = YES;
        [self.view addSubview:_videoCutView];
    }else{
        if (_videoCutView) {
            [_videoCutView updateFrame:_duration - 1/ 30];
        }else{
            [_videoCutView removeFromSuperview];
            _videoCutView = [[VideoCutView alloc] initWithFrame:frame pictureList:_imageList duration:_duration fps:ImageSlideFPS];
            flag = YES;
            [self.view addSubview:_videoCutView];
        }
    }
    if (flag) {
        [_videoCutView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.height.equalTo(@(videoPreviewBarHeight));
            make.left.equalTo(leftGuide);
            make.right.equalTo(rightGuide);
            make.bottom.equalTo(_accessoryView.mas_top);
        }];
    }
    _videoCutView.delegate = self;
    [_videoCutView setCenterPanHidden:YES];
}

- (UIView*)generatingView
{
    /*用作生成时的提示浮层*/
    if (!_generationView) {
        _generationView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.width, self.view.height + 64)];
        _generationView.backgroundColor = UIColor.blackColor;
        _generationView.alpha = 0.9f;
        
        _generateProgressView = [UIProgressView new];
        _generateProgressView.center = CGPointMake(_generationView.width / 2, _generationView.height / 2);
        _generateProgressView.bounds = CGRectMake(0, 0, 225, 20);
        _generateProgressView.progressTintColor = TXColor.cyan;
        [_generateProgressView setTrackImage:[UIImage imageNamed:@"slide_bar_small"]];
        //_generateProgressView.trackTintColor = UIColor.whiteColor;
        //_generateProgressView.transform = CGAffineTransformMakeScale(1.0, 2.0);
        
        _generationTitleLabel = [UILabel new];
        _generationTitleLabel.font = [UIFont systemFontOfSize:14];
        _generationTitleLabel.text = @"视频生成中";
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
        [[[UIApplication sharedApplication] delegate].window addSubview:_generationView];
    }
    
    _generateProgressView.progress = 0.f;
    return _generationView;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if (!_videoPreview.isPlaying) {
        [_videoPreview playVideo];
    }
}

- (void)goBack
{
    [self pause];
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

//保存
- (void)goSave
{
    [self pause];
    
    _actionType = ActionType_Save;
    
    if (_videoCutView.coloredCount > 0) {
        // 因为有特效时画面的变动会比较大，需要适当提高码率来保证清晰度
        int fps = 30;
        if (_imageList.count > 0) {
            fps = ImageSlideFPS;
        } else {
            fps = [TXVideoInfoReader getVideoInfoWithAsset:_videoAsset].fps;
        }
        [_ugcEdit setVideoBitrate:500 + 100 * fps];
    }
    [self onVideoPause];
    [_videoPreview setPlayBtn:NO];
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"请选择压缩模式"
                                                                             message:nil 
                                                                      preferredStyle:UIAlertControllerStyleActionSheet];
    UIAlertAction *onePassAction = [UIAlertAction actionWithTitle:@"普通模式"
                                                            style:UIAlertActionStyleDefault 
                                                          handler:^(UIAlertAction * _Nonnull action) {
                                                              [self startGenerateWithTwoPassEnabled:NO];
                                                          }];
    [alertController addAction:onePassAction];
    
    if (_ugcEdit.supportsTwoPassEncoding) {
        
        UIAlertAction *twoPassAction = [UIAlertAction actionWithTitle:@"质量优化模式"
                                                                style:UIAlertActionStyleDefault 
                                                              handler:^(UIAlertAction * _Nonnull action) {
                                                                  [self startGenerateWithTwoPassEnabled:YES];
                                                              }];
        [alertController addAction:twoPassAction];
    }
    
    //视频生成GIF示例
    if (_videoAsset != nil){
        UIAlertAction *gifAction = [UIAlertAction actionWithTitle:@"原视频转换为gif"
                                                            style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction * _Nonnull action) {
                                                              [self startGenerateGif];
                                                          }];
        [alertController addAction:gifAction];
    }
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil];
    
    [alertController addAction:cancelAction];
    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)startGenerateWithTwoPassEnabled:(BOOL)twoPass
{
    [_videoPreview stopObservingAudioNotification];
    _generationView = [self generatingView];
    _generationView.hidden = NO;
    
    [_ugcEdit setCutFromTime:_leftTime toTime:_rightTime];
    [self checkVideoOutputPath];
    
    if (twoPass) {
        [_ugcEdit generateVideoWithTwoPass:VIDEO_COMPRESSED_720P videoOutputPath:_videoOutputPath];                                                              
    } else {
        [_ugcEdit generateVideo:VIDEO_COMPRESSED_720P videoOutputPath:_videoOutputPath];                                                              
    }
}

- (void)onGenerateCancelBtnClicked:(UIButton*)sender
{
    [_videoPreview startObservingAudioNotification];
    _generationView.hidden = YES;
    [_ugcEdit cancelGenerate];
}

- (void)pause
{
    [_ugcEdit pausePlay];
    [_videoPreview setPlayBtn:NO];
}

- (void)checkVideoOutputPath
{
    NSFileManager *manager = [[NSFileManager alloc] init];
    if ([manager fileExistsAtPath:_videoOutputPath]) {
        BOOL success =  [manager removeItemAtPath:_videoOutputPath error:nil];
        if (success) {
            NSLog(@"Already exist. Removed!");
        }
    }
}

#pragma mark - Lazy Loader
- (MusicMixView *)musixMixView {
    if (_musixMixView == nil) {
        _musixMixView = [[MusicMixView alloc] initWithFrame:CGRectMake(0, _videoPreview.bottom + 10 * kScaleY, self.view.width, _bottomBar.y - _videoPreview.bottom - 10 * kScaleY)];
        _musixMixView.delegate = self;
    }
    return _musixMixView;
}

- (PasterAddView *)pasterView {
    if (_pasterView == nil) {
        _pasterView = [[PasterAddView alloc] initWithFrame:CGRectMake(0, _videoPreview.bottom + 30 * kScaleY, self.view.width, _bottomBar.y - _videoPreview.bottom - 30 * kScaleY)];
        _pasterView.delegate = self;
    }
    return _pasterView;
}

- (TextAddView *)textView {
    if (_textView == nil) {
        _textView = [[TextAddView alloc] initWithFrame:CGRectMake(0, _videoPreview.bottom + 30 * kScaleY, self.view.width, _bottomBar.y - _videoPreview.bottom - 30 * kScaleY)];
        _textView.delegate = self;
    }
    return _textView;
}

#pragma mark - BottomTabBarDelegate
- (void)setAccessoryView:(UIView *)view withPreviewBarHidden:(BOOL)hidden
{
    BOOL changed = _videoCutView.hidden != hidden;
    _videoCutView.hidden = hidden;
    if (changed) {
        [_accessoryView mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.height.equalTo(@(accessoryToolHeight + (hidden ? _videoCutView.height - 5 : 0)));
            make.left.equalTo(leftGuide);
            make.right.equalTo(rightGuide);
            make.bottom.equalTo(_bottomBar.mas_top);
        }];
        [self.view layoutIfNeeded];
    }
    [_accessoryView removeAllSubViews];
    view.center = CGPointMake(CGRectGetMidX(_accessoryView.bounds), CGRectGetMidY(_accessoryView.bounds));
    [_accessoryView addSubview:view];
}

- (void)onCutBtnClicked
{
    [self setAccessoryView:_cutTipsLabel withPreviewBarHidden:NO];
    [_videoCutView setEffectDeleteBtnHidden:YES];
    [_videoPreview setBGMControlBtnHidden:YES];
}

-(void)onTimeBtnClicked
{
    [self setAccessoryView:_videoAsset == nil ? _transitionView : _timeSelectView withPreviewBarHidden:NO];
    
    [_videoCutView setEffectDeleteBtnHidden:YES];
    [_videoPreview setBGMControlBtnHidden:YES];
}

- (void)onEffectBtnClicked
{
    [self setAccessoryView:_effectSelectView withPreviewBarHidden:NO];
    [_videoCutView setEffectDeleteBtnHidden:NO];
    [_videoPreview setBGMControlBtnHidden:YES];
}

- (FilterSettingView *)filterView {
    if (_filterView == nil) {
        _filterView = [[FilterSettingView alloc] initWithFrame:CGRectMake(0, _videoPreview.bottom + 10 * kScaleY, self.view.width, _bottomBar.y - _videoPreview.bottom - 10 * kScaleY)];
        _filterView.delegate = self;
    }
    return _filterView;
}

- (void)onSetFilterWithImage:(UIImage *)image
{
    [_ugcEdit setFilter:image];
    [_videoPreview setBGMControlBtnHidden:YES];
}

- (void)onFilterBtnClicked
{
    [self setAccessoryView:self.filterView withPreviewBarHidden:YES];
    _videoCutView.videoRangeSlider.hidden = NO;
    [_videoPreview setBGMControlBtnHidden:YES];
}

- (void)onMusicBtnClicked
{
    [self setAccessoryView:self.musixMixView withPreviewBarHidden:YES];
    _videoCutView.videoRangeSlider.hidden = NO;
    [_videoPreview setBGMControlBtnHidden:NO];
}

- (void)onPasterBtnClicked
{
    [self setAccessoryView:self.pasterView withPreviewBarHidden:YES];
    _videoCutView.videoRangeSlider.hidden = NO;
    [_videoPreview setBGMControlBtnHidden:YES];
}

- (void)onTextBtnClicked
{
    [self setAccessoryView:self.textView withPreviewBarHidden:YES];
    
    //    
    //    //    [self pause];
    //    [_filterView removeFromSuperview];
    //    [_videoCutView removeFromSuperview];
    //    [_musixMixView removeFromSuperview];
    //    [_pasterView removeFromSuperview];
    //    [_timeSelectView removeFromSuperview];
    //    [_transitionView removeFromSuperview];
    //    [_effectSelectView removeFromSuperview];
    //    [_cutTipsLabel removeFromSuperview];
    //    
    //    [self.view addSubview:_textView];
    _videoCutView.videoRangeSlider.hidden = NO;
    [_videoPreview setBGMControlBtnHidden:YES];
}

#pragma mark VideoEffectViewDelegate
- (void)onVideoEffectBeginClick:(TXEffectType)effectType
{
    _effectType = effectType;
    UIColor *color = TXCVEFColorPaletteColorAtIndex((NSUInteger)effectType);
    const CGFloat alpha = 0.7;
    [_videoCutView startColoration:color alpha:alpha];
    [_ugcEdit startEffect:(TXEffectType)_effectType startTime:_playTime];
    if (!_isReverse) {
        [_ugcEdit startPlayFromTime:_videoCutView.videoRangeSlider.currentPos toTime:_videoCutView.videoRangeSlider.rightPos];
    }else{
        [_ugcEdit startPlayFromTime:_videoCutView.videoRangeSlider.leftPos toTime:_videoCutView.videoRangeSlider.currentPos];
    }
    [_videoPreview setPlayBtn:YES];
}

- (void)onVideoEffectEndClick:(TXEffectType)effectType
{
    if (_effectType != -1) {
        [_videoPreview setPlayBtn:NO];
        [_videoCutView stopColoration];
        [_ugcEdit stopEffect:effectType endTime:_playTime];
        [_ugcEdit pausePlay];
        _effectType = -1;
    }
}

#pragma mark TimeSelectViewDelegate
- (void)onVideoTimeEffectsClear
{
    _timeType = TimeType_Clear;
    _isReverse = NO;
    [_ugcEdit setReverse:_isReverse];
    [_ugcEdit setRepeatPlay:nil];
    [_ugcEdit setSpeedList:nil];
    [_ugcEdit startPlayFromTime:_videoCutView.videoRangeSlider.leftPos toTime:_videoCutView.videoRangeSlider.rightPos];
    
    [_videoPreview setPlayBtn:YES];
    [_videoCutView setCenterPanHidden:YES];
}
- (void)onVideoTimeEffectsBackPlay
{
    _timeType = TimeType_Back;
    _isReverse = YES;
    [_ugcEdit setReverse:_isReverse];
    [_ugcEdit setRepeatPlay:nil];
    [_ugcEdit setSpeedList:nil];
    [_ugcEdit startPlayFromTime:_videoCutView.videoRangeSlider.leftPos toTime:_videoCutView.videoRangeSlider.rightPos];
    
    [_videoPreview setPlayBtn:YES];
    [_videoCutView setCenterPanHidden:YES];
    _videoCutView.videoRangeSlider.hidden = NO;
}
- (void)onVideoTimeEffectsRepeat
{
    _timeType = TimeType_Repeat;
    _isReverse = NO;
    [_ugcEdit setReverse:_isReverse];
    [_ugcEdit setSpeedList:nil];
    TXRepeat *repeat = [[TXRepeat alloc] init];
    repeat.startTime = _leftTime + (_rightTime - _leftTime) / 5;
    repeat.endTime = repeat.startTime + 0.5;
    repeat.repeatTimes = 3;
    [_ugcEdit setRepeatPlay:@[repeat]];
    [_ugcEdit startPlayFromTime:_videoCutView.videoRangeSlider.leftPos toTime:_videoCutView.videoRangeSlider.rightPos];
    
    [_videoPreview setPlayBtn:YES];
    [_videoCutView setCenterPanHidden:NO];
    [_videoCutView setCenterPanFrame:repeat.startTime];
}

- (void)onVideoTimeEffectsSpeed
{
    _timeType = TimeType_Speed;
    _isReverse = NO;
    [_ugcEdit setReverse:_isReverse];
    [_ugcEdit setRepeatPlay:nil];
    TXSpeed *speed1 =[[TXSpeed alloc] init];
    speed1.startTime = _leftTime + (_rightTime - _leftTime) * 1.5 / 5;
    speed1.endTime = speed1.startTime + 0.5;
    speed1.speedLevel = SPEED_LEVEL_SLOW;
    TXSpeed *speed2 =[[TXSpeed alloc] init];
    speed2.startTime = speed1.endTime;
    speed2.endTime = speed2.startTime + 0.5;
    speed2.speedLevel = SPEED_LEVEL_SLOWEST;
    TXSpeed *speed3 =[[TXSpeed alloc] init];
    speed3.startTime = speed2.endTime;
    speed3.endTime = speed3.startTime + 0.5;
    speed3.speedLevel = SPEED_LEVEL_SLOW;
    [_ugcEdit setSpeedList:@[speed1,speed2,speed3]];
    [_ugcEdit startPlayFromTime:_videoCutView.videoRangeSlider.leftPos toTime:_videoCutView.videoRangeSlider.rightPos];
    
    [_videoPreview setPlayBtn:YES];
    [_videoCutView setCenterPanHidden:NO];
    [_videoCutView setCenterPanFrame:speed1.startTime];
}

#pragma mark TransitionViewDelegate
- (void)onVideoTransitionLefRightSlipping
{
    __weak __typeof(self) weakSelf = self;
    [_ugcEdit setPictureTransition:TXTransitionType_LefRightSlipping duration:^(CGFloat duration) {
        _duration = duration;
        _rightTime = duration;
        [weakSelf initVideoCutView:VideoType_Picture];
        [weakSelf.ugcEdit startPlayFromTime:0 toTime:weakSelf.duration];
        [weakSelf.videoPreview setPlayBtn:YES];
    }];
}

- (void)onVideoTransitionUpDownSlipping
{
    __weak __typeof(self) weakSelf = self;
    [_ugcEdit setPictureTransition:TXTransitionType_UpDownSlipping duration:^(CGFloat duration) {
        _duration = duration;
        _rightTime = duration;
        [weakSelf initVideoCutView:VideoType_Picture];
        [weakSelf.ugcEdit startPlayFromTime:0 toTime:weakSelf.duration];
        [weakSelf.videoPreview setPlayBtn:YES];
    }];
}

- (void)onVideoTransitionEnlarge
{
    __weak __typeof(self) weakSelf = self;
    [_ugcEdit setPictureTransition:TXTransitionType_Enlarge duration:^(CGFloat duration) {
        _duration = duration;
        _rightTime = duration;
        [weakSelf initVideoCutView:VideoType_Picture];
        [weakSelf.ugcEdit startPlayFromTime:0 toTime:weakSelf.duration];
        [weakSelf.videoPreview setPlayBtn:YES];
    }];
}

- (void)onVideoTransitionNarrow
{
    __weak __typeof(self) weakSelf = self;
    [_ugcEdit setPictureTransition:TXTransitionType_Narrow duration:^(CGFloat duration) {
        _duration = duration;
        _rightTime = duration;
        [weakSelf initVideoCutView:VideoType_Picture];
        [weakSelf.ugcEdit startPlayFromTime:0 toTime:weakSelf.duration];
        [weakSelf.videoPreview setPlayBtn:YES];
    }];
}

- (void)onVideoTransitionRotationalScaling
{
    __weak __typeof(self) weakSelf = self;
    [_ugcEdit setPictureTransition:TXTransitionType_RotationalScaling duration:^(CGFloat duration) {
        _duration = duration;
        _rightTime = duration;
        [weakSelf initVideoCutView:VideoType_Picture];
        [weakSelf.ugcEdit startPlayFromTime:0 toTime:weakSelf.duration];
        [weakSelf.videoPreview setPlayBtn:YES];
    }];
}

- (void)onVideoTransitionFadeinFadeout
{
    __weak __typeof(self) weakSelf = self;
    [_ugcEdit setPictureTransition:TXTransitionType_FadeinFadeout duration:^(CGFloat duration) {
        _duration = duration;
        _rightTime = duration;
        [weakSelf initVideoCutView:VideoType_Picture];
        [weakSelf.ugcEdit startPlayFromTime:0 toTime:weakSelf.duration];
        [weakSelf.videoPreview setPlayBtn:YES];
    }];
}

#pragma mark TXVideoGenerateListener
-(void) onGenerateProgress:(float)progress
{
    _generateProgressView.progress = progress;
}

-(void) onGenerateComplete:(TXGenerateResult *)result
{
    _generationView.hidden = YES;
    [_videoPreview startObservingAudioNotification];
    
    if (result.retCode == 0) {
        
        TXVideoInfo *videoInfo = [TXVideoInfoReader getVideoInfo:_videoOutputPath];
        VideoPreviewViewController* vc = [[VideoPreviewViewController alloc] initWithCoverImage:videoInfo.coverImage videoPath:_videoOutputPath renderMode:RENDER_MODE_FILL_EDGE showEditButton:NO];
        [self.navigationController pushViewController:vc animated:YES];
        
    }else{
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"视频生成失败"
                                                            message:[NSString stringWithFormat:@"错误码：%ld 错误信息：%@",(long)result.retCode,result.descMsg]
                                                           delegate:self
                                                  cancelButtonTitle:@"知道了"
                                                  otherButtonTitles:nil, nil];
        [alertView show];
    }
}


#pragma mark VideoPreviewDelegate
- (void)onVideoPlay
{
    CGFloat currentPos = _videoCutView.videoRangeSlider.currentPos;
    if (currentPos < _leftTime || currentPos > _rightTime)
        currentPos = _leftTime;
    
    if(_isReverse && currentPos != 0){
        [_ugcEdit startPlayFromTime:0 toTime:currentPos];
    }
    else if(_videoCutView.videoRangeSlider.rightPos != 0){
        [_ugcEdit startPlayFromTime:currentPos toTime:_videoCutView.videoRangeSlider.rightPos];
    }
    else{
        [_ugcEdit startPlayFromTime:currentPos toTime:_rightTime];
    }
}

- (void)onVideoPause
{
    [_ugcEdit pausePlay];
}

- (void)onVideoResume
{
    //    [_ugcEdit resumePlay];
    [self onVideoPlay];
}

- (void)onVideoPlayProgress:(CGFloat)time
{
    _playTime = time;
    [_videoCutView setPlayTime:_playTime];
}

- (void)onVideoPlayFinished
{
    if (_effectType != -1) {
        [self onVideoEffectEndClick:_effectType];
    }else{
        [_ugcEdit startPlayFromTime:_leftTime toTime:_rightTime];
    }
}

- (void)onBGMLoop:(BOOL)isLoop
{
    _isBGMLoop = isLoop;
    [_ugcEdit setBGMLoop:_isBGMLoop];
}

- (void)onBGMFadeIn:(BOOL)isFadeIn
{
    _isFadeIn = isFadeIn;
    [_ugcEdit setBGMFadeInDuration:_isFadeIn ? 3 : 0 fadeOutDuration:_isFadeOut ? 3 : 0];
}

- (void)onBGMFadeOut:(BOOL)isFadeOut
{
    _isFadeOut = isFadeOut;
    [_ugcEdit setBGMFadeInDuration:_isFadeIn ? 3 : 0 fadeOutDuration:_isFadeOut ? 3 : 0];
}

- (void)onVideoEnterBackground
{
    [_ugcEdit pauseGenerate];
}

- (void)onVideoWillEnterForeground
{
    [_ugcEdit resumeGenerate];
}

#pragma mark TXVideoCustomProcessListener
- (GLuint)onPreProcessTexture:(GLuint)texture width:(CGFloat)width height:(CGFloat)height timestamp:(UInt64)timestamp
{
    static int i = 0;
    if (i++ % 100 == 0) {
        NSLog(@"onPreProcessTexture width:%f height:%f  timestamp:%f", width, height,timestamp/1000.0);
    }
    
    return texture;
}

- (void)onTextureDestoryed
{
    NSLog(@"onTextureDestoryed");
}

#pragma mark - VideoCutViewDelegate
//裁剪
- (void)onVideoLeftCutChanged:(VideoRangeSlider *)sender
{
    //[_ugcEdit pausePlay];
    [_videoPreview setPlayBtn:NO];
    [_ugcEdit previewAtTime:sender.leftPos];
}

- (void)onVideoRightCutChanged:(VideoRangeSlider *)sender
{
    [_videoPreview setPlayBtn:NO];
    [_ugcEdit previewAtTime:sender.rightPos];
}

- (void)onVideoCutChangedEnd:(VideoRangeSlider *)sender
{
    _leftTime = sender.leftPos;
    _rightTime = sender.rightPos;
    [_ugcEdit startPlayFromTime:sender.leftPos toTime:sender.rightPos];
    [_videoPreview setPlayBtn:YES];
}

- (void)onVideoCenterRepeatChanged:(VideoRangeSlider*)sender
{
    [_videoPreview setPlayBtn:NO];
    [_ugcEdit previewAtTime:sender.centerPos];
}

- (void)onVideoCenterRepeatEnd:(VideoRangeSlider*)sender;
{
    _leftTime = sender.leftPos;
    _rightTime = sender.rightPos;
    
    if (_timeType == TimeType_Repeat) {
        TXRepeat *repeat = [[TXRepeat alloc] init];
        repeat.startTime = sender.centerPos;
        repeat.endTime = sender.centerPos + 0.5;
        repeat.repeatTimes = 3;
        [_ugcEdit setRepeatPlay:@[repeat]];
        [_ugcEdit setSpeedList:nil];
    }
    else if (_timeType == TimeType_Speed) {
        TXSpeed *speed1 =[[TXSpeed alloc] init];
        speed1.startTime = sender.centerPos;
        speed1.endTime = speed1.startTime + 0.5;
        speed1.speedLevel = SPEED_LEVEL_SLOW;
        TXSpeed *speed2 =[[TXSpeed alloc] init];
        speed2.startTime = speed1.endTime;
        speed2.endTime = speed2.startTime + 0.5;
        speed2.speedLevel = SPEED_LEVEL_SLOWEST;
        TXSpeed *speed3 =[[TXSpeed alloc] init];
        speed3.startTime = speed2.endTime;
        speed3.endTime = speed3.startTime + 0.5;
        speed3.speedLevel = SPEED_LEVEL_SLOW;
        [_ugcEdit setSpeedList:@[speed1,speed2,speed3]];
        [_ugcEdit setRepeatPlay:nil];
    }
    
    if (_isReverse) {
        [_ugcEdit startPlayFromTime:sender.leftPos toTime:sender.centerPos + 1.5];
    }else{
        [_ugcEdit startPlayFromTime:sender.centerPos toTime:sender.rightPos];
    }
    [_videoPreview setPlayBtn:YES];
}

- (void)onVideoCutChange:(VideoRangeSlider *)sender seekToPos:(CGFloat)pos
{
    _playTime = pos;
    [_ugcEdit previewAtTime:_playTime];
    [_videoPreview setPlayBtn:NO];
}

//美颜
- (void)onSetBeautyDepth:(float)beautyDepth WhiteningDepth:(float)whiteningDepth
{
    [_ugcEdit setBeautyFilter:beautyDepth setWhiteningLevel:whiteningDepth];
}

- (void)onEffectDelete:(VideoColorInfo *)info
{
    if (info) {
        float time = _isReverse ? MAX(info.endPos, info.startPos) : MIN(info.endPos, info.startPos);
        [_videoCutView setPlayTime:time];
        _playTime = time;
    }
    [_ugcEdit deleteLastEffect];
    [_videoPreview setPlayBtn:NO];
}

#pragma mark - TextAddViewDelegate
//打开字幕操作viewcontroller
- (void)onAddTextBtnClicked
{
    [_videoPreview removeFromSuperview];
    
    //己有添加字幕的话只操作本地裁剪时间内的
    NSMutableArray* inRangeVideoTexts = [NSMutableArray new];
    for (VideoTextInfo* info in _videoTextInfos) {
        if (info.startTime >= _rightTime || info.endTime <= _leftTime)
            continue;
        
        [inRangeVideoTexts addObject:info];
    }
    
    [_ugcEdit pausePlay];
    [_videoPreview setPlayBtn:NO];
    
    VideoTextViewController* vc = [[VideoTextViewController alloc] initWithVideoEditer:_ugcEdit previewView:_videoPreview startTime:_leftTime endTime:_rightTime videoTextInfos:inRangeVideoTexts];
    vc.delegate = self;
    UINavigationController* nav = [[UINavigationController alloc] initWithRootViewController:vc];
    [self presentViewController:nav animated:YES completion:nil];
}

- (void)onSetVideoPasterInfosFinish:(NSArray<VideoPasterInfo*>*)videoPasterInfos
{
    //更新贴纸信息
    [_videoPaterInfos removeAllObjects];
    [_videoPaterInfos addObjectsFromArray:videoPasterInfos];
    
    _videoPreview.frame = CGRectMake(0, 0, self.view.width, 350 * kScaleY);
    _videoPreview.delegate = self;
    [_videoPreview setPlayBtnHidden:NO];
    [self.view addSubview:_videoPreview];
    [_videoPreviewConstrains makeObjectsPerformSelector:@selector(install)];
    if (videoPasterInfos.count > 0) {
        [_textView setEdited:YES];
    }else {
        [_textView setEdited:NO];
    }
}

#pragma mark - VideoTextViewControllerDelegate
- (void)onSetVideoTextInfosFinish:(NSArray<VideoTextInfo *> *)videoTextInfos
{
    //更新文字信息
    //新增的
    for (VideoTextInfo* info in videoTextInfos) {
        if (![_videoTextInfos containsObject:info]) {
            [_videoTextInfos addObject:info];
        }
    }
    
    NSMutableArray* removedTexts = [NSMutableArray new];
    for (VideoTextInfo* info in _videoTextInfos) {
        //删除的
        NSUInteger index = [videoTextInfos indexOfObject:info];
        if ( index != NSNotFound) {
            continue;
        }
        
        if (info.startTime < _rightTime && info.endTime > _leftTime)
            [removedTexts addObject:info];
    }
    
    if (removedTexts.count > 0)
        [_videoTextInfos removeObjectsInArray:removedTexts];
    
    _videoPreview.frame = CGRectMake(0, 0, self.view.width, 350 * kScaleY);
    _videoPreview.delegate = self;
    [_videoPreview setPlayBtnHidden:NO];
    [self.view addSubview:_videoPreview];
    [_videoPreviewConstrains makeObjectsPerformSelector:@selector(install)];
    
    if (videoTextInfos.count > 0) {
        [_textView setEdited:YES];
    }
    else {
        [_textView setEdited:NO];
    }
}

#pragma mark - PasterAddViewDelegate
- (void)onAddPasterBtnClicked
{
    [_videoPreview removeFromSuperview];
    [_videoPreview removeConstraints:_videoPreview.constraints];
    //己有添加字幕的话只操作本地裁剪时间内的
    NSMutableArray* inRangeVideoPasters = [NSMutableArray new];
    for (VideoPasterInfo* info in _videoPaterInfos) {
        if (info.startTime >= _rightTime || info.endTime <= _leftTime)
            continue;
        
        [inRangeVideoPasters addObject:info];
    }
    
    [_ugcEdit pausePlay];
    [_videoPreview setPlayBtn:NO];
    
    VideoPasterViewController* vc = [[VideoPasterViewController alloc] initWithVideoEditer:_ugcEdit previewView:_videoPreview startTime:_leftTime endTime:_rightTime videoPasterInfos:inRangeVideoPasters];
    vc.delegate = self;
    UINavigationController* nav = [[UINavigationController alloc] initWithRootViewController:vc];
    [self presentViewController:nav animated:YES completion:nil];
}


#pragma mark - MPMediaPickerControllerDelegate
- (void)mediaPicker:(MPMediaPickerController *)mediaPicker didPickMediaItems:(MPMediaItemCollection *)mediaItemCollection
{
    NSArray *items = mediaItemCollection.items;
    MPMediaItem *songItem = [items objectAtIndex:0];
    
    NSURL *url = [songItem valueForProperty:MPMediaItemPropertyAssetURL];
    NSString* songName = [songItem valueForProperty: MPMediaItemPropertyTitle];
    NSString* authorName = [songItem valueForProperty:MPMediaItemPropertyArtist];
    NSNumber* duration = [songItem valueForKey:MPMediaItemPropertyPlaybackDuration];
    NSLog(@"MPMediaItemPropertyAssetURL = %@", url);
    
    MusicInfo* musicInfo = [MusicInfo new];
    musicInfo.duration = duration.floatValue;
    musicInfo.soneName = songName;
    musicInfo.singerName = authorName;
    
    if (mediaPicker.editing) {
        mediaPicker.editing = NO;
        dispatch_async(dispatch_get_main_queue(), ^{
            [self saveAssetURLToFile:musicInfo assetURL:url];
        });
        
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

//点击取消时回调
- (void)mediaPickerDidCancel:(MPMediaPickerController *)mediaPicker{
    [self dismissViewControllerAnimated:YES completion:nil];
}

// 将AssetURL(音乐)导出到app的文件夹并播放
- (void)saveAssetURLToFile:(MusicInfo*)musicInfo assetURL:(NSURL*)assetURL
{
    musicInfo.fileAsset = [AVAsset assetWithURL:assetURL];
    if (musicInfo.fileAsset != nil) {
        [_musixMixView addMusicInfo:musicInfo];
    }
}

#pragma mark - MusicMixViewDelegate
//打开本地系统音乐
- (void)onOpenLocalMusicList
{
    [self pause];
    
    MPMediaPickerController *mpc = [[MPMediaPickerController alloc] initWithMediaTypes:MPMediaTypeAnyAudio];
    mpc.delegate = self;
    mpc.editing = YES;
    mpc.allowsPickingMultipleItems = NO;
    [self presentViewController:mpc animated:YES completion:nil];
}

//设音量效果
- (void)onSetVideoVolume:(CGFloat)videoVolume musicVolume:(CGFloat)musicVolume
{
    [_ugcEdit setVideoVolume:videoVolume];
    [_ugcEdit setBGMVolume:musicVolume];
}

- (void)onSetBGMWithFileAsset:(AVURLAsset*)fileAsset startTime:(CGFloat)startTime endTime:(CGFloat)endTime
{
    if (![_fileAsset isEqual:fileAsset]) {
        __weak __typeof(self) weakSelf = self;
        [_ugcEdit setBGMAsset:fileAsset result:^(int result) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (result == -1){
                    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"设置背景音乐失败"
                                                                        message:@"不支持当前格式的背景音乐!"
                                                                       delegate:weakSelf
                                                              cancelButtonTitle:@"知道了"
                                                              otherButtonTitles:nil, nil];
                    [alertView show];
                }else{
                    [weakSelf setBGMVolume:fileAsset startTime:startTime endTime:endTime];
                }
            });
        }];
    }else{
        [self setBGMVolume:fileAsset startTime:startTime endTime:endTime];
    }
}

-(void)setBGMVolume:(AVURLAsset *)fileAsset startTime:(CGFloat)startTime endTime:(CGFloat)endTime
{
    _fileAsset = fileAsset;
    [_ugcEdit setBGMStartTime:startTime endTime:endTime];
    [_ugcEdit setBGMFadeInDuration:_isFadeIn ? 3 : 0 fadeOutDuration:_isFadeOut ? 3 : 0];
    [_ugcEdit setBGMLoop:_isBGMLoop];
    [_ugcEdit startPlayFromTime:_leftTime toTime:_rightTime];
   
    if (_fileAsset == nil) [_ugcEdit setVideoVolume:1.f];
    [_videoPreview setPlayBtn:YES];
}

//生成gif图片
-(void)startGenerateGif{
    //创建CFURL对象
    /*
     CFURLCreateWithFileSystemPath(CFAllocatorRef allocator, CFStringRef filePath, CFURLPathStyle pathStyle, Boolean isDirectory)
     
     allocator : 分配器,通常使用kCFAllocatorDefault
     filePath : 路径
     pathStyle : 路径风格,我们就填写kCFURLPOSIXPathStyle 更多请打问号自己进去帮助看
     isDirectory : 一个布尔值,用于指定是否filePath被当作一个目录路径解决时相对路径组件
     */
    CFURLRef url = CFURLCreateWithFileSystemPath (
                                                  kCFAllocatorDefault,
                                                  (CFStringRef)_gifOutputPath,
                                                  kCFURLPOSIXPathStyle,
                                                  false);
    
    //通过一个url返回图像目标 kUTTypeGIF  CFStringRef
    __block int picCount = 20;
    NSMutableArray *picArr = [NSMutableArray arrayWithCapacity:picCount];
    [TXVideoInfoReader getSampleImages:picCount videoAsset:_videoAsset progress:^BOOL(int number, UIImage *image) {
        if (image == nil){
            picCount--;
        }else{
            [picArr addObject:image];
        }
        if (picArr.count >= picCount) {
            dispatch_async(dispatch_get_main_queue(), ^{
                CGImageDestinationRef destination = CGImageDestinationCreateWithURL(url, kUTTypeGIF, picArr.count, NULL);
                
                //设置gif的信息,播放间隔时间,基本数据,和delay时间
                NSDictionary *frameProperties = [NSDictionary
                                                 dictionaryWithObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithFloat:0.001f], (NSString *)kCGImagePropertyGIFDelayTime, nil]
                                                 forKey:(NSString *)kCGImagePropertyGIFDictionary];
                
                //设置gif信息
                NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:2];

                [dict setObject:[NSNumber numberWithBool:YES] forKey:(NSString*)kCGImagePropertyGIFHasGlobalColorMap];
                
                [dict setObject:(NSString *)kCGImagePropertyColorModelRGB forKey:(NSString *)kCGImagePropertyColorModel];
                
                [dict setObject:[NSNumber numberWithInt:8] forKey:(NSString*)kCGImagePropertyDepth];
                
                [dict setObject:[NSNumber numberWithInt:0] forKey:(NSString *)kCGImagePropertyGIFLoopCount];
                
                NSDictionary *gifProperties = [NSDictionary dictionaryWithObject:dict
                                                                          forKey:(NSString *)kCGImagePropertyGIFDictionary];
                //合成gif
                CGImageDestinationSetProperties(destination, (__bridge CFDictionaryRef)gifProperties);
                for (UIImage* dImg in picArr)
                {
                    CGImageDestinationAddImage(destination, dImg.CGImage, (__bridge CFDictionaryRef)frameProperties);
                }
                CGImageDestinationFinalize(destination);
                CFRelease(destination);
                NSData *data = [NSData dataWithContentsOfFile:self->_gifOutputPath];
                [PhotoUtil saveDataToAlbum:data
                                completion:^(BOOL success, NSError * _Nullable error) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if (success) {
                            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"gif生成成功，已经保存到系统相册，请前往系统相册查看" message:nil delegate:self cancelButtonTitle:@"知道了" otherButtonTitles:nil, nil];
                            [alert show];
                        } else {
                            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"gif 保存失败"
                                                                            message:error.localizedDescription
                                                                           delegate:self
                                                                  cancelButtonTitle:@"知道了"
                                                                  otherButtonTitles:nil];
                            [alert show];
                        }
                    });
                }];
            });
        }
        return YES;
    }];
}


@end
