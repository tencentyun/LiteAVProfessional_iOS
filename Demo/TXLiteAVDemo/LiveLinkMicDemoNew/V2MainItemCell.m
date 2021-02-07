//
//  V2MainItemCell.m
//  TXLiteAVDemo
//
//  Created by coddyliu on 2020/11/27.
//  Copyright © 2020 Tencent. All rights reserved.
//

#import "V2MainItemCell.h"
#import "Masonry.h"
#import "V2PusherViewController.h"
#import "V2PlayerViewController.h"
#import "MBProgressHUD.h"

@interface V2MainItemCell ()
@property (nonatomic, strong) UIButton *addButton;

@property (nonatomic, strong) UIButton *switchCameraBtn;
@property (nonatomic, strong) UIButton *muteVideoBtn;
@property (nonatomic, strong) UIButton *muteAudioBtn;
@property (nonatomic, strong) UIButton *bigViewBtn;
@property (nonatomic, strong) UIButton *closeBtn;

@property (nonatomic, strong) TXView *videoView;

- (void)updateAllButtons;
@end

@implementation V2MainItemCell

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self constructSubViews];
        [self configSubViews];
    }
    return self;
}

- (NSArray *)showButtons {
    return @[];
}

- (void)constructSubViews {
    self.addButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 200, 100)];
    [self.contentView addSubview:self.addButton];
    [self.addButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.contentView);
    }];
    [self.addButton addTarget:self action:@selector(onAddClick:) forControlEvents:UIControlEventTouchUpInside];
    
    self.switchCameraBtn = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 40, 40)];
    [self.switchCameraBtn addTarget:self action:@selector(swichCamera:) forControlEvents:UIControlEventTouchUpInside];
    [self.switchCameraBtn setImage:[UIImage imageNamed:@"camera_b2"] forState:UIControlStateNormal];
    [self.switchCameraBtn setImage:[UIImage imageNamed:@"camera_b"] forState:UIControlStateSelected];

    self.muteVideoBtn = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 40, 40)];
    [self.muteVideoBtn addTarget:self action:@selector(muteVideo:) forControlEvents:UIControlEventTouchUpInside];
    [self.muteVideoBtn setImage:[UIImage imageNamed:@"rtc_remote_video_on"] forState:UIControlStateNormal];
    [self.muteVideoBtn setImage:[UIImage imageNamed:@"rtc_remote_video_off"] forState:UIControlStateSelected];

    self.muteAudioBtn = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 40, 40)];
    [self.muteAudioBtn addTarget:self action:@selector(muteAudio:) forControlEvents:UIControlEventTouchUpInside];
    [self.muteAudioBtn setImage:[UIImage imageNamed:@"mute_b"] forState:UIControlStateNormal];
    [self.muteAudioBtn setImage:[UIImage imageNamed:@"mute_b2"] forState:UIControlStateSelected];

    self.bigViewBtn = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 40, 40)];
    [self.bigViewBtn addTarget:self action:@selector(onBigView:) forControlEvents:UIControlEventTouchUpInside];
    [self.bigViewBtn setImage:[UIImage imageNamed:@"rtc_bottom_fullscreen"] forState:UIControlStateNormal];
    
    self.closeBtn = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 35.0, 35.0)];
    [self.closeBtn addTarget:self action:@selector(onClose:) forControlEvents:UIControlEventTouchUpInside];
    [self.closeBtn setImage:[UIImage imageNamed:@"rtc_player_close"] forState:UIControlStateNormal];
    [self.contentView addSubview:self.closeBtn];
    [self.closeBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.contentView);
        make.top.equalTo(self.contentView);
        make.width.height.mas_equalTo(35.0);
    }];
    
    /// layout buttons
    CGFloat horizonOffset = 10;
    CGFloat bottomOffset = 10;
    NSArray *buttons = [self showButtons];
    UIButton *preButton = nil;
    CGFloat offset = (buttons.count == 4)?0:(8.0);
    for (UIButton *button in buttons) {
        [self.contentView addSubview:button];
        [button mas_makeConstraints:^(MASConstraintMaker *make) {
            make.bottom.mas_equalTo(self.contentView).offset(-bottomOffset);
            if ([button isEqual:buttons.firstObject]) {
                make.left.mas_equalTo(@(horizonOffset + offset));
            } else if ([button isEqual:buttons.lastObject]) {
                make.right.equalTo(self.contentView.mas_right).offset(-horizonOffset -offset);
                make.left.equalTo(preButton.mas_right).offset(offset);
                make.width.equalTo(preButton);
            } else {
                make.left.equalTo(preButton.mas_right).offset(offset);
                make.width.equalTo(preButton);
            }
            make.height.equalTo(button.mas_width);
        }];
        preButton = button;
    }
    
    self.videoView = [[TXView alloc] initWithFrame:self.contentView.bounds];
    [self.contentView insertSubview:self.videoView atIndex:0];
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onTapGesture:)];
    tap.numberOfTapsRequired = 2;
    [self.videoView addGestureRecognizer:tap];
}

