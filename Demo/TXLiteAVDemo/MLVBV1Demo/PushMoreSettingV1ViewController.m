/**
 * Module:   PushMoreSettingV1ViewController
 *
 * Function: 推流相关的更多设置项
 */

#import "PushMoreSettingV1ViewController.h"
#import "UIView+Additions.h"
#import "AppLocalized.h"

/* 列表项 */
#define CELL_DISABLE_VIDEO          0
#define CELL_MUTE_AUDIO             1
#define CELL_HORIZONTAL_PUSH        2
#define CELL_DEBUG_LOG              3
#define CELL_WARTERMARK             4
#define CELL_MIRROR                 5
#define CELL_TORCH                  6
#define CELL_DELAY_CHECK            7
#define CELL_TOUCH_FOCUS            8
#define CELL_ZOOM                   9
#define CELL_PURE_AUDIO             10
#define CELL_SNAPSHOT               11
#define CELL_SEND_MESSAGE           12
#define CELL_SHARPNESS_ENHANCEMENT  13
#define CELL_VIDEO_CODEC            14
#define CELL_CAPTURE_FRAME          15

/* 编号，请不要修改，写配置文件依赖这个 */
#define TAG_DISABLE_VIDEO          1000
#define TAG_MUTE_AUDIO             1001
#define TAG_HORIZONTAL_PUSH        1002
#define TAG_DEBUG_LOG              1003
#define TAG_WARTERMARK             1004
#define TAG_MIRROR                 1005
#define TAG_TORCH                  1006
#define TAG_DELAY_CHECK            1007
#define TAG_TOUCH_FOCUS            1008
#define TAG_ZOOM                   1009
#define TAG_PURE_AUDIO             1010
#define TAG_SEND_MESSAGE           1011
#define TAG_SHARPNESS_ENHANCEMENT  1012
#define TAG_VIDEO_ENCODE_TYPE      1013
#define TAG_CAPTURE_FRAME          1014

@interface PushMoreSettingV1ViewController ()<UITextFieldDelegate> {
    UISwitch        *_disableVideoSwitch;
    UISwitch        *_muteAudioSwitch;
    UISwitch        *_mirrorSwitch;
    UISwitch        *_torchSwitch;
    UISwitch        *_delayCheckSwitch;
    UISwitch        *_horizontalPushSwitch;
    UISwitch        *_debugLogSwitch;
    UISwitch        *_watermarkSwitch;
    UISwitch        *_touchFocusSwitch;
    UISwitch        *_zoomSwitch;
    UISwitch        *_pureAudioSwitch;
    UISwitch        *_videoCodecSwitch;
    UIButton        *_snapShotButton;
    UISwitch        *_sharpnessEnhancementSwitch;
    UITextField     *_messageField;
    UIView          *_messageView;
    UIColor         *_tintColor;
}
@end

@implementation PushMoreSettingV1ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor.blackColor colorWithAlphaComponent:0.3];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    
    _tintColor = [[UISegmentedControl alloc] init].tintColor;
    
    _disableVideoSwitch         = [self createUISwitch:TAG_DISABLE_VIDEO on:[PushMoreSettingV1ViewController isDisableVideo]];
    _muteAudioSwitch            = [self createUISwitch:TAG_MUTE_AUDIO on:[PushMoreSettingV1ViewController isMuteAudio]];
    _mirrorSwitch               = [self createUISwitch:TAG_MIRROR on:[PushMoreSettingV1ViewController isMirrorVideo]];
    _torchSwitch                = [self createUISwitch:TAG_TORCH on:[PushMoreSettingV1ViewController isOpenTorch]];
    _delayCheckSwitch           = [self createUISwitch:TAG_DELAY_CHECK on:[PushMoreSettingV1ViewController isEnableDelayCheck]];
    _horizontalPushSwitch       = [self createUISwitch:TAG_HORIZONTAL_PUSH on:[PushMoreSettingV1ViewController isHorizontalPush]];
    _debugLogSwitch             = [self createUISwitch:TAG_DEBUG_LOG on:[PushMoreSettingV1ViewController isShowDebugLog]];
    _watermarkSwitch            = [self createUISwitch:TAG_WARTERMARK on:[PushMoreSettingV1ViewController isEnableWaterMark]];
    _touchFocusSwitch           = [self createUISwitch:TAG_TOUCH_FOCUS on:[PushMoreSettingV1ViewController isEnableTouchFocus]];
    _zoomSwitch                 = [self createUISwitch:TAG_ZOOM on:[PushMoreSettingV1ViewController isEnableVideoZoom]];
    _pureAudioSwitch            = [self createUISwitch:TAG_PURE_AUDIO on:[PushMoreSettingV1ViewController isEnablePureAudioPush]];
    _sharpnessEnhancementSwitch = [self createUISwitch:TAG_SHARPNESS_ENHANCEMENT on:YES];
    _videoCodecSwitch           = [self createUISwitch:TAG_VIDEO_ENCODE_TYPE on:[PushMoreSettingV1ViewController isEnableHEVC]];
    _snapShotButton             = [self createButtonWithTitle:LivePlayerLocalize(@"LivePusherDemo.MoreSetting.screenshots") action:@selector(onSnapShot:)];
    _messageView                = [self createMessageView];
}

