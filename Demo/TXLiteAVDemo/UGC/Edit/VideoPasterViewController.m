//
//  VideoTextViewController.m
//  DeviceManageIOSApp
//
//  Created by rushanting on 2017/5/18.
//  Copyright © 2017年 tencent. All rights reserved.
//

#import "VideoPasterViewController.h"
#import "TXLiteAVSDKHeader.h"
#import "VideoPreview.h"
#import "UIView+Additions.h"
#import "TXColor.h"
#import "RangeContent.h"
#import "TextCollectionCell.h"
#import "VideoPasterView.h"
#import "PasterSelectView.h"
#import "Masonry.h"

@implementation VideoPasterInfo
@end


@interface VideoPasterViewController () <VideoPreviewDelegate, UICollectionViewDelegate, UICollectionViewDataSource, RangeContentDelegate, VideoPasterViewDelegate , PasterSelectViewDelegate>
{
    VideoPreview  *_videoPreview;       //视频预览view
    TXVideoEditer* _ugcEditer;          //sdk的editer
    
    RangeContent* _videoRangeSlider;    //字幕的时间区域操作条
    UILabel*       _leftTimeLabel;
    UILabel*       _rightTimeLabel;
    
    UISlider*   _progressView;          //播放进度条
    UILabel*    _progressedLabel;       //播放时间
    
    UICollectionView* _videoPasterCollection; //己添加贴纸列表
    
    UIButton*      _playBtn;            //播放按钮
    
    CGFloat        _videoStartTime;     //裁剪的视频开始时间
    CGFloat        _videoEndTime;       //裁剪的视频结束时间
    
    CGFloat        _previewAtTime;      //预览时间点
    
    CGFloat        _videoDuration;      //裁剪的视频总时间
    UILabel*       _timeLabel;
    
    BOOL            _isVideoPlaying;
    
    NSMutableArray<VideoPasterInfo*>* _videoPasterInfos;    //字幕列表信息
    
    UITapGestureRecognizer* _singleTap;
    
    UIView *       _videoPasterView;
    NSArray *      _pasterList;
    PasterSelectView * _animateView;
    PasterSelectView * _staticView;
    UIView *_bottomView;
    
    __weak VideoPasterView *_editingPasterView;
    __weak VideoPasterInfo *_selectedPasterInfo;
}

@end

@implementation VideoPasterViewController

- (id)initWithVideoEditer:(TXVideoEditer*)videoEditer previewView:(VideoPreview*)previewView startTime:(CGFloat)startTime endTime:(CGFloat)endTime videoPasterInfos:(NSArray<VideoPasterInfo*>*)videoPasterInfos;

{
    if (self = [super init]) {
        _ugcEditer = videoEditer;
        _videoPreview = previewView;
        _videoPreview.delegate = self;
        _videoStartTime = startTime;
        _videoEndTime = endTime;
        _videoDuration = endTime - startTime;
        
        _videoPasterInfos = videoPasterInfos.mutableCopy;
        //未添加过动图
        if (!_videoPasterInfos) {
            _videoPasterInfos = [NSMutableArray new];
        } else {
            //有己添加过动图
            for (VideoPasterInfo* pasterInfo in _videoPasterInfos) {
                pasterInfo.pasterView.delegate = self;
            }
        }
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self initUI];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    //    [_videoPreview playVideo];
}


- (void)dealloc
{
    [_videoPreview removeGestureRecognizer:_singleTap];
    NSLog(@"VideoTextViewController dealloc");
}