- (void)onViewControllerDidAppear:(UIViewController *)viewController {
    [self updateAllButtons];
}

- (void)configSubViews {
    self.backgroundColor = [UIColor colorWithWhite:0.5 alpha:1.0];
    [self updateAllButtons];
}

- (void)updateAllButtons {
    self.addButton.hidden = self.isBusy;
    self.closeBtn.hidden = !self.isBusy;
    for (UIButton *button in [self showButtons]) {
        button.hidden = !self.isBusy;
    }
}

- (void)onTapGesture:(UITapGestureRecognizer *)tap {
    if (self.isBusy) {
        [self onBigView:self.bigViewBtn];
    }
}

- (IBAction)onClose:(UIButton *)sender {
}

- (IBAction)onBigView:(UIButton *)sender {
    NSLog(@"");
}
- (IBAction)onAddClick:(UIButton *)sender {
    sender.hidden = YES;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self updateAllButtons];
    });
}
- (void)muteVideo:(UIButton *)sender {
}
- (void)swichCamera:(UIButton *)sender {
}
- (void)muteAudio:(UIButton *)sender {
}

- (void)showText:(NSString *)text withDetailText:(NSString *)detail {
    MBProgressHUD *hud = [MBProgressHUD HUDForView:[UIApplication sharedApplication].delegate.window];
    if (hud == nil) {
        hud = [MBProgressHUD showHUDAddedTo:[UIApplication sharedApplication].delegate.window animated:YES];
    }
    hud.mode = MBProgressHUDModeText;
    hud.label.text = text;
    hud.detailsLabel.text = detail;
    [hud showAnimated:YES];
    [hud hideAnimated:YES afterDelay:1];
}


@end


@interface V2MainItemPushCell ()
@end

@implementation V2MainItemPushCell

- (NSArray *)showButtons {
    return @[self.switchCameraBtn, self.muteVideoBtn, self.muteAudioBtn, self.bigViewBtn];
}

- (void)configSubViews {
    [super configSubViews];
    self.switchCameraBtn.selected = YES;
    [self.addButton setTitle:@" + Pusher" forState:UIControlStateNormal];
}

- (void)updateAllButtons {
    [super updateAllButtons];
    self.switchCameraBtn.selected = self.relateVC.usefrontCamera;
    self.muteVideoBtn.selected = self.relateVC.muteVideo;
    self.muteAudioBtn.selected = self.relateVC.muteAudio;
}

- (BOOL)isBusy {
    return self.relateVC.pusher.isPushing;
}

- (void)onViewControllerDidAppear:(UIViewController *)viewController {
    [super onViewControllerDidAppear:viewController];
    self.switchCameraBtn.selected = self.relateVC.usefrontCamera;
    self.muteVideoBtn.selected = self.relateVC.muteVideo;
    self.muteAudioBtn.selected = self.relateVC.muteAudio;
}

- (void)setRelateVC:(V2PusherViewController *)pusherVC {
    _relateVC = pusherVC;
    _relateVC.smallPreView = self.videoView;
    self.addButton.hidden = self.isBusy;
}

- (IBAction)onClose:(UIButton *)sender {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self updateAllButtons];
    });
    [self.relateVC stopPush];
}

- (IBAction)onAddClick:(UIButton *)sender {
    [super onAddClick:sender];
    self.onSetUrlBtnClick(self);
}

- (void)setPusherMode:(V2TXLiveMode)mode {
    [self.relateVC setPusherMode:mode];
}

- (void)startWithUrl:(NSString *)url playUrls:(NSDictionary * _Nullable)playUrls {
    self.addButton.hidden = YES;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self updateAllButtons];
    });
    self.relateVC.muteAudio = self.muteAudioBtn.selected;
    self.relateVC.muteVideo = self.muteVideoBtn.selected;
    self.relateVC.usefrontCamera = self.switchCameraBtn.selected;
    self.relateVC.url = url;
    if (playUrls) {
        //@"url_play_acc" @"url_play_flv" @"url_play_hls" @"url_play_rtmp"
        self.relateVC.playUrl = playUrls[@"url_play_flv"];
    }
    __weak __typeof(self) weakSelf = self;
    [self.relateVC setOnStatusUpdate:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf updateAllButtons];
        });
    }];
    V2TXLiveCode result = [self.relateVC startPush];
    if (result == V2TXLIVE_ERROR_REFUSED) {
        NSString *msg = @"推流失败：抱歉，RTC暂不支持同一台设备使用相同streamid同时推拉流";
        [self showText:nil withDetailText:msg];
    } else if (result == V2TXLIVE_ERROR_INVALID_PARAMETER) {
        [self showText:@"参数错误" withDetailText:nil];
    }
}

