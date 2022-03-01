//
//  MineAboutViewController.m
//  TXLiteAVDemo_Enterprise
//
//  Created by peterwtma on 2021/7/21.
//  Copyright © 2021 Tencent. All rights reserved.
//

#import "MineAboutViewController.h"
#import "AppLocalized.h"
#import "ColorMacro.h"
#import "TXLiteAVSDKHeader.h"
#import "MineAboutResignViewController.h"
#import <Masonry.h>
#import "TXAppInfo.h"

typedef NS_ENUM (NSInteger, MineAboutCellType) {
	ENUM_NORMAL,
	ENUM_RESIGN,
};

@interface MineAboutTableViewCell : UITableViewCell
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *descLabel;
@property (nonatomic, strong) UIView *lineView;
@end

@interface MineAboutDetailCell : UITableViewCell
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UIView *lineView;
@property (nonatomic, strong) UIImageView *detailImageView;
@end

@interface MineAboutModel : NSObject
@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSString *value;
@property (nonatomic, assign) MineAboutCellType type;
- (instancetype)initWithTitle:(NSString*)title
        WithValue:(NSString*)value
        WithType:(MineAboutCellType)type;
@end

@interface MineAboutViewController ()<UITableViewDataSource, UITableViewDelegate>
@property (nonatomic, strong) UIButton *backBtn;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSMutableArray<MineAboutModel*> *dataSource;
@end

@implementation MineAboutViewController

- (instancetype)init {
	self = [super init];
	if (self) {
		self.tableView = [[UITableView alloc] init];
		self.tableView.backgroundColor = [UIColor clearColor];
		self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
		self.tableView.dataSource = self;
		self.tableView.delegate = self;
		self.tableView.contentInset = UIEdgeInsetsMake(20, 0, 20, 0);

		[self.tableView registerClass:[MineAboutTableViewCell class] forCellReuseIdentifier:@"MineAboutTableViewCell"];
		[self.tableView registerClass:[MineAboutDetailCell class] forCellReuseIdentifier:@"MineAboutDetailCell"];

		self.dataSource = [[NSMutableArray alloc] init];
#if LIVE
		MineAboutModel* model = [[MineAboutModel alloc] initWithTitle:AppPortalLocalize(@"Demo.TRTC.Portal.sdkversion") WithValue:[V2TXLivePremier getSDKVersionStr] WithType:ENUM_NORMAL];
		[self.dataSource addObject:model];
#else
		MineAboutModel* model = [[MineAboutModel alloc] initWithTitle:AppPortalLocalize(@"Demo.TRTC.Portal.sdkversion") WithValue:[TXLiveBase getSDKVersionStr] WithType:ENUM_NORMAL];
		[self.dataSource addObject:model];
#endif
		NSString *str = [TXAppInfo appVersionWithBuild];
		model = [[MineAboutModel alloc] initWithTitle:AppPortalLocalize(@"Demo.TRTC.Portal.appversion") WithValue:str WithType:ENUM_NORMAL];
		[self.dataSource addObject:model];
		model = [[MineAboutModel alloc] initWithTitle:AppPortalLocalize(@"Demo.TRTC.Portal.resignaccount") WithValue:@"" WithType:ENUM_RESIGN];
		[self.dataSource addObject:model];
	}
	return self;
}

- (void)viewDidLoad {
	[super viewDidLoad];
	self.view.backgroundColor = [UIColor clearColor];

	self.title = AppPortalLocalize(@"Demo.TRTC.Portal.Mine.about");

	self.backBtn = [UIButton buttonWithType:UIButtonTypeCustom];
	[self.backBtn setImage:[UIImage imageNamed:@"back"] forState:normal];
	[self.backBtn addTarget:self action:@selector(backBtnClick) forControlEvents:UIControlEventTouchUpInside];
	[self.backBtn sizeToFit];
	UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithCustomView:self.backBtn];
	item.tintColor = [UIColor clearColor];

	self.navigationItem.leftBarButtonItem = item;
	[self.view addSubview:self.tableView];

	[self.tableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.tableView.superview);
	 }];
}

- (void)backBtnClick {
	[self.navigationController popViewControllerAnimated:TRUE];
}

- (void)viewWillAppear:(BOOL)animated {
	[self.navigationController setNavigationBarHidden:FALSE animated:FALSE];
	[self.navigationController.navigationBar setTranslucent:true];

	self.navigationController.navigationBar.titleTextAttributes = @{NSFontAttributeName:[UIFont systemFontOfSize:18], NSForegroundColorAttributeName:[UIColor whiteColor]};

	NSArray* colors = @[(__bridge id)[UIColor colorWithRed:(19.0/255.0) green:(41.0/255.0) blue:(75.0/255.0) alpha:1].CGColor, (__bridge id)[UIColor colorWithRed:(5.0/255.0) green:(12.0/255.0) blue:(23.0/255.0) alpha:1].CGColor];
	CAGradientLayer* gradientLayer = [CAGradientLayer layer];
	gradientLayer.colors = colors;
	gradientLayer.startPoint = CGPointMake(0, 0);
	gradientLayer.endPoint = CGPointMake(1, 1);
	gradientLayer.frame = self.view.bounds;
	[self.view.layer insertSublayer:gradientLayer atIndex:0];
}

