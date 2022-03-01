/*
 * Module:   V2SettingsContainerViewController
 *
 * Function: 基础框架类。包含多个子ViewController，标题栏为segmentControl，对应各页面的title
 *
 */

#import "V2SettingsContainerViewController.h"

#import "ColorMacro.h"
#import "Masonry.h"
#import "UISegmentedControl+V2.h"

@interface V2SettingsContainerViewController ()

@property(strong, nonatomic) UISegmentedControl *segment;
@property(strong, nonatomic) UIView *            containerView;

@end

@implementation V2SettingsContainerViewController

- (instancetype)init {
    self = [super init];
    if (self) {
        [self setupSegment];
        [self setupContainerView];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.clearColor;
}

- (void)setupSegment {
    self.segment = [UISegmentedControl v2_segment];

    NSMutableDictionary *normalTextAttr = [[self.segment titleTextAttributesForState:UIControlStateNormal] mutableCopy];
    normalTextAttr[NSFontAttributeName] = [UIFont systemFontOfSize:16 weight:UIFontWeightMedium];
    [self.segment setTitleTextAttributes:normalTextAttr forState:UIControlStateNormal];

    normalTextAttr                      = [[self.segment titleTextAttributesForState:UIControlStateSelected] mutableCopy];
    normalTextAttr[NSFontAttributeName] = [UIFont systemFontOfSize:16 weight:UIFontWeightMedium];
    [self.segment setTitleTextAttributes:normalTextAttr forState:UIControlStateSelected];

    [self.segment addTarget:self action:@selector(onSegmentChange:) forControlEvents:UIControlEventValueChanged];
    [self.segment mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.mas_equalTo(60);
        make.height.mas_equalTo(32);
    }];
    self.navigationItem.titleView = self.segment;
}

- (void)setupContainerView {
    self.containerView                 = [[UIView alloc] init];
    self.containerView.backgroundColor = UIColor.clearColor;

    [self.view addSubview:self.containerView];
    [self.containerView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view).offset(44);
        make.leading.trailing.bottom.equalTo(self.view);
    }];
}

- (void)setSettingVCs:(NSArray<UIViewController *> *)settingVCs {
    for (UIViewController *vc in _settingVCs) {
        [self unembedSubVC:vc];
    }

    _settingVCs = settingVCs;

    [self.segment removeAllSegments];
    [settingVCs enumerateObjectsUsingBlock:^(UIViewController *_Nonnull vc, NSUInteger idx, BOOL *_Nonnull stop) {
        [self.segment insertSegmentWithTitle:vc.title atIndex:idx animated:NO];
    }];
    self.segment.selectedSegmentIndex = 0;
    [self showSubVCAt:0];

    [self.segment mas_updateConstraints:^(MASConstraintMaker *make) {
        make.width.mas_equalTo(self.segment.numberOfSegments * 60);
    }];
}

- (void)onSegmentChange:(id)sender {
    [self showSubVCAt:self.segment.selectedSegmentIndex];
}

#pragma mark -

- (void)unembedSubVC:(UIViewController *)vc {
    [vc willMoveToParentViewController:nil];
    [vc removeFromParentViewController];
    [vc.view removeFromSuperview];
}

- (void)embedSubVC:(UIViewController *)vc {
    [self addChildViewController:vc];
    [vc didMoveToParentViewController:self];
}

- (void)showSubVCAt:(NSInteger)index {
    for (UIView *view in self.containerView.subviews) {
        [view removeFromSuperview];
    }
    [self.containerView addSubview:self.settingVCs[index].view];
    [self.settingVCs[index].view mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.containerView);
    }];
}

@end
