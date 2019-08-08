//
//  WebRTCViewController.m
//  TXLiteAVDemo
//
//  Created by lijie on 2018/1/22.
//  Copyright © 2018年 Tencent. All rights reserved.
//

#import "WebRTCViewController.h"
#import "TXLiveSDKTypeDef.h"
#import "TXLivePush.h"
#import "TXLivePlayer.h"
#import "UIView+Additions.h"
#import <AVFoundation/AVFoundation.h>
#import "ColorMacro.h"
#import "AFNetworking.h"
#import "AppDelegate.h"
@interface WebRTCViewController() <UITextFieldDelegate, TXLivePushListener, WebRTCPlayerListener> {
    TXLivePush               *_livePusher;
    NSMutableDictionary      *_livePlayerDic;  // [userID, player]
    NSMutableDictionary      *_playerEventDic; // [userID, WebRTCPlayerListenerWrapper]
    NSString                 *_pushUrl;        // 推流地址
    NSString                 *_userID;         // 用户账号，字符串类型，在SDK里面叫openid
    NSString                 *_pwd;            // 用户密码
    uint32_t                 _roomID;          // 房间号
    uint32_t                 _sdkappid;        // 在腾讯云后台注册的产品sdkappid
    NSMutableArray           *_userListArray;  // 保存房间列表userID，不包括自己
}
@end

