//
//  VideoTextViewController.m
//  DeviceManageIOSApp
//
//  Created by rushanting on 2017/5/18.
//  Copyright © 2017年 tencent. All rights reserved.
//

#import "VideoTextViewController.h"
#import "TXLiteAVSDKHeader.h"
#import "VideoPreview.h"
#import "UIView+Additions.h"
#import "TXColor.h"
#import "RangeContent.h"
#import "TextCollectionCell.h"
#import "VideoTextFiled.h"
#import "PasterSelectView.h"
#import "Masonry.h"

@implementation VideoTextInfo
@end


@interface VideoTextViewController () <VideoPreviewDelegate, UICollectionViewDelegate, UICollectionViewDataSource, RangeContentDelegate, VideoTextFieldDelegate , PasterSelectViewDelegate>
{
    VideoPreview  *_videoPreview;       //视频预览view
    TXVideoEditer* _ugcEditer;          //sdk的editer
    
    RangeContent* _videoRangeSlider;    //字幕的时间区域操作条
    UILabel*       _leftTimeLabel;
    UILabel*       _rightTimeLabel;
    
    UISlider*   _progressView;          //播放进度条
    UILabel*    _progressedLabel;       //播放时间
    
    UICollectionView* _videoTextCollection; //己添加字幕列表
    
    UIButton*      _playBtn;            //播放按钮
    
    CGFloat        _videoStartTime;     //裁剪的视频开始时间
    CGFloat        _videoEndTime;       //裁剪的视频结束时间
    
    CGFloat        _previewAtTime;      //预览时间点
    
    CGFloat        _videoDuration;      //裁剪的视频总时间
    UILabel*       _timeLabel;
    
    BOOL            _isVideoPlaying;
    
    NSMutableArray<VideoTextInfo*>* _videoTextInfos;    //字幕列表信息
    
    UITapGestureRecognizer* _singleTap;
    
    PasterSelectView *  _selectView;
    NSArray *      _qipaoList;
}

@end

@implementation VideoTextViewController