- (UIButton *)createButtonWithTitle:(NSString *)title action:(SEL)action {
    UIButton *newBtn       = [UIButton new];
    newBtn.frame = CGRectMake(0, 0, 50, 30);
    newBtn.layer.cornerRadius  = 5;
    newBtn.layer.shadowOffset  =  CGSizeMake(1, 1);
    newBtn.layer.shadowOpacity = 0.8;
    newBtn.layer.shadowColor   =  [UIColor whiteColor].CGColor;
    newBtn.backgroundColor     = [_tintColor colorWithAlphaComponent:0.6];
    newBtn.titleLabel.font     = [UIFont systemFontOfSize:14];
    [newBtn setTitle:title forState:UIControlStateNormal];
    [newBtn addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    return newBtn;
}

- (UISwitch *)createUISwitch:(NSInteger)tag on:(BOOL)on {
    UISwitch *sw = [[UISwitch alloc] initWithFrame:CGRectZero];
    sw.tag = tag;
    sw.on = on;
    sw.tintColor = _tintColor;
    sw.onTintColor = _tintColor;
    [sw addTarget:self action:@selector(onSwitchTap:) forControlEvents:UIControlEventTouchUpInside];
    return sw;
}

- (UIView *)createMessageView {
    UIView *panel = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 200, 30)];
    _messageField = [[UITextField alloc] initWithFrame:CGRectMake(0, 0, 140, 30)];
    _messageField.delegate = self;
    _messageField.backgroundColor = [UIColor whiteColor];
    [panel addSubview:_messageField];
    UIButton *sendButton = [self createButtonWithTitle:LivePlayerLocalize(@"LiveLinkMicDemoOld.RoomPlayer.send") action:@selector(onSendMessage:)];
    sendButton.frame = CGRectMake(150, 0, 50, 30);
    [panel addSubview:sendButton];
    
    return panel;
}

- (void)onSwitchTap:(UISwitch *)switchBtn {
    [PushMoreSettingV1ViewController saveSetting:switchBtn.tag value:switchBtn.on];
    
    if (switchBtn.tag == TAG_DISABLE_VIDEO) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(onPushMoreSetting:disableVideo:)]) {
            [self.delegate onPushMoreSetting:self disableVideo:switchBtn.on];
        }
    } else if (switchBtn.tag == TAG_MUTE_AUDIO) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(onPushMoreSetting:muteAudio:)]) {
            [self.delegate onPushMoreSetting:self muteAudio:switchBtn.on];
        }
    } else if (switchBtn.tag == TAG_MIRROR) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(onPushMoreSetting:mirrorVideo:)]) {
            [self.delegate onPushMoreSetting:self mirrorVideo:switchBtn.on];
        }
        
    } else if (switchBtn.tag == TAG_TORCH) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(onPushMoreSetting:openTorch:)]) {
            [self.delegate onPushMoreSetting:self openTorch:switchBtn.on];
        }
    } else if (switchBtn.tag == TAG_HORIZONTAL_PUSH) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(onPushMoreSetting:horizontalPush:)]) {
            [self.delegate onPushMoreSetting:self horizontalPush:switchBtn.on];
        }
    } else if (switchBtn.tag == TAG_DEBUG_LOG) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(onPushMoreSetting:debugLog:)]) {
            [self.delegate onPushMoreSetting:self debugLog:switchBtn.on];
        }
    } else if (switchBtn.tag == TAG_WARTERMARK) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(onPushMoreSetting:waterMark:)]) {
            [self.delegate onPushMoreSetting:self waterMark:switchBtn.on];
        }
    } else if (switchBtn.tag == TAG_DELAY_CHECK) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(onPushMoreSetting:delayCheck:)]) {
            [self.delegate onPushMoreSetting:self delayCheck:switchBtn.on];
        }
    } else if (switchBtn.tag == TAG_TOUCH_FOCUS) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(onPushMoreSetting:touchFocus:)]) {
            [self.delegate onPushMoreSetting:self touchFocus:switchBtn.on];
        }
    } else if (switchBtn.tag == TAG_ZOOM) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(onPushMoreSetting:videoZoom:)]) {
            [self.delegate onPushMoreSetting:self videoZoom:switchBtn.on];
        }
    } else if (switchBtn.tag == TAG_PURE_AUDIO) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(onPushMoreSetting:videoZoom:)]) {
            [self.delegate onPushMoreSetting:self pureAudioPush:switchBtn.on];
        }
    } else if (switchBtn.tag == TAG_SHARPNESS_ENHANCEMENT) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(onPushMoreSetting:enableSharpnessEnhancement:)]) {
            [self.delegate onPushMoreSetting:self enableSharpnessEnhancement:switchBtn.on];
        }
    } else if (switchBtn.tag == TAG_VIDEO_ENCODE_TYPE) {
        if (self.delegate && [self.delegate respondsToSelector:@selector((onPushMoreSetting:enableHEVC:))]) {
            [self.delegate onPushMoreSetting:self enableHEVC:switchBtn.on];
        }
    }
}

