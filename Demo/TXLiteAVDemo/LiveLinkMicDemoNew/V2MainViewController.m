//
//  V2MainViewController.m
//  TXLiteAVDemo
//
//  Created by coddyliu on 2020/11/27.
//  Copyright © 2020 Tencent. All rights reserved.
//

#import "V2MainViewController.h"
#import "Masonry.h"
#import "V2MainItemCell.h"
#import "V2PusherViewController.h"
#import "V2PlayerViewController.h"
#import "V2MainProtocolSelectViewController.h"
#import "AppLocalized.h"

@interface V2MainViewController ()<UICollectionViewDelegate, UICollectionViewDataSource>
@property (nonatomic, strong) UICollectionView *roomListCollection;
@property (nonatomic, strong) NSMutableArray *roomListDatas; //
@property (nonatomic, strong) V2MainProtocolSelectViewController *urlSettingVC;
@property (nonatomic, weak) V2MainItemCell *curSetUrlCell;
@end

@implementation V2MainViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    CGFloat itemWidth = ([UIScreen mainScreen].bounds.size.width - 40.0 - 5.0) / 2.0;
    layout.itemSize = CGSizeMake(itemWidth, itemWidth);
    layout.minimumLineSpacing = 5.0;
    layout.minimumInteritemSpacing = 5.0;
    layout.scrollDirection = UICollectionViewScrollDirectionVertical;
    layout.sectionInset = UIEdgeInsetsMake(20, 20, 80, 20);
    _roomListCollection = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
    [_roomListCollection registerClass:[V2MainItemPushCell class] forCellWithReuseIdentifier:@"V2MainItemPushCell"];
    [_roomListCollection registerClass:[V2MainItemPlayCell class] forCellWithReuseIdentifier:@"V2MainItemPlayCell"];
    _roomListCollection.bounces = YES;
    _roomListCollection.delegate = self;
    _roomListCollection.dataSource = self;
    _roomListCollection.backgroundColor = UIColor.whiteColor;
    [self.view addSubview:_roomListCollection];
    [self.roomListCollection mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view).offset(88);
        make.left.right.bottom.equalTo(self.view);
    }];
    
    self.view.backgroundColor = [UIColor blueColor];
    self.title = V2Localize(@"V2.Live.LinkMicNew.coanchornew");
    
    [self initRoomListDatas];
    
    self.urlSettingVC = [[V2MainProtocolSelectViewController alloc] init];
//    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(onNotify:) name:@"V2TRTCNotifyOnRemoteStreamAvailable" object:nil];
//    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(onNotify:) name:@"V2TRTCNotifyOnRemoteStreamAvailable_Stop" object:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:NO];
    self.navigationController.interactivePopGestureRecognizer.enabled = NO;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:NO];
    self.navigationController.interactivePopGestureRecognizer.enabled = YES;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    for (V2MainItemCell *cell in self.roomListCollection.visibleCells) {
        if ([cell isKindOfClass:[V2MainItemCell class]]) {
            [cell onViewControllerDidAppear:self];
        }
    }
}

- (void)dealloc {
    [NSNotificationCenter.defaultCenter removeObserver:self];
}

- (void)initRoomListDatas {
    self.roomListDatas = [[NSMutableArray alloc] initWithCapacity:6];
    V2PusherViewController *pushVC = [[V2PusherViewController alloc] init];
    [self.roomListDatas addObject:pushVC];

    for (int i = 0; i<5; i++) {
        V2PlayerViewController *playVC = [[V2PlayerViewController alloc] init];
        [self.roomListDatas addObject:playVC];
    }
}

//- (void)onNotify:(NSNotification *)notify {
//    dispatch_async(dispatch_get_main_queue(), ^{
//        if ([notify.name isEqualToString:@"V2TRTCNotifyOnRemoteStreamAvailable"]) {
//            for (V2MainItemPlayCell *cell in self.roomListCollection.visibleCells) {
//                if ([cell isKindOfClass:[V2MainItemPlayCell class]] && !cell.relateVC.player.isPlaying) {
//                    [cell startWithUrl:notify.object playUrls:nil];
//                    break;
//                }
//            }
//        } else if ([notify.name isEqualToString:@"V2TRTCNotifyOnRemoteStreamAvailable_Stop"]) {
//            for (V2MainItemPlayCell *cell in self.roomListCollection.visibleCells) {
//                if ([cell isKindOfClass:[V2MainItemPlayCell class]] && [cell.relateVC.userId isEqualToString:notify.object]) {
//                    [cell stopPlay];
//                    break;
//                }
//            }
//        }
//    });
//}

#pragma mark - UICollectionViewDelegate
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    
}

#pragma mark - UICollectionViewDataSource
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.roomListDatas.count;
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    id vc = self.roomListDatas[indexPath.row];
    __weak V2MainViewController *weakSelf = self;
    void (^onSetUrl)(V2MainItemCell *cell) = ^(V2MainItemCell *cell) {
        __strong V2MainViewController * strongSelf = weakSelf;
        strongSelf.curSetUrlCell = cell;
        strongSelf.urlSettingVC.isPush = [cell isKindOfClass:[V2MainItemPushCell class]];
        strongSelf.urlSettingVC.modalPresentationStyle = UIModalPresentationOverFullScreen;
        [strongSelf.urlSettingVC setOnStart:^(V2MainProtocolSelectViewController * _Nonnull vc, NSString * _Nonnull url, NSDictionary *playUrls, BOOL isPush) {
            __strong V2MainViewController * strongSelf = weakSelf;
            if (isPush && [strongSelf.curSetUrlCell isKindOfClass:[V2MainItemPushCell class]]) {
                [(V2MainItemPushCell *)strongSelf.curSetUrlCell setPusherMode:[url hasPrefix:@"trtc"] ? V2TXLiveMode_RTC : V2TXLiveMode_RTMP];
            }
            [strongSelf.curSetUrlCell startWithUrl:url playUrls:playUrls];
        }];
        [strongSelf presentViewController:strongSelf.urlSettingVC animated:YES completion:nil];
    };
    if ([vc isKindOfClass:V2PlayerViewController.class]) {
        V2MainItemPlayCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"V2MainItemPlayCell" forIndexPath:indexPath];
        cell.relateVC = self.roomListDatas[indexPath.row];
        cell.delegate = self;
        cell.backgroundColor = [UIColor lightGrayColor];
        cell.onSetUrlBtnClick = onSetUrl;
        return cell;
    } else {
        V2MainItemPushCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"V2MainItemPushCell" forIndexPath:indexPath];
        cell.delegate = self;
        cell.relateVC = self.roomListDatas[indexPath.row];
        cell.backgroundColor = [UIColor lightGrayColor];
        cell.onSetUrlBtnClick = onSetUrl;
        return cell;
    }
}

@end