@implementation WebRTCViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _playerViewDic = [[NSMutableDictionary alloc] init];
    _placeViewArray = [[NSMutableArray alloc] init];
    
    _appIsInActive = NO;
    _appIsBackground = NO;
    
    TXLivePushConfig *config = [[TXLivePushConfig alloc] init];
    _livePusher = [[TXLivePush alloc] initWithConfig:config];
    
    _livePlayerDic = [[NSMutableDictionary alloc] init];
    _playerEventDic = [[NSMutableDictionary alloc] init];
    _userListArray = [[NSMutableArray alloc] init];
    
    _sdkappid = YOUR_SDK_APP_ID;
    
    [self initUI];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.navigationController.navigationBar.hidden = NO;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onAppDidEnterBackGround:) name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onAppWillEnterForeground:) name:UIApplicationWillEnterForegroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onAppWillResignActive:) name:UIApplicationWillResignActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onAppDidBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    self.navigationController.navigationBar.hidden = YES;
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    
    [self stop];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)initUI {
    HelpBtnUI(webrtc)
    self.title = @"WebRTC Room";
    [self.view setBackgroundColor:UIColorFromRGB(0x333333)];
    
    
    CGSize size = [[UIScreen mainScreen] bounds].size;
    int ICON_SIZE = 46;
    
    CGFloat topBase = [UIApplication sharedApplication].statusBarFrame.size.height + self.navigationController.navigationBar.height;
    topBase += 3;
    
    _txtRoomId = [[UITextField alloc] initWithFrame:CGRectMake(10, topBase, 70, ICON_SIZE)];
    [_txtRoomId setBorderStyle:UITextBorderStyleRoundedRect];
    _txtRoomId.background = [UIImage imageNamed:@"Input_box"];
    _txtRoomId.placeholder = @"房间号";
    _txtRoomId.delegate = self;
    _txtRoomId.alpha = 0.5;
    [self.view addSubview:_txtRoomId];
    
    _txtUserId = [[UITextField alloc] initWithFrame:CGRectMake(85, topBase, 120, ICON_SIZE)];
    [_txtUserId setBorderStyle:UITextBorderStyleRoundedRect];
    _txtUserId.background = [UIImage imageNamed:@"Input_box"];
    _txtUserId.placeholder = @"账号";
    _txtUserId.delegate = self;
    _txtUserId.alpha = 0.5;
    [self.view addSubview:_txtUserId];
    
    _txtUserPwd = [[UITextField alloc] initWithFrame:CGRectMake(210, topBase, 120, ICON_SIZE)];
    [_txtUserPwd setBorderStyle:UITextBorderStyleRoundedRect];
    _txtUserPwd.background = [UIImage imageNamed:@"Input_box"];
    _txtUserPwd.placeholder = @"密码";
    _txtUserPwd.delegate = self;
    _txtUserPwd.alpha = 0.5;
    [self.view addSubview:_txtUserPwd];
    
    
    float startSpace = 30;
    float centerInterVal = (size.width - 2 * startSpace - ICON_SIZE) / 4;
    float iconY = size.height - ICON_SIZE / 2 - 5;
    if (@available(iOS 11, *)) {
        iconY -= [UIApplication sharedApplication].keyWindow.safeAreaInsets.bottom;
    }
    
    // 进房和退出按钮
    _join_switch = NO;
    _btnJoin = [UIButton buttonWithType:UIButtonTypeCustom];
    _btnJoin.center = CGPointMake(startSpace + ICON_SIZE / 2, iconY);
    _btnJoin.bounds = CGRectMake(0, 0, ICON_SIZE, ICON_SIZE);
    [_btnJoin setImage:[UIImage imageNamed:@"start"] forState:UIControlStateNormal];
    [_btnJoin addTarget:self action:@selector(clickjoin:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_btnJoin];
    
    // 前置后置摄像头切换
    _camera_switch = NO;
    _btnCamera = [UIButton buttonWithType:UIButtonTypeCustom];
    _btnCamera.center = CGPointMake(startSpace + ICON_SIZE/2 + centerInterVal * 1, iconY);
    _btnCamera.bounds = CGRectMake(0, 0, ICON_SIZE, ICON_SIZE);
    [_btnCamera setImage:[UIImage imageNamed:@"camera"] forState:UIControlStateNormal];
    [_btnCamera addTarget:self action:@selector(clickCamera:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_btnCamera];
    
    // 推流端静音(纯视频推流)
    _mute_switch = NO;
    _btnMute = [UIButton buttonWithType:UIButtonTypeCustom];
    _btnMute.center = CGPointMake(startSpace + ICON_SIZE/2 + centerInterVal * 2, iconY);
    _btnMute.bounds = CGRectMake(0, 0, ICON_SIZE, ICON_SIZE);
    [_btnMute setImage:[UIImage imageNamed:@"mic"] forState:UIControlStateNormal];
    [_btnMute addTarget:self action:@selector(clickMute:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_btnMute];
    
    // log按钮
    _btnLog = [UIButton buttonWithType:UIButtonTypeCustom];
    _btnLog.center = CGPointMake(startSpace + ICON_SIZE/2 + centerInterVal * 3, iconY);
    _btnLog.bounds = CGRectMake(0, 0, ICON_SIZE, ICON_SIZE);
    [_btnLog setImage:[UIImage imageNamed:@"log"] forState:UIControlStateNormal];
    [_btnLog addTarget:self action:@selector(clickLog:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_btnLog];
    
    // LOG界面
    _log_switch = 0;
    _logView = [[UITextView alloc] initWithFrame:CGRectMake(0, 80*kScaleY, size.width, size.height - 150*kScaleY)];
    _logView.backgroundColor = [UIColor clearColor];
    _logView.alpha = 1;
    _logView.textColor = [UIColor whiteColor];
    _logView.editable = NO;
    _logView.hidden = YES;
    [self.view addSubview:_logView];
    
    // 正式环境 or 测试环境
    _env_switch = YES;
    _btnEnv = [UIButton buttonWithType:UIButtonTypeCustom];
    _btnEnv.center = CGPointMake(startSpace + ICON_SIZE/2 + centerInterVal * 4, iconY);
    _btnEnv.bounds = CGRectMake(0, 0, ICON_SIZE, ICON_SIZE);
//    [_btnEnv setTitle:@"正式" forState:UIControlStateNormal];
//    _btnEnv.titleLabel.font = [UIFont systemFontOfSize:15];
//    [_btnEnv setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
//    [_btnEnv setBackgroundColor:[UIColor whiteColor]];
//    _btnEnv.layer.cornerRadius = _btnEnv.frame.size.width / 2;
//    [_btnEnv setAlpha:0.5];
    [_btnEnv setImage:[UIImage imageNamed:@"release-env"] forState:UIControlStateNormal];
    [_btnEnv addTarget:self action:@selector(clickEnv:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_btnEnv];
    
    // 半透明浮层，用于方便查看log
    _coverView = [[UIView alloc] init];
    _coverView.frame = _logView.frame;
    _coverView.backgroundColor = [UIColor whiteColor];
    _coverView.alpha = 0.5;
    _coverView.hidden = YES;
    [self.view addSubview:_coverView];
    [self.view sendSubviewToBack:_coverView];
    
    // 本地预览view
    _pusherView = [[UIView alloc] initWithFrame:self.view.bounds];
    [_pusherView setBackgroundColor:UIColorFromRGB(0x262626)];
    [self.view insertSubview:_pusherView atIndex:0];
    
    [self relayout];
    
    [self.view bringSubviewToFront:_txtRoomId];
    [self.view bringSubviewToFront:_txtUserId];
    [self.view bringSubviewToFront:_txtUserPwd];
}

- (void)relayout {
    CGFloat minTop = _txtRoomId.bottom + 3;
    
    // 房间视频布局为rowNum行，colNum列，所有视频的布局范围为videoRectScope
    int rowNum = 2;
    int colNum = 2;
    CGRect videoRectScope = CGRectMake(0, MAX(minTop, 100*kScaleY), self.view.size.width, self.view.size.height - 150*kScaleY);
    
    int offsetX = 6 * kScaleX;  // 每个视频view之间的间距
    int offsetY = 12 * kScaleY;
    int videoViewWidth = (videoRectScope.size.width - (colNum-1) * offsetX) / colNum;
    int videoViewHeight = videoViewWidth * 4.0 / 3.0;  // 分辨率使用3:4
    if (videoViewHeight * rowNum > videoRectScope.size.height) {
        // 简单兼容下ipad
        videoViewHeight = (videoRectScope.size.height - (rowNum-1) * offsetY) / rowNum;
    }
    
    int row = 0;
    int col = 0;
    int originX = videoRectScope.origin.x + col * (offsetX + videoViewWidth);
    int originY = videoRectScope.origin.y + row * (offsetY + videoViewHeight);
    
    // 先设置本地预览
    _pusherView.frame = CGRectMake(originX, originY, videoViewWidth, videoViewHeight);
    
    // 设置其他remoteView
    int index = 1;
    for (id userID in _playerViewDic) {
        row = index / colNum;
        col = index % colNum;
        originX = videoRectScope.origin.x + col * (offsetX + videoViewWidth);
        originY = videoRectScope.origin.y + row * (offsetY + videoViewHeight);
        
        UIView *playerView = [_playerViewDic objectForKey:userID];
        playerView.frame = CGRectMake(originX, originY, videoViewWidth, videoViewHeight);
        ++ index;
        
        if (index >= rowNum * colNum) {
            break;
        }
    }
    
    // 设置占位view
    for (UIView *view in _placeViewArray) {
        [view removeFromSuperview];
    }
    [_placeViewArray removeAllObjects];
    
    for (int i = index; i < rowNum * colNum; ++i) {
        row = i / colNum;
        col = i % colNum;
        originX = videoRectScope.origin.x + col * (offsetX + videoViewWidth);
        originY = videoRectScope.origin.y + row * (offsetY + videoViewHeight);
        
        UIView *view = [[UIView alloc] initWithFrame:CGRectMake(originX, originY, videoViewWidth, videoViewHeight)];
        
        UIImageView *imgView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, view.width, view.height)];
        [imgView setBackgroundColor:UIColorFromRGB(0x262626)];
        [imgView setImage:[UIImage imageNamed:@"people"]];
        imgView.contentMode = UIViewContentModeCenter;
        imgView.clipsToBounds = YES;
        [view addSubview:imgView];
        
        [self.view addSubview:view];
        [_placeViewArray addObject:view];
    }
}

- (BOOL)start {
    if (_livePusher) {
        TXLivePushConfig *config = [[TXLivePushConfig alloc] init];
        config.pauseFps = 10;
        config.pauseTime = 300;
        config.pauseImg = [UIImage imageNamed:@"pause_publish.jpg"];
        
        [_livePusher setConfig:config];
        [_livePusher setVideoQuality:VIDEO_QUALITY_REALTIME_VIDEOCHAT adjustBitrate:YES adjustResolution:YES];
        
        config.videoResolution = VIDEO_RESOLUTION_TYPE_480_640;
        config.audioSampleRate = AUDIO_SAMPLE_RATE_48000;
        config.videoBitrateMin = 200;
        config.videoBitrateMax = 400;
        [_livePusher setConfig:config];
        
        // 设置是否静音(上次推流的设置)
        [_livePusher setMute:_mute_switch];
        
        _livePusher.delegate = self;
        [_livePusher startPreview:_pusherView];
        
        if ([_livePusher startPush:_pushUrl] != 0) {
            return NO;
        }
    }
    
    return YES;
}

- (void)stop {
    _pushUrl = @"";
    
    // 关闭本地采集和预览
    if (_livePusher) {
        _livePusher.delegate = nil;
        [_livePusher stopPreview];
        [_livePusher stopPush];
    }
    
    // 关闭所有播放器
    for (id userID in _livePlayerDic) {
        TXLivePlayer *player = [_livePlayerDic objectForKey:userID];
        [player stopPlay];
    }
    [_livePlayerDic removeAllObjects];
    [_playerViewDic removeAllObjects];
    [_playerEventDic removeAllObjects];
    
    [_userListArray removeAllObjects];
}

// 进房/退房
- (void)clickjoin:(UIButton*)btn {
    //-[UIApplication setIdleTimerDisabled:]用于控制自动锁屏，SDK内部并无修改系统锁屏的逻辑
    if (_join_switch) {
        [self stop];
        
        [_btnJoin setImage:[UIImage imageNamed:@"start"] forState:UIControlStateNormal];
        _join_switch = NO;
        [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
        
    } else {
        //是否有摄像头权限
        AVAuthorizationStatus statusVideo = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
        if (statusVideo == AVAuthorizationStatusDenied) {
            [self toastTip:@"获取摄像头权限失败，请前往隐私-相机设置里面打开应用权限"];
            return;
        }
        
        //是否有麦克风权限
        AVAuthorizationStatus statusAudio = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeAudio];
        if (statusAudio == AVAuthorizationStatusDenied) {
            [self toastTip:@"获取麦克风权限失败，请前往隐私-麦克风设置里面打开应用权限"];
            return;
        }
        
        // 获取房间号，账号，密码
        if ([_txtRoomId.text isEqual:@""]) {
            _txtRoomId.text = @"104629";
        }
        if ([_txtUserId.text isEqual:@""]) {
            _txtUserId.text = @"webrtc32";
        }
        if ([_txtUserPwd.text isEqual:@""]) {
            _txtUserPwd.text = @"12345678";
        }
        _roomID = (uint32_t)[_txtRoomId.text integerValue];
        _userID = _txtUserId.text;
        _pwd = _txtUserPwd.text;
        
        // 获取进房所需要的签名，拼成推流地址
        [self getRoomSig:^(NSString *roomSig) {
            if (roomSig) {
                // 注意roomSig是一个json串，里面有空格，需要先url编码
                NSString *strUrl = [NSString stringWithFormat:@"room://cloud.tencent.com?sdkappid=%u&roomid=%u&userid=%@&roomsig=%@",
                            _sdkappid, _roomID, _userID, roomSig];
                _pushUrl = [strUrl stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
                
                //[self appendLog:[NSString stringWithFormat:@"推流地址: %@", _pushUrl]];
                
                // 开始上行推流
                if (![self start]) {
                    return;
                }
                
                // 修改UI
                [_btnJoin setImage:[UIImage imageNamed:@"suspend"] forState:UIControlStateNormal];
                _join_switch = YES;
                [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
                
            } else {
                [self appendLog:@"获取RoomSig失败!"];
            }
        }];
    }
}

// 切换摄像头
- (void)clickCamera:(UIButton*)btn {
    _camera_switch = !_camera_switch;
    [btn setImage:[UIImage imageNamed:(_camera_switch? @"camera2" : @"camera")] forState:UIControlStateNormal];
    [_livePusher switchCamera];
}

// 静音
- (void)clickMute:(UIButton *)btn {
    _mute_switch = !_mute_switch;
    [_btnMute setImage:[UIImage imageNamed:(_mute_switch ? @"mic_dis" : @"mic")] forState:UIControlStateNormal];
    [_livePusher setMute:_mute_switch];
}

// 切换正式环境和测试环境
- (void)clickEnv:(UIButton *)btn {
    if (_env_switch) {
        [btn setImage:[UIImage imageNamed:@"test-env"] forState:UIControlStateNormal];
    } else {
        [btn setImage:[UIImage imageNamed:@"release-env"] forState:UIControlStateNormal];
    }
    _env_switch = !_env_switch;
}

// 设置log显示
- (void)clickLog:(UIButton *)btn {
    switch (_log_switch) {
        case 0:
            _log_switch = 1;
            [_livePusher showVideoDebugLog:YES];
            for (id key in _livePlayerDic) {
                TXLivePlayer *player = [_livePlayerDic objectForKey:key];
                [player showVideoDebugLog:YES];
            }
            
            _logView.hidden = YES;
            _coverView.hidden = YES;
            [btn setImage:[UIImage imageNamed:@"log2"] forState:UIControlStateNormal];
            break;
        case 1:
            _log_switch = 2;
            [_livePusher showVideoDebugLog:NO];
            for (id key in _livePlayerDic) {
                TXLivePlayer *player = [_livePlayerDic objectForKey:key];
                [player showVideoDebugLog:NO];
            }
            
            _logView.hidden = NO;
            _coverView.hidden = NO;
            [self.view bringSubviewToFront:_logView];
            [btn setImage:[UIImage imageNamed:@"log2"] forState:UIControlStateNormal];
            break;
        case 2:
            _log_switch = 0;
            [_livePusher showVideoDebugLog:NO];
            for (id key in _livePlayerDic) {
                TXLivePlayer *player = [_livePlayerDic objectForKey:key];
                [player showVideoDebugLog:NO];
            }
            
            _logView.hidden = YES;
            _coverView.hidden = YES;
            [btn setImage:[UIImage imageNamed:@"log"] forState:UIControlStateNormal];
            break;
        default:
            break;
    }
}

- (void)appendLog:(NSString *)msg {
    NSDateFormatter *format = [[NSDateFormatter alloc] init];
    format.dateFormat = @"hh:mm:ss";
    NSString *time = [format stringFromDate:[NSDate date]];
    NSString *log = [NSString stringWithFormat:@"[%@] %@", time, msg];
    NSString *logMsg = [NSString stringWithFormat:@"%@\n%@", _logView.text, log];
    [_logView setText:logMsg];
}

#pragma mark - TXLivePushListener

- (void)onPushEvent:(int)EvtID withParam:(NSDictionary *)param {
    NSString *msg = (NSString *)[param valueForKey:EVT_MSG];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (EvtID == PUSH_ERR_NET_DISCONNECT) {
            // 关闭推流
            [self clickjoin:_btnJoin];
            
        } else if (EvtID == PUSH_EVT_ROOM_USERLIST) {
            // 下发webrtc房间成员列表(不包括自己)
            [self onWebRTCUserListPush:msg];
            
        } else if (EvtID == PUSH_EVT_ROOM_IN) {
            // 已经在webrtc房间里面，进房成功后通知
            [self appendLog:msg];
            
        } else if (EvtID == PUSH_EVT_ROOM_OUT) {
            // 不在webrtc房间里面，进房失败或者中途退出房间时通知
            [self appendLog:msg];
            // 关闭推流
            [self clickjoin:_btnJoin];
            
        } else if (EvtID == PUSH_EVT_ROOM_NEED_REENTER) {
            // 需要重新进入房间，原因是网络发生切换，需要重新拉取最优的服务器地址
            [self appendLog:msg];
            [self clickjoin:_btnJoin];  // stop
            [self clickjoin:_btnJoin];  // start
        }
    });
}

- (void)onNetStatus:(NSDictionary *)param {

}

#pragma mark - NSNotification
- (void)onAppWillResignActive:(NSNotification*)notification {
    _appIsInActive = YES;
    [_livePusher pausePush];
}

- (void)onAppDidBecomeActive:(NSNotification*)notification {
    _appIsInActive = NO;
    if (!_appIsBackground && !_appIsInActive) {
        [_livePusher resumePush];
    }
}

- (void)onAppDidEnterBackGround:(NSNotification *)notification {
    [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
        
    }];
    
    _appIsBackground = YES;
    [_livePusher pausePush];
}

- (void)onAppWillEnterForeground:(NSNotification *)notification {
    _appIsBackground = NO;
    if (!_appIsBackground && !_appIsInActive) {
        [_livePusher resumePush];
    }
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

/**
    @method 获取指定宽度width的字符串在UITextView上的高度
    @param textView 待计算的UITextView
    @param width 限制字符串显示区域的宽度
    @result float 返回的高度
 */
- (float)heightForString:(UITextView *)textView andWidth:(float)width {
    CGSize sizeToFit = [textView sizeThatFits:CGSizeMake(width, MAXFLOAT)];
    return sizeToFit.height;
}

- (void)toastTip:(NSString *)toastInfo {
    CGRect frameRC = [[UIScreen mainScreen] bounds];
    frameRC.origin.y = frameRC.size.height - 110;
    frameRC.size.height -= 110;
    __block UITextView *toastView = [[UITextView alloc] init];
    
    toastView.editable = NO;
    toastView.selectable = NO;
    
    frameRC.size.height = [self heightForString:toastView andWidth:frameRC.size.width];
    
    toastView.frame = frameRC;
    
    toastView.text = toastInfo;
    toastView.backgroundColor = [UIColor whiteColor];
    toastView.alpha = 0.5;
    
    [self.view addSubview:toastView];
    
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC);
    
    dispatch_after(popTime, dispatch_get_main_queue(), ^() {
        [toastView removeFromSuperview];
        toastView = nil;
    });
}


#pragma mark - 房间逻辑

// 房间列表下发
// 注意服务器下发的列表中不包含自己
// {"userlist":[{"userid":"webrtc11","playurl":"room://183.3.225.15:1935/webrtc/1400037025_107688_webrtc11"},{"userid":"webrtc12","playurl":"room://183.3.225.15:1935/webrtc/1400037025_107688_webrtc12"}]}
- (void)onWebRTCUserListPush:(NSString *)msg {
    if (!msg) {
        return;
    }
    
    NSLog(@"onRecvWebRTCMsg: %@", msg);
    
    // 解析json串
    NSData *jsonData = [msg dataUsingEncoding:NSUTF8StringEncoding];
    NSError *err = NULL;
    NSDictionary *jsonDic = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:&err];
    if (err) {
        return;
    }
    NSArray *userList = jsonDic[@"userlist"];
    if (userList == nil) {
        return;
    }
    
    // 判断哪些人是进房或者退房, userlist为空表示房间里只有自己了
    NSMutableArray *oldUserListArray = _userListArray;
    NSMutableArray *newUserListArray = [[NSMutableArray alloc] init];
    for (id dic in userList) {
        [newUserListArray addObject:dic[@"userid"]];
    }
    
    NSMutableSet *leaveSet = [[NSMutableSet alloc] init];
    for (id userid in oldUserListArray) {
        [leaveSet addObject:userid];
    }
    
    for (int i = 0; i < [newUserListArray count]; ++i) {
        id userid = newUserListArray[i];
        if ([leaveSet containsObject:userid]) {
            [leaveSet removeObject:userid];
        } else {
            NSDictionary *dic = userList[i];
            NSString *playUrl = dic[@"playurl"];
            
            // 进房
            [self onWebRTCUserJoin:userid playUrl:playUrl];
        }
    }
    
    // 退房
    for (id userid in leaveSet) {
        [self onWebRTCUserQuit:userid];
    }
    
    // 更新
    _userListArray = newUserListArray;
}

// 成员加入
- (void)onWebRTCUserJoin:(NSString *)userid playUrl:(NSString *)playUrl {
    // 设置播放view
    UIView *playerView = [[UIView alloc] init];
    [playerView setBackgroundColor:UIColorFromRGB(0x262626)];
    [self.view addSubview:playerView];
    [_playerViewDic setObject:playerView forKey:userid];
    
    // 启动播放器
    TXLivePlayer *player = [_livePlayerDic objectForKey:userid];
    if (!player) {
        WebRTCPlayerListenerWrapper *listenerWrapper = [[WebRTCPlayerListenerWrapper alloc] init];
        listenerWrapper.userID = userid;
        listenerWrapper.delegate = self;
        
        player = [[TXLivePlayer alloc] init];
        player.delegate = listenerWrapper;
        
        TXLivePlayConfig *config = [[TXLivePlayConfig alloc] init];
        [player setConfig:config];
        [_livePlayerDic setObject:player forKey:userid];
        [_playerEventDic setObject:listenerWrapper forKey:userid];
    }
    
    [player setupVideoWidget:CGRectZero containView:playerView insertIndex:0];
    [player startPlay:playUrl type:PLAY_TYPE_LIVE_RTMP_ACC];
    
    [self relayout];
}

// 成员离开
- (void)onWebRTCUserQuit:(NSString *)userid {
    // 关闭播放器
    TXLivePlayer *player = [_livePlayerDic objectForKey:userid];
    if (player) {
        [player stopPlay];
        [player removeVideoWidget];
        player.delegate = nil;
    }
    [_livePlayerDic removeObjectForKey:userid];
    [_playerEventDic removeObjectForKey:userid];
    
    // 更新UI
    UIView *playerView = [_playerViewDic objectForKey:userid];
    [playerView removeFromSuperview];
    [_playerViewDic removeObjectForKey:userid];
    
    [self relayout];
}

#pragma mark - WebRTCPlayerListener

// 播放端事件
-(void)onPlayEvent:(NSString*)userID withEvtID:(int)evtID andParam:(NSDictionary*)param {
    if (evtID == PLAY_ERR_NET_DISCONNECT) {  // 断开连接
        // 将其关闭
        [self onWebRTCUserQuit:userID];
    }
}

#pragma mark - 登录和鉴权

// 登录客户自己的服务器，拿到userSig和privMapEncrypt，用于获取roomSig
typedef void (^ILoginAppCompletion)(NSString *userSig, NSString *privMapEncrypt);
- (void)loginAppServer:(NSString *)userID pwd:(NSString *)pwd roomID:(uint32_t)roomID sdkappid:(uint32_t)sdkappid withCompletion:(ILoginAppCompletion)completion {
    NSDictionary *reqParam = @{@"identifier": userID, @"pwd": pwd, @"appid": @(sdkappid), @"roomnum": @(roomID), @"privMap": @(255)};
    NSString *reqUrl = @"https://sxb.qcloud.com/sxb_dev/?svc=account&cmd=authPrivMap";
    
    [self POST:reqUrl parameters:reqParam retryCount:0 retryLimit:5 progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        dispatch_async(dispatch_get_main_queue(), ^{
            id data = responseObject[@"data"];
            id userSig = data[@"userSig"];
            id privMapEncrypt = data[@"privMapEncrypt"];
            NSLog(@"loginAppServer:[%@]", responseObject);
            if (userSig == nil || privMapEncrypt == nil) {
                [self appendLog:[NSString stringWithFormat:@"loginAppServer:[%@]", [responseObject description]]];
            }
            
            if (completion) {
                completion(userSig, privMapEncrypt);
            }
        });
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completion) {
                completion(nil, nil);
            }
        });
    }];
}

