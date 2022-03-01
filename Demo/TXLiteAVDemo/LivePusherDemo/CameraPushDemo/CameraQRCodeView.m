//
//  CameraQRCodeView.m
//  TXLiteAVDemo
//
//  Created by adams on 2021/7/22.
//  Copyright © 2021 Tencent. All rights reserved.
//

#import "CameraQRCodeView.h"

#import <MBProgressHUD.h>
#import <Masonry.h>

#import "AppLocalized.h"
#import "CameraStartPushViewController.h"
#import "ColorMacro.h"
#import "QRCode.h"

static CGFloat const QRCode_ImageSize = 122.0;

@implementation CameraQRCodeModel

@end

@interface CameraQRCodeView () <UICollectionViewDelegate, UICollectionViewDataSource> {
    UILabel *          _descLabel;
    CameraQRCodeModel *_selectedQRModel;
}

@property(nonatomic, strong) NSDictionary *                       streamDictionary;
@property(nonatomic, strong) UICollectionView *                   collectionView;
@property(nonatomic, strong) NSMutableArray<CameraQRCodeModel *> *collectionDataSource;
@property(nonatomic, strong) UIImageView *                        qrImageView;

@end

@class CameraQRCodeCell;
@class CameraQRCodeModel;

@implementation CameraQRCodeView

#pragma mark - lazy property
- (UICollectionView *)collectionView {
    if (!_collectionView) {
        UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
        layout.scrollDirection             = UICollectionViewScrollDirectionVertical;
        layout.minimumLineSpacing          = 20;
        layout.minimumInteritemSpacing     = 30;
        CGFloat width                      = (264 - 30) * 0.5;
        CGFloat height                     = 25;
        layout.itemSize                    = CGSizeMake(width, height);

        _collectionView                 = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
        _collectionView.delegate        = self;
        _collectionView.dataSource      = self;
        _collectionView.backgroundColor = UIColor.clearColor;
        [_collectionView registerClass:[CameraQRCodeCell class] forCellWithReuseIdentifier:NSStringFromClass(CameraQRCodeCell.class)];
    }
    return _collectionView;
}

- (UIImageView *)qrImageView {
    if (!_qrImageView) {
        _qrImageView = [[UIImageView alloc] initWithFrame:CGRectZero];
    }
    return _qrImageView;
}

#pragma mark - init
- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.collectionDataSource = [NSMutableArray array];
        [self setupView];
    }
    return self;
}

