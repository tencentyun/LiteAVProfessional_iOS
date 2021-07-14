/*
* Module:   TRTCRemoteUserListViewController
*
* Function: 房间内其它用户（即远端用户）的列表页
*
*    1. 列表中显示每个用户的ID，以及该用户的视频、音频开启状态
*
*    2. 点击用户项，将跳转到远端用户设置页
*
*/

#import "TRTCRemoteUserListViewController.h"
#import "TRTCRemoteUserCell.h"
#import "TRTCRemoteUserSettingsViewController.h"
#import "Masonry.h"
#import "AppLocalized.h"

@interface TRTCRemoteUserListViewController ()

@property (strong, nonatomic) UIVisualEffectView *backView;

@end

@implementation TRTCRemoteUserListViewController

- (void)makeCustomRegistrition {
    [self.tableView registerClass:TRTCRemoteUserItem.bindedCellClass
           forCellReuseIdentifier:TRTCRemoteUserItem.bindedCellId];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = TRTCLocalize(@"Demo.TRTC.Live.userList");
    self.view.backgroundColor = UIColor.clearColor;
    self.tableView.allowsSelection = YES;
    
    [self setupBackgroudColor];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    self.items = [self buildMemberItems];
    [self.tableView reloadData];
}

- (void)setupBackgroudColor {
    UIColor *startColor = [UIColor colorWithRed:19.0 / 255.0 green:41.0 / 255.0 blue:75.0 / 255.0 alpha:1];
    UIColor *endColor = [UIColor colorWithRed:5.0 / 255.0 green:12.0 / 255.0 blue:23.0 / 255.0 alpha:1];

    NSArray* colors = @[(id)startColor.CGColor, (id)endColor.CGColor];

    CAGradientLayer *layer = [CAGradientLayer layer];
    layer.colors = colors;
    layer.startPoint = CGPointMake(0, 0);
    layer.endPoint = CGPointMake(1, 1);
    layer.frame = self.view.bounds;
    
    [self.view.layer insertSublayer:layer atIndex:0];
}


- (NSMutableArray *)buildMemberItems {
    NSMutableArray *users = [NSMutableArray array];
    for (TRTCVideoView *view in [self.trtcCloudManager.viewDic allValues]) {
        if ([view.userId isEqualToString:self.trtcCloudManager.userId]) { continue; }
        [users addObject:[[TRTCRemoteUserItem alloc] initWithUser:view.userId settings:view.userConfig]];
    }
    return users;
}

- (void)onSelectItem:(TRTCSettingsBaseItem *)item {
    TRTCRemoteUserSettingsViewController *vc = [[TRTCRemoteUserSettingsViewController alloc] init];
    vc.trtcCloudManager = self.trtcCloudManager;
    vc.userId = ((TRTCRemoteUserItem *) item).userId;
    [self.navigationController pushViewController:vc animated:YES];
}

@end