- (id)initWithVideoEditer:(TXVideoEditer *)videoEditer previewView:(VideoPreview *)previewView startTime:(CGFloat)startTime endTime:(CGFloat)endTime videoTextInfos:(NSArray<VideoTextInfo *> *)videoTextInfos
{
    if (self = [super init]) {
        _ugcEditer = videoEditer;
        _videoPreview = previewView;
        _videoPreview.delegate = self;
        _videoStartTime = startTime;
        _videoEndTime = endTime;
        _videoDuration = endTime - startTime;
        
        _videoTextInfos = videoTextInfos.mutableCopy;
        //未添加过字幕
        if (!_videoTextInfos) {
            _videoTextInfos = [NSMutableArray new];
        } else {
            //有己添加过字幕时
            for (VideoTextInfo* textInfo in _videoTextInfos) {
                textInfo.textField.delegate = self;
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
//    _videoPreview.frame = CGRectMake(0, 0, self.view.width, 432 * kScaleY);
//    _videoPreview.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
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
    bottomView.backgroundColor = TXColor.black;
    [self.view addSubview:bottomView];
    
    UIButton* newTextBtn = [[UIButton alloc] initWithFrame:CGRectMake(17.5 * kScaleX, 20 * kScaleY, 40, 40)];
    [newTextBtn setImage:[UIImage imageNamed:@"text_add"] forState:UIControlStateNormal];
    newTextBtn.backgroundColor = UIColor.clearColor;
    newTextBtn.layer.borderWidth = 1;
    newTextBtn.layer.borderColor = TXColor.gray.CGColor;
    [newTextBtn addTarget:self action:@selector(onNewTextBtnClicked:) forControlEvents:UIControlEventTouchUpInside];
    [bottomView addSubview:newTextBtn];
    
    UICollectionViewFlowLayout* layout = [UICollectionViewFlowLayout new];
    layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    _videoTextCollection = [[UICollectionView alloc] initWithFrame:CGRectMake(newTextBtn.right + 10, 20 * kScaleY, self.view.width - 35 - 10, 40) collectionViewLayout:layout];
    _videoTextCollection.delegate = self;
    _videoTextCollection.dataSource = self;
    _videoTextCollection.backgroundColor = UIColor.clearColor;
    _videoTextCollection.allowsMultipleSelection = NO;
    [_videoTextCollection registerClass:[TextCollectionCell class] forCellWithReuseIdentifier:@"TextCollectionCell"];
    [bottomView addSubview:_videoTextCollection];
    
    [self createSelectView];
    
    //点击选中文字
    _singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onTap:)];
    [_videoPreview addGestureRecognizer:_singleTap];
}

- (void)createSelectView
{
    NSString *bundlePath = [[NSBundle mainBundle] pathForResource:@"bubbleText" ofType:@"bundle"];
    int height = 80 * kScaleY;
    CGFloat offset = 0;
    if (@available(iOS 11, *)) {
        offset = [UIApplication sharedApplication].keyWindow.safeAreaInsets.bottom;
    }
    _selectView = [[PasterSelectView alloc] initWithFrame:CGRectMake(0, self.view.bottom - height - 60 - offset, self.view.width, height) pasterType:PasterType_Qipao boundPath:bundlePath];
    _selectView.delegate = self;
    _selectView.hidden = YES;
    [self.view addSubview:_selectView];
}

#pragma mark PasterSelectViewDelegate
- (void)onPasterQipaoSelect:(PasterQipaoInfo *)info
{
    if (_videoTextInfos.count > 0) {
        int width = 170;
        int height = info.height / info.width * width;
        
        VideoTextInfo* textInfo =  [self getSelectedVideoTextInfo];;
        VideoTextFiled *textField = textInfo.textField;
        [textField setTextBubbleImage:info.image textNormalizationFrame:CGRectMake(info.textLeft / info.width, info.textTop / info.height, (info.width - info.textLeft - info.textRight) / info.width, (info.height - info.textTop - info.textBottom) / info.height)];
        textField.frame = CGRectMake((_videoPreview.width - width) / 2, (_videoPreview.height - height) / 2, width, height);
    }
    _selectView.hidden = YES;
}

- (void)onBubbleTap
{
    _selectView.hidden = NO;
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
        NSArray* indexPaths = [_videoTextCollection indexPathsForSelectedItems];
        if (indexPaths.count > 0) {
            [_videoTextCollection deselectItemAtIndexPath:indexPaths[0] animated:NO];
        }
        //不选中作何字幕
        [self showVideoTextInfo:nil];
    }
}

//当前选中的字幕信息
- (VideoTextInfo*)getSelectedVideoTextInfo
{
    NSArray<NSIndexPath *> *indexPathsForSelectedItems =  [_videoTextCollection indexPathsForSelectedItems];
    if (indexPathsForSelectedItems.count > 0) {
        NSIndexPath* selectedIndexPath = [_videoTextCollection indexPathsForSelectedItems][0];
        if (selectedIndexPath.row < _videoTextInfos.count) {
            return _videoTextInfos[selectedIndexPath.row];
        }
    }
    return nil;
}