- (void)initUI
{
    
    self.title = @"编辑视频";
    UIBarButtonItem *customBackButton = [[UIBarButtonItem alloc] initWithTitle:@"返回"
                                                                         style:UIBarButtonItemStylePlain
                                                                        target:self
                                                                        action:@selector(goBack)];
    customBackButton.tintColor = UIColor.whiteColor;
    self.navigationItem.leftBarButtonItem = customBackButton;
    
    self.view.backgroundColor = UIColor.blackColor;
    self.navigationController.navigationBar.translucent = NO;
    
    _videoPreview.frame = CGRectMake(0, 0, self.view.width, 432 * kScaleY);
    _videoPreview.delegate = self;
    _videoPreview.backgroundColor = UIColor.darkTextColor;
    
    [_ugcEditer previewAtTime:_videoStartTime];
    [_ugcEditer pausePlay];
    _isVideoPlaying = NO;
    
    [_videoPreview setPlayBtnHidden:YES];
    [self.view addSubview:_videoPreview];
    [_videoPreview mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.width.equalTo(self.view.mas_width);
        make.left.equalTo(self.view.mas_left);
        make.height.equalTo(@(432*kScaleY));
    }];

    
    UIImage* image = [UIImage imageNamed:@"videotext_play"];
    _playBtn = [[UIButton alloc] initWithFrame:CGRectMake(15 * kScaleX, 432*kScaleY + 30 * kScaleY, image.size.width, image.size.height)];
    [_playBtn setImage:image forState:UIControlStateNormal];
    [_playBtn addTarget:self action:@selector(onPlayBtnClicked:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_playBtn];
    
    
    _timeLabel = [[UILabel alloc] init];
    _timeLabel.text = [NSString stringWithFormat:@"%02d:%02d", (int)(_videoDuration) / 60, (int)(_videoDuration) % 60];
    _timeLabel.textColor = TXColor.gray;
    _timeLabel.font = [UIFont systemFontOfSize:14];
    [_timeLabel sizeToFit];
    _timeLabel.center = CGPointMake(self.view.width - 15 * kScaleX - _timeLabel.width / 2, _playBtn.center.y);
    [self.view addSubview:_timeLabel];
    
    UIView* toImageView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.width, 2)];
    toImageView.backgroundColor = UIColor.lightGrayColor;
    UIImage* coverImage = toImageView.toImage;
    
    toImageView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 18, 18)];
    toImageView.backgroundColor = TXColor.cyan;
    toImageView.layer.cornerRadius = 9;
    UIImage* thumbImage = toImageView.toImage;
    
    RangeContentConfig* config = [[RangeContentConfig alloc] init];
    config.pinWidth = 18;
    config.borderHeight = 0;
    config.thumbHeight = 20;
    config.leftPinImage = thumbImage;
    config.rightPigImage = thumbImage;
    config.leftCorverImage = coverImage;
    config.rightCoverImage = coverImage;
    
    toImageView = [UIView new];
    toImageView.backgroundColor = TXColor.cyan;
    toImageView.bounds = CGRectMake(0, 0, _timeLabel.left - _playBtn.right - 15 - config.pinWidth * 2, 2);
    _videoRangeSlider = [[RangeContent alloc] initWithImageList:@[toImageView.toImage] config:config];
    _videoRangeSlider.center = CGPointMake(_playBtn.right + 7.5 + _videoRangeSlider.width / 2, _playBtn.center.y);
    _videoRangeSlider.delegate = self;
    _videoRangeSlider.hidden = YES;
    [self.view addSubview:_videoRangeSlider];
    
    _leftTimeLabel = [[UILabel alloc] init];
    _leftTimeLabel.textColor = TXColor.gray;
    _leftTimeLabel.font = [UIFont systemFontOfSize:10];
    _leftTimeLabel.text = @"0:00";
    _leftTimeLabel.hidden = YES;
    [self.view addSubview:_leftTimeLabel];
    
    _rightTimeLabel = [[UILabel alloc] init];
    _rightTimeLabel.textColor = TXColor.gray;
    _rightTimeLabel.font = [UIFont systemFontOfSize:10];
    _rightTimeLabel.text = @"0:00";
    _rightTimeLabel.hidden = YES;
    [self.view addSubview:_rightTimeLabel];
    
    _progressView = [UISlider new];
    _progressView.center = _videoRangeSlider.center;
    _progressView.bounds = CGRectMake(0, 0, _videoRangeSlider.width, 20);
    [self.view addSubview:_progressView];
    _progressView.tintColor = TXColor.cyan;
    [_progressView setThumbImage:thumbImage forState:UIControlStateNormal];
    _progressView.minimumValue = _videoStartTime;
    _progressView.maximumValue = _videoEndTime;
    [_progressView addTarget:self action:@selector(onProgressSlided:) forControlEvents:UIControlEventValueChanged];
    [_progressView addTarget:self action:@selector(onProgressSlideEnd:) forControlEvents:UIControlEventTouchUpInside];
    
    _progressedLabel = [[UILabel alloc] initWithFrame:CGRectMake(_progressView.x, _progressView.y - 12, 30, 10)];
    _progressedLabel.textColor = TXColor.gray;
    _progressedLabel.text = @"0:00";
    _progressedLabel.font = [UIFont systemFontOfSize:10];
    [self.view addSubview:_progressedLabel];
    
    CGFloat offset = 0;
    if (@available(iOS 11, *)) {
        offset = [UIApplication sharedApplication].keyWindow.safeAreaInsets.bottom;
    }
    UIView* bottomView = [[UIView alloc] initWithFrame:CGRectMake(0, self.view.height - offset - (40 + 40 * kScaleY) - 65, self.view.width, (40 + 40 * kScaleY))];
    _bottomView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
    bottomView.backgroundColor = TXColor.black;
    [self.view addSubview:bottomView];
    _bottomView = bottomView;
    
    UIButton* newPasterBtn = [[UIButton alloc] initWithFrame:CGRectMake(17.5 * kScaleX, 20 * kScaleY, 40, 40)];
    [newPasterBtn setImage:[UIImage imageNamed:@"text_add"] forState:UIControlStateNormal];
    newPasterBtn.backgroundColor = UIColor.clearColor;
    newPasterBtn.layer.borderWidth = 1;
    newPasterBtn.layer.borderColor = TXColor.gray.CGColor;
    [newPasterBtn addTarget:self action:@selector(onNewPasterBtnClicked:) forControlEvents:UIControlEventTouchUpInside];
    [bottomView addSubview:newPasterBtn];
    
    UICollectionViewFlowLayout* layout = [UICollectionViewFlowLayout new];
    layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    _videoPasterCollection = [[UICollectionView alloc] initWithFrame:CGRectMake(newPasterBtn.right + 10, 20 * kScaleY, self.view.width - newPasterBtn.right - 10, 40) collectionViewLayout:layout];
    _videoPasterCollection.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin;
    _videoPasterCollection.delegate = self;
    _videoPasterCollection.dataSource = self;
    _videoPasterCollection.backgroundColor = UIColor.clearColor;
    _videoPasterCollection.allowsMultipleSelection = NO;
    [_videoPasterCollection registerClass:[PasterCollectionCell class] forCellWithReuseIdentifier:@"PasterCollectionCell"];
    [bottomView addSubview:_videoPasterCollection];
    
    [self createBubbleSelectView];
    
    //点击选中文字
    _singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onTap:)];
    [_videoPreview addGestureRecognizer:_singleTap];
}

