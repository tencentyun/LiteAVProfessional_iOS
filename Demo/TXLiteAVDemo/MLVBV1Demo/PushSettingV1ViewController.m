/**
 * Module:   PushSettingV1ViewController
 *
 * Function: 推流相关的主要设置项
 */

#import "PushSettingV1ViewController.h"
#import "UIView+Additions.h"
#import "ColorMacro.h"
#import "AppLocalized.h"

/* 列表项 */
#define SECTION_QUALITY             0
#define SECTION_AUDIO_QUALITY       1
#define SECTION_REVERB              2
#define SECTION_VOICE_CHANGER       3
#define SECTION_BANDWIDTH_ADJUST    4
#define SECTION_HW                  5
#define SECTION_AUDIO_PREVIEW       6

/* 编号，请不要修改，写配置文件依赖这个 */
#define TAG_QUALITY                 1000
#define TAG_REVERB                  1001
#define TAG_VOICE_CHANGER           1002
#define TAG_BANDWIDTH_ADJUST        1003
#define TAG_HW                      1004
#define TAG_AUDIO_PREVIEW           1005
#define TAG_AUDIO_QUALITY           1006

@interface PushSettingOldQuality : NSObject
@property (copy, nonatomic) NSString *title;
@property (assign, nonatomic) TX_Enum_Type_VideoQuality value;
@end

@implementation PushSettingOldQuality
@end

@interface PushSettingV1ViewController () <UITableViewDelegate, UITableViewDataSource, UIActionSheetDelegate>
{
    UISwitch                            *_bandwidthSwitch;
    UISwitch                            *_hwSwitch;
    UISwitch                            *_audioPreviewSwitch;
    NSArray<PushSettingOldQuality *>    *_qualities;
    NSArray<NSString *>                 *_audioQualities;
    NSArray<NSString *>                 *_voiceChangers;
    NSArray<NSString *>                 *_reverbs;
}

@property (strong, nonatomic) UITableView *mainTableView;

@end