- (void)onSnapShot:(UIButton *)btn {
    if (self.delegate && [self.delegate respondsToSelector:@selector(onPushMoreSettingSnapShot:)]) {
        [self.delegate onPushMoreSettingSnapShot:self];
    }
}

- (void)onSendMessage:(UIButton *)btn {
    if (self.delegate && [self.delegate respondsToSelector:@selector(onPushMoreSettingSendMessage:message:)]) {
        [self.delegate onPushMoreSettingSendMessage:self message:_messageField.text];
    }
    [_messageField resignFirstResponder];
    _messageField.text = nil;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return YES;
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    if (_messageField) {
        [_messageField resignFirstResponder];
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 16;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [[UITableViewCell alloc] initWithFrame:CGRectMake(0, 0, self.tableView.width, self.tableView.height / 10)];
    cell.backgroundColor = UIColor.clearColor;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.textLabel.textColor = UIColor.whiteColor;
    cell.textLabel.font = [UIFont systemFontOfSize:16];
    
    switch (indexPath.row) {
        case CELL_DISABLE_VIDEO: {
            cell.textLabel.text = LivePlayerLocalize(@"LivePusherDemo.MoreSetting.enableprivacymode");
            cell.accessoryView = _disableVideoSwitch;
            
            break;
        }
            
        case CELL_MUTE_AUDIO: {
            cell.textLabel.text = LivePlayerLocalize(@"LivePusherDemo.MoreSetting.turnonmutemode");
            cell.accessoryView = _muteAudioSwitch;
            
            break;
        }
            
        case CELL_MIRROR: {
            cell.textLabel.text = LivePlayerLocalize(@"LivePusherDemo.MoreSetting.turnonviewmirror");
            cell.accessoryView = _mirrorSwitch;
            
            break;
        }
            
        case CELL_TORCH: {
            cell.textLabel.text = LivePlayerLocalize(@"LivePusherDemo.MoreSetting.turnontherearflash");
            cell.accessoryView = _torchSwitch;
            
            break;
        }
            
        case CELL_HORIZONTAL_PUSH: {
            cell.textLabel.text = LivePlayerLocalize(@"LivePusherDemo.MoreSetting.turnonhorizontalpushflow");
            cell.accessoryView = _horizontalPushSwitch;
            
            break;
        }
            
        case CELL_DEBUG_LOG: {
            cell.textLabel.text = LivePlayerLocalize(@"LivePusherDemo.MoreSetting.openingdebuglog");
            cell.accessoryView = _debugLogSwitch;
            
            break;
        }
            
        case CELL_WARTERMARK: {
            cell.textLabel.text = LivePlayerLocalize(@"LivePusherDemo.MoreSetting.addwatermark");
            cell.accessoryView = _watermarkSwitch;
            
            break;
        }
            
        case CELL_DELAY_CHECK: {
            cell.textLabel.text = LivePlayerLocalize(@"LivePusherDemo.MoreSetting.delaymeasurementbar");
            cell.accessoryView = _delayCheckSwitch;
            
            break;
        }
            
        case CELL_TOUCH_FOCUS: {
            cell.textLabel.text = LivePlayerLocalize(@"LivePusherDemo.MoreSetting.manuallyclickexposureandfocus");
            cell.accessoryView = _touchFocusSwitch;
            
            break;
        }
        case CELL_ZOOM: {
            cell.textLabel.text = LivePlayerLocalize(@"LivePusherDemo.MoreSetting.gesturetozoominonthepreview");
            cell.accessoryView = _zoomSwitch;
            
            break;
        }
        case CELL_PURE_AUDIO: {
            cell.textLabel.text = LivePlayerLocalize(@"LivePusherDemo.MoreSetting.enableaudiopushstream");
            cell.accessoryView = _pureAudioSwitch;
            
            break;
        }
        case CELL_SNAPSHOT: {
            cell.textLabel.text = LivePlayerLocalize(@"LivePusherDemo.MoreSetting.localscreenshots");
            cell.accessoryView = _snapShotButton;
            
            break;
        }
        case CELL_SEND_MESSAGE: {
            cell.textLabel.text = LivePlayerLocalize(@"LivePusherDemo.MoreSetting.sendmessage");
            cell.accessoryView = _messageView;
            
            break;
        }
        case CELL_SHARPNESS_ENHANCEMENT: {
            cell.textLabel.text = LivePlayerLocalize(@"LivePusherDemo.MoreSetting.turnonsharpnessenhancement");
            cell.accessoryView = _sharpnessEnhancementSwitch;
            
            break;
        }
        case CELL_VIDEO_CODEC: {
            cell.textLabel.text = LivePlayerLocalize(@"LivePusherDemo.MoreSetting.enableHevcCodec");
            cell.accessoryView  = _videoCodecSwitch;
                    
            break;
        }
        case CELL_CAPTURE_FRAME: {
            cell.textLabel.text = [NSString stringWithFormat:@"%@(%@)", LivePlayerLocalize(@"LivePusherDemo.MoreSetting.captureframe"), @([self getCaptureFrame])];
            cell.accessoryView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"arrow"]];
            break;
        }
        default:
            break;
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    
    if (indexPath.row == CELL_CAPTURE_FRAME) {
        // 采集帧率选择
        [self presentSelectCaptureFrame];
    }
}