- (void)createBubbleSelectView
{
    int height = 90 * kScaleY;
    CGFloat offset = 0;
    if (@available(iOS 11, *)) {
        offset = [UIApplication sharedApplication].keyWindow.safeAreaInsets.bottom;
    }
    _videoPasterView = [[UIView alloc] initWithFrame:CGRectMake(0, self.view.bottom - height - 60 - offset, self.view.width, height)];
    
    UIButton* animateBtn = [[UIButton alloc] initWithFrame:CGRectMake(0, 0 , _videoPasterView.width / 2, 20)];
    [animateBtn setTitleColor:TXColor.cyan forState:UIControlStateNormal];
    [animateBtn setTitle:@"动态贴纸" forState:UIControlStateNormal];
    [animateBtn addTarget:self action:@selector(onPasterClicked:) forControlEvents:UIControlEventTouchUpInside];
    animateBtn.tag = 0;
    [_videoPasterView addSubview:animateBtn];
    
    UIButton* staticBtn = [[UIButton alloc] initWithFrame:CGRectMake(_videoPasterView.width / 2, 0 , _videoPasterView.width / 2, 20)];
    [staticBtn setTitleColor:TXColor.cyan forState:UIControlStateNormal];
    [staticBtn setTitle:@"静态贴纸" forState:UIControlStateNormal];
    [staticBtn addTarget:self action:@selector(onPasterClicked:) forControlEvents:UIControlEventTouchUpInside];
    staticBtn.tag = 1;
    [_videoPasterView addSubview:staticBtn];

    NSString *bundlePath = [[NSBundle mainBundle] pathForResource:@"AnimatedPaster" ofType:@"bundle"];
    _animateView = [[PasterSelectView alloc] initWithFrame:CGRectMake(0, 20, _videoPasterView.width, _videoPasterView.height - 20)  pasterType:PasterType_Animate boundPath:bundlePath];
    _animateView.delegate = self;
    _animateView.hidden = NO;
    [_videoPasterView addSubview:_animateView];
    
    NSString *bundlePath2 = [[NSBundle mainBundle] pathForResource:@"Paster" ofType:@"bundle"];
    _staticView = [[PasterSelectView alloc] initWithFrame:CGRectMake(0, 20, _videoPasterView.width, _videoPasterView.height - 20) pasterType:PasterType_static boundPath:bundlePath2];
    _staticView.delegate = self;
    _staticView.hidden = YES;
    [_videoPasterView addSubview:_staticView];
    
    _videoPasterView.hidden = YES;
    [self.view addSubview:_videoPasterView];
}