// 请求腾讯云签名服务器，拿到roomSig，用来进入WebRTC房间
typedef void (^IRequestSigCompletion)(NSString *roomSig);
- (void)requestSigServer:(NSString *)userID userSig:(NSString *)userSig privMapEncrypt:(NSString *)privMapEncrypt roomID:(uint32_t)roomID sdkappid:(uint32_t)sdkappid withCompletion:(IRequestSigCompletion)completion {
    NSDictionary *reqHead = @{@"Cmd": @(1), @"SeqNo": @(1), @"BusType": @(7), @"GroupId": @(roomID)};
    NSDictionary *reqBody = @{@"PrivMapEncrypt": privMapEncrypt, @"TerminalType": @(1), @"FromType": @(3), @"SdkVersion": @(26280566)};
    
    NSDictionary *reqParam = @{@"ReqHead": reqHead, @"ReqBody": reqBody};
    
    NSString *reqUrl = nil;
    if (_env_switch) {
        // 正式环境
        reqUrl = [NSString stringWithFormat:@"https://official.opensso.tencent-cloud.com/v4/openim/jsonvideoapp?sdkappid=%u&identifier=%@&usersig=%@&random=9999&contenttype=json", sdkappid, userID, userSig];
    } else {
        // 测试环境
        reqUrl = [NSString stringWithFormat:@"https://test.opensso.tencent-cloud.com/v4/openim/jsonvideoapp?sdkappid=%u&identifier=%@&usersig=%@&random=9999&contenttype=json", sdkappid, userID, userSig];
    }
    
    [self POST:reqUrl parameters:reqParam retryCount:0 retryLimit:5 progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        dispatch_async(dispatch_get_main_queue(), ^{
            id rspHead = responseObject[@"RspHead"];
            id rspBody = responseObject[@"RspBody"];
            NSLog(@"requestSigServer:[%@]", responseObject);
            
            if ([rspHead[@"ErrorCode"] integerValue] != 0) {
                [self appendLog:[NSString stringWithFormat:@"requestSigServer:[%@]", [responseObject description]]];
                
                // 有错误就返回nil
                if (completion) {
                    completion(nil);
                }
                return;
            }
            
            // 将rspBody作为roomSig返回
            if (completion) {
                if (rspBody) {
                    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:rspBody options:NSJSONWritingPrettyPrinted error:NULL];
                    NSString *roomSig = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
                    completion(roomSig);
                } else {
                    completion(nil);
                }
            }
            
        });
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completion) {
                completion(nil);
            }
        });
    }];
}

