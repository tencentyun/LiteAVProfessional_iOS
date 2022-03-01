//
//  LebPlayerViewController.m
//  TXLiteAVDemo
//
//  Created by abyyxwang on 2021/5/11.
//  Copyright © 2021 Tencent. All rights reserved.
//

#import "LebPlayerViewController.h"

#import "AppLocalized.h"
#import "ColorMacro.h"
#import "GenerateTestUserSig.h"
#import "LebLiveUtils.h"
#import "LebPlayerSettingViewController.h"
#import "MBProgressHUD.h"
#import "Masonry.h"
#import "PhotoUtil.h"
#import "V2TXLivePlayer.h"
#import "V2TXLivePlayerObserver.h"

#define LebLogSimple()        NSLog(@"[%@ %p %s %d]", NSStringFromClass(self.class), self, __func__, __LINE__);
#define LebLog(_format_, ...) NSLog(@"[%@ %p %s %d] %@", NSStringFromClass(self.class), self, __func__, __LINE__, [NSString stringWithFormat:_format_, ##__VA_ARGS__]);

@interface                                                   LebPlayerViewController () <V2TXLivePlayerObserver, LebPlayerSettingViewControllerDelegate>
@property(nonatomic, strong) V2TXLivePlayer *                player;
@property(atomic, assign) BOOL                               hasRecvFirstFrame;  /// 是否收到首帧
@property(atomic, strong) dispatch_block_t                   delayBlock;
@property(nonatomic, strong) NSString *                      userId;
@property(nonatomic, strong) TXView *                        videoView;
@property(nonatomic, strong) LebPlayerSettingViewController *settingContainer;
@property(nonatomic, strong) UIProgressView *                audioVolumeIndicator;

@end

@implementation LebPlayerViewController

- (instancetype)init {
    self = [super init];
    if (self) {
        self.player = [[V2TXLivePlayer alloc] init];
        [self.player setObserver:self];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    if ([self.title length] == 0) {
        self.title = V2Localize(@"MLVB.lebLauncher.title");
    }

    self.videoView                 = [[TXView alloc] initWithFrame:self.view.bounds];
    self.videoView.backgroundColor = [UIColor clearColor];
    [self.view addSubview:self.videoView];
    self.view.backgroundColor = [UIColor lightGrayColor];

    [self addSettingContainerView];
    [self addVolumeIndicator];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"rtc_back"] style:UIBarButtonItemStylePlain target:self action:@selector(popToPre)];
    [self startPlay];
}

- (void)dealloc {
    if (self.delayBlock) {
        dispatch_block_cancel(self.delayBlock);
        self.delayBlock = nil;
    }
    LebLogSimple()
}

- (void)addSettingContainerView {
    self.settingContainer          = [[LebPlayerSettingViewController alloc] initWithHostVC:self muteAudio:NO muteVideo:NO logView:NO player:self.player];
    self.settingContainer.isStart  = self.player.isPlaying;
    self.settingContainer.delegate = self;
    [self.view addSubview:self.settingContainer];
    [self.settingContainer mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.trailing.equalTo(self.view);
        if (@available(iOS 11.0, *)) {
            make.top.equalTo(self.view.mas_safeAreaLayoutGuideTop);
            make.bottom.equalTo(self.view.mas_safeAreaLayoutGuideBottom);
        } else {
            make.top.equalTo(self.view).offset(64);
            make.bottom.equalTo(self.view);
        }
    }];
}