- (void)onPasterClicked:(UIButton *)btn
{
    if (btn.tag == 0) {
        _animateView.hidden = NO;
        _staticView.hidden = YES;
    }else{
        _animateView.hidden = YES;
        _staticView.hidden = NO;
    }
}

#pragma PasterSelectViewDelegate
- (void)onPasterAnimateSelect:(PasterAnimateInfo *)info
{
    VideoPasterInfo *pasterInfo = [self infoFromAnimatedPaster:info];
    [self addOrModifyPaster:pasterInfo];
}

- (void)onPasterStaticSelect:(PasterStaticInfo *)info
{
    VideoPasterInfo *pasterInfo = [self infoFromStaticPaster:info];
    [self addOrModifyPaster:pasterInfo];
}

- (void)addOrModifyPaster:(VideoPasterInfo *)pasterInfo {
    UIView *newPaster = [self appendPasterInfo:pasterInfo];
    if (_editingPasterView) {
        NSUInteger currentIndex = [_videoPasterInfos indexOfObject:_selectedPasterInfo];
        [_videoPasterInfos removeLastObject];
        pasterInfo.startTime = _selectedPasterInfo.startTime;
        pasterInfo.endTime   = _selectedPasterInfo.endTime;
        _videoPasterInfos[currentIndex] = pasterInfo;
        [self showTimeRangeAtStart:pasterInfo.startTime end:pasterInfo.endTime];
        newPaster.center = _editingPasterView.center;
        [_editingPasterView removeFromSuperview];
        [_videoPasterCollection reloadData];
    }
    [self showVideoPasterInfo:pasterInfo];
    [self hideVideoPasterView];
    [self setVideoPasters:_videoPasterInfos];
}

- (void)onPasterViewTap:(VideoPasterView *)pasterView
{
    _editingPasterView = pasterView;
    _selectedPasterInfo = [self findPasterInView:pasterView];
    _videoPasterView.hidden = NO;
}

- (VideoPasterInfo *)findPasterInView:(VideoPasterView *)view {
    for (VideoPasterInfo *info in _videoPasterInfos) {
        if (info.pasterView == view) {
            return info;
        }
    }
    return nil;
}

- (NSDictionary *)dictionaryWithJsonString:(NSString *)jsonString {
    if (jsonString == nil) {
        return nil;
    }
    
    NSData *jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    NSError *err;
    NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:jsonData
                                                        options:NSJSONReadingMutableContainers
                                                          error:&err];
    if(err) {
        NSLog(@"json解析失败：%@",err);
        return nil;
    }
    return dic;
}

- (void)setProgressHidden:(BOOL)isHidden
{
    [_playBtn setImage:[UIImage imageNamed:@"videotext_play"] forState:UIControlStateNormal];
    
    if (isHidden) {
        //隐藏进度条时显示时间区域选择条
        _progressView.hidden = YES;
        _progressedLabel.hidden = YES;
        _videoRangeSlider.hidden = NO;
        _leftTimeLabel.hidden = NO;
        _rightTimeLabel.hidden = NO;
        [_ugcEditer pausePlay];
        _isVideoPlaying = NO;
        //[_ugcEditer previewAtTime:_videoRangeSlider.leftScale * (_videoDuration) + _videoStartTime];
        [_ugcEditer previewAtTime:_previewAtTime];

    } else {
        //显示进度条时隐藏时间区域选择条
        _progressView.hidden = NO;
        _progressedLabel.hidden = NO;
        _videoRangeSlider.hidden = YES;
        _leftTimeLabel.hidden = YES;
        _rightTimeLabel.hidden = YES;
        NSArray* indexPaths = [_videoPasterCollection indexPathsForSelectedItems];
        if (indexPaths.count > 0) {
            [_videoPasterCollection deselectItemAtIndexPath:indexPaths[0] animated:NO];
        }
        //不选中作何字幕
        [self showVideoPasterInfo:nil];
    }
}