@implementation PushSettingV1ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = LivePlayerLocalize(@"LivePusherDemo.PushSetting.setting");
    
    NSArray<NSString *> *titleArray = @[LivePlayerLocalize(@"LivePusherDemo.PushSetting.bluray"),
                                         LivePlayerLocalize(@"LivePusherDemo.PushSetting.superclear"),
                                         LivePlayerLocalize(@"LivePusherDemo.PushSetting.hd"),
                                         LivePlayerLocalize(@"LivePusherDemo.PushSetting.standarddefinition"),
                                         LivePlayerLocalize(@"LivePusherDemo.PushSetting.lianmaibighost"),
                                         LivePlayerLocalize(@"LivePusherDemo.PushSetting.lianmaismallhost"),
                                         LivePlayerLocalize(@"LivePusherDemo.PushSetting.realtimeaudioandvideo")];
    TX_Enum_Type_VideoQuality qualityArray[] = {
        VIDEO_QUALITY_ULTRA_DEFINITION,
        VIDEO_QUALITY_SUPER_DEFINITION,
        VIDEO_QUALITY_HIGH_DEFINITION,
        VIDEO_QUALITY_STANDARD_DEFINITION,
        VIDEO_QUALITY_LINKMIC_MAIN_PUBLISHER,
        VIDEO_QUALITY_LINKMIC_SUB_PUBLISHER,
        VIDEO_QUALITY_REALTIME_VIDEOCHAT
    };
    NSMutableArray *qualities = [[NSMutableArray alloc] initWithCapacity:titleArray.count];
    for (int i = 0; i < titleArray.count; ++i) {
        PushSettingOldQuality *quality = [[PushSettingOldQuality alloc] init];
        quality.title = titleArray[i];
        quality.value = qualityArray[i];
        [qualities addObject:quality];
    }
    _qualities      = qualities;
    
    _audioQualities = @[LivePlayerLocalize(@"LivePusherDemo.PushSetting.voice"),
                        LivePlayerLocalize(@"LivePusherDemo.PushSetting.standard"),
                        LivePlayerLocalize(@"LivePusherDemo.PushSetting.music")];
    
    _reverbs        = @[LivePlayerLocalize(@"LivePusherDemo.PushSetting.turnoffreverb"),
                        LivePlayerLocalize(@"LivePusherDemo.PushSetting.ktv"),
                        LivePlayerLocalize(@"LivePusherDemo.PushSetting.room"),
                        LivePlayerLocalize(@"LivePusherDemo.PushSetting.hall"),
                        LivePlayerLocalize(@"LivePusherDemo.PushSetting.muffled"),
                        LivePlayerLocalize(@"LivePusherDemo.PushSetting.sonorous"),
                        LivePlayerLocalize(@"LivePusherDemo.PushSetting.metal"),
                        LivePlayerLocalize(@"LivePusherDemo.PushSetting.magnetic")];
    
    _voiceChangers  = @[LivePlayerLocalize(@"LivePusherDemo.PushSetting.turnoffvoicechanger"),
                        LivePlayerLocalize(@"LivePusherDemo.PushSetting.badboy"),
                        LivePlayerLocalize(@"LivePusherDemo.PushSetting.loli"),
                        LivePlayerLocalize(@"LivePusherDemo.PushSetting.uncle"),
                        LivePlayerLocalize(@"LivePusherDemo.PushSetting.heavymetal"),
                        LivePlayerLocalize(@"LivePusherDemo.PushSetting.catarrh"),
                        LivePlayerLocalize(@"LivePusherDemo.PushSetting.foreigner"),
                        LivePlayerLocalize(@"LivePusherDemo.PushSetting.sleepybeast"),
                        LivePlayerLocalize(@"LivePusherDemo.PushSetting.Otaku"),
                        LivePlayerLocalize(@"LivePusherDemo.PushSetting.strongcurrent"),
                        LivePlayerLocalize(@"LivePusherDemo.PushSetting.heavymachinery"),
                        LivePlayerLocalize(@"LivePusherDemo.PushSetting.ethereal")];
    
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:LivePlayerLocalize(@"LivePusherDemo.PushSetting.back") style:UIBarButtonItemStylePlain target:self action:@selector(onClickedCancel:)];
    
    _bandwidthSwitch = [self createUISwitch:TAG_BANDWIDTH_ADJUST on:[PushSettingV1ViewController getBandWidthAdjust]];
    _hwSwitch = [self createUISwitch:TAG_HW on:[PushSettingV1ViewController getEnableHWAcceleration]];
    _audioPreviewSwitch = [self createUISwitch:TAG_AUDIO_PREVIEW on:[PushSettingV1ViewController getEnableAudioPreview]];
    
    _mainTableView = [[UITableView alloc] initWithFrame:self.view.frame style:UITableViewStyleGrouped];
    _mainTableView.delegate = self;
    _mainTableView.dataSource = self;
    _mainTableView.separatorColor = [UIColor darkGrayColor];
    [self.view addSubview:_mainTableView];
    [_mainTableView setContentInset:UIEdgeInsetsMake(0, 0, 34, 0)];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.navigationController.navigationBar.translucent = NO;
    [self.navigationController setNavigationBarHidden:NO animated:NO];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:NO];
    self.navigationController.navigationBar.translucent = YES;
}

- (void)onClickedCancel:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)onClickedOK:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

- (UISwitch *)createUISwitch:(NSInteger)tag on:(BOOL)on {
    UISwitch *sw = [[UISwitch alloc] initWithFrame:CGRectZero];
    sw.tag = tag;
    sw.on = on;
    [sw addTarget:self action:@selector(onSwitchTap:) forControlEvents:UIControlEventTouchUpInside];
    return sw;
}

- (void)onSwitchTap:(UISwitch *)switchBtn {
    [PushSettingV1ViewController saveSetting:switchBtn.tag value:switchBtn.on];
    
    if (switchBtn.tag == TAG_BANDWIDTH_ADJUST) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(onPushSetting:enableBandwidthAdjust:)]) {
            [self.delegate onPushSetting:self enableBandwidthAdjust:switchBtn.on];
        }
    } else if (switchBtn.tag == TAG_HW) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(onPushSetting:enableHWAcceleration:)]) {
            [self.delegate onPushSetting:self enableHWAcceleration:switchBtn.on];
        }
    } else if (switchBtn.tag == TAG_AUDIO_PREVIEW) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(onPushSetting:enableAudioPreview:)]) {
            [self.delegate onPushSetting:self enableAudioPreview:switchBtn.on];
        }
    }
}

- (NSString *)getQualityStr {
    TX_Enum_Type_VideoQuality quality = [PushSettingV1ViewController getVideoQuality];
    for (PushSettingOldQuality *q in _qualities) {
        if (q.value == quality) {
            return q.title;
        }
    }
    return _qualities.firstObject.title;
}

