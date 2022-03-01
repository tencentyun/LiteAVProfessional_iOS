//
//  MineViewController.m
//  TXLiteAVDemo_Enterprise
//
//  Created by peterwtma on 2021/7/20.
//  Copyright © 2021 Tencent. All rights reserved.
//

#import "MineViewController.h"
#import "MineViewModel.h"
#import "MineRootView.h"
#import "WebViewController.h"
#import "AppLocalized.h"
#import "MineAboutViewController.h"
#import "ProfileManager.h"
#import "AppDelegate.h"

@interface MineViewController()<UITableViewDataSource, UITableViewDelegate>
@property (nonatomic, strong) MineViewModel *viewModel;
@end

@implementation MineViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
}

- (void)viewWillAppear:(BOOL)animated{
    [self.navigationController setNavigationBarHidden:true animated:false];
    [self.navigationController.navigationBar setTranslucent:true];
    self.navigationController.navigationBar.titleTextAttributes = @{NSFontAttributeName:[UIFont systemFontOfSize:18], NSForegroundColorAttributeName:[UIColor whiteColor]};
    
    
    NSArray* colors = @[(__bridge id)[UIColor colorWithRed:(19.0 / 255.0) green:(41.0 / 255.0) blue:(75.0 / 255.0) alpha:1].CGColor, (__bridge id)[UIColor colorWithRed:(5.0 / 255.0) green:(12.0 / 255.0) blue:(23.0 / 255.0) alpha:1].CGColor];
    CAGradientLayer* gradientLayer = [CAGradientLayer layer];
    gradientLayer.colors = colors;
    gradientLayer.startPoint = CGPointMake(0, 0);
    gradientLayer.endPoint = CGPointMake(1, 1);
    gradientLayer.frame = self.view.bounds;
    [self.view.layer insertSublayer:gradientLayer atIndex:0];
}

- (void)loadView {
    self.viewModel = [[MineViewModel alloc] init];
    MineRootView *rootView = [MineRootView initWithViewModel:self.viewModel withViewController:self];
    rootView.tableView.delegate = self;
    rootView.tableView.dataSource = self;
    
    self.view = rootView;
}

- (void)logoutBtnClick{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:V2Localize(@"V2.Live.LinkMicNew.suretologout") message:nil preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:V2Localize(@"V2.Live.LinkMicNew.cancel") style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
    }];
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:V2Localize(@"V2.Live.LinkMicNew.confirm") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [ProfileManager.shared removeLoginCache];
        AppDelegate* appDelegate = (AppDelegate*) UIApplication.sharedApplication.delegate;
        [appDelegate showLoginController];
    }];
    [alert addAction:cancelAction];
    [alert addAction:okAction];
    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return self.viewModel.subCells.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 56;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    MineTableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:@"MineTableViewCell"];
    if (!cell) {
        cell = [[MineTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"MineTableViewCell"];
    }
    cell.model = [self.viewModel.subCells objectAtIndex:indexPath.row];
    if ([cell.model.title isEqualToString:AppPortalLocalize(@"Demo.TRTC.Portal.Home.logout")]) {
        cell.detailImageView.hidden = true;
    }
    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    MinTableViewCellModel* model = [self.viewModel.subCells objectAtIndex:indexPath.row];
    switch (model.type) {
        case ENUM_ABOUT:
        {
            MineAboutViewController *aboutViewController = [[MineAboutViewController alloc] init];
            [self.navigationController pushViewController:aboutViewController animated:TRUE];
            break;
        }
        case ENUM_PRIVACY:
        {
            WebViewController* webViewController = [[WebViewController alloc] initWithUrlString:@"https://web.sdk.qcloud.com/document/Tencent-Video-Cloud-Toolkit-Privacy-Protection-Guidelines.html" withTitleString:model.title];
            [self.navigationController pushViewController:webViewController animated:TRUE];
            break;
        }
        case ENUM_AGREEMENT:
        {
            WebViewController *webViewController = [[WebViewController alloc] initWithUrlString:@"https://web.sdk.qcloud.com/document/Tencent-Video-Cloud-Toolkit-User-Agreement.html" withTitleString:model.title];
            [self.navigationController pushViewController:webViewController animated:TRUE];
            break;
        }
        case ENUM_DISCLAIMER:
        {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:AppPortalLocalize(@"Demo.TRTC.Portal.disclaimerdesc") message:@"" preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *action = [UIAlertAction actionWithTitle:AppPortalLocalize(@"Demo.TRTC.Portal.confirm") style:UIAlertActionStyleDefault handler:nil];
            [alert addAction:action];
            [self presentViewController:alert animated:YES completion:nil];
            break;
        }
        case ENUM_LOGOUT:
        {
            [self logoutBtnClick];
            break;
        }
    }
}

@end