- (void)setupView {
    UIView *containerView         = [[UIView alloc] initWithFrame:CGRectZero];
    containerView.backgroundColor = UIColorFromRGB(0x18182E);
    [self addSubview:containerView];

    UILabel *titleLabel                  = [[UILabel alloc] initWithFrame:CGRectZero];
    titleLabel.text                      = V2Localize(@"MLVB.CameraQRCode.Playback");
    titleLabel.font                      = [UIFont fontWithName:@"PingFangSC-Semibold" size:14];
    titleLabel.textColor                 = UIColor.whiteColor;
    titleLabel.textAlignment             = NSTextAlignmentCenter;
    titleLabel.adjustsFontSizeToFitWidth = true;
    titleLabel.numberOfLines             = 2;
    [containerView addSubview:titleLabel];

    UILabel *descLabel                  = [[UILabel alloc] initWithFrame:CGRectZero];
    descLabel.text                      = V2Localize(@"MLVB.CameraQRCode.Useanother");
    descLabel.font                      = [UIFont fontWithName:@"PingFangSC-Semibold" size:12];
    descLabel.textColor                 = UIColorFromRGB(0x7689BC);
    descLabel.textAlignment             = NSTextAlignmentCenter;
    descLabel.adjustsFontSizeToFitWidth = true;
    descLabel.numberOfLines             = 2;
    [containerView addSubview:descLabel];
    _descLabel = descLabel;

    [titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(containerView.mas_left).offset(10);
        make.right.equalTo(containerView.mas_right).offset(-10);
        make.top.equalTo(containerView.mas_top).offset(10);
    }];

    [descLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(containerView.mas_left).offset(10);
        make.right.equalTo(containerView.mas_right).offset(-10);
        make.top.equalTo(titleLabel.mas_bottom).offset(14);
    }];

    [containerView addSubview:self.collectionView];

    [containerView addSubview:self.qrImageView];

    UIButton *copyURLBtn = [[UIButton alloc] initWithFrame:CGRectZero];
    [copyURLBtn setTitle:V2Localize(@"MLVB.CameraQRCode.Copyaddress") forState:UIControlStateNormal];
    copyURLBtn.titleLabel.font = [UIFont fontWithName:@"PingFangSC-Semibold" size:14];
    [copyURLBtn setTitleColor:UIColorFromRGB(0x7689BC) forState:UIControlStateNormal];
    [copyURLBtn setImage:[UIImage imageNamed:@"copy"] forState:UIControlStateNormal];
    copyURLBtn.imageEdgeInsets  = UIEdgeInsetsMake(0, -10, 0, 0);
    copyURLBtn.imageView.bounds = CGRectMake(0, 0, 22, 22);
    [copyURLBtn addTarget:self action:@selector(copyBtnClick:) forControlEvents:UIControlEventTouchUpInside];
    [containerView addSubview:copyURLBtn];

    UIView *line         = [[UIView alloc] initWithFrame:CGRectZero];
    line.backgroundColor = UIColorFromRGB(0x979797);
    [containerView addSubview:line];

    UIButton *closeBtn       = [[UIButton alloc] initWithFrame:CGRectZero];
    closeBtn.titleLabel.font = [UIFont fontWithName:@"PingFangSC-Semibold" size:16];
    [closeBtn setTitleColor:UIColorFromRGB(0x0077FF) forState:UIControlStateNormal];
    [closeBtn setTitle:V2Localize(@"V2.Live.LinkMicNew.close") forState:UIControlStateNormal];
    [closeBtn addTarget:self action:@selector(closeBtnClick:) forControlEvents:UIControlEventTouchUpInside];
    [containerView addSubview:closeBtn];

    [containerView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self);
        make.width.mas_equalTo(284);
    }];

    [self.collectionView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(_descLabel.mas_left);
        make.right.equalTo(_descLabel.mas_right);
        make.top.equalTo(_descLabel.mas_bottom).offset(15);
        make.height.mas_equalTo(120);
    }];

    [self.qrImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.collectionView.mas_bottom).offset(15);
        make.centerX.equalTo(containerView.mas_centerX);
        make.size.mas_equalTo(CGSizeMake(QRCode_ImageSize, QRCode_ImageSize));
    }];

    [copyURLBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(containerView.mas_centerX);
        make.top.equalTo(self.qrImageView.mas_bottom).offset(10);
    }];

    [line mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(containerView.mas_left);
        make.right.equalTo(containerView.mas_right);
        make.height.mas_equalTo(1);
        make.top.equalTo(copyURLBtn.mas_bottom).offset(10);
    }];

    [closeBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(line.mas_bottom).offset(10);
        make.left.equalTo(containerView.mas_left);
        make.right.equalTo(containerView.mas_right);
        make.bottom.equalTo(containerView.mas_bottom).offset(-10);
    }];
}

#pragma mark - public method
- (void)loadStreamData:(NSDictionary *)streamDictionary {
    self.streamDictionary = streamDictionary;
    NSString *flvURL      = [streamDictionary valueForKey:kFLV_PLAY_URL];
    NSString *rtmpURL     = [streamDictionary valueForKey:kRTMP_PLAY_URL];
    NSString *hlsURL      = [streamDictionary valueForKey:kHLS_PLAY_URL];
    NSString *lebURL      = [streamDictionary valueForKey:kLEB_PLAY_URL];
    NSString *rtcURL      = [streamDictionary valueForKey:kRTC_PLAY_URL];

    CGSize   qrCodeSize      = CGSizeMake(QRCode_ImageSize, QRCode_ImageSize);
    UIImage *flvQRCodeImage  = [QRCode qrCodeWithString:flvURL size:qrCodeSize];
    UIImage *rtmpQRCodeImage = [QRCode qrCodeWithString:rtmpURL size:qrCodeSize];
    UIImage *hlsQRCodeImage  = [QRCode qrCodeWithString:hlsURL size:qrCodeSize];
    UIImage *lebQRCodeImage  = [QRCode qrCodeWithString:lebURL size:qrCodeSize];

    CameraQRCodeModel *flvModel = [[CameraQRCodeModel alloc] init];
    flvModel.title              = @"flv";
    flvModel.link               = flvURL;
    flvModel.selected           = YES;
    flvModel.qrImage            = flvQRCodeImage;
    [self.collectionDataSource addObject:flvModel];

    CameraQRCodeModel *rtmpModel = [[CameraQRCodeModel alloc] init];
    rtmpModel.title              = @"rtmp";
    rtmpModel.link               = rtmpURL;
    rtmpModel.selected           = NO;
    rtmpModel.qrImage            = rtmpQRCodeImage;
    [self.collectionDataSource addObject:rtmpModel];

    CameraQRCodeModel *hlsModel = [[CameraQRCodeModel alloc] init];
    hlsModel.title              = @"hls";
    hlsModel.link               = hlsURL;
    hlsModel.selected           = NO;
    hlsModel.qrImage            = hlsQRCodeImage;
    [self.collectionDataSource addObject:hlsModel];

    CameraQRCodeModel *lebModel = [[CameraQRCodeModel alloc] init];
    lebModel.title              = LivePlayerLocalize(@"LivePusherDemo.CameraPush.lebUrl");
    lebModel.link               = lebURL;
    lebModel.selected           = NO;
    lebModel.qrImage            = lebQRCodeImage;
    [self.collectionDataSource addObject:lebModel];

    if (rtcURL) {
        UIImage *          rtcQRCodeImage = [QRCode qrCodeWithString:rtcURL size:qrCodeSize];
        CameraQRCodeModel *rtcModel       = [[CameraQRCodeModel alloc] init];
        rtcModel.title                    = V2Localize(@"MLVB.CameraQRCode.Ultralow");
        rtcModel.link                     = rtcURL;
        rtcModel.selected                 = NO;
        rtcModel.qrImage                  = rtcQRCodeImage;
        [self.collectionDataSource addObject:rtcModel];
    }
    [self.collectionView reloadData];

    self.qrImageView.image = flvModel.qrImage;
    _selectedQRModel       = flvModel;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.35 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.collectionView selectItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0] animated:false scrollPosition:UICollectionViewScrollPositionNone];
    });
}

