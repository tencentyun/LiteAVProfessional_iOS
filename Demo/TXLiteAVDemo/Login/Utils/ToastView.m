//
//  ToastView.m
//  TXLiteAVDemo_Enterprise
//
//  Created by peterwtma on 2021/8/8.
//  Copyright © 2021 Tencent. All rights reserved.
//

#import "ToastView.h"

static const CGFloat Default_max_w = 180;
static const CGFloat Default_min_w = 100;
static const CGFloat Default_min_h = 24;
static const CGFloat Default_Display_Duration = 1.5;
static const CGFloat Default_Font_Size = 15.0;
static const CGFloat Default_min_Font_Size = 10.0;
static const CGFloat Default_max_Font_Size = 22.0;
static const CGFloat Default_View_Radius = 8.0;
static const CGFloat Default_bg_Alpha = 0.8;
static NSString * const Default_text = @"  ";

@interface CSToast ()

@property (nonatomic, assign) CGFloat toastFontSize;
@property (nonatomic, assign) CGFloat toastRadius;
@property (nonatomic, assign) CGFloat toastDuration;
@property (nonatomic, assign) CGFloat topMargin;
@property (nonatomic, assign) CGFloat bottomMargin;
@property (nonatomic, strong) UIView   *showView;
@property (nonatomic, strong) UIButton *contentView;
@property (nonatomic, strong) UIColor  *toastBGColor;
@property (nonatomic,   copy) NSString *toastText;
@property (nonatomic, strong) UIColor  *toastTextColor;
@property (nonatomic, strong) UILabel  *msgLabel;

@end

@implementation CSToast

+ (instancetype)sharedInstance {
	static CSToast *sharedInstance = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		sharedInstance = [[self alloc] init];
	});
	return sharedInstance;
}

- (instancetype)initWithFrame:(CGRect)frame {
	if (self = [super initWithFrame:frame]) {
		[self setupUI];
	}
	return self;
}

- (void)setupUI {
	CGSize textSize = CGSizeMake(Default_max_w, Default_min_h);
	self.contentView = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, textSize.width, textSize.height)];
	self.contentView.layer.cornerRadius = Default_View_Radius;
	self.contentView.layer.masksToBounds = YES;
	self.contentView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:Default_bg_Alpha];
	[self.contentView addTarget:self action:@selector(hideAnimation) forControlEvents:UIControlEventTouchUpInside];
	self.contentView.alpha = 0;
	self.msgLabel = [[UILabel alloc] initWithFrame:self.contentView.bounds];
	self.msgLabel.numberOfLines = 0;
	self.msgLabel.backgroundColor = [UIColor clearColor];
	self.msgLabel.text = Default_text;
	self.msgLabel.textColor = [UIColor whiteColor];
	self.msgLabel.textAlignment = NSTextAlignmentCenter;
	self.msgLabel.font = [UIFont boldSystemFontOfSize:Default_Font_Size];
	[self.contentView addSubview:self.msgLabel];
	[self defaultConfig];
}

- (void)defaultConfig {
	self.toastRadius = Default_View_Radius;
	self.showView = [UIApplication sharedApplication].keyWindow;
	self.toastBGColor = [[UIColor blackColor] colorWithAlphaComponent:Default_bg_Alpha];
	self.toastTextColor = [UIColor whiteColor];
	self.toastDuration = Default_Display_Duration;
	self.toastFontSize = Default_Font_Size;
	self.toastText = Default_text;
}

-(void)setText:(NSString *)text {
	if (self.toastFontSize < Default_min_Font_Size) {
		self.toastFontSize = Default_min_Font_Size;
	}else if (self.toastFontSize > Default_max_Font_Size) {
		self.toastFontSize = Default_max_Font_Size;
	}
	self.msgLabel.font = [UIFont boldSystemFontOfSize:self.toastFontSize];
	CGSize textSize = [text boundingRectWithSize:CGSizeMake(Default_max_w, CGFLOAT_MAX)
	                   options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading
	                   attributes:@{NSFontAttributeName : self.msgLabel.font}
	                   context:nil].size;
	CGSize viewSize = CGSizeMake(MIN(Default_max_w, MAX(Default_min_w, ceil(textSize.width))) + 30, ceil(textSize.height) + 20);
	self.contentView.frame = CGRectMake(0, 0, viewSize.width, viewSize.height);
	self.contentView.layer.cornerRadius = self.toastRadius;
	self.contentView.layer.masksToBounds = YES;
	self.contentView.backgroundColor = self.toastBGColor;
	self.msgLabel.frame = CGRectMake(0, 0, viewSize.width - 30, viewSize.height - 20);
	self.msgLabel.center = CGPointMake(viewSize.width/2, viewSize.height/2);
	self.msgLabel.text = self.toastText;
	self.msgLabel.textColor = self.toastTextColor;
}

- (void)setDuration:(CGFloat)duration {
	if (duration <= 0.0f) { duration = NSIntegerMax; }
	self.toastDuration = duration;
}