//当前选中的动图信息
- (VideoPasterInfo*)getSelectedVideoTextInfo
{
    return _selectedPasterInfo;
}

- (void)showVideoPasterInfo:(VideoPasterInfo*)pasterInfo
{
    [self showTimeRangeAtStart:pasterInfo.startTime end:pasterInfo.endTime];
    NSMutableArray<VideoPasterInfo*>* videoPasterInfos = [NSMutableArray new];

    _selectedPasterInfo = pasterInfo;
    //除正在操作的贴纸外，其它贴纸设置为隐藏(不给预处理显示)
    for (VideoPasterInfo* info in _videoPasterInfos) {
        info.pasterView.hidden = YES;
        if (info != pasterInfo) {
            [videoPasterInfos addObject:info];
        }
    }
    
    if (!pasterInfo)
        return;
    
    //设置展示当前选中贴纸的时间信息
    pasterInfo.pasterView.hidden = NO;
    [_videoPreview addSubview:pasterInfo.pasterView];
    
    _previewAtTime = pasterInfo.startTime;
    
    [self setVideoPasters:videoPasterInfos];
    [self setProgressHidden:YES];
}

- (void)showTimeRangeAtStart:(float)start end:(float)end
{
    CGFloat leftX = MAX(0, (start - _videoStartTime)) / (_videoDuration) * _videoRangeSlider.imageWidth;
    CGFloat rightX = MIN(_videoDuration, (end - _videoStartTime)) / (_videoDuration) * _videoRangeSlider.imageWidth;
    _videoRangeSlider.leftPinCenterX = leftX + _videoRangeSlider.pinWidth / 2;
    _videoRangeSlider.rightPinCenterX = MAX(_videoRangeSlider.leftPinCenterX + _videoRangeSlider.pinWidth, rightX + _videoRangeSlider.pinWidth * 3 / 2);
    [_videoRangeSlider setNeedsLayout];
    
    _leftTimeLabel.frame = CGRectMake(_videoRangeSlider.x + _videoRangeSlider.leftPinCenterX - _videoRangeSlider.pinWidth / 2, _videoRangeSlider.top - 12, 30, 10);
    _leftTimeLabel.text = [NSString stringWithFormat:@"%.02f", _videoRangeSlider.leftScale *_videoDuration];
    
    _rightTimeLabel.frame = CGRectMake(_videoRangeSlider.x + _videoRangeSlider.rightPinCenterX - _videoRangeSlider.pinWidth / 2, _videoRangeSlider.top - 12, 30, 10);
    _rightTimeLabel.text = [NSString stringWithFormat:@"%.02f", _videoRangeSlider.rightScale *_videoDuration];
}

//设置贴纸到 UGCEdit
- (void)setVideoPasters:(NSArray<VideoPasterInfo*>*)videoPasterInfos
{
    NSMutableArray* animatePasters = [NSMutableArray new];
    NSMutableArray* staticPasters = [NSMutableArray new];
    for (VideoPasterInfo* pasterInfo in videoPasterInfos) {
        if (pasterInfo.pasterInfoType == PasterInfoType_Animate) {
            TXAnimatedPaster* paster = [TXAnimatedPaster new];
            paster.startTime = pasterInfo.startTime;
            paster.endTime = pasterInfo.endTime;
            paster.frame = [pasterInfo.pasterView pasterFrameOnView:_videoPreview];
            paster.rotateAngle = pasterInfo.pasterView.rotateAngle * 180 / M_PI;
            paster.animatedPasterpath = pasterInfo.path;
            [animatePasters addObject:paster];
        }
        else if (pasterInfo.pasterInfoType == PasterInfoType_static){
            TXPaster *paster = [TXPaster new];
            paster.startTime = pasterInfo.startTime;
            paster.endTime = pasterInfo.endTime;
            paster.frame = [pasterInfo.pasterView pasterFrameOnView:_videoPreview];
            paster.pasterImage = pasterInfo.pasterView.staticImage;
            [staticPasters addObject:paster];
        }
    }
    [_ugcEditer setAnimatedPasterList:animatePasters];
    [_ugcEditer setPasterList:staticPasters];
}