- (void)showVideoTextInfo:(VideoTextInfo*)textInfo
{
    NSMutableArray<VideoTextInfo*>* videoTexts = [NSMutableArray new];
    
    //除正在操作的字幕外，其它字幕在预览中生效
    for (VideoTextInfo* info in _videoTextInfos) {
        info.textField.hidden = YES;
        if (info != textInfo) {
            [videoTexts addObject:info];
        }
    }
    
    if (!textInfo)
        return;
    
    //设置展示当前选中字幕的时间信息
    textInfo.textField.hidden = NO;
    [_videoPreview addSubview:textInfo.textField];
    
    CGFloat leftX = MAX(0, (textInfo.startTime - _videoStartTime)) / (_videoDuration) * _videoRangeSlider.imageWidth;
    CGFloat rightX = MIN(_videoDuration, (textInfo.endTime - _videoStartTime)) / (_videoDuration) * _videoRangeSlider.imageWidth;
    _videoRangeSlider.leftPinCenterX = leftX + _videoRangeSlider.pinWidth / 2;
    _videoRangeSlider.rightPinCenterX = MAX(_videoRangeSlider.leftPinCenterX + _videoRangeSlider.pinWidth, rightX + _videoRangeSlider.pinWidth * 3 / 2);
    [_videoRangeSlider setNeedsLayout];
    
    _leftTimeLabel.frame = CGRectMake(_videoRangeSlider.x + _videoRangeSlider.leftPinCenterX - _videoRangeSlider.pinWidth / 2, _videoRangeSlider.top - 12, 30, 10);
    _leftTimeLabel.text = [NSString stringWithFormat:@"%.02f", _videoRangeSlider.leftScale *_videoDuration];
    
    _rightTimeLabel.frame = CGRectMake(_videoRangeSlider.x + _videoRangeSlider.rightPinCenterX - _videoRangeSlider.pinWidth / 2, _videoRangeSlider.top - 12, 30, 10);
    _rightTimeLabel.text = [NSString stringWithFormat:@"%.02f", _videoRangeSlider.rightScale *_videoDuration];
    
    _previewAtTime = textInfo.startTime;
    
    [self setVideoSubtitles:videoTexts];
    [self setProgressHidden:YES];

}

//设置字幕
- (void)setVideoSubtitles:(NSArray<VideoTextInfo*>*)videoTextInfos
{
    NSMutableArray* subtitles = [NSMutableArray new];

    NSMutableArray<VideoTextInfo*>* emptyVideoTexts;
    
    for (VideoTextInfo* textInfo in videoTextInfos) {
        if (textInfo.textField.text.length < 1) {
            [emptyVideoTexts addObject:textInfo];
            continue;
        }
        
        TXSubtitle* subtitle = [TXSubtitle new];
        subtitle.titleImage = textInfo.textField.textImage;
        subtitle.frame = [textInfo.textField textFrameOnView:_videoPreview];
        subtitle.startTime = textInfo.startTime;
        subtitle.endTime = textInfo.endTime;
        [subtitles addObject:subtitle];
    }
    
    [_ugcEditer setSubtitleList:subtitles];
}



#pragma mark - UICollectionViewDataSource
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return _videoTextInfos.count;
}

- (UICollectionViewCell*)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *identify = @"TextCollectionCell";
    
    TextCollectionCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:identify forIndexPath:indexPath];
    
    if (indexPath.row < _videoTextInfos.count) {
        VideoTextInfo* info = _videoTextInfos[indexPath.row];
        cell.textLabel.text = info.textField.text;
    }
    
    return cell;
    
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    VideoTextInfo* textInfo = [self getSelectedVideoTextInfo];
    //if (_previewAtTime < textInfo.startTime || _previewAtTime > textInfo.endTime) {
        _previewAtTime = textInfo.startTime;
    //}
    [self showVideoTextInfo:textInfo];
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return CGSizeMake(40, 40);
}

//设置每个item水平间距
- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section
{
    return 10;
}


#pragma mark - UI event Handle
//播放，每次从头开始
- (void)onPlayBtnClicked:(UIButton*)sender
{
    [self setProgressHidden:NO];
    if (!_isVideoPlaying) {
        [self setVideoSubtitles:_videoTextInfos];
        [_ugcEditer startPlayFromTime:_videoStartTime toTime:_videoEndTime];
        [_playBtn setImage:[UIImage imageNamed:@"videotext_stop"] forState:UIControlStateNormal];
        _isVideoPlaying = YES;
    } else {
        [_ugcEditer pausePlay];
        [_playBtn setImage:[UIImage imageNamed:@"videotext_play"] forState:UIControlStateNormal];
        _isVideoPlaying = NO;
        
        _previewAtTime = _progressView.value;
    }
    _selectView.hidden = YES;
}