-(void)showAnimation {
	if (self.contentView.alpha > 0.8) self.contentView.alpha = 0.8;
	[UIView animateWithDuration:0.25 animations:^{
        self.contentView.alpha = 1.0;
	 }];
}

-(void)hideAnimation {
	[UIView animateWithDuration:0.25 animations:^{
        self.contentView.alpha = 0.0;
	 } completion:^(BOOL finished){
        if (finished) { [self dismissToast]; }
	 }];
}

-(void)dismissToast {
	[self.contentView removeFromSuperview];
}

- (void)showToast {
	[self showInView:self.showView withCenterPosition:[self showWithCenter]];
}

- (CGPoint)showWithCenter {
	CGPoint center = self.showView.center;
	self.autoresizingMask = UIViewAutoresizingNone;

	if (self.showView != [UIApplication sharedApplication].keyWindow) {
		return CGPointMake(self.showView.bounds.size.width / 2, self.showView.bounds.size.height /2);
	}
	if (self.topMargin) {
		self.autoresizingMask = UIViewAutoresizingFlexibleTopMargin;
		CGFloat center_y = self.topMargin + self.contentView.bounds.size.height/2;
		self.topMargin = 0.0;
		return CGPointMake(self.showView.center.x, center_y);
	}
	if (self.bottomMargin) {
		self.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin;
		CGFloat center_y = self.showView.frame.size.height - self.bottomMargin - self.contentView.bounds.size.height/2;
		self.bottomMargin = 0.0;
		return CGPointMake(self.showView.center.x, center_y);
	}
	return center;
}

- (void)showInView:(UIView *)view withCenterPosition:(CGPoint)center {
	if (self.contentView.superview != view) {
		[self.contentView removeFromSuperview];
		[view addSubview:self.contentView];
	}
	self.contentView.center = center;
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
	[self showAnimation];
	if (self.toastDuration < 0) return;
	if (self.toastDuration == 0) self.toastDuration = Default_Display_Duration;
	[self performSelector:@selector(hideAnimation) withObject:nil afterDelay:self.toastDuration];
}

#pragma mark  -  OC风格API
+ (void)showWithText:(NSString *)text {
	CSToast.text(text).show();
}

+ (void)showWithText:(NSString *)text duration:(CGFloat)duration {
	CSToast.text(text).duration(duration).show();
}

+ (void)showWithText:(NSString *)text topOffset:(CGFloat)topOffset {
	CSToast.text(text).top(topOffset).show();
}

+ (void)showWithText:(NSString *)text topOffset:(CGFloat)topOffset duration:(CGFloat)duration {
	CSToast.text(text).top(topOffset).duration(duration).show();
}

+ (void)showWithText:(NSString *)text bottomOffset:(CGFloat)bottomOffset {
	CSToast.text(text).bottom(bottomOffset).show();
}

+ (void)showWithText:(NSString *)text bottomOffset:(CGFloat)bottomOffset duration:(CGFloat)duration {
	CSToast.text(text).bottom(bottomOffset).duration(duration).show();
}

+ (void)showWithText:(NSString *)text inView:(UIView *)view {
	CSToast.text(text).inView(view).show();
}

+ (void)showWithText:(NSString *)text inView:(UIView *)view duration:(CGFloat)duration {
	CSToast.text(text).inView(view).duration(duration).show();
}

#pragma mark  -  链式风格API
+ (CSToast *(^)(NSString *text))text {
	return ^(NSString *text){
        CSToast *toast = [CSToast sharedInstance];
        toast.toastText = text;
        return toast;
	};
}

- (CSToast *(^)(CGFloat fontSize))fontSize {
	return ^(CGFloat fontSize){
        self.toastFontSize = fontSize;
        return self;
	};
}

- (CSToast *(^)(CGFloat duration))duration {
	return ^(CGFloat duration){
        self.toastDuration = duration;
        return self;
	};
}

- (CSToast *(^)(CGFloat topOffset))top {
	return ^(CGFloat topOffset){
        self.topMargin = topOffset;
        return self;
	};
}

- (CSToast *(^)(CGFloat bottomOffset))bottom {
	return ^(CGFloat bottomOffset){
        self.bottomMargin = bottomOffset;
        return self;
	};
}

- (CSToast *(^)(UIView *view))inView {
	return ^(UIView *view){
        self.showView = view;
        return self;
	};
}

- (CSToast *(^)(UIColor *textColor))textColor {
	return ^(UIColor *textColor){
        self.toastTextColor = textColor;
        return self;
	};
}

- (CSToast *(^)(UIColor *bgColor))bgColor {
	return ^(UIColor *bgColor){
        self.toastBGColor = [bgColor colorWithAlphaComponent:Default_bg_Alpha];
        return self;
	};
}

- (void (^)())show {
	return ^(){
        [self setText:self.toastText];
        [self setDuration:self.toastDuration];
        [self showToast];
        [self defaultConfig];
	};
}


@end