#pragma mark - 采集帧率选择

/// 采集帧率选择 15, 20
- (void)presentSelectCaptureFrame{
    UIAlertController *selectSheet = [UIAlertController alertControllerWithTitle:LivePlayerLocalize(@"LivePusherDemo.MoreSetting.captureframe") message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    __weak typeof(self) weakSelf = self;
    // 采集帧率：15
    UIAlertAction *fps15 = [UIAlertAction actionWithTitle:@"15" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [weakSelf selectCaptureFrame:15];
    }];
    [selectSheet addAction:fps15];
    // 采集帧率：20
    UIAlertAction *fps20 = [UIAlertAction actionWithTitle:@"20" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [weakSelf selectCaptureFrame:20];
    }];
    [selectSheet addAction:fps20];
    // 取消
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:LivePlayerLocalize(@"LivePusherDemo.PushSetting.cancel") style:UIAlertActionStyleCancel handler:nil];
    [selectSheet addAction:cancelAction];

    [self presentViewController:selectSheet animated:YES completion:nil];
}

/// 设置采集帧率
- (void)selectCaptureFrame:(NSInteger)fps{
    [PushMoreSettingV1ViewController saveSetting:TAG_CAPTURE_FRAME value:fps];
    
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:CELL_CAPTURE_FRAME inSection:0]];
    if (cell) {
        cell.textLabel.text = [NSString stringWithFormat:@"%@(%@)", LivePlayerLocalize(@"LivePusherDemo.MoreSetting.captureframe"), @(fps)];
    }
    if (self.delegate && [self.delegate respondsToSelector:@selector(onPushMoreSetting:captureFPS:)]) {
        [self.delegate onPushMoreSetting:self captureFPS:fps];
    }
}

#pragma mark - 读写配置文件

+ (NSString *)getKey:(NSInteger)tag {
    return [NSString stringWithFormat:@"PUSH_V1_MORE_SETTING_%ld", tag];
}