- (NSString *)getReverbStr {
    static NSArray *arr = nil;
    if (arr == nil) {
        arr = [NSArray arrayWithObjects:
               LivePlayerLocalize(@"LivePusherDemo.PushSetting.turnoffreverb"),
               LivePlayerLocalize(@"LivePusherDemo.PushSetting.ktv"),
               LivePlayerLocalize(@"LivePusherDemo.PushSetting.room"),
               LivePlayerLocalize(@"LivePusherDemo.PushSetting.hall"),
               LivePlayerLocalize(@"LivePusherDemo.PushSetting.muffled"),
               LivePlayerLocalize(@"LivePusherDemo.PushSetting.sonorous"),
               LivePlayerLocalize(@"LivePusherDemo.PushSetting.metal"),
               LivePlayerLocalize(@"LivePusherDemo.PushSetting.magnetic"), nil];
    }
    NSInteger index = [PushSettingV1ViewController getReverbType];
    if (index < arr.count && index >= 0) {
        return arr[index];
    }
    return arr[0];
}

- (NSString *)getVoiceChangerStr {
    static NSArray *arr = nil;
    if (arr == nil) {
        arr = [NSArray arrayWithObjects:
               LivePlayerLocalize(@"LivePusherDemo.PushSetting.turnoffvoicechanger"),
               LivePlayerLocalize(@"LivePusherDemo.PushSetting.badboy"),
               LivePlayerLocalize(@"LivePusherDemo.PushSetting.loli"),
               LivePlayerLocalize(@"LivePusherDemo.PushSetting.uncle"),
               LivePlayerLocalize(@"LivePusherDemo.PushSetting.heavymetal"),
               LivePlayerLocalize(@"LivePusherDemo.PushSetting.catarrh"),
               LivePlayerLocalize(@"LivePusherDemo.PushSetting.foreigner"),
               LivePlayerLocalize(@"LivePusherDemo.PushSetting.sleepybeast"),
               LivePlayerLocalize(@"LivePusherDemo.PushSetting.Otaku"),
               LivePlayerLocalize(@"LivePusherDemo.PushSetting.strongcurrent"),
               LivePlayerLocalize(@"LivePusherDemo.PushSetting.heavymachinery"),
               LivePlayerLocalize(@"LivePusherDemo.PushSetting.ethereal"), nil];
    }
    NSInteger index = [PushSettingV1ViewController getVoiceChangerType];
    if (index < arr.count && index >= 0) {
        return arr[index];
    }
    return arr[0];
}

- (NSString *)getAudioQualityStr {
    NSInteger value = [PushSettingV1ViewController getAudioQuality];
    return [_audioQualities objectAtIndex:value];
}

+ (UIView *)buildAccessoryView {
    return [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"arrow"]];
}

- (void)_showQualityActionSheet {
    UIAlertController *controller = [UIAlertController alertControllerWithTitle:LivePlayerLocalize(@"LivePusherDemo.PushSetting.imagequality")
                                                                        message:nil
                                                                 preferredStyle:UIAlertControllerStyleActionSheet];
    __weak __typeof(self) wself = self;
    for (PushSettingOldQuality *q in _qualities) {
        UIAlertAction *action = [UIAlertAction actionWithTitle:q.title
                                                         style:UIAlertActionStyleDefault
                                                       handler:^(UIAlertAction * _Nonnull action) {
            __strong __typeof(wself) self = wself;
            if (self == nil) return;
            [PushSettingV1ViewController saveSetting:TAG_QUALITY value:q.value];
            id<PushSettingV1Delegate> delegate = self.delegate;
            if ([delegate respondsToSelector:@selector(onPushSetting:videoQuality:)]) {
                [delegate onPushSetting:self videoQuality:q.value];
            }
            [self.mainTableView reloadData];
        }];
        [controller addAction:action];
    }
    [controller addAction:[UIAlertAction actionWithTitle:LivePlayerLocalize(@"LivePusherDemo.PushSetting.cancel")
                                                   style:UIAlertActionStyleCancel
                                                 handler:nil]];
    [self presentViewController:controller animated:YES completion:nil];
}