//新添加文字
- (void)onNewTextBtnClicked:(UIButton*)sender
{
    _selectView.hidden = NO;
    
    [self setProgressHidden:YES];
    
    VideoTextFiled* videoTextField = [[VideoTextFiled alloc] initWithFrame:CGRectMake((_videoPreview.width - 170) / 2, (_videoPreview.height - 50) / 2, 170, 50)];
    videoTextField.delegate = self;
    [_videoPreview addSubview:videoTextField];

    VideoTextInfo* info = [VideoTextInfo new];
    info.textField = videoTextField;
    info.startTime = [self getStartTime];
    info.endTime = [self getEndTime:info.startTime];
    [_videoTextInfos addObject:info];
    
    [_videoTextCollection reloadData];
    [_videoTextCollection performBatchUpdates:nil completion:^(BOOL finished) {
        NSIndexPath* indexPath = [NSIndexPath indexPathForRow:_videoTextInfos.count - 1 inSection:0];
        [_videoTextCollection selectItemAtIndexPath:indexPath animated:YES scrollPosition:UICollectionViewScrollPositionCenteredHorizontally];
    }];
    
    _previewAtTime = info.startTime;
    
    [self showVideoTextInfo:info];
}

- (float)getStartTime
{
    CGFloat time = 0;
    if (_videoTextInfos.count > 0) {
        VideoTextInfo * info = [_videoTextInfos lastObject];
        time += info.endTime;
    }
    
    if (time == 0) {
        time += (_videoStartTime);
    }else{
        time += (_videoStartTime + 0.5);
    }
  
    if (time >= _videoEndTime) {
        time = 0;
    }
    return time;
}

- (float)getEndTime:(float)startTime
{
    CGFloat time = startTime + (_videoEndTime - _videoStartTime) / 10;
    if (time >= _videoEndTime) {
        time = _videoEndTime;
    }
    return time;
}

//播放条拖动，
- (void)onProgressSlided:(UISlider*)progressSlider
{
    _progressedLabel.x = _progressView.x + (progressSlider.value - _videoStartTime) / _videoDuration * (_progressView.width - _progressView.currentThumbImage.size.width);
    _progressedLabel.text = [NSString stringWithFormat:@"%.02f", progressSlider.value - _videoStartTime];
    [_ugcEditer previewAtTime:progressSlider.value];
    
    _previewAtTime = progressSlider.value;

}

- (void)onProgressSlideEnd:(UISlider*)progressSlider
{
//    [_ugcEditer pausePlay];
    if (_isVideoPlaying)
        [_ugcEditer startPlayFromTime:progressSlider.value toTime:_videoEndTime];
    //_isVideoPlaying = YES;
    //[_playBtn setImage:[UIImage imageNamed:@"videotext_stop"] forState:UIControlStateNormal];
}

