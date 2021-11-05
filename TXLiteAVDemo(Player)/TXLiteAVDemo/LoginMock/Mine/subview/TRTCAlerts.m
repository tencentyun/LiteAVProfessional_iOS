//
//  TRTCAlerts.m
//  TXLiteAVDemo_Enterprise
//
//  Created by peterwtma on 2021/8/6.
//  Copyright © 2021 Tencent. All rights reserved.
//

#import "TRTCAlerts.h"
#import "ColorMacro.h"
#import "AppLocalized.h"
#import "LayoutDefine.h"
#import "RoundRect.h"
#import <SDWebImage.h>
#import <Masonry.h>

@interface TRTCAlertContentView ()
@property (nonatomic, strong) UIView *bgView;
@property (nonatomic, strong) UIView *contentView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) TRTCAlertViewModel *viewModel;
@end
@implementation TRTCAlertContentView


- (instancetype)initWithFrame:(CGRect)frame viewModel:(TRTCAlertViewModel*)viewModel {
	self = [super initWithFrame:frame];
	if (self) {
		self.viewModel = viewModel;

		self.contentView.transform = CGAffineTransformMake(1, 0, 0, 1, 0, UIScreen.mainScreen.bounds.size.height);
		self.alpha = 0;
		[self initUI];
	}
	return self;
}

- (void)initUI {
	self.bgView = [[UIView alloc] initWithFrame:CGRectZero];
	self.bgView.backgroundColor = [UIColor blackColor];
	self.bgView.alpha = 0.6;

	self.contentView = [[UIView alloc] initWithFrame:CGRectZero];
	self.contentView.backgroundColor = [UIColor whiteColor];
	self.contentView.transform = CGAffineTransformMakeTranslation(0, 100);

	self.titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
	self.titleLabel.textColor = [UIColor blackColor];
	self.titleLabel.font = [UIFont fontWithName:@"PingFangSC-Medium" size:24];
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
        self.contentView.transform = CGAffineTransformMakeTranslation(0, 100);
        self.alpha = 0;
	 } completion:^(BOOL finished) {
        if (self.didDismiss) {
        self.didDismiss();
    }
        [self removeFromSuperview];
    }];
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

- (void)bindInteraction {

}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
	CGPoint point = [[touches anyObject] locationInView:self.contentView];
	if (!CGRectContainsPoint(self.contentView.bounds, point)) {
		[self dismiss];
	}
}

- (void)drawRect:(CGRect)rect {
	[super drawRect:rect];
	[self.contentView roundedRect:self.contentView.bounds byRoundingCorners:(UIRectCornerTopLeft + UIRectCornerTopRight) cornerRadii:CGSizeMake(20, 20)];
}
@end

#pragma mark - TRTCAvatarListCell

@interface TRTCAvatarListCell : UICollectionViewCell
@property (nonatomic, strong) AvatarModel *model;
@property (nonatomic, strong) UIView *selectView;
@property (nonatomic, strong) UIImageView *headImageView;
@end


@implementation TRTCAvatarListCell
- (void)initUI {
	self.headImageView = [[UIImageView alloc] initWithFrame:CGRectZero];
	self.headImageView.contentMode = UIViewContentModeScaleAspectFill;
	self.headImageView.clipsToBounds = true;

	self.selectView = [[UIView alloc] initWithFrame:CGRectZero];
	self.selectView.backgroundColor = [UIColor clearColor];
	[self.selectView setHidden:true];

	if (!self.model) {
		return;
	}

	[self.headImageView sd_setImageWithURL:[NSURL URLWithString:self.model.url] placeholderImage:nil options:SDWebImageContinueInBackground];
}


- (instancetype)initWithFrame:(CGRect)frame {
	self = [super initWithFrame:frame];
	if (self) {
	}
	return self;
}

- (void)drawRect:(CGRect)rect {
	[super drawRect:rect];
	self.headImageView.layer.cornerRadius = self.frame.size.height * 0.5;
	self.selectView.layer.cornerRadius = self.selectView.frame.size.height * 0.5;
	self.selectView.layer.borderWidth = 3;
	self.selectView.layer.borderColor = UIColorFromRGB(0x006EFF).CGColor;
}

- (void)didMoveToWindow {
	[super didMoveToWindow];
	[self initUI];
	[self constructViewHierarchy];
	[self activateConstraints];
}

- (void)constructViewHierarchy {
	[self.contentView addSubview:self.headImageView];
	[self.headImageView addSubview:self.selectView];
}

- (void)activateConstraints {
	[self.headImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.headImageView.superview);
	 }];

	[self.selectView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.selectView.superview);
	 }];
}
@end