- (void)addVolumeIndicator {
    self.audioVolumeIndicator                   = [[UIProgressView alloc] init];
    self.audioVolumeIndicator.progressTintColor = UIColor.yellowColor;
    self.audioVolumeIndicator.progress          = 0.0;
    [self.view addSubview:self.audioVolumeIndicator];
    CGFloat leftRightPadding = 0;
    if (@available(iOS 11.0, *)) {
        UIWindow *window = UIApplication.sharedApplication.windows.firstObject;
        leftRightPadding = window.safeAreaInsets.bottom;
    }
    [self.audioVolumeIndicator mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(self.view).offset(leftRightPadding);
        make.bottom.equalTo(self.view);
        make.height.mas_equalTo(2);
    }];
    self.audioVolumeIndicator.hidden = YES;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:NO];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:NO];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self.player setRenderView:self.videoView];
    [self.player showDebugView:self.settingContainer.isLogShow];
    if (self.muteVideo) {
        [self.player pauseVideo];
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.player setProperty:@"setDebugViewMargin" value:@{@"top" : @(80), @"bottom" : @(50), @"left" : @(0), @"right" : @(0)}];
    });
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    if (self.muteVideo) {
        [self.player pauseVideo];
    }
}

- (void)popToPre {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)setUrl:(NSString *)url {
    LebLog(@"url:%@", url);
    _url                 = [self.class convertPushUrl:url];
    NSDictionary *params = [LebLiveUtils parseURLParametersAndLowercaseKey:url];
    _userId              = params[@"userid"];
    if ([LebLiveUtils isTRTCUrl:url]) {
        self.title = [NSString stringWithFormat:@"%@（%@）", V2Localize(@"MLVB.lebLauncher.title"), params[@"strroomid"]];
    } else {
        self.title = V2Localize(@"MLVB.lebLauncher.title");  //[NSString stringWithFormat:@"Leb拉流（%@_%@）", params[@"strroomid"], params[@"remoteuserid"]];
    }
}

- (V2TXLiveCode)startPlay {
    [self.player setRenderView:self.videoView];
    if ([NSThread isMainThread]) {
        return [self startPlayInner:YES];
    } else {
        __block V2TXLiveCode result = V2TXLIVE_OK;
        dispatch_sync(dispatch_get_main_queue(), ^{
            result = [self startPlayInner:YES];
        });
        return result;
    }
}

- (V2TXLiveCode)stopPlay {
    LebLogSimple() if ([NSThread isMainThread]) { return [self startPlayInner:NO]; }
    else {
        __block V2TXLiveCode result = V2TXLIVE_OK;
        dispatch_sync(dispatch_get_main_queue(), ^{
            result = [self startPlayInner:NO];
        });
        return result;
    }
}

- (V2TXLiveCode)startPlayInner:(BOOL)start {
    self.settingContainer.isStart = start;
    V2TXLiveCode result           = -1;
    if (start == self.player.isPlaying) {
        NSString *message = start ? @"in playing" : @"stoped";
        LebLog(@"startPlay ignored, already %@", message);
        return V2TXLIVE_OK;
    }
    if (start) {
        LebLog(@"startPlay.") self.hasRecvFirstFrame = NO;
        [self.player setRenderFillMode:self.settingContainer.fillMode];
        result = [self.player startPlay:self.url];
        if (result == V2TXLIVE_OK) {
            [self showLoading:V2Localize(@"V2.Live.LinkMicNew.loading") withDetailText:V2Localize(@"V2.Live.LinkMicNew.pleasewait")];
            //                [self.settingContainer clearSettingVC];
            /// 开始播放后，超过5秒未收到首帧视频，则提示播放失败，并退出播放。
            if (self.delayBlock) {
                dispatch_block_cancel(self.delayBlock);
                self.delayBlock = nil;
            }
            __weak LebPlayerViewController *weakSelf = self;
            self.delayBlock                          = dispatch_block_create(DISPATCH_BLOCK_INHERIT_QOS_CLASS, ^{
                if (!weakSelf.hasRecvFirstFrame) {
                    [weakSelf showText:V2Localize(@"V2.Live.LinkMicNew.getvideoframetimeout") withDetailText:nil];
                    [weakSelf startPlayInner:NO];
                    [weakSelf hiddeLoading];
                }
            });
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(6 * NSEC_PER_SEC)), dispatch_get_main_queue(), self.delayBlock);
            if (self.onStatusUpdate) {
                self.onStatusUpdate();
            }
            self.muteAudio = self.settingContainer.isAudioMuted;
            self.muteVideo = self.settingContainer.isVideoMuted;
        } else {
            self.settingContainer.isStart = NO;
        }
    } else {
        LebLog(@"stopPlay.") result = [self.player stopPlay];
        if (result == V2TXLIVE_OK) {
            if (self.delayBlock) {
                dispatch_block_cancel(self.delayBlock);
                self.delayBlock = nil;
            }
            if (self.onStatusUpdate) {
                self.onStatusUpdate();
            }
        } else {
            self.settingContainer.isStart = YES;
            LebLog(@"topPlay faild.");
        }
    }
    return result;
}