- (IBAction)onBigView:(UIButton *)sender {
    NSLog(@"");
    [[(UIViewController *)self.delegate navigationController] pushViewController:self.relateVC animated:NO];
}

- (void)muteVideo:(UIButton *)sender {
    self.relateVC.muteVideo = !self.relateVC.muteVideo;
    sender.selected = self.relateVC.muteVideo;
}

- (void)muteAudio:(UIButton *)sender {
    self.relateVC.muteAudio = !self.relateVC.muteAudio;
    sender.selected = self.relateVC.muteAudio;
}

- (void)swichCamera:(UIButton *)sender {
    self.relateVC.usefrontCamera = !self.relateVC.usefrontCamera;
    sender.selected = self.relateVC.usefrontCamera;
}

@end

@interface V2MainItemPlayCell ()
@end

@implementation V2MainItemPlayCell

- (NSArray *)showButtons {
    return @[self.muteVideoBtn, self.muteAudioBtn, self.bigViewBtn];
}

- (void)configSubViews {
    [super configSubViews];
    [self.addButton setTitle:@" + Player" forState:UIControlStateNormal];
}

- (void)updateAllButtons {
    NSLog(@"V2MainItemPlayCell %p updateAllButtons isBusy:%d", self, self.isBusy);
    [super updateAllButtons];
    self.muteVideoBtn.selected = self.relateVC.muteVideo;
    self.muteAudioBtn.selected = self.relateVC.muteAudio;
}

- (BOOL)isBusy {
    return self.relateVC.player.isPlaying;
}

- (void)setRelateVC:(V2PlayerViewController *)playerVC {
    _relateVC = playerVC;
    _relateVC.smallPreView = self.videoView;
    self.addButton.hidden = self.isBusy;
}

- (void)onViewControllerDidAppear:(UIViewController *)viewController {
    [super onViewControllerDidAppear:viewController];
    self.muteVideoBtn.selected = self.relateVC.muteVideo;
    self.muteAudioBtn.selected = self.relateVC.muteAudio;
    if (self.relateVC.isLoading) {
        [self onClose:self.closeBtn];
    }
}

- (IBAction)onAddClick:(UIButton *)sender {
    [super onAddClick:sender];
    self.onSetUrlBtnClick(self);
}

- (IBAction)onClose:(UIButton *)sender {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self updateAllButtons];
    });
    [self.relateVC stopPlay];
}

- (void)startWithUrl:(NSString *)url playUrls:(NSDictionary * _Nullable)playUrls {
    self.addButton.hidden = YES;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self updateAllButtons];
    });
    self.relateVC.muteAudio = NO;
    self.relateVC.muteVideo = NO;
    __weak V2MainItemCell * weakSelf = self;
    [self.relateVC setOnStatusUpdate:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf updateAllButtons];
        });
    }];
    self.relateVC.url = url;
    V2TXLiveCode result = [self.relateVC startPlay];
    if (result == V2TXLIVE_ERROR_REFUSED) {
        NSString *msg = @"拉流失败：抱歉，RTC暂不支持同一台设备使用相同streamid同时推拉流";
        [self showText:nil withDetailText:msg];
    } else if (result == V2TXLIVE_ERROR_INVALID_PARAMETER) {
        [self showText:@"参数错误" withDetailText:nil];
    }
}

- (IBAction)onBigView:(UIButton *)sender {
    NSLog(@"");
    [[(UIViewController *)self.delegate navigationController] pushViewController:self.relateVC animated:NO];
}

- (void)muteVideo:(UIButton *)sender {
    self.relateVC.muteVideo = !self.relateVC.muteVideo;
    sender.selected = self.relateVC.muteVideo;
}

- (void)muteAudio:(UIButton *)sender {
    self.relateVC.muteAudio = !self.relateVC.muteAudio;
    sender.selected = self.relateVC.muteAudio;
}

- (void)swichCamera:(UIButton *)sender {
    /// player不需要处理
}

- (void)stopPlay {
    [self.relateVC stopPlay];
}


@end