@interface TRTCAvatarListAlertView ()<UICollectionViewDelegate, UICollectionViewDataSource>
@property (nonatomic, strong) UIButton *confirmBtn;
@property (nonatomic, strong) UICollectionView *collectionView;
- (void)initUI;
@end

@implementation TRTCAvatarListAlertView

- (instancetype)initWithFrame:(CGRect)frame viewModel:(TRTCAlertViewModel *)viewModel {
	self = [super initWithFrame:frame viewModel:viewModel];
	if (self) {
		self.titleLabel.font = [UIFont fontWithName:@"PingFangSC-Medium" size:20];
		self.titleLabel.text = TRTCLocalize(@"Demo.TRTC.Login.setavatar");
		self.backgroundColor = [UIColor clearColor];
	}
	return self;
}

- (void)initUI {
	[super initUI];
	self.confirmBtn = [UIButton buttonWithType:UIButtonTypeSystem];

	[self.confirmBtn setTitle:TRTCLocalize(@"Demo.TRTC.Login.done") forState:normal];
	if (self.confirmBtn.titleLabel) {
		self.confirmBtn.titleLabel.font = [UIFont fontWithName:@"PingFangSC-Medium" size:16];
	}

	[self.confirmBtn setEnabled:false];

	CGFloat itemWH = (UIScreen.mainScreen.bounds.size.width - 20 * 5) / 4;
	UICollectionViewFlowLayout* layout = [[UICollectionViewFlowLayout alloc] init];
	layout.scrollDirection = UICollectionViewScrollDirectionVertical;
	layout.itemSize = CGSizeMake(itemWH, itemWH);
	layout.minimumLineSpacing = 20;
	layout.minimumInteritemSpacing = 20;
	self.collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
	self.collectionView.allowsMultipleSelection = NO;
	self.collectionView.contentInset = UIEdgeInsetsMake(20, 20, 20, 20);
	self.collectionView.showsVerticalScrollIndicator = false;
	self.collectionView.showsHorizontalScrollIndicator = false;
	self.collectionView.backgroundColor = [UIColor clearColor];
}

- (void)constructViewHierarchy {
	[super constructViewHierarchy];
	[self.contentView addSubview:self.collectionView];
	[self.contentView addSubview:self.confirmBtn];
}

- (void)activateConstraints {
	[super activateConstraints];
	[self.collectionView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.bottom.trailing.equalTo(self.collectionView.superview);
        make.top.equalTo(self.titleLabel.mas_bottom);
        make.height.mas_equalTo([LayoutDefine convertPixel:440]);
	 }];

	[self.confirmBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.trailing.equalTo(self.confirmBtn.superview).offset(-20);
        make.centerY.equalTo(self.titleLabel);
	 }];
}


- (void)bindInteraction {
	[super bindInteraction];
	[self.confirmBtn addTarget:self action:@selector(confirmBtnClick) forControlEvents:UIControlEventTouchUpInside];

	self.collectionView.delegate = self;
	self.collectionView.dataSource = self;
	[self.collectionView registerClass:[TRTCAvatarListCell class] forCellWithReuseIdentifier:@"TRTCAvatarListCell"];
}

- (void)confirmBtnClick {
	if (!self.viewModel.currentSelectAvatarModel) {
		return;
	}
	[self.viewModel setUserAvatar:self.viewModel.currentSelectAvatarModel.url];
	if (self.didClickConfirmBtn) {
		self.didClickConfirmBtn();
	}
	[self dismiss];
}

- (void)dismiss {
	[super dismiss];
	self.viewModel.currentSelectAvatarModel = nil;
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
	if (self.viewModel) {
		return self.viewModel.avatarListDataSource.count;
	}
	return 0;
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
	TRTCAvatarListCell* cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"TRTCAvatarListCell" forIndexPath:indexPath];
	if (!cell) {
		cell = [[TRTCAvatarListCell alloc] initWithFrame:CGRectZero];
	}
	AvatarModel* model = self.viewModel.avatarListDataSource[indexPath.item];
	cell.model = model;
	if (cell.isSelected) {
		[cell.selectView setHidden:false];
	} else {
		[cell.selectView setHidden:true];
	}
	return cell;
}

#pragma mark - UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
	static TRTCAvatarListCell* lastCell = nil;

	TRTCAvatarListCell *cell = (TRTCAvatarListCell*)[collectionView cellForItemAtIndexPath:indexPath];
	[cell.selectView setHidden:false];
	if (lastCell) {
		[lastCell.selectView setHidden:true];
	}
	lastCell = cell;
	self.viewModel.currentSelectAvatarModel = self.viewModel.avatarListDataSource[indexPath.item];
	[self.confirmBtn setEnabled:true];
}
@end