- (void)show {
    [UIView animateWithDuration:0.35
                     animations:^{
                         self.alpha = 1;
                     }];
}

- (void)hide {
    [UIView animateWithDuration:0.35
                     animations:^{
                         self.alpha = 0;
                     }];
}

#pragma mark - UICollectionViewDataSource
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.collectionDataSource.count;
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    CameraQRCodeCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:NSStringFromClass(CameraQRCodeCell.class) forIndexPath:indexPath];
    cell.qrCodeModel       = self.collectionDataSource[indexPath.item];
    return cell;
}

#pragma mark - UICollectionViewDelegate
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    _selectedQRModel       = self.collectionDataSource[indexPath.item];
    self.qrImageView.image = _selectedQRModel.qrImage;
}

#pragma mark - Event
- (void)copyBtnClick:(UIButton *)sender {
    UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
    pasteboard.string        = _selectedQRModel.link;

    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self animated:YES];
    hud.mode           = MBProgressHUDModeText;
    hud.label.text     = V2Localize(@"MLVB.CameraQRCode.Addedto");
    [hud showAnimated:YES];
    [hud hideAnimated:YES afterDelay:2];
}

- (void)closeBtnClick:(UIButton *)sender {
    [self hide];
}

@end

#pragma mark - CameraQRCodeCell
@interface                                CameraQRCodeCell ()
@property(nonatomic, strong) UIImageView *qrImageView;
@property(nonatomic, strong) UILabel *    qrLabel;
@end

@implementation CameraQRCodeCell

- (UIImageView *)qrImageView {
    if (!_qrImageView) {
        _qrImageView       = [[UIImageView alloc] initWithFrame:CGRectZero];
        _qrImageView.image = [UIImage imageNamed:@"checkbox_nor"];
    }
    return _qrImageView;
}

- (UILabel *)qrLabel {
    if (!_qrLabel) {
        _qrLabel           = [[UILabel alloc] initWithFrame:CGRectZero];
        _qrLabel.font      = [UIFont fontWithName:@"PingFangSC-Semibold" size:16];
        _qrLabel.textColor = UIColorFromRGB(0x7689BC);
    }
    return _qrLabel;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupView];
    }
    return self;
}

- (void)setSelected:(BOOL)selected {
    [super setSelected:selected];
    self.qrImageView.image    = [UIImage imageNamed:selected ? @"checkbox_sel" : @"checkbox_nor"];
    self.qrLabel.textColor    = UIColorFromRGB(selected ? 0xFFFBFB : 0x7689BC);
    self.qrCodeModel.selected = selected;
}

- (void)setupView {
    [self.contentView addSubview:self.qrImageView];
    [self.contentView addSubview:self.qrLabel];

    [self.qrImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.contentView.mas_left).offset(12);
        make.centerY.equalTo(self.contentView.mas_centerY);
    }];

    [self.qrLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.qrImageView.mas_right).offset(5);
        make.centerY.equalTo(self.qrImageView.mas_centerY);
    }];
}

- (void)setQrCodeModel:(CameraQRCodeModel *)qrCodeModel {
    _qrCodeModel      = qrCodeModel;
    self.qrLabel.text = qrCodeModel.title;
    self.selected     = qrCodeModel.selected;
}

@end
