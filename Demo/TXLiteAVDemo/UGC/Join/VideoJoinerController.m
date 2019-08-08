//
//  VideoComposeController.m
//  TCLVBIMDemo
//
//  Created by annidyfeng on 2017/4/19.
//  Copyright © 2017年 tencent. All rights reserved.
//

#import "VideoJoinerController.h"
#import "VideoJoinerCell.h"
#import "VideoEditPrevController.h"
#import "TXLiteAVSDKHeader.h"
#import "TXColor.h"
#import "AppDelegate.h"
#import "MBProgressHUD.h"
static NSString *indetifer = @"VideoJoinerCell";

@interface VideoJoinerController ()<UITableViewDelegate, UITableViewDataSource>
@property (weak) IBOutlet UITableView *tableView;
@end

@implementation VideoJoinerController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    [_tableView registerNib:[UINib nibWithNibName:@"VideoJoinerCell" bundle:nil] forCellReuseIdentifier:indetifer];
    _tableView.dataSource = self;
    _tableView.delegate = self;
    [_tableView setEditing:YES animated:YES];
    
    _reorderVideoList = [NSMutableArray new];
    for (AVAsset *asset in self.videoAssertList) {
        VideoJoinerCellModel *model = [VideoJoinerCellModel new];
        model.videoAsset = asset;
        TXVideoInfo *info = [TXVideoInfoReader getVideoInfoWithAsset:asset];
        model.cover = info.coverImage;
        model.duration = info.duration;
        model.width = info.width;
        model.height = info.height;

        [_reorderVideoList addObject:model];
    }
    
    UIBarButtonItem *customBackButton = [[UIBarButtonItem alloc] initWithTitle:@"取消"
                                                                         style:UIBarButtonItemStylePlain
                                                                        target:self
                                                                        action:@selector(goBack)];
    customBackButton.tintColor = TXColor.cyan;    
    self.navigationItem.leftBarButtonItem = customBackButton;
    self.navigationItem.title = @"视频拼接";
    
//    [self.navigationController.navigationBar setBackgroundImage:[UIImage imageNamed:@"black"] forBarMetrics:UIBarMetricsDefault];
#ifdef HelpBtnUI
    HelpBtnUI(视频拼接)
#endif

}

- (void)goBack
{
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return @"视频将按照列表顺序进行合成，您可以拖动进行片段顺序调整。";
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath;
{
    return 75;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.reorderVideoList.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    VideoJoinerCell *cell = [tableView dequeueReusableCellWithIdentifier:indetifer];
    cell.model = self.reorderVideoList[indexPath.row];
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    return YES;
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath
{
    NSString *toMove = [self.reorderVideoList objectAtIndex:sourceIndexPath.row];
    [self.reorderVideoList removeObjectAtIndex:sourceIndexPath.row];
    [self.reorderVideoList insertObject:toMove atIndex:destinationIndexPath.row];
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        [self.reorderVideoList removeObjectAtIndex:indexPath.row];
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:YES];
    }
}

- (IBAction)preview:(id)sender {
    if (self.reorderVideoList.count < 1)
        return;
    
    if (self.reorderVideoList.count < 2) {
        MBProgressHUD* hub = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        hub.mode = MBProgressHUDModeText;
        hub.label.text = @"必须选择两个以上视频文件";
        hub.removeFromSuperViewOnHide = YES;
        [hub showAnimated:YES];
        [hub hideAnimated:YES afterDelay:3];
        return;
    }
    
    VideoEditPrevController *vc = [VideoEditPrevController new];
    NSMutableArray *list = [NSMutableArray new];
    for (VideoJoinerCellModel *model in self.reorderVideoList) {
        [list addObject:model.videoAsset];
    }
    vc.composeArray = list;
    [self.navigationController pushViewController:vc animated:YES];
}

@end
