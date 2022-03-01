//
//  TRTCSubRoomSettingsViewController.m
//  TXReplaykitUpload_TRTC
//
//  Created by J J on 2020/7/15.
//  Copyright © 2020 Tencent. All rights reserved.
//

#import "TRTCSubRoomSettingsViewController.h"

#import "AppLocalized.h"
#import "ColorMacro.h"
#import "GenerateTestUserSig.h"
#import "TRTCCloud.h"
#import "TRTCSettingsMainRoomTableViewCell.h"
#import "TRTCSettingsSubRoomTableViewCell.h"
#import "TRTCVideoView.h"

@interface                                               TRTCSubRoomSettingsViewController ()
@property(copy, nonatomic) NSString *                    ownRoomId;
@property(copy, nonatomic) NSString *                    ownUserId;
@property(strong, nonatomic) NSMutableArray<NSString *> *arraySubRoomId;
@end

@implementation TRTCSubRoomSettingsViewController

- (NSString *)title {
    return TRTCLocalize(@"Demo.TRTC.Live.subRoom");
}

- (void)dealloc {
    @try {
        [_trtcCloudManager.audioConfig removeObserver:self forKeyPath:@"isMuted"];
        [_trtcCloudManager.videoConfig removeObserver:self forKeyPath:@"isMuted"];
        [_trtcCloudManager.params removeObserver:self forKeyPath:@"role"];
        [_trtcCloudManager.params removeObserver:self forKeyPath:@"roomId"];
        [_trtcCloudManager.params removeObserver:self forKeyPath:@"strRoomId"];
    } @catch (NSException *exception) {
        NSLog(@"TRTCSubRoomSettingsViewController dealloc observer 未注册");
    }
}

- (instancetype)initWithCloudManager:(TRTCCloudManager *)trtcCloudManager {
    self = [super init];
    if (self) {
        _trtcCloudManager = trtcCloudManager;
        [_trtcCloudManager.audioConfig addObserver:self forKeyPath:@"isMuted" options:NSKeyValueObservingOptionNew context:nil];
        [_trtcCloudManager.videoConfig addObserver:self forKeyPath:@"isMuted" options:NSKeyValueObservingOptionNew context:nil];
        [_trtcCloudManager.params addObserver:self forKeyPath:@"roomId" options:NSKeyValueObservingOptionNew context:nil];
        [_trtcCloudManager.params addObserver:self forKeyPath:@"role" options:NSKeyValueObservingOptionNew context:nil];
        [_trtcCloudManager.params addObserver:self forKeyPath:@"strRoomId" options:NSKeyValueObservingOptionNew context:nil];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    _arraySubRoomId = [[NSMutableArray alloc] init];

    _ownRoomId                  = _trtcCloudManager.roomId;
    _ownUserId                  = _trtcCloudManager.userId;
    __weak __typeof(self) wSelf = self;

    TRTCSettingsMessageItem *createRoomItem =
        [[TRTCSettingsMessageItem alloc] initWithTitle:TRTCLocalize(@"Demo.TRTC.Live.newRoom")
                                           placeHolder:TRTCLocalize(@"Demo.TRTC.Live.numRoomSupport")
                                               content:nil
                                           actionTitle:TRTCLocalize(@"Demo.TRTC.Live.enter")
                                                action:^(NSString *roomId) {
                                                    if (![self.arraySubRoomId containsObject:roomId] && ![roomId isEqual:@""] && ![roomId isEqual:self.ownRoomId]) {
                                                        [wSelf createChildRoom:roomId];
                                                        [self.arraySubRoomId addObject:roomId];
                                                    } else {
                                                        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:TRTCLocalize(@"Demo.TRTC.Live.failedEnterRoom")
                                                                                                        message:TRTCLocalize(@"Demo.TRTC.Live.failedEnterRoomTip")
                                                                                                       delegate:self
                                                                                              cancelButtonTitle:TRTCLocalize(@"Demo.TRTC.Live.ok")
                                                                                              otherButtonTitles:nil];
                                                        [alert show];
                                                    }
                                                }];

    //主房间
    BOOL                               isPushing = !(_trtcCloudManager.audioConfig.isMuted && _trtcCloudManager.videoConfig.isMuted);
    TRTCSettingsMainRoomTableViewItem *mainRoomItem =
        [[TRTCSettingsMainRoomTableViewItem alloc] initWithRoomId:_ownRoomId
                                                             isOn:isPushing
                                                          actionA:^(BOOL isPush, id _Nonnull cell) {
                                                              //用户切换主房间推流开关后会触发这个Block
                                                              __strong __typeof(self) self         = wSelf;
                                                              NSArray *               cellIndPaths = [self.tableView indexPathsForVisibleRows];
                                                              for (int index = 2; index < cellIndPaths.count; index++) {
                                                                  TRTCSettingsSubRoomTableViewCell *subCell = [self.tableView cellForRowAtIndexPath:cellIndPaths[index]];
                                                                  if ([subCell.relatedItem.subRoomId isEqualToString:wSelf.trtcCloudManager.currentPublishingRoomId]) {
                                                                      //一、如果主房间开始推流，则关闭所有子房间的推流
                                                                      [subCell setCellSelected:NO];  //切换按钮选择状态
                                                                      [wSelf.trtcCloudManager pushAudioStreamInSubRoom:subCell.relatedItem.subRoomId push:NO];
                                                                      [wSelf.trtcCloudManager pushVideoStreamInSubRoom:subCell.relatedItem.subRoomId push:NO];
                                                                      [wSelf.trtcCloudManager switchSubRoomRole:TRTCRoleAudience roomId:subCell.relatedItem.subRoomId];
                                                                  }
                                                              }

                                                              //二、根据isPush来开关主房间的推流
                                                                if (isPush) {
                                                                    //如果是打开主房间推流，那么设置当前推流RoomId
                                                                    TRTCSettingsMainRoomTableViewCell *mainCell = [self.tableView cellForRowAtIndexPath:cellIndPaths[1]];
                                                                    wSelf.trtcCloudManager.currentPublishingRoomId = mainCell.relatedItem.title;
                                                                } else {
                                                                    //如果关闭推流，那么当前推流房间Id应该为无效值
                                                                    wSelf.trtcCloudManager.currentPublishingRoomId = @"";
                                                                }
                                                              [wSelf.trtcCloudManager switchRole:isPush ? TRTCRoleAnchor : TRTCRoleAudience];
                                                              [wSelf.trtcCloudManager setAudioMuted:!isPush];
                                                              [wSelf.trtcCloudManager setVideoMuted:!isPush];
                                                              [cell setCellSelected:isPush];
                                                          }
                                                      actionTitle:@""
                                                          actionB:^(NSString *_Nullable content){
                                                              //
                                                          }];
    self.items = [@[
        createRoomItem,
        mainRoomItem,
    ] mutableCopy];
}

