/*
 * Module:   RTCSettingsBaseViewController
 *
 * Function: 基础框架类。用作包含各种配置项的列表页
 *
 *    1. 列表的各种配置Cell定义在Cells目录中，也可继承
 *
 *    2. 通过继承RTCSettingsBaseCell，可自定义Cell，需要在RTCSettingsBaseViewController
 *       子类中重载makeCustomRegistrition，并调用registerClass将Cell注册到tableView中。
 *
 */

#import "RTCSettingsBaseViewController.h"

#import "Masonry.h"

@interface RTCSettingsBaseViewController () <UITableViewDelegate, UITableViewDataSource>

@property(nonatomic, strong) UITableView *tableView;

@end

@implementation RTCSettingsBaseViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.view.backgroundColor = UIColor.clearColor;
    [self setupTableView];
}

- (void)setupTableView {
    self.tableView                     = [[UITableView alloc] init];
    self.tableView.backgroundColor     = UIColor.clearColor;
    self.tableView.allowsSelection     = NO;
    self.tableView.separatorStyle      = UITableViewCellSeparatorStyleNone;
    self.tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;

    self.tableView.delegate   = self;
    self.tableView.dataSource = self;

    [self.tableView registerClass:RTCSettingsSwitchItem.bindedCellClass forCellReuseIdentifier:RTCSettingsSwitchItem.bindedCellId];
    [self.tableView registerClass:RTCSettingsSegmentItem.bindedCellClass forCellReuseIdentifier:RTCSettingsSegmentItem.bindedCellId];
    [self.tableView registerClass:RTCSettingsButtonItem.bindedCellClass forCellReuseIdentifier:RTCSettingsButtonItem.bindedCellId];
    [self.tableView registerClass:RTCSettingsSliderItem.bindedCellClass forCellReuseIdentifier:RTCSettingsSliderItem.bindedCellId];
    [self.tableView registerClass:RTCSettingsSelectorItem.bindedCellClass forCellReuseIdentifier:RTCSettingsSelectorItem.bindedCellId];
    [self makeCustomRegistrition];

    [self.view addSubview:self.tableView];
    [self.tableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self.view endEditing:NO];
}

- (void)makeCustomRegistrition {
}

- (void)onSelectItem:(RTCSettingsBaseItem *)item {
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:NO];

    RTCSettingsBaseCell *cell = [tableView dequeueReusableCellWithIdentifier:self.items[indexPath.row].bindedCellId];
    [cell didSelect];
    [self onSelectItem:self.items[indexPath.row]];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return self.items[indexPath.row].height;
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.items.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    RTCSettingsBaseCell *cell = [tableView dequeueReusableCellWithIdentifier:self.items[indexPath.row].bindedCellId];
    cell.item                 = self.items[indexPath.row];

    return cell;
}

@end
