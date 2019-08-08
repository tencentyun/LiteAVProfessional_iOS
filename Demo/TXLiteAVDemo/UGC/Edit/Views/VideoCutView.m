//
//  VideoCutView.m
//  DeviceManageIOSApp
//
//  Created by rushanting on 2017/5/11.
//  Copyright © 2017年 tencent. All rights reserved.
//

#import "VideoCutView.h"
#import "VideoRangeConst.h"
#import "VideoRangeSlider.h"
#import "TXColor.h"
#import "UIView+Additions.h"
#import "TXLiteAVSDKHeader.h"

@interface VideoCutView ()<VideoRangeSliderDelegate>

@end

@implementation VideoCutView
{
    CGFloat         _duration;          //视频时长
    float           _fps;
    UILabel*        _timeTipsLabel;    //当前播放时间显示
    NSString*       _videoPath;         //视频路径
    AVAsset*        _videoAsset;
    UIButton*       _effectDeleteBtn;
    UILabel *       _cutTipsLabel;
    BOOL            _isContinue;
}

- (id)initWithFrame:(CGRect)frame videoPath:(NSString *)videoPath  orVideoAsset:(AVAsset *)videoAsset
{
    if (self = [super initWithFrame:frame]) {
        _videoPath = videoPath;
        _videoAsset = videoAsset;
        if (videoAsset == nil) {
            _videoAsset = [AVAsset assetWithURL:[NSURL fileURLWithPath:videoPath]];
        }
        TXVideoInfo *info = [TXVideoInfoReader getVideoInfoWithAsset:_videoAsset];
        _duration   = info.duration;
        _fps = info.fps;
        _imageList = [NSMutableArray new];
        int imageNum = 12;
        
        _isContinue = YES;
        
        [self initUI];

        UIGraphicsBeginImageContext(CGSizeMake(1, 1));
        UIImage *placeholder = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        CGFloat size = round(frame.size.height * [UIScreen mainScreen].scale);
        [TXVideoInfoReader getSampleImages:imageNum maxSize:CGSizeMake(size, size) videoAsset:_videoAsset progress:^BOOL(int number, UIImage *image) {
            if (!_isContinue) {
                return NO;
            }else{
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (!_isContinue) {
                        return;
                    } else {
                        int index = number - 1;
                        UIImage *img = image ?: placeholder;
                        if (_imageList.count == 0) {
                            _videoRangeSlider.delegate = self;
                            for (int i = 0; i < imageNum; i++) {
                                [_imageList addObject:img];
                            }
                            [_videoRangeSlider setImageList:_imageList];
                            [_videoRangeSlider setDurationMs:_duration];
                        } else {
                            _imageList[index] = img;
                            [_videoRangeSlider updateImage:img atIndex:index];
                        }
                    }
                });
                return YES;
            }
        }];
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame pictureList:(NSMutableArray *)pictureList  duration:(CGFloat)duration fps:(float)fps
{
    if (self = [super initWithFrame:frame]) {
        _duration   = duration;
        _fps = fps;
        _imageList = pictureList;
        [self initUI];
        [_videoRangeSlider setImageList:_imageList];
        [_videoRangeSlider setDurationMs:_duration];
    }
    return self;
}

- (void)updateFrame:(CGFloat)duration
{
    _duration = duration;
    [_videoRangeSlider setDurationMs:_duration];
}