- (BOOL)muteVideo {
    return self.settingContainer.isVideoMuted;
}

- (BOOL)muteAudio {
    return self.settingContainer.isAudioMuted;
}

- (void)setMuteVideo:(BOOL)muteVideo {
    self.settingContainer.isVideoMuted = muteVideo;
    if (muteVideo) {
        [self.player pauseVideo];
    } else {
        [self.player resumeVideo];
    }
}

- (void)setMuteAudio:(BOOL)muteAudio {
    self.settingContainer.isAudioMuted = muteAudio;
    if (muteAudio) {
        [self.player pauseAudio];
    } else {
        [self.player resumeAudio];
    }
}

#pragma mark - LebPlayerSettingViewControllerDelegate
- (void)lebPlayerSettingVC:(LebPlayerSettingViewController *)container didClickStartVideo:(BOOL)start {
    [self startPlayInner:start];
}

- (void)lebPlayerSettingVC:(LebPlayerSettingViewController *)container didClickMuteVideo:(BOOL)muteVideo {
    self.muteVideo = muteVideo;
}

- (void)lebPlayerSettingVC:(LebPlayerSettingViewController *)container didClickMuteAudio:(BOOL)muteAudio {
    self.muteAudio = muteAudio;
}

- (void)lebPlayerSettingVC:(LebPlayerSettingViewController *)container didClickLog:(BOOL)isLogShow {
    [self.player showDebugView:isLogShow];
}

- (void)lebPlayerSettingVC:(id)container enableVolumeEvaluation:(BOOL)isEnable {
    self.audioVolumeIndicator.hidden = !isEnable;
}

- (void)lebPlayerSettingVC:(LebPlayerSettingViewController *)container enableSEI:(BOOL)isEnable payloadType:(NSInteger)payloadType {
}

#define kLastTRTCUserId @"kLastTRTCUserId"
+ (NSString *)convertPushUrl:(NSString *)pushUrl {
    NSString *defaultUserId = [[NSUserDefaults standardUserDefaults] stringForKey:kLastTRTCUserId];
    if (!defaultUserId) {
        LebLog(@"faild. no default userid.");
        return pushUrl;
    }
    NSArray *urlComponents = [pushUrl componentsSeparatedByString:@"?"];
    if ([urlComponents count] != 2) {
        LebLog(@"faild. invalid url:%@", pushUrl);
        return pushUrl;
    }
    NSString *urlPrefix = urlComponents.firstObject;
    NSString *userSig   = [GenerateTestUserSig genTestUserSig:@(SDKAPPID).stringValue];
    //[GenerateTestUserSig genTestUserSig:defaultUserId sdkAppId:_SDKAppID secretKey:_SECRETKEY];
    NSMutableDictionary *params = [self parseURLParameters:pushUrl];
    if ([pushUrl hasPrefix:@"trtc://"] && [pushUrl containsString:@"/push/"]) {
        // trtc push
        for (NSString *key in params.allKeys) {
            if ([key.lowercaseString isEqualToString:@"userid"]) {
                [params setObject:defaultUserId forKey:key];
            } else if ([key.lowercaseString isEqualToString:@"usersig"]) {
                [params setObject:userSig forKey:key];
            }
        }
        urlPrefix              = [urlPrefix stringByReplacingOccurrencesOfString:@"push" withString:@"rtcplay"];
        NSMutableString *query = [NSMutableString stringWithCapacity:30];
        [query appendString:@"?"];
        for (NSString *key in params) {
            if ([query length] == 1) {
                [query appendFormat:@"%@=%@", key, params[key]];
            } else {
                [query appendFormat:@"&%@=%@", key, params[key]];
            }
        }
        NSString *playUrl = [urlPrefix stringByAppendingString:query];
        LebLog(@"succ. playUrl:%@ originUrl:%@", playUrl, pushUrl);
        return playUrl;
    } else if ([pushUrl hasPrefix:@"room://"] && ![pushUrl.lowercaseString containsString:@"remoteuserid"]) {
        // room push
        for (NSString *key in params.allKeys) {
            if ([key.lowercaseString isEqualToString:@"userid"]) {
                [params setObject:params[key] forKey:@"remoteuserid"];
                [params setObject:defaultUserId forKey:key];
            } else if ([key.lowercaseString isEqualToString:@"usersig"]) {
                [params setObject:userSig forKey:key];
            }
        }
        NSMutableString *query = [NSMutableString stringWithCapacity:30];
        [query appendString:@"?"];
        for (NSString *key in params) {
            if ([query length] == 1) {
                [query appendFormat:@"%@=%@", key, params[key]];
            } else {
                [query appendFormat:@"&%@=%@", key, params[key]];
            }
        }
        NSString *playUrl = [urlPrefix stringByAppendingString:query];
        LebLog(@"succ. playUrl:%@ originUrl:%@", playUrl, pushUrl);
        return playUrl;
    } else {
        LebLog(@"faild. is not push url.");
        return pushUrl;
    }
}