#pragma mark - Model Translator
- (VideoPasterInfo *)infoFromAnimatedPaster:(PasterAnimateInfo *)info {
    VideoPasterInfo* pasterInfo = [VideoPasterInfo new];
    pasterInfo.size = CGSizeMake(info.width, info.height);
    pasterInfo.startTime = [self getStartTime];
    pasterInfo.endTime = [self getEndTime:pasterInfo.startTime];
    pasterInfo.pasterInfoType = PasterInfoType_Animate;
    pasterInfo.path = info.path;
    pasterInfo.iconImage = info.iconImage;
    pasterInfo.imageList = info.imageList;
    pasterInfo.duration = info.duration;
    return pasterInfo;
}

- (VideoPasterInfo *)infoFromStaticPaster:(PasterStaticInfo *)info {
    VideoPasterInfo* pasterInfo = [VideoPasterInfo new];
    pasterInfo.size = CGSizeMake(info.width, info.height);
    pasterInfo.startTime = [self getStartTime];
    pasterInfo.endTime = [self getEndTime:pasterInfo.startTime];
    pasterInfo.pasterInfoType = PasterInfoType_static;
    pasterInfo.image = info.image;
    pasterInfo.iconImage = info.iconImage;
    
    return pasterInfo;
}

#pragma mark - UICollectionViewDataSource
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return _videoPasterInfos.count;
}

- (UICollectionViewCell*)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *identify = @"PasterCollectionCell";
    PasterCollectionCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:identify forIndexPath:indexPath];
    if (indexPath.row < _videoPasterInfos.count) {
        VideoPasterInfo* info = _videoPasterInfos[indexPath.row];
        cell.imageView.image = info.iconImage;
    }
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    VideoPasterInfo *pasterInfo = _videoPasterInfos[indexPath.item];
    [self showVideoPasterInfo:pasterInfo];
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return CGSizeMake(40, 40);
}

//设置每个item水平间距
- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumInteritemSpac1ingForSectionAtIndex:(NSInteger)section
{
    return 10;
}

- (void)hideVideoPasterView
{
    _editingPasterView = nil;
//    NSMutableArray *emtyInfos = [NSMutableArray new];
//    for (VideoPasterInfo *info in _videoPasterInfos) {
//        if (info.pasterView.pasterImageView.image == nil && info.pasterView.pasterImageView.animationImages.count == 0) {
//            [emtyInfos addObject:info];
//        }
//    }
//    [_videoPasterInfos removeObjectsInArray:emtyInfos];
//    [_videoPasterCollection reloadData];
    _videoPasterView.hidden = YES;
}

#pragma mark - UI event Handle
//播放，每次从头开始
- (void)onPlayBtnClicked:(UIButton*)sender
{
    [self setProgressHidden:NO];
    if (!_isVideoPlaying) {
        [self setVideoPasters:_videoPasterInfos];
        [_ugcEditer startPlayFromTime:_videoStartTime toTime:_videoEndTime];
        [_playBtn setImage:[UIImage imageNamed:@"videotext_stop"] forState:UIControlStateNormal];
        _isVideoPlaying = YES;
    }
    else{
        [_ugcEditer pausePlay];
        [_playBtn setImage:[UIImage imageNamed:@"videotext_play"] forState:UIControlStateNormal];
        _isVideoPlaying = NO;
        
        _previewAtTime = _progressView.value;
    }
    [self hideVideoPasterView];
}

//新添加动图
- (void)onNewPasterBtnClicked:(UIButton*)sender
{
    _videoPasterView.hidden = NO;
    float start = [self getStartTime];
    float end = [self getEndTime:start];
    [self showTimeRangeAtStart:start end:end];

    [self setProgressHidden:YES];
    
    VideoPasterView * pasterView = [[VideoPasterView alloc] initWithFrame:CGRectZero];
    pasterView.delegate = self;
    [_videoPreview addSubview:pasterView];
//    
//    VideoPasterInfo* info = [VideoPasterInfo new];
//    info.pasterView = pasterView;
//    info.startTime = [self getStartTime];
//    info.endTime = [self getEndTime:info.startTime];
//    
//    if (!_animateView.hidden) info.pasterInfoType = PasterInfoType_Animate;
//    if (!_staticView.hidden) info.pasterInfoType = PasterInfoType_static;
//    [self showVideoPasterInfo:info];
}