- (void)initUI
{
    _timeTipsLabel = [[UILabel alloc] init];
    _timeTipsLabel.text = @"0 s";
    _timeTipsLabel.textAlignment = NSTextAlignmentCenter;
    _timeTipsLabel.font = [UIFont systemFontOfSize:14];
    _timeTipsLabel.textColor = TXColor.gray;
    [self addSubview:_timeTipsLabel];
    
    _videoRangeSlider = [[VideoRangeSlider alloc] init];
    _videoRangeSlider.fps = _fps;
    [self addSubview:_videoRangeSlider];
    _videoRangeSlider.delegate = self;

    CGFloat width = 42 * 0.7 * kScaleX;
    CGFloat height = 32 * 0.7 * kScaleY;
    _effectDeleteBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [_effectDeleteBtn setBackgroundImage:[UIImage imageNamed:@"effectDelete" inBundle:nil compatibleWithTraitCollection:nil] forState:UIControlStateNormal];
    _effectDeleteBtn.titleLabel.textColor = [UIColor redColor];
    _effectDeleteBtn.frame = CGRectMake(self.width - width - 20, 10, width, height);
    _effectDeleteBtn.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin;
    [_effectDeleteBtn addTarget:self action:@selector(onEffectDelete) forControlEvents:UIControlEventTouchUpInside];
    _effectDeleteBtn.hidden = YES;
    [self addSubview:_effectDeleteBtn];
    
    _cutTipsLabel = [[UILabel alloc] init];
    _cutTipsLabel.text = @"请选择视频的剪裁区域";
    _cutTipsLabel.font = [UIFont systemFontOfSize:14];
    _cutTipsLabel.textAlignment = NSTextAlignmentCenter;
    [self addSubview:_cutTipsLabel];
    
    _timeTipsLabel.frame = CGRectMake(self.width / 2 - 30 * kScaleX, 0, 60 * kScaleX, 20 * kScaleY);
    _videoRangeSlider.frame = CGRectMake(0, _effectDeleteBtn.bottom, self.width,  self.height - _effectDeleteBtn.bottom);
}

- (void)stopGetImageList
{
    _isContinue = NO;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
}

- (void)dealloc
{
    NSLog(@"VideoCutView dealloc");
}

- (void)setPlayTime:(CGFloat)time
{
    _videoRangeSlider.currentPos = time;
    _timeTipsLabel.text = [NSString stringWithFormat:@"%.2f s",time];
}

- (void)setCenterPanHidden:(BOOL)isHidden
{
    [_videoRangeSlider setCenterPanHidden:isHidden];
}

- (void)setCenterPanFrame:(CGFloat)time
{
    [_videoRangeSlider setCenterPanFrame:time];
}

- (void)setEffectDeleteBtnHidden:(BOOL)isHidden
{
    [_effectDeleteBtn setHidden:isHidden];
}

- (void)startColoration:(UIColor *)color alpha:(CGFloat)alpha
{
    [_videoRangeSlider startColoration:color alpha:alpha];
}
- (void)stopColoration
{
    [_videoRangeSlider stopColoration];
}

- (NSUInteger)coloredCount
{
    return [_videoRangeSlider coloredCount];
}

- (void)removeLastColoration
{
    [self _removeLastColoration];
}

- (VideoColorInfo *)_removeLastColoration
{
    return [_videoRangeSlider removeLastColoration];
}

- (void)onEffectDelete
{
    VideoColorInfo *info = [self _removeLastColoration];
    [self.delegate onEffectDelete:info];
}

#pragma mark - VideoRangeDelegate
//左拉
- (void)onVideoRangeLeftChanged:(VideoRangeSlider *)sender
{
    [self.delegate onVideoLeftCutChanged:sender];
}

- (void)onVideoRangeLeftChangeEnded:(VideoRangeSlider *)sender
{
    _videoRangeSlider.currentPos = sender.leftPos;
    _timeTipsLabel.text = [NSString stringWithFormat:@"%.2f s",sender.leftPos];
    [self.delegate onVideoCutChangedEnd:sender];
}

//中拉
- (void)onVideoRangeCenterChanged:(VideoRangeSlider *)sender
{
    [self.delegate onVideoCenterRepeatChanged:sender];
}

- (void)onVideoRangeCenterChangeEnded:(VideoRangeSlider *)sender
{
    [self.delegate onVideoCenterRepeatEnd:sender];
}

//右拉
- (void)onVideoRangeRightChanged:(VideoRangeSlider *)sender {
    [self.delegate onVideoRightCutChanged:sender];
}

- (void)onVideoRangeRightChangeEnded:(VideoRangeSlider *)sender
{
    _videoRangeSlider.currentPos = sender.leftPos;
    _timeTipsLabel.text = [NSString stringWithFormat:@"%.2f s",sender.leftPos];
    [self.delegate onVideoCutChangedEnd:sender];
}

- (void)onVideoRangeLeftAndRightChanged:(VideoRangeSlider *)sender {
    
}

//拖动缩略图条
- (void)onVideoRange:(VideoRangeSlider *)sender seekToPos:(CGFloat)pos {
    _timeTipsLabel.text = [NSString stringWithFormat:@"%.2f s",pos];
    [self.delegate onVideoCutChange:sender seekToPos:pos];
}

@end