+ (NSMutableDictionary *)parseURLParameters:(NSString *)url {
    NSRange range = [url rangeOfString:@"?"];
    if (range.location == NSNotFound) return nil;

    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    if (url.length <= range.location + 1) return nil;
    NSString *parametersString = [url substringFromIndex:range.location + 1];
    NSArray * urlComponents    = [parametersString componentsSeparatedByString:@"&"];

    for (NSString *keyValuePair in urlComponents) {
        NSArray * pairComponents = [keyValuePair componentsSeparatedByString:@"="];
        NSString *key            = pairComponents.firstObject;
        NSString *value          = pairComponents.lastObject;
        if (key && value) {
            [parameters setValue:value forKey:key];
        }
    }
    return parameters;
}

- (void)showText:(NSString *)text withDetailText:(NSString *)detail {
    MBProgressHUD *hud = [MBProgressHUD HUDForView:[UIApplication sharedApplication].delegate.window];
    if (hud == nil) {
        hud = [MBProgressHUD showHUDAddedTo:[UIApplication sharedApplication].delegate.window animated:NO];
    }
    hud.mode              = MBProgressHUDModeText;
    hud.label.text        = text;
    hud.detailsLabel.text = detail;
    [hud showAnimated:YES];
    [hud hideAnimated:YES afterDelay:1];
}

- (void)showLoading:(NSString *)text withDetailText:(NSString *)detail {
    if (!self.view) return;
    self.isLoading     = YES;
    MBProgressHUD *hud = [MBProgressHUD HUDForView:self.view];
    if (hud == nil) {
        hud = [MBProgressHUD showHUDAddedTo:self.view animated:NO];
    }
    hud.mode              = MBProgressHUDModeText;
    hud.label.text        = text;
    hud.detailsLabel.text = detail;
}

- (void)hiddeLoading {
    if (!self.view) return;
    MBProgressHUD *hud = [MBProgressHUD HUDForView:self.view];
    [hud showAnimated:YES];
    [hud hideAnimated:YES];
    self.isLoading = NO;
}

#pragma mark - V2TXLivePlayerObserver

- (void)onConnected:(id<V2TXLivePlayer>)player extraInfo:(NSDictionary *)extraInfo {
    NSLog(@"----- onConnected");
}

- (void)onVideoLoading:(id<V2TXLivePlayer>)player extraInfo:(NSDictionary *)extraInfo {
    NSLog(@"----- onVideoLoading");
    [self showLoading:V2Localize(@"V2.Live.LinkMicNew.loading") withDetailText:V2Localize(@"V2.Live.LinkMicNew.pleasewait")];
    LebLogSimple()
}