#pragma mark - Actions

- (void)createChildRoom:(NSString *)roomId {
    __weak __typeof(self) wSelf = self;
    //注意，这里将roomId转换成了整数，代表进入的子房间都是数值房间号
    UInt32 copyRoomId     = [roomId intValue];
    _params               = [[TRTCParams alloc] init];
    _params.roomId        = copyRoomId;
    _params.sdkAppId      = SDKAPPID;
    _params.userId        = _ownUserId;
    _params.userSig       = [GenerateTestUserSig genTestUserSig:_ownUserId sdkAppId:SDKAPPID secretKey:SECRETKEY];
    _params.privateMapKey = @"";
    _params.role          = TRTCRoleAudience;

    [_trtcCloudManager enterSubRoom:_params];
    //子房间
    __block TRTCSettingsSubRoomCellTableViewItem *subItem = [[TRTCSettingsSubRoomCellTableViewItem alloc] initWithRoomId:roomId
        isOn:NO
        actionA:^(BOOL isPush, id _Nonnull cell) {
            //用户切换子房间推流开关后会触发这个Block
            NSArray *cellIndPaths = [self.tableView indexPathsForVisibleRows];
            for (int index = 1; index < cellIndPaths.count; index++) {
                if (index == 1) {
                    TRTCSettingsMainRoomTableViewCell *mainCell = [self.tableView cellForRowAtIndexPath:cellIndPaths[index]];
                    if ([mainCell.relatedItem.title isEqualToString:wSelf.trtcCloudManager.currentPublishingRoomId]) {
                        [mainCell setCellSelected:NO];  //切换按钮选择状态
                        //一、在subCloud推流前先停止主房间的推流
                        [wSelf.trtcCloudManager setAudioMuted:YES];
                        [wSelf.trtcCloudManager setVideoMuted:YES];
                        [wSelf.trtcCloudManager switchRole:TRTCRoleAudience];
                    }
                } else if (cell != cellIndPaths[index]) {
                    TRTCSettingsSubRoomTableViewCell *subCell = [self.tableView cellForRowAtIndexPath:cellIndPaths[index]];
                    if ([subCell.relatedItem.subRoomId isEqualToString:wSelf.trtcCloudManager.currentPublishingRoomId]) {
                        //二、在目标subCloud推流前先停止其它子房间的推流
                        [subCell setCellSelected:NO];
                        [wSelf.trtcCloudManager pushAudioStreamInSubRoom:subCell.relatedItem.subRoomId push:NO];
                        [wSelf.trtcCloudManager pushVideoStreamInSubRoom:subCell.relatedItem.subRoomId push:NO];
                        [wSelf.trtcCloudManager switchSubRoomRole:TRTCRoleAudience roomId:subCell.relatedItem.subRoomId];
                    }
                }
            }
        
        if (isPush) {
            //三、最后开启目标子房间的推流
            [wSelf.trtcCloudManager switchSubRoomRole:TRTCRoleAnchor roomId:roomId];
        } else {
            wSelf.trtcCloudManager.currentPublishingRoomId = @"";
            [wSelf.trtcCloudManager switchSubRoomRole:TRTCRoleAudience roomId:roomId];
        }

            [wSelf.trtcCloudManager pushAudioStreamInSubRoom:subItem.subRoomId push:isPush];
            [wSelf.trtcCloudManager pushVideoStreamInSubRoom:subItem.subRoomId push:isPush];
        }
        actionTitle:TRTCLocalize(@"Demo.TRTC.Live.exitRoom")
        actionB:^(NSString *_Nullable content) {
            for (NSString *userId in wSelf.trtcCloudManager.viewDic.allKeys) {
                TRTCVideoView *videoView = wSelf.trtcCloudManager.viewDic[userId];
                if ([videoView.roomId isEqualToString:subItem.title]) {
                    [videoView removeFromSuperview];
                    [wSelf.trtcCloudManager.viewDic removeObjectForKey:userId];
                    break;
                }
            }
            [wSelf.trtcCloudManager exitSubRoom:roomId];
            [wSelf.arraySubRoomId removeObject:subItem.title];
            [wSelf.items removeObject:subItem];
            [wSelf.tableView reloadData];
        }];
    [self.items addObject:subItem];
    [self.tableView reloadData];
}

