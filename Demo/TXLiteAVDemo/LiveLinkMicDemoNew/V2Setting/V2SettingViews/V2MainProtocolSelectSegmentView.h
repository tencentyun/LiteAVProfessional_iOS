//
//  TXSegmentView.h
//  TopTitle
//
//  Created by coddyliu on 2020/12/5.
//  Copyright © 2020 aspilin. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class V2MainProtocolSelectSegmentView;
@protocol V2MainProtocolSelectSegmentViewProtocol <NSObject>
- (void)onSegmentView:(V2MainProtocolSelectSegmentView *)segmentView selectedIndex:(NSInteger)index;
@end

@interface                                                             V2MainProtocolSelectSegmentView : UIView
@property(nonatomic, strong, readonly) UISegmentedControl *            titleSegment;
@property(nonatomic, strong, readonly) UIScrollView *                  pageScrollView;
@property(nonatomic, assign, readonly) NSInteger                       selectedIndex;
@property(nonatomic, strong, readonly) UIView *                        selectedView;
@property(nonatomic, strong, readonly) NSArray *                       orderTitles;
@property(nonatomic, weak) id<V2MainProtocolSelectSegmentViewProtocol> delegate;
- (instancetype)initWithFrame:(CGRect)frame titlesAndViews:(NSDictionary<NSString *, UIView *> *)titlesAndViews titleOrder:(NSArray *)orderTitles;

@end

NS_ASSUME_NONNULL_END