- (void)onVideoPlaying:(id<V2TXLivePlayer>)player firstPlay:(BOOL)firstPlay extraInfo:(NSDictionary *)extraInfo {
    NSLog(@"----- onVideoPlaying firstPlay: %d",firstPlay);
    self.hasRecvFirstFrame = YES;
    [self hiddeLoading];
    LebLogSimple()
}

- (void)onAudioLoading:(id<V2TXLivePlayer>)player extraInfo:(NSDictionary *)extraInfo {
    NSLog(@"----- onAudioLoading");
}

- (void)onAudioPlaying:(id<V2TXLivePlayer>)player firstPlay:(BOOL)firstPlay extraInfo:(NSDictionary *)extraInfo {
    NSLog(@"----- onAudioPlaying firstPlay: %d",firstPlay);
}

- (void)onPlayoutVolumeUpdate:(id<V2TXLivePlayer>)player volume:(NSInteger)volume {
    if (!self.audioVolumeIndicator.hidden) {
        self.audioVolumeIndicator.progress = (CGFloat)volume / 100.0f;
    }
}

- (void)onError:(id<V2TXLivePlayer>)player code:(V2TXLiveCode)code message:(NSString *)msg extraInfo:(NSDictionary *)extraInfo {
    if (code == V2TXLIVE_ERROR_REQUEST_TIMEOUT) {
        [self showText:V2Localize(@"V2.Live.LinkMicNew.enterroomtimeout") withDetailText:V2Localize(@"V2.Live.LinkMicNew.checknetworkandtry")];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self startPlayInner:NO];
        });
    } else if (code == V2TXLIVE_ERROR_DISCONNECTED) {
        [self showLoading:V2Localize(@"V2.Live.LinkMicNew.disconnected") withDetailText:V2Localize(@"V2.Live.LinkMicNew.checknetworkandtry")];
        [self stopPlay];
    }
    LebLog(@"code:%ld msg:%@ extraInfo:%@", (long)code, msg, extraInfo);
}

- (void)onWarning:(id<V2TXLivePlayer>)player code:(V2TXLiveCode)code message:(NSString *)msg extraInfo:(NSDictionary *)extraInfo {
    LebLog(@"code:%ld msg:%@ extraInfo:%@", (long)code, msg, extraInfo);
}

- (void)onSnapshotComplete:(id<V2TXLivePlayer>)player image:(TXImage *)image {
    if (!image) {
        [self showText:V2Localize(@"V2.Live.LinkMicNew.getsnapshotfailed")];
    } else {
        [PhotoUtil saveDataToAlbum:UIImagePNGRepresentation(image)
                        completion:^(BOOL success, NSError *_Nullable error) {
                            if (success) {
                                [self showText:V2Localize(@"V2.Live.LinkMicNew.snapshotsavetoalbum")];
                            } else {
                                [self showText:V2Localize(@"V2.Live.LinkMicNew.snapshotsavefailed")];
                            }
                        }];
    }
}

- (void)onReceiveSeiMessage:(id<V2TXLivePlayer>)player payloadType:(int)payloadType data:(NSData *)data {
    NSString *content = data ? [NSString stringWithCString:[data bytes] encoding:NSUTF8StringEncoding] : @"";
    LebLog(@"onReceiveSeiMessage payloadType: %d, data: %@ %@", payloadType, data, content);
}

#pragma mark - Util

- (void)showText:(NSString *)text {
    dispatch_async(dispatch_get_main_queue(), ^{
        MBProgressHUD *hud = [MBProgressHUD HUDForView:[UIApplication sharedApplication].delegate.window];
        if (hud == nil) {
            hud = [MBProgressHUD showHUDAddedTo:[UIApplication sharedApplication].delegate.window animated:NO];
        }
        hud.mode       = MBProgressHUDModeText;
        hud.label.text = text;
        [hud showAnimated:YES];
        [hud hideAnimated:YES afterDelay:1];
    });
}

@end
