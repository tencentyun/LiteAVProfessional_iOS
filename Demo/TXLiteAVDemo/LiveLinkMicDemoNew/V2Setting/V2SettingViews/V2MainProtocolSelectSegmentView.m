//
//  TXSegmentView.m
//  TopTitle
//
//  Created by coddyliu on 2020/12/5.
//  Copyright © 2020 aspilin. All rights reserved.
//

#import "V2MainProtocolSelectSegmentView.h"
//#import "Masonry.h"

#define ViewWidth  self.frame.size.width
#define ViewHeight self.frame.size.height

#define UIColorFromRGB(rgbValue) \
    [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16)) / 255.0 green:((float)((rgbValue & 0xFF00) >> 8)) / 255.0 blue:((float)(rgbValue & 0xFF)) / 255.0 alpha:1.0]

@interface                                       V2MainProtocolSelectSegmentView () <UIScrollViewDelegate>
@property(nonatomic, strong) NSDictionary *      titlesAndViews;
@property(nonatomic, strong) UISegmentedControl *titleSegment;
@property(nonatomic, strong) UIScrollView *      pageScrollView;
@property(nonatomic, strong) UIView *            lineView;
@property(nonatomic, assign) CGFloat             titleWidth;
@property(nonatomic, strong) NSArray *           orderTitles;
@end

@implementation V2MainProtocolSelectSegmentView

- (instancetype)initWithFrame:(CGRect)frame titlesAndViews:(NSDictionary<NSString *, UIView *> *)titlesAndViews titleOrder:(NSArray *)orderTitles {
    self = [super initWithFrame:frame];
    if (self) {
        self.titlesAndViews = titlesAndViews;
        self.orderTitles    = orderTitles ?: titlesAndViews.allKeys;
        [self constructSubviews];
        self.backgroundColor = [UIColor whiteColor];
    }
    return self;
}

- (void)constructSubviews {
    self.titleSegment                    = [[UISegmentedControl alloc] initWithFrame:CGRectMake(0, 0, ViewWidth, 50)];
    NSDictionary *selectedTextAttributes = @{NSFontAttributeName : [UIFont systemFontOfSize:15.0f], NSForegroundColorAttributeName : UIColorFromRGB(0x6495ED)};

    [self.titleSegment setTitleTextAttributes:selectedTextAttributes forState:UIControlStateSelected];  //设置文字属性
    NSDictionary *unselectedTextAttributes = @{NSFontAttributeName : [UIFont systemFontOfSize:15.0f], NSForegroundColorAttributeName : [UIColor whiteColor]};

    [self.titleSegment setTitleTextAttributes:unselectedTextAttributes forState:UIControlStateNormal];
    [self.titleSegment addTarget:self action:@selector(onSegmentChanged:) forControlEvents:UIControlEventValueChanged];
    self.titleSegment.tintAdjustmentMode = UIViewTintAdjustmentModeDimmed;
    [self.titleSegment setBackgroundImage:nil forState:UIControlStateSelected barMetrics:UIBarMetricsDefault];
    if ([self.titleSegment respondsToSelector:@selector(setSelectedSegmentTintColor:)]) {
        [self.titleSegment performSelector:@selector(setSelectedSegmentTintColor:) withObject:UIColor.clearColor];
    } else {
        self.titleSegment.tintColor = UIColor.clearColor;
    }
    [self addSubview:self.titleSegment];

    CGFloat segmengHeight = CGRectGetMaxY(self.titleSegment.frame);
    //滑动sc
    self.pageScrollView                                = [[UIScrollView alloc] initWithFrame:CGRectMake(0, segmengHeight, ViewWidth, ViewHeight - segmengHeight)];
    self.pageScrollView.bounces                        = YES;
    self.pageScrollView.pagingEnabled                  = YES;
    self.pageScrollView.showsVerticalScrollIndicator   = NO;
    self.pageScrollView.showsHorizontalScrollIndicator = NO;
    self.pageScrollView.delegate                       = self;

    [self addSubview:self.pageScrollView];
    if (@available(iOS 11.0, *)) {
        self.pageScrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    }
    //底部线
    self.lineView                 = [[UIView alloc] init];
    self.lineView.backgroundColor = [UIColor blueColor];
    [self addSubview:self.lineView];

    int i = 0;
    for (NSString *title in self.orderTitles) {
        [self.titleSegment insertSegmentWithTitle:title atIndex:i animated:NO];
        UIView *view = self.titlesAndViews[title];
        [self.pageScrollView addSubview:view];
        view.frame = CGRectMake(ViewWidth * i++, 0, ViewWidth, ViewHeight - segmengHeight);
    }
    self.titleSegment.selectedSegmentIndex = 0;

    CAGradientLayer *layer = [CAGradientLayer layer];
    layer.colors           = @[ (__bridge id)UIColorFromRGB(0x13294B).CGColor, (__bridge id)UIColorFromRGB(0x000000).CGColor ];
    layer.startPoint       = CGPointMake(0, 0);
    layer.endPoint         = CGPointMake(0, 1.0);
    layer.frame            = self.bounds;
    [self.layer insertSublayer:layer atIndex:0];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self layoutUI];
    });
}

