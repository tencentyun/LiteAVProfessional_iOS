//
//  MineAlertContentView.m
//  TXLiteAVDemo_Enterprise
//
//  Created by peterwtma on 2021/8/5.
//  Copyright © 2021 Tencent. All rights reserved.
//

#import "MineAlertContentView.h"
#import "MineViewModel.h"
#import "AppLocalized.h"
#import "ColorMacro.h"
#import "ProfileManager.h"
#import "RoundRect.h"
#import <Masonry.h>

@interface MineUserIdEditView ()<UITextFieldDelegate>
@property (nonatomic, strong) UIButton *confirmBtn;
@property (nonatomic, strong) UITextField *textField;
@property (nonatomic, strong) UILabel *alertTitleLabel;
@property (nonatomic, assign) BOOL canUse;
@end

@implementation MineUserIdEditView


- (void)constructViewHierarchy {
	[super constructViewHierarchy];
	[self.contentView addSubview:self.confirmBtn];
	[self.contentView addSubview:self.textField];
	[self.contentView addSubview:self.alertTitleLabel];
}

- (void)addConstraint {
	[super addConstraint];
	[self.confirmBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.trailing.equalTo(self.confirmBtn.superview).offset(-20);
        make.centerY.equalTo(self.titleLabel);
	 }];
	[self.textField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.titleLabel.mas_bottom).offset(20);
        make.leading.equalTo(self.titleLabel);
        make.trailing.equalTo(self.confirmBtn);
        make.height.mas_equalTo(52);
	 }];
	[self.alertTitleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(self.textField);
        make.top.equalTo(self.textField.mas_bottom).offset(10);
        make.trailing.lessThanOrEqualTo(self.alertTitleLabel.superview).offset(-20);
        make.bottom.equalTo(self.alertTitleLabel.superview).offset(-20);
	 }];
}

- (void)confirmBtnClick {
	[self.textField resignFirstResponder];
	if (!self.textField.text || self.textField.text.length <= 0) {
		return;
	}
	if (ProfileManager.shared.curUserModel) {
		ProfileManager.shared.curUserModel.name = self.textField.text;
		[ProfileManager.shared synchronizUserInfo];
	}
	[self dismiss];
	[ProfileManager.shared setNickName:self.textField.text success:^{
	         NSLog(@"sms set profile success");
	 } failed:^(NSString *_error) {
	         NSLog(@"sms set profile err: %@", _error);
	 }];
}

- (void)bindInteraction {
	[super bindInteraction];
	[self.confirmBtn addTarget:self action:@selector(confirmBtnClick) forControlEvents:UIControlEventTouchUpInside];
	self.textField.delegate = self;
}

- (void)initUI {
	[super initUI];
	self.confirmBtn = [UIButton buttonWithType:UIButtonTypeSystem];
	[self.confirmBtn setTitle:AppPortalLocalize(@"Demo.TRTC.Portal.confirm") forState:normal];
	[self.confirmBtn setEnabled:false];

	self.textField = [[UITextField alloc] initWithFrame:CGRectZero];
	self.textField.font = [UIFont fontWithName:@"PingFangSC-Regular" size:16];
	self.textField.textColor = UIColorFromRGB(0x333333);
	self.textField.backgroundColor = UIColorFromRGB(0xF4F5F9);
	UIView *leftView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 20, 0)];
	leftView.backgroundColor = [UIColor clearColor];
	[leftView setUserInteractionEnabled:false];
	self.textField.leftView = leftView;
	self.textField.leftViewMode = UITextFieldViewModeAlways;

	NSAttributedString *attr = [[NSAttributedString alloc] initWithString:AppPortalLocalize(@"Demo.TRTC.Portal.enterusername")];
	self.textField.attributedPlaceholder = attr;
	self.textField.layer.cornerRadius = 52 / 2;

	self.alertTitleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
	self.alertTitleLabel.font = [UIFont fontWithName:@"PingFangSC-Regular" size:14];
	[self.alertTitleLabel sizeToFit];
	self.alertTitleLabel.textColor = [UIColor grayColor];
	self.alertTitleLabel.text = AppPortalLocalize(@"Demo.TRTC.Portal.limit20count");
}