- (UIView *)appendPasterInfo:(VideoPasterInfo *)pasterInfo
{
    CGFloat width = 170;
    CGFloat height = pasterInfo.size.height / pasterInfo.size.width * width;
    CGRect frame = CGRectIntegral(CGRectMake((_videoPreview.width - width) / 2, (_videoPreview.height - height) / 2, width, height));
    VideoPasterView *pasterView = [[VideoPasterView alloc] initWithFrame:frame];
    pasterView.delegate = self;
    
    pasterInfo.pasterView = pasterView;

    if (pasterInfo.imageList) {
        [pasterView setImageList:pasterInfo.imageList imageDuration:pasterInfo.duration];
    } else {
        [pasterView setImageList:@[pasterInfo.image] imageDuration:0];
    }
    [_videoPreview addSubview:pasterView];
    [_videoPasterInfos addObject:pasterInfo];
    [_videoPasterCollection reloadData];
    [self setVideoPasters:_videoPasterInfos];
    return pasterView;
}

- (float)getStartTime
{
    CGFloat time = 0;
    
    if (_videoPasterInfos.count > 0) {
        VideoPasterInfo * info = [_videoPasterInfos lastObject];
        time = info.endTime;
    }
    
    if (time == 0) {
        time = (_videoStartTime);
    } else {
        time += (_videoStartTime + 0.5);
    }
    
    if (time >= _videoEndTime) {
        time = _videoStartTime;
    }
    return time;
}

- (float)getEndTime:(float)startTime
{
    CGFloat time = startTime + (_videoEndTime - _videoStartTime)  /  10;
    if (time >= _videoEndTime) {
        time = _videoEndTime;
    }
    return time;
}

//播放条拖动
- (void)onProgressSlided:(UISlider*)progressSlider
{
    _progressedLabel.x = _progressView.x + (progressSlider.value - _videoStartTime) / _videoDuration * (_progressView.width - _progressView.currentThumbImage.size.width);
    _progressedLabel.text = [NSString stringWithFormat:@"%.02f", progressSlider.value - _videoStartTime];
    [_ugcEditer previewAtTime:progressSlider.value];
    _previewAtTime = progressSlider.value;
}

//播放条拖动结束
- (void)onProgressSlideEnd:(UISlider*)progressSlider
{
    if (_isVideoPlaying){
        [_ugcEditer startPlayFromTime:progressSlider.value toTime:_videoEndTime];
    }
}

//返回
- (void)goBack
{
    [self hideVideoPasterView];
    [self showVideoPasterInfo:nil];
    [self setVideoPasters:_videoPasterInfos];
    for (VideoPasterInfo *info in _videoPasterInfos) {
        [info.pasterView removeFromSuperview];
    }
    [_videoPreview removeFromSuperview];
    [self.delegate onSetVideoPasterInfosFinish:_videoPasterInfos];
    [self dismissViewControllerAnimated:YES completion:nil];
}

//点击选中贴纸
- (void)onTap:(UITapGestureRecognizer*)recognizer
{
    CGPoint tapPoint = [recognizer locationInView:recognizer.view];
    
    BOOL hasPaster = NO;
    for (NSInteger i = 0; i < _videoPasterInfos.count; i++) {
        CGRect pasterFrame = [_videoPasterInfos[i].pasterView pasterFrameOnView:recognizer.view];
        if (CGRectContainsPoint(pasterFrame, tapPoint)) {
            VideoPasterInfo *info = _videoPasterInfos[i];
            if (_previewAtTime >= info.startTime && _previewAtTime <= info.endTime) {
                [self showVideoPasterInfo:info];
                hasPaster = YES;
                break;
            }
        }
    }
    if (!hasPaster) {
        [self hideVideoPasterView];
    }
}

#pragma mark - VideoTextFieldDelegate