- (void)_showAudioQualityActionSheet {
    UIAlertController *controller = [UIAlertController alertControllerWithTitle:LivePlayerLocalize(@"LivePusherDemo.PushSetting.thesoundquality")
                                                                        message:nil
                                                                 preferredStyle:UIAlertControllerStyleActionSheet];
    __weak typeof(self) wsself = self;
    for (NSString *title in _audioQualities) {
        UIAlertAction *action = [UIAlertAction actionWithTitle:title style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            __strong typeof(wsself) self = wsself;
            if (self == nil) {
                return;
            }
            NSInteger qualityValue = [self->_audioQualities indexOfObject:title];
            [PushSettingV1ViewController saveSetting:TAG_AUDIO_QUALITY value:qualityValue];
            id<PushSettingV1Delegate> delegate = self.delegate;
            if ([delegate respondsToSelector:@selector(onPushSetting:videoQuality:)]) {
                [delegate onPushSetting:self audioQuality:qualityValue];
            }
            [self.mainTableView reloadData];
        }];
        [controller addAction:action];
    }
    [controller addAction:[UIAlertAction actionWithTitle:LivePlayerLocalize(@"LivePusherDemo.PushSetting.cancel")
                                                   style:UIAlertActionStyleCancel
                                                 handler:nil]];
    [self presentViewController:controller animated:YES completion:nil];
}

- (void)_showActionSheet:(NSInteger )actionTag {
    NSArray *actionArray = @[];
    NSString *actionTitle = @"";
    if (actionTag == TAG_REVERB) {
        actionArray = _reverbs;
        actionTitle = LivePlayerLocalize(@"LivePusherDemo.PushSetting.reverb");
    } else if (actionTag == TAG_VOICE_CHANGER) {
        actionArray = _voiceChangers;
        actionTitle = LivePlayerLocalize(@"LivePusherDemo.PushSetting.voicechanger");
    }
    
    UIAlertController *controller = [UIAlertController alertControllerWithTitle:actionTitle
                                                                        message:nil
                                                                 preferredStyle:UIAlertControllerStyleActionSheet];
   
    __weak typeof(self) wsself = self;
    for (NSString *title in actionArray) {
        UIAlertAction *action = [UIAlertAction actionWithTitle:title style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            __strong typeof(wsself) self = wsself;
            if (self == nil) {
                return;
            }
            NSInteger actionValue = [actionArray indexOfObject:title];
            [PushSettingV1ViewController saveSetting:actionTag value:actionValue];
            id<PushSettingV1Delegate> delegate = self.delegate;
            if (actionTag == TAG_REVERB) {
                if ([delegate respondsToSelector:@selector(onPushSetting:reverbType:)]) {
                    [delegate onPushSetting:self reverbType:actionValue];
                }
            } else if (actionTag == TAG_VOICE_CHANGER) {
                if ([delegate respondsToSelector:@selector(onPushSetting:voiceChangerType:)]) {
                    [delegate onPushSetting:self voiceChangerType:actionValue];
                }
            }
            [self.mainTableView reloadData];
        }];
        [controller addAction:action];
    }
    [controller addAction:[UIAlertAction actionWithTitle:LivePlayerLocalize(@"LivePusherDemo.PushSetting.cancel")
                                                   style:UIAlertActionStyleCancel
                                                 handler:nil]];
    [self presentViewController:controller animated:YES completion:nil];
}