+ (void)saveSetting:(NSInteger)tag value:(NSInteger)value {
    NSString *key = [PushMoreSettingV1ViewController getKey:tag];
    [[NSUserDefaults standardUserDefaults] setObject:@(value) forKey:key];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (BOOL)isDisableVideo {
    NSString *key = [PushMoreSettingV1ViewController getKey:TAG_DISABLE_VIDEO];
    NSNumber *d = [[NSUserDefaults standardUserDefaults] objectForKey:key];
    if (d != nil) {
        return [d intValue];
    }
    return NO;
}

+ (BOOL)isMuteAudio {
    NSString *key = [PushMoreSettingV1ViewController getKey:TAG_MUTE_AUDIO];
    NSNumber *d = [[NSUserDefaults standardUserDefaults] objectForKey:key];
    if (d != nil) {
        return [d intValue];
    }
    return NO;
}

+ (BOOL)isMirrorVideo {
    NSString *key = [PushMoreSettingV1ViewController getKey:TAG_MIRROR];
    NSNumber *d = [[NSUserDefaults standardUserDefaults] objectForKey:key];
    if (d != nil) {
        return [d intValue];
    }
    return NO;
}

+ (BOOL)isOpenTorch {
    NSString *key = [PushMoreSettingV1ViewController getKey:TAG_TORCH];
    NSNumber *d = [[NSUserDefaults standardUserDefaults] objectForKey:key];
    if (d != nil) {
        return [d intValue];
    }
    return NO;
}

+ (BOOL)isHorizontalPush {
    NSString *key = [PushMoreSettingV1ViewController getKey:TAG_HORIZONTAL_PUSH];
    NSNumber *d = [[NSUserDefaults standardUserDefaults] objectForKey:key];
    if (d != nil) {
        return [d intValue];
    }
    return NO;
}

+ (BOOL)isShowDebugLog {
    NSString *key = [PushMoreSettingV1ViewController getKey:TAG_DEBUG_LOG];
    NSNumber *d = [[NSUserDefaults standardUserDefaults] objectForKey:key];
    if (d != nil) {
        return [d intValue];
    }
    return NO;
}

+ (BOOL)isEnableWaterMark {
    NSString *key = [PushMoreSettingV1ViewController getKey:TAG_WARTERMARK];
    NSNumber *d = [[NSUserDefaults standardUserDefaults] objectForKey:key];
    if (d != nil) {
        return [d intValue];
    }
    return NO;
}

+ (BOOL)isEnableDelayCheck {
    NSString *key = [PushMoreSettingV1ViewController getKey:TAG_DELAY_CHECK];
    NSNumber *d = [[NSUserDefaults standardUserDefaults] objectForKey:key];
    if (d != nil) {
        return [d intValue];
    }
    return NO;
}

+ (BOOL)isEnableTouchFocus {
    NSString *key = [PushMoreSettingV1ViewController getKey:TAG_TOUCH_FOCUS];
    NSNumber *d = [[NSUserDefaults standardUserDefaults] objectForKey:key];
    if (d != nil) {
        return [d intValue];
    }
    return YES;
}

+ (BOOL)isEnableVideoZoom {
    NSString *key = [PushMoreSettingV1ViewController getKey:TAG_ZOOM];
    NSNumber *d = [[NSUserDefaults standardUserDefaults] objectForKey:key];
    if (d != nil) {
        return [d intValue];
    }
    return NO;
}

+ (BOOL)isEnablePureAudioPush {
    NSString *key = [PushMoreSettingV1ViewController getKey:TAG_PURE_AUDIO];
    NSNumber *d = [[NSUserDefaults standardUserDefaults] objectForKey:key];
    if (d != nil) {
        return [d intValue];
    }
    return NO;
}

+ (BOOL)isEnableHEVC {
    NSString *key = [PushMoreSettingV1ViewController getKey:TAG_VIDEO_ENCODE_TYPE];
    NSNumber *d   = [[NSUserDefaults standardUserDefaults] objectForKey:key];
    if (d != nil) {
        return [d boolValue];
    }
    return NO;
}

// 默认值为15
- (NSInteger)getCaptureFrame {
    NSString *key = [PushMoreSettingV1ViewController getKey:TAG_CAPTURE_FRAME];
    NSNumber *value = [[NSUserDefaults standardUserDefaults] objectForKey:key];
    if (value != nil) {
        return [value integerValue];
    }
    return 15;
}

+ (void)setDisableVideo:(BOOL)disable {
    [PushMoreSettingV1ViewController saveSetting:TAG_DISABLE_VIDEO value:disable];
}

@end