//返回
- (void)goBack
{
    [self setVideoSubtitles:_videoTextInfos];
    
    for (VideoTextInfo* info in _videoTextInfos) {
        [info.textField resignFirstResponser];
        [info.textField removeFromSuperview];
    }
    
    [_videoPreview removeFromSuperview];
    
    [self.delegate onSetVideoTextInfosFinish:_videoTextInfos];
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

//点击选中文字
- (void)onTap:(UITapGestureRecognizer*)recognizer
{
    CGPoint tapPoint = [recognizer locationInView:recognizer.view];
    
    BOOL hasText = NO;
    for (NSInteger i = 0; i < _videoTextInfos.count; i++) {
        CGRect textFrame = [_videoTextInfos[i].textField textFrameOnView:recognizer.view];
        if (CGRectContainsPoint(textFrame, tapPoint)) {
            VideoTextInfo *info = _videoTextInfos[i];
            if (_previewAtTime >= info.startTime && _previewAtTime <= info.endTime){
                NSIndexPath* indexPath = [NSIndexPath indexPathForRow:i inSection:0];
                [_videoTextCollection selectItemAtIndexPath:indexPath animated:YES scrollPosition:UICollectionViewScrollPositionCenteredHorizontally];
                [self showVideoTextInfo:info];
                hasText = YES;
                break;
            }
        }
    }
    if (!hasText) {
        _selectView.hidden = YES;
    }
}

#pragma mark - VideoTextFieldDelegate
//文字输入完成
- (void)onTextInputDone:(NSString *)text
{
    NSIndexPath* selectedIndexPath = [_videoTextCollection indexPathsForSelectedItems][0];
    TextCollectionCell* selectedCell = (TextCollectionCell*)[_videoTextCollection cellForItemAtIndexPath:selectedIndexPath];
    selectedCell.textLabel.text = text;
}

//删除在文字操作view
- (void)onRemoveTextField:(VideoTextFiled *)textField
{
    VideoTextInfo* info = [self getSelectedVideoTextInfo];
    [info.textField resignFirstResponser];
    [_videoTextInfos removeObject:info];
    [_videoTextCollection reloadData];
    
    //没有了选中字幕,显示播放条
    [self setProgressHidden:NO];
    [self setVideoSubtitles:_videoTextInfos];
    [_selectView setHidden:YES];
}

#pragma mark - RangeContentDelegate
- (void)onRangeLeftChanged:(RangeContent *)sender
{
    CGFloat textStartTime =  _videoStartTime + sender.leftScale * (_videoDuration);
    //[_ugcEditer startPlayFromTime:textStartTime toTime:textEndTime];
    [_ugcEditer previewAtTime:textStartTime];
    
    _leftTimeLabel.frame = CGRectMake(_videoRangeSlider.x + _videoRangeSlider.leftPin.x, _videoRangeSlider.top - 12, 30, 10);
    _leftTimeLabel.text = [NSString stringWithFormat:@"%.02f", sender.leftScale * _videoDuration];
    
    _previewAtTime = textStartTime;
}

- (void)onRangeLeftChangeEnded:(RangeContent *)sender
{
    CGFloat textStartTime =  _videoStartTime + sender.leftScale * (_videoDuration);
    //[_ugcEditer startPlayFromTime:textStartTime toTime:textEndTime];
    [_ugcEditer previewAtTime:textStartTime];
    
    VideoTextInfo* textInfo = [self getSelectedVideoTextInfo];
    textInfo.startTime = textStartTime;
    
    _previewAtTime = textStartTime;
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
    CGFloat textEndTime =  _videoStartTime+ sender.rightScale * (_videoDuration);
    [_ugcEditer previewAtTime:textEndTime];
    
    VideoTextInfo* textInfo = [self getSelectedVideoTextInfo];
    textInfo.endTime = textEndTime;
    
    _previewAtTime = textEndTime;
}

#pragma mark - VideoPreviewDelegate
- (void)onVideoPlay
{
    [_ugcEditer startPlayFromTime:_videoStartTime toTime:_videoEndTime];
    [_playBtn setImage:[UIImage imageNamed:@"videotext_stop"] forState:UIControlStateNormal];

    _isVideoPlaying = YES;
    _selectView.hidden = YES;
}

- (void)onVideoPause
{
    [_ugcEditer pausePlay];
    [_playBtn setImage:[UIImage imageNamed:@"videotext_play"] forState:UIControlStateNormal];
    _isVideoPlaying = NO;

}

- (void)onVideoResume
{
    //[_ugcEditer resumePlay];
    [_ugcEditer startPlayFromTime:_progressView.value toTime:_videoEndTime];
    _isVideoPlaying = YES;
    _selectView.hidden = YES;
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