- (void)layoutUI {
    self.titleWidth         = ViewWidth / self.titlesAndViews.count;
    self.titleSegment.frame = CGRectMake(0, 0, ViewWidth, 50);

    CGFloat segmengHeight     = CGRectGetMaxY(self.titleSegment.frame);
    self.lineView.frame       = CGRectMake(self.titleSegment.selectedSegmentIndex * self.titleWidth, segmengHeight - 1, self.titleWidth, 1);
    self.pageScrollView.frame = CGRectMake(0, segmengHeight, ViewWidth, ViewHeight - segmengHeight);
    int i                     = 0;
    for (NSString *title in self.orderTitles) {
        UIView *view = self.titlesAndViews[title];
        view.frame   = CGRectMake(ViewWidth * i++, 0, ViewWidth, ViewHeight - segmengHeight);
    }
    self.pageScrollView.contentSize = CGSizeMake(ViewWidth * i, self.pageScrollView.bounds.size.height);

    CAGradientLayer *layer = [self.layer.sublayers firstObject];
    if ([layer isKindOfClass:[CAGradientLayer class]]) {
        layer.frame = self.bounds;
        [layer setNeedsLayout];
        [layer layoutIfNeeded];
    }
}

- (NSInteger)selectedIndex {
    return self.titleSegment.selectedSegmentIndex;
}

- (UIView *)selectedView {
    if (self.orderTitles.count > self.selectedIndex) {
        NSString *title = self.orderTitles[self.selectedIndex];
        return self.titlesAndViews[title];
    } else {
        return nil;
    }
}

- (void)onSegmentChanged:(UISegmentedControl *)seg {
    /// 防重复点击，防抖动
    seg.userInteractionEnabled        = NO;
    self.pageScrollView.scrollEnabled = NO;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        seg.userInteractionEnabled        = YES;
        self.pageScrollView.scrollEnabled = YES;
    });
    [self.pageScrollView setContentOffset:CGPointMake(ViewWidth * seg.selectedSegmentIndex, 0) animated:NO];
    [self changeBtnBottomLineWithPage:seg.selectedSegmentIndex];
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    NSInteger page = scrollView.contentOffset.x / ViewWidth;
    if (self.titleSegment.selectedSegmentIndex != page) {
        self.titleSegment.selectedSegmentIndex = page;
    }
    [self changeBtnBottomLineWithPage:page];
}

- (void)changeBtnBottomLineWithPage:(NSInteger)page {
    CGFloat lineViewCenterX = page * self.titleWidth + self.titleWidth / 2;
    [UIView transitionWithView:self.lineView
        duration:0.3
        options:UIViewAnimationOptionAllowUserInteraction
        animations:^{
            self.lineView.center = CGPointMake(lineViewCenterX, 50);
        }
        completion:^(BOOL finished) {
            if ([self.delegate respondsToSelector:@selector(onSegmentView:selectedIndex:)]) {
                [self.delegate onSegmentView:self selectedIndex:page];
            }
        }];
}

@end