// 获取进房签名
typedef void (^IGetRoomSigCompletion)(NSString *roomSig);
- (void)getRoomSig:(IGetRoomSigCompletion)completion {
    [self loginAppServer:_userID pwd:_pwd roomID: _roomID sdkappid:_sdkappid withCompletion:^(NSString *userSig, NSString *privMapEncrypt) {
        if (userSig && privMapEncrypt) {
            [self requestSigServer:_userID userSig:userSig privMapEncrypt:privMapEncrypt roomID:_roomID sdkappid:_sdkappid withCompletion:^(NSString *roomSig) {
                if (completion) {
                    completion(roomSig);
                }
            }];
        } else if (completion) {
            completion(nil);
        }
    }];
}

// 网络请求包装，每次请求重试若干次
- (void)POST:(NSString *)URLString
                parameters:(id)parameters
                 retryCount:(NSInteger)retryCount
                 retryLimit:(NSInteger)retryLimit
                  progress:(void (^)(NSProgress * _Nonnull))uploadProgress
                   success:(void (^)(NSURLSessionDataTask * _Nonnull, id _Nullable))success
                   failure:(void (^)(NSURLSessionDataTask * _Nullable, NSError * _Nonnull))failure {
    
    AFHTTPSessionManager *_httpSession;
    _httpSession = [AFHTTPSessionManager manager];
    [_httpSession setRequestSerializer:[AFJSONRequestSerializer serializer]];
    [_httpSession setResponseSerializer:[AFJSONResponseSerializer serializer]];
    [_httpSession.requestSerializer willChangeValueForKey:@"timeoutInterval"];
    _httpSession.requestSerializer.timeoutInterval = 5.0;
    [_httpSession.requestSerializer didChangeValueForKey:@"timeoutInterval"];
    _httpSession.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"application/json", @"text/json", @"text/javascript", @"text/html", @"text/xml", @"text/plain", nil];
    __weak AFHTTPSessionManager *weakManager = _httpSession;
    [_httpSession POST:URLString parameters:parameters progress:uploadProgress success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject){
        [weakManager invalidateSessionCancelingTasks:YES];
        success(task, responseObject);
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        [weakManager invalidateSessionCancelingTasks:YES];
        if (retryCount < retryLimit) {
            // 1秒后重试
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self appendLog:@"https request retry"];
                [self POST:URLString parameters:parameters retryCount:retryCount+1 retryLimit:retryLimit progress:uploadProgress success:success failure:failure];
            });
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (failure) {
                    failure(task, error);
                }
            });
        }
        
    }];
}

@end


@implementation WebRTCPlayerListenerWrapper

- (void)onPlayEvent:(int)EvtID withParam:(NSDictionary*)param {
    if (self.delegate && [self.delegate respondsToSelector:@selector(onPlayEvent:withEvtID:andParam:)]) {
        [self.delegate onPlayEvent:self.userID withEvtID:EvtID andParam:param];
    }
}

- (void)onNetStatus:(NSDictionary*)param {
    if (self.delegate && [self.delegate respondsToSelector:@selector(onNetStatus:withParam:)]) {
        [self.delegate onNetStatus:self.userID withParam:param];
    }
}

@end