//删除在文字操作view
- (void)onRemovePasterView:(VideoPasterView*)pasterView;
{
    NSInteger index = [_videoPasterInfos indexOfObject:_selectedPasterInfo];
    
    VideoPasterInfo* info = [self getSelectedVideoTextInfo];
    [_videoPasterInfos removeObject:info];
    [_videoPasterCollection reloadData];
    [self setVideoPasters:_videoPasterInfos];
    [self setProgressHidden:NO];
    
    if (index != NSNotFound && _videoPasterInfos.count > 0) {
        VideoPasterInfo *next = nil;
        if (index < _videoPasterInfos.count) {
            next = _videoPasterInfos[index];
        } else {
            next = _videoPasterInfos.lastObject;
        }
        [self showVideoPasterInfo:next];
    }
}

#pragma mark - RangeContentDelegate
- (void)onRangeLeftChanged:(RangeContent *)sender
{
    CGFloat textStartTime =  _videoStartTime + sender.leftScale * (_videoDuration);
    [_ugcEditer previewAtTime:textStartTime];
    _leftTimeLabel.frame = CGRectMake(_videoRangeSlider.x + _videoRangeSlider.leftPin.x, _videoRangeSlider.top - 12, 30, 10);
    _leftTimeLabel.text = [NSString stringWithFormat:@"%.02f", sender.leftScale * _videoDuration];
    _previewAtTime = textStartTime;
}

- (void)onRangeLeftChangeEnded:(RangeContent *)sender
{
    CGFloat pasterStartTime =  _videoStartTime + sender.leftScale * (_videoDuration);
    [_ugcEditer previewAtTime:pasterStartTime];
    VideoPasterInfo* pasterInfo = [self getSelectedVideoTextInfo];
    pasterInfo.startTime = pasterStartTime;
    _previewAtTime = pasterStartTime;
}

- (void)onRangeRightChanged:(RangeContent *)sender
{
    CGFloat textEndTime =  _videoStartTime+ sender.rightScale * (_videoDuration);
    [_ugcEditer previewAtTime:textEndTime];
    _rightTimeLabel.frame = CGRectMake(_videoRangeSlider.x + _videoRangeSlider.rightPin.x, _videoRangeSlider.top - 12, 30, 10);
    _rightTimeLabel.text = [NSString stringWithFormat:@"%.02f", sender.rightScale * _videoDuration];
    _previewAtTime = textEndTime;
}

- (void)onRangeRightChangeEnded:(RangeContent *)sender
{
    CGFloat pasterEndTime =  _videoStartTime+ sender.rightScale * (_videoDuration);
    [_ugcEditer previewAtTime:pasterEndTime];
    VideoPasterInfo* pasterInfo = [self getSelectedVideoTextInfo];
    pasterInfo.endTime = pasterEndTime;
    _previewAtTime = pasterEndTime;
}

#pragma mark - VideoPreviewDelegate
- (void)onVideoPlay
{
    [_ugcEditer startPlayFromTime:_videoStartTime toTime:_videoEndTime];
    [_playBtn setImage:[UIImage imageNamed:@"videotext_stop"] forState:UIControlStateNormal];
    _isVideoPlaying = YES;
    [self hideVideoPasterView];
}

- (void)onVideoPause
{
    [_ugcEditer pausePlay];
    [_playBtn setImage:[UIImage imageNamed:@"videotext_play"] forState:UIControlStateNormal];
    _isVideoPlaying = NO;
}

- (void)onVideoResume
{
    [_ugcEditer startPlayFromTime:_progressView.value toTime:_videoEndTime];
    _isVideoPlaying = YES;
    [self hideVideoPasterView];
}

- (void)onVideoPlayProgress:(CGFloat)time
{
    _progressView.value = time;
    _previewAtTime = time;
    _progressedLabel.text = [NSString stringWithFormat:@"%.02f", time - _videoStartTime];
    _progressedLabel.x = _progressView.x + (time - _videoStartTime) / _videoDuration * (_progressView.width - _progressView.currentThumbImage.size.width);
}

- (void)onVideoPlayFinished
{
    _isVideoPlaying = NO;
    [self onVideoPlay];
}

- (void)onVideoEnterBackground
{
    //进后台，暂停播放
    if (_isVideoPlaying) {
        [_ugcEditer pausePlay];
        [_playBtn setImage:[UIImage imageNamed:@"videotext_play"] forState:UIControlStateNormal];
        _isVideoPlaying = NO;
    }
}

@end