- (void)onSelectItem:(TRTCSettingsBaseItem *)item {
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey, id> *)change context:(void *)context {
    if ([keyPath isEqualToString:@"role"] || [keyPath isEqualToString:@"isMuted"]) {
        BOOL     isPushing    = !(_trtcCloudManager.audioConfig.isMuted && _trtcCloudManager.videoConfig.isMuted);
        NSArray *cellIndPaths = [self.tableView indexPathsForVisibleRows];
        if ([_trtcCloudManager.currentPublishingRoomId isEqualToString:_ownRoomId]) {
            //当前在主房间推流，更新主房间状态
            TRTCSettingsMainRoomTableViewCell *mainCell = (TRTCSettingsMainRoomTableViewCell *)[self.tableView cellForRowAtIndexPath:cellIndPaths[1]];
            [mainCell setCellSelected:isPushing && [_trtcCloudManager.currentPublishingRoomId isEqualToString:mainCell.relatedItem.title]];
        } else {
            //若当前是在子房间推流
            for (int i = 2; i < cellIndPaths.count; i++) {
                TRTCSettingsSubRoomTableViewCell *subCell = (TRTCSettingsSubRoomTableViewCell *)[self.tableView cellForRowAtIndexPath:cellIndPaths[i]];
                if ([subCell.relatedItem.subRoomId isEqualToString:_trtcCloudManager.currentPublishingRoomId]) {
                    [subCell setCellSelected:isPushing && [_trtcCloudManager.currentPublishingRoomId isEqualToString:subCell.relatedItem.subRoomId]];
                }
            }
        }
    }
    if ([keyPath isEqualToString:@"roomId"] || [keyPath isEqualToString:@"strRoomId"]) {
        //切换了房间
        _ownRoomId = _trtcCloudManager.params.roomId ? [@(_trtcCloudManager.params.roomId) stringValue] : _trtcCloudManager.params.strRoomId;
        //更新主房间cell的房间号
        TRTCSettingsMainRoomTableViewItem *mainItem = (TRTCSettingsMainRoomTableViewItem *)self.items[1];
        [mainItem setTitle:_ownRoomId];
    }
    [self.tableView reloadData];
}

@end
