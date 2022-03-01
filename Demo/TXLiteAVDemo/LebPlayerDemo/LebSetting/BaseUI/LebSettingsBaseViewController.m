/*
 * Module:   LebSettingsBaseViewController
 *
 * Function: 基础框架类。用作包含各种配置项的列表页
 *
 *    1. 列表的各种配置Cell定义在Cells目录中，也可继承
 *
 *    2. 通过继承LebSettingsBaseCell，可自定义Cell，需要在LebSettingsBaseViewController
 *       子类中重载makeCustomRegistrition，并调用registerClass将Cell注册到tableView中。
 *
 */

#import "LebSettingsBaseViewController.h"

#import "Masonry.h"

@interface LebSettingsBaseViewController () <UITableViewDelegate, UITableViewDataSource>

@property(strong, nonatomic) UITableView *tableView;

@end

@implementation LebSettingsBaseViewController

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

    [self.tableView registerClass:LebSettingsSwitchItem.bindedCellClass forCellReuseIdentifier:LebSettingsSwitchItem.bindedCellId];
    [self.tableView registerClass:LebSettingsSegmentItem.bindedCellClass forCellReuseIdentifier:LebSettingsSegmentItem.bindedCellId];
    [self.tableView registerClass:LebSettingsButtonItem.bindedCellClass forCellReuseIdentifier:LebSettingsButtonItem.bindedCellId];
    [self.tableView registerClass:LebSettingsSliderItem.bindedCellClass forCellReuseIdentifier:LebSettingsSliderItem.bindedCellId];
    [self.tableView registerClass:LebSettingsSelectorItem.bindedCellClass forCellReuseIdentifier:LebSettingsSelectorItem.bindedCellId];
    [self.tableView registerClass:LebSettingsTextFieldItem.bindedCellClass forCellReuseIdentifier:LebSettingsTextFieldItem.bindedCellId];
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

- (void)onSelectItem:(LebSettingsBaseItem *)item {
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:NO];

    LebSettingsBaseCell *cell = [tableView dequeueReusableCellWithIdentifier:self.items[indexPath.row].bindedCellId];
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
    LebSettingsBaseCell *cell = [tableView dequeueReusableCellWithIdentifier:self.items[indexPath.row].bindedCellId];
    cell.item                 = self.items[indexPath.row];

    return cell;
}

@end
