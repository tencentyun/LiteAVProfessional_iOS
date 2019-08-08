//
//  TXBitrateView.m
//  TXLiteAVDemo
//
//  Created by annidyfeng on 2017/11/15.
//  Copyright © 2017年 Tencent. All rights reserved.
//

#import "TXBitrateView.h"

#define BTN_HEIGHT 30
#define H_PADDING  8
#define WIDTH      60

@implementation TXBitrateView {
    NSArray<TXBitrateItem *> *_dataSource;
    NSInteger _shown;
    UIButton *_selBtn;
}

- (void)setDataSource:(NSArray *)dataSource; {
    self.backgroundColor = [UIColor grayColor];
    [self.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    
    _dataSource = [dataSource sortedArrayUsingDescriptors:@[[[NSSortDescriptor alloc] initWithKey:@"bitrate" ascending:NO]]];
    
    NSArray *titles = @[@"流畅",@"高清",@"超清",@"原画"];
    _shown = dataSource.count > titles.count?titles.count:dataSource.count;
    if (_shown <= 1) {
        self.hidden = YES;
        return;
    }
    self.hidden = NO;
    
    titles = [titles subarrayWithRange:NSMakeRange(0, _shown)];
    
    [self sizeToFit];
    for (int i = 0; i < _shown; i++) {
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
        [btn setTitle:titles[_shown-1-i] forState:UIControlStateNormal];
        btn.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
        [btn addTarget:self action:@selector(clickBtn:) forControlEvents:UIControlEventTouchUpInside];
        btn.tag = _dataSource[i].index;
        if (btn.tag == self.selectedIndex) {
            [btn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            _selBtn = btn;
        } else {
            [btn setTitleColor:[UIColor lightTextColor] forState:UIControlStateNormal];
        }
        [btn sizeToFit];
        btn.center = CGPointMake(WIDTH/2, H_PADDING+BTN_HEIGHT*i+BTN_HEIGHT/2);
        [self addSubview:btn];
    }
}

- (void)clickBtn:(UIButton *)sender {
    if (sender.tag < _dataSource.count) {
        if (_selBtn != sender) {
            [_selBtn setTitleColor:[UIColor lightTextColor] forState:UIControlStateNormal];
            _selBtn = sender;
        }
        [_selBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        self.selectedIndex = sender.tag;
        
        if ([self.delegate respondsToSelector:@selector(onSelectBitrateIndex)]) {
            [self.delegate onSelectBitrateIndex];
        }
    }
}

- (CGSize)sizeThatFits:(CGSize)size {
    return CGSizeMake(WIDTH, H_PADDING*2+_shown*BTN_HEIGHT);
}

@end
