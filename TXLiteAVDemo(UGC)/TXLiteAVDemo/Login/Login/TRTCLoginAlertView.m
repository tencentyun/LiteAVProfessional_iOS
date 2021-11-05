//
//  TRTCLoginAlertView.m
//  TXLiteAVDemo_Enterprise
//
//  Created by peterwtma on 2021/7/26.
//  Copyright © 2021 Tencent. All rights reserved.
//

#import "TRTCLoginAlertView.h"
#import "AppLocalized.h"
#import "RoundRect.h"
#import <Masonry.h>




@interface TRTCLoginAlertContextView ()
@property (nonatomic, strong) UIView *bgView;
@property (nonatomic, strong) UIView *contentView;
@property (nonatomic, strong) UILabel *titleLabel;
- (void)constructViewHierarchy;
- (void)activateConstraints;
- (void) bindInteraction;
@end

@implementation TRTCLoginAlertContextView

- (void) initUI {
	self.bgView = [[UIView alloc] initWithFrame:CGRectZero];
	self.bgView.backgroundColor = [UIColor blackColor];
	self.bgView.alpha = 0.6;

	self.contentView = [[UIView alloc] initWithFrame:CGRectZero];
	self.contentView.backgroundColor = [UIColor whiteColor];

	self.titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
	self.titleLabel.textColor = [UIColor blackColor];
	[self.titleLabel setFont:[UIFont fontWithName:@"PingFangSC-Medium" size:24]];
}

- (void)didMoveToWindow {
	[super didMoveToWindow];
	[self constructViewHierarchy];
	[self activateConstraints];
	[self bindInteraction];
}

- (void)show {
	[UIView animateWithDuration:0.3 animations:^{
        self.alpha = 1;
        self.contentView.transform = CGAffineTransformIdentity;
	 }];
}

- (void)dismiss {
	if (self.willDissmiss) {
		self.willDissmiss();
	}
	[UIView animateWithDuration:0.3 animations:^{
        self.alpha = 0;
	 } completion:^(BOOL finished) {
        if (self.didDismiss) {
           self.didDismiss();
		 }
        [self removeFromSuperview];
	 }];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
	CGPoint point = [[touches anyObject] locationInView:self];
	if([self.contentView.layer containsPoint:point]) {
		[self dismiss];
	}
}

- (void)drawRect:(CGRect)rect {
	[super drawRect:rect];
	[self.contentView roundedRect:self.contentView.bounds byRoundingCorners:(UIRectCornerTopLeft + UIRectCornerTopRight) cornerRadii:CGSizeMake(20, 20)];
}

- (void)constructViewHierarchy {
	[self addSubview:self.bgView];
	[self addSubview:self.contentView];
	[self.contentView addSubview:self.titleLabel];
}

- (void)activateConstraints {
	[self.bgView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.bgView.superview);
	 }];
	[self.contentView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.trailing.bottom.equalTo(self.contentView.superview);
	 }];
	[self.titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(self.titleLabel.superview).offset(20);
        make.top.equalTo(self.titleLabel.superview).offset(32);
	 }];
}

- (void) bindInteraction {

}

- (instancetype)initWithFrame:(CGRect)frame {
	self = [super initWithFrame:frame];
	if (self) {
		[self initUI];
		self.contentView.transform = CGAffineTransformMake(1, 0, 0, 1, 0, UIScreen.mainScreen.bounds.size.height);
		self.alpha = 0;
	}
	return self;
}

- (instancetype)init {
	self = [super init];
	if (self) {
		[self initUI];
	}
	return self;
}
@end


@interface NSString (Extension)
+ (BOOL) isChineseLanguage;
@end

@implementation NSString (Extension)
+ (BOOL)isChineseLanguage {
	NSString* prefererdLang = NSBundle.mainBundle.preferredLocalizations.firstObject;

	if(!prefererdLang) {
		return false;
	}

	return [prefererdLang hasPrefix:@"zh-"];
}
@end


@implementation TRTCLoginCountryModel

- (instancetype)initWithCode:(NSString*)code displayEN:(NSString*)displayEN
        displayZH:(NSString*)displayZH {
	self = [super init];
	if (self) {
		self.code = code;
		self.displayEN = displayEN;
		self.displayZH = displayZH;
		NSString* addStr = @"+";
		self.displayTitle = [addStr stringByAppendingFormat:@"%@",self.code];
		self.countryName =  [NSString isChineseLanguage] == TRUE ? displayZH : displayEN;
	}
	return self;
}