- (BOOL)prefersStatusBarHidden {
	return false;
}

#pragma mark ---- UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return self.dataSource.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	MineAboutModel* model = [self.dataSource objectAtIndex:indexPath.row];
	switch (model.type) {
	case ENUM_NORMAL:
	{
		MineAboutTableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:@"MineAboutTableViewCell" forIndexPath:indexPath];
		if(cell) {
			cell.titleLabel.text = model.title;
			cell.descLabel.text = model.value;
		}
		return cell;
	}
	case ENUM_RESIGN:
	{
		MineAboutDetailCell* cell = [tableView dequeueReusableCellWithIdentifier:@"MineAboutDetailCell" forIndexPath:indexPath];
		if(cell) {
			cell.titleLabel.text = model.title;
		}
		return cell;
	}
	}
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	return 56;
}

#pragma mark ---- UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	MineAboutModel *model = self.dataSource[indexPath.row];
	if (model.type == ENUM_RESIGN) {
		MineAboutResignViewController *vc = [[MineAboutResignViewController alloc] init];
		[self.navigationController pushViewController:vc animated:true];
	}
}
@end

#pragma mark ---- MineAboutDetailCell


@implementation MineAboutDetailCell
- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{

	self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
	self.selectionStyle = UITableViewCellSelectionStyleNone;
	self.backgroundColor = [UIColor clearColor];
	if (self) {
		self.titleLabel = [[UILabel alloc] init];
		self.titleLabel.font = [UIFont fontWithName:@"PingFangSC-Regular" size:16];
		self.titleLabel.textColor = [UIColor whiteColor];

		self.lineView = [[UIView alloc] init];
		self.lineView.backgroundColor = UIColorFromRGB(0x666666);

		self.detailImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"main_mine_detail"]];

	}
	return self;
}

- (void)didMoveToWindow {
	[super didMoveToWindow];
	[self constructViewHierarchy];
	[self activateConstraints];
	[self bindInteraction];
}

- (void) constructViewHierarchy {
	[self.contentView addSubview:self.titleLabel];
	[self.contentView addSubview:self.detailImageView];
	[self.contentView addSubview:self.lineView];
}

- (void) activateConstraints {
	[self.titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(self.titleLabel.superview).offset(20);
        make.centerY.equalTo(self.titleLabel.superview);
	 }];
	[self.detailImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.trailing.equalTo(self.detailImageView.superview).offset(-20);
        make.centerY.equalTo(self.detailImageView.superview);
	 }];
	[self.lineView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(self.titleLabel);
        make.trailing.equalTo(self.lineView.superview).offset(-20);
        make.bottom.equalTo(self.lineView.superview);
        make.height.equalTo(@1);
	 }];
}

- (void) bindInteraction {

}
@end

#pragma mark ---- MineAboutTableViewCell


@implementation MineAboutTableViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{

	self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
	self.selectionStyle = UITableViewCellSelectionStyleNone;
	self.backgroundColor = [UIColor clearColor];
	if (self) {
		self.titleLabel = [[UILabel alloc] init];
		self.titleLabel.font = [UIFont fontWithName:@"PingFangSC-Regular" size:16];
		self.titleLabel.textColor = [UIColor whiteColor];

		self.lineView = [[UIView alloc] init];
		self.lineView.backgroundColor = UIColorFromRGB(0x666666);

		self.descLabel = [[UILabel alloc] init];
		self.descLabel.font = [UIFont fontWithName:@"PingFangSC-Regular" size:16];
		self.descLabel.textColor = UIColorFromRGB(0x666666);
	}
	return self;
}

- (void)didMoveToWindow {
	[super didMoveToWindow];
	[self constructViewHierarchy];
	[self activateConstraints];
	[self bindInteraction];
}

- (void) constructViewHierarchy {
	[self.contentView addSubview:self.titleLabel];
	[self.contentView addSubview:self.descLabel];
	[self.contentView addSubview:self.lineView];
}

- (void) activateConstraints {
	[self.titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(self.titleLabel.superview).offset(20);
        make.centerY.equalTo(self.titleLabel.superview);
	 }];
	[self.descLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.trailing.equalTo(self.descLabel.superview).offset(-20);
        make.centerY.equalTo(self.descLabel.superview);
	 }];
	[self.lineView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(self.titleLabel);
        make.trailing.equalTo(self.descLabel);
        make.bottom.equalTo(self.lineView.superview);
        make.height.equalTo(@1);
	 }];
}

- (void) bindInteraction {

}
@end

@implementation MineAboutModel

- (instancetype)initWithTitle:(NSString*)title
        WithValue:(NSString*)value
        WithType:(MineAboutCellType)type {
	self = [super init];
	if (self) {
		self.title  = title;
		self.value = value;
		self.type = type;
	}
	return self;
}
@end