#pragma mark - UITableView delegate
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 7;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [[UITableViewCell alloc] initWithFrame:CGRectMake(0, 0, self.view.width, 40)];

    if (indexPath.section == SECTION_QUALITY) {
        cell.textLabel.text = [self getQualityStr];
        cell.accessoryView = [PushSettingV1ViewController buildAccessoryView];
    } else if (indexPath.section == SECTION_AUDIO_QUALITY) {
        cell.textLabel.text = [self getAudioQualityStr];
        cell.accessoryView = [PushSettingV1ViewController buildAccessoryView];
    } else if (indexPath.section == SECTION_REVERB) {
        cell.textLabel.text = [self getReverbStr];
        cell.accessoryView = [PushSettingV1ViewController buildAccessoryView];
    } else if (indexPath.section == SECTION_VOICE_CHANGER) {
        cell.textLabel.text = [self getVoiceChangerStr];
        cell.accessoryView = [PushSettingV1ViewController buildAccessoryView];
    } else if (indexPath.section == SECTION_BANDWIDTH_ADJUST) {
        cell.textLabel.text = LivePlayerLocalize(@"LivePusherDemo.PushSetting.openbandwidthadaptation");
        cell.accessoryView = _bandwidthSwitch;
    } else if (indexPath.section == SECTION_HW) {
        cell.textLabel.text = LivePlayerLocalize(@"LivePusherDemo.PushSetting.enablehardwareacceleration");
        cell.accessoryView = _hwSwitch;
    } else if (indexPath.section == SECTION_AUDIO_PREVIEW) {
        cell.textLabel.text = LivePlayerLocalize(@"LivePusherDemo.PushSetting.opentheearsback");
        cell.accessoryView = _audioPreviewSwitch;
    }
    
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == SECTION_QUALITY) {
        return LivePlayerLocalize(@"LivePusherDemo.PushSetting.qualitypreference");
    }
    if (section == SECTION_AUDIO_QUALITY) {
        return LivePlayerLocalize(@"LivePusherDemo.PushSetting.thesoundqualitychoice");
    }
    if (section == SECTION_REVERB) {
        return LivePlayerLocalize(@"LivePusherDemo.PushSetting.reverb");
    }
    if (section == SECTION_VOICE_CHANGER) {
        return LivePlayerLocalize(@"LivePusherDemo.PushSetting.voicechanger");
    }
    return @"";
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == SECTION_QUALITY) {
        [self _showQualityActionSheet];
    }
    if (indexPath.section == SECTION_AUDIO_QUALITY) {
        [self _showAudioQualityActionSheet];
    }
    if (indexPath.section == SECTION_REVERB) {
        [self _showActionSheet:TAG_REVERB];
    }
    if (indexPath.section == SECTION_VOICE_CHANGER) {
        [self _showActionSheet:TAG_VOICE_CHANGER];
    }
}

#pragma mark - 读写配置文件
+ (NSString *)getKey:(NSInteger)tag {
    return [NSString stringWithFormat:@"PUSH_SETTING_%ld", tag];
}

+ (void)saveSetting:(NSInteger)tag value:(NSInteger)value {
    NSString *key = [PushSettingV1ViewController getKey:tag];
    [[NSUserDefaults standardUserDefaults] setObject:@(value) forKey:key];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (BOOL)getBandWidthAdjust {
    NSString *key = [PushSettingV1ViewController getKey:TAG_BANDWIDTH_ADJUST];
    NSNumber *d = [[NSUserDefaults standardUserDefaults] objectForKey:key];
    if (d != nil) {
        return [d intValue];
    }
    return NO;
}

+ (BOOL)getEnableHWAcceleration {
    NSString *key = [PushSettingV1ViewController getKey:TAG_HW];
    NSNumber *d = [[NSUserDefaults standardUserDefaults] objectForKey:key];
    if (d != nil) {
        return [d intValue];
    }
    return YES;
}

+ (BOOL)getEnableAudioPreview {
    NSString *key = [PushSettingV1ViewController getKey:TAG_AUDIO_PREVIEW];
    NSNumber *d = [[NSUserDefaults standardUserDefaults] objectForKey:key];
    if (d != nil) {
        return [d intValue];
    }
    return NO;
}

+ (TX_Enum_Type_VideoQuality)getVideoQuality {
    NSString *key = [PushSettingV1ViewController getKey:TAG_QUALITY];
    NSNumber *d = [[NSUserDefaults standardUserDefaults] objectForKey:key];
    if (d != nil) {
        return [d intValue];
    }
    return VIDEO_QUALITY_SUPER_DEFINITION;
}

+ (NSInteger)getAudioQuality {
    NSString *key = [PushSettingV1ViewController getKey:TAG_AUDIO_QUALITY];
    NSNumber *value = [[NSUserDefaults standardUserDefaults] objectForKey:key];
    if (value != nil) {
        return [value integerValue];
    }
    return 1;
}

+ (TXReverbType)getReverbType {
    NSString *key = [PushSettingV1ViewController getKey:TAG_REVERB];
    NSNumber *d = [[NSUserDefaults standardUserDefaults] objectForKey:key];
    if (d != nil) {
        return [d intValue];
    }
    return REVERB_TYPE_0;
}

+ (TXVoiceChangerType)getVoiceChangerType {
    NSString *key = [PushSettingV1ViewController getKey:TAG_VOICE_CHANGER];
    NSNumber *d = [[NSUserDefaults standardUserDefaults] objectForKey:key];
    if (d != nil) {
        return [d intValue];
    }
    return VOICECHANGER_TYPE_0;
}

@end