+ (NSArray*)loadLoginCountryJson {
	NSString* path = [[NSBundle mainBundle] pathForResource:@"LoginCountryList" ofType:@"json"];
	if (path == nil) {
		return nil;
	}

	NSData* data = [NSData dataWithContentsOfURL:[NSURL fileURLWithPath:path]];
	NSError* error = [[NSError alloc] init];
	NSArray* value = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:&error];
	return value;
}

+ (NSMutableArray*)getLoginCountryList {
	static NSMutableArray *loginCountryList;
	NSArray* list;
	if (!loginCountryList) {
		list = [TRTCLoginCountryModel loadLoginCountryJson];
		loginCountryList = [[NSMutableArray alloc] init];
	}
	for (NSInteger i = 0; i < list.count; i++) {
		id model = [[TRTCLoginCountryModel alloc] initWithCode:[[list[i] objectForKey:@"code"] stringValue] displayEN:[list[i] objectForKey:@"en"] displayZH:[list[i] objectForKey:@"zh"]];
		[loginCountryList addObject:model];
	}

	return loginCountryList;
}
@end

#pragma mark - TRTCLoginCountryListCell

@interface TRTCLoginCountryListCell : UITableViewCell
@property (nonatomic, strong) TRTCLoginCountryModel *model;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *descLabel;
@end

@implementation TRTCLoginCountryListCell

- (instancetype) initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
	self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
	if (self) {
		self.backgroundColor = [UIColor clearColor];
	}
	return self;
}

- (void)constructViewHierarchy {
	self.titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
	self.titleLabel.text = self.model.countryName;
	self.titleLabel.font = [UIFont fontWithName:@"PingFangSC-Regular" size:18];
	self.titleLabel.textColor = [UIColor blackColor];

	self.descLabel = [[UILabel alloc] init];
	self.descLabel.text = self.model.displayTitle;
	self.descLabel.font = [UIFont fontWithName:@"PingFangSC-Regular" size:16];
	self.descLabel.textColor = [UIColor blackColor];
	self.descLabel.alpha = 0.6;
	[self.contentView addSubview:self.titleLabel];
	[self.contentView addSubview:self.descLabel];
}

- (void)activateConstraints {
	[self.titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.titleLabel.superview);
        make.leading.equalTo(self.titleLabel.superview).offset(20);
	 }];
	[self.descLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.descLabel.superview);
        make.trailing.equalTo(self.descLabel.superview).offset(-20);
	 }];
}
- (void)didMoveToWindow {
	[super didMoveToWindow];

	[self constructViewHierarchy];
	[self activateConstraints];
}
@end


@interface TRTCLoginCountryAlert ()<UITableViewDelegate, UITableViewDataSource>
@end

@implementation TRTCLoginCountryAlert
- (instancetype) init {
	self = [super init];
	if (self) {
		self.dataSource = [TRTCLoginCountryModel getLoginCountryList];

		self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
		self.tableView.backgroundColor = [UIColor clearColor];

		self.titleLabel.text = LoginNetworkLocalize(@"Demo.TRTC.Login.countrycode");;
	}
	return self;
}

- (void) constructViewHierarchy {
	[super constructViewHierarchy];
	[self.contentView addSubview:self.tableView];
}

- (void) activateConstraints {
	[super activateConstraints];
	[self.tableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.titleLabel.mas_bottom);
        make.height.mas_equalTo(UIScreen.mainScreen.bounds.size.height * 2/3);
        make.leading.trailing.bottom.equalTo(self.tableView.superview);
	 }];
}

- (void) bindInteraction {
	[super bindInteraction];
	self.tableView.delegate = self;
	self.tableView.dataSource = self;
}

#pragma mark - UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return self.dataSource.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	return 40;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	TRTCLoginCountryListCell* cell = [tableView dequeueReusableCellWithIdentifier:@"TRTCLoginCountryListCell"];
	if (!cell) {
		cell = [[TRTCLoginCountryListCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"TRTCLoginCountryListCell"];
	}
	cell.model = [self.dataSource objectAtIndex:indexPath.row];

	return cell;
}

#pragma mark - UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	if (self.didSelect) {
		self.didSelect([self.dataSource objectAtIndex:indexPath.row]);
	}
	[self dismiss];
}

@end