- (void)keyboardFrameChange:(NSNotification*)noti {
	if (!noti.userInfo) {
		return;
	}
	NSDictionary* info = noti.userInfo;
	CGRect keyBoardFrame = [info[UIKeyboardFrameEndUserInfoKey]CGRectValue];

	self.transform = CGAffineTransformMake(1, 0, 0, 1, 0, -UIScreen.mainScreen.bounds.size.height + keyBoardFrame.origin.y);
	NSLog(@"keyboardFrameChange");
}

- (instancetype)initWithFrame:(CGRect)frame viewModel:(MineViewModel*)viewModel {
	self = [super initWithFrame:frame viewModel:viewModel];
	if (self) {
		[self initUI];
		self.canUse = false;
		self.titleLabel.text = AppPortalLocalize(@"Demo.TRTC.Portal.changenickname");
		[NSNotificationCenter.defaultCenter addObserver:self selector:@selector(keyboardFrameChange:) name:UIKeyboardWillChangeFrameNotification object:nil];

	}
	return self;
}

- (void)dealloc {
	[NSNotificationCenter.defaultCenter removeObserver:self];
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
	[self.textField becomeFirstResponder];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
	[self.textField resignFirstResponder];
	[self checkConfirmBtnState:-1];
	return true;
}

- (void)textFieldDidChangeSelection:(UITextField *)textField {
    NSInteger maxCount = 20;
    if (self.textField.text.length <= maxCount) {
        [self checkAlertTitleLState:self.textField.text];
        [self checkConfirmBtnState:self.textField.text.length];
    } else {
        [self.confirmBtn setEnabled:false];
    }
}

- (void)checkAlertTitleLState:(NSString*)text {
	if (text.length <= 0) {
		self.canUse = false;
	} else {
		if (self.viewModel) {
			self.canUse = [self.viewModel validate:text];
		} else {
			self.canUse = true;
		}
	}
	if (self.canUse) {
		self.alertTitleLabel.textColor = [UIColor grayColor];
	} else {
		self.alertTitleLabel.textColor = [UIColor redColor];
	}
}

- (void)checkConfirmBtnState:(NSInteger)count {
	NSInteger ctt;
	if (self.textField.text.length > 0) {
		ctt = self.textField.text.length;
	} else {
		ctt = 0;
	}

	if (count > -1) {
		ctt = count;
	}
	BOOL isEnabled = self.canUse && ctt > 0;
	[self.confirmBtn setEnabled:isEnabled];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
	[self.textField resignFirstResponder];
	CGPoint point = [[touches anyObject] locationInView:self.contentView];
	if (!CGRectContainsPoint(self.contentView.bounds, point)) {
		[self dismiss];
	}
	else {
		[self checkConfirmBtnState:-1];
	}
}
@end


@interface MineAlertContentView ()
@end

@implementation MineAlertContentView

- (void)initUI {
	self.bgView = [[UIView alloc] initWithFrame:CGRectZero];
	self.bgView.backgroundColor = [UIColor blackColor];
	self.bgView.alpha = 0.6;

	self.contentView = [[UIView alloc] init];
	self.contentView.backgroundColor = [UIColor whiteColor];
	//    self.contentView.transform = CGAffineTransformMake(1, 0, 0, 1, 0, UIScreen.mainScreen.bounds.size.height);

	self.titleLabel = [[UILabel alloc] init];
	self.titleLabel.textColor = [UIColor blackColor];
	self.titleLabel.font = [UIFont fontWithName:@"PingFangSC-Medium" size:24];
}

- (void)constructViewHierarchy {
	[self addSubview:self.bgView];
	[self addSubview:self.contentView];
	[self.contentView addSubview:self.titleLabel];
}

- (void)addConstraint {
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

- (instancetype)initWithFrame:(CGRect)frame viewModel:(MineViewModel*)viewModel {
	self = [super initWithFrame:frame];
	if (self) {
		self.alpha = 0;
		self.viewModel = viewModel;
	}
	return self;
}

- (void)didMoveToWindow {
	[super didMoveToWindow];
	//生成视图层次布局
	[self constructViewHierarchy];

	//约束布局
	[self addConstraint];

	//绑定事件
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
		[self willDissmiss];
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
