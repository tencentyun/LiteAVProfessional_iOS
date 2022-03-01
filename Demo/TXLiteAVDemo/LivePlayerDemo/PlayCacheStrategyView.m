//
//  PlayCacheStrategyView.m
//  TXLiteAVDemo_Enterprise
//
//  Created by gg on 2021/8/24.
//  Copyright © 2021 Tencent. All rights reserved.
//

#import "PlayCacheStrategyView.h"
#import <Masonry.h>
#import "UIColor+MLPFlatColors.h"

@interface PlayCacheStrategyTableCell : UITableViewCell

@property (nonatomic, weak) UIButton *displayBtn;

@end

@interface PlayCacheStrategyView () <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, weak) UILabel *titleLabel;

@property (nonatomic, weak) UIButton *closeBtn;

@property (nonatomic, weak) UITableView *tableView;

@property (nonatomic, assign) BOOL isViewReady;
@end

@implementation PlayCacheStrategyView

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        
        self.selectIndex = 2;
        self.isViewReady = NO;
        
        self.backgroundColor = [UIColor colorWithRed:19.0 / 255.0 green:41.0 / 255.0 blue:75.0 / 255.0 alpha:1];
        self.layer.cornerRadius = 10;
        self.clipsToBounds = YES;
        self.alpha = 0;
        
        [self initUI];
    }
    return self;
}

- (void)setSelectIndex:(NSInteger)selectIndex {
    _selectIndex = selectIndex;
    [self.tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:selectIndex inSection:0] animated:YES scrollPosition:UITableViewScrollPositionNone];
}

- (void)setTitleText:(NSString *)titleText {
    _titleText = titleText;
    self.titleLabel.text = _titleText;
}

- (void)setCloseText:(NSString *)closeText {
    _closeText = closeText;
    [self.closeBtn setTitle:closeText forState:UIControlStateNormal];
}

- (void)didMoveToWindow {
    [super didMoveToWindow];
    if (self.isViewReady) {
        return;
    }
    self.isViewReady = YES;
    [self layoutUI];
}

- (void)show {
    [UIView animateWithDuration:0.3 animations:^{
        self.alpha = 1;
    }];
}

- (void)dismiss {
    [UIView animateWithDuration:0.3 animations:^{
        self.alpha = 0;
    }];
}

- (void)initUI {
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    titleLabel.textColor = [UIColor whiteColor];
    [self addSubview:titleLabel];
    self.titleLabel = titleLabel;
    
    UIButton *closeBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [closeBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self addSubview:closeBtn];
    self.closeBtn = closeBtn;
    [closeBtn addTarget:self action:@selector(closeBtnClick:) forControlEvents:UIControlEventTouchUpInside];
    
    UITableView *tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    tableView.dataSource = self;
    tableView.delegate = self;
    tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    [tableView registerClass:[PlayCacheStrategyTableCell class] forCellReuseIdentifier:@"PlayCacheStrategyTableCell"];
    tableView.backgroundColor = [UIColor clearColor];
    [self addSubview:tableView];
    self.tableView = tableView;
}

- (void)setDataSource:(NSArray<NSString *> *)dataSource {
    _dataSource = dataSource;
    [self.tableView reloadData];
}

- (void)closeBtnClick:(UIButton *)btn {
    [self dismiss];
}

- (void)layoutUI {
    [self.titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self);
        make.top.equalTo(self).offset(10);
    }];
    
    [self.closeBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.titleLabel);
        make.trailing.equalTo(self).offset(-20);
    }];
    
    [self.tableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.trailing.bottom.equalTo(self);
        make.top.equalTo(self.titleLabel.mas_bottom).offset(10);
    }];
}

#pragma mark - UITableViewDataSource & UITableViewDelegate
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.dataSource.count;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    PlayCacheStrategyTableCell *cell = [tableView dequeueReusableCellWithIdentifier:@"PlayCacheStrategyTableCell" forIndexPath:indexPath];
    NSString *title = self.dataSource[indexPath.row];
    [cell.displayBtn setTitle:title forState:UIControlStateNormal];
    [cell.displayBtn setTitle:title forState:UIControlStateSelected];
    if (indexPath.row == self.selectIndex) {
        [tableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionNone];
    }
    return cell;
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.didSelectIndex != nil && indexPath.row != self.selectIndex) {
        self.didSelectIndex(indexPath.row);
    }
    self.selectIndex = indexPath.row;
}
@end

@implementation PlayCacheStrategyTableCell

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
    self.displayBtn.selected = selected;
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        
        self.backgroundColor = [UIColor clearColor];
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
        btn.userInteractionEnabled = NO;
        [btn setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
        [btn setTitleColor:[UIColor whiteColor] forState:UIControlStateSelected];
        [btn setImage:[UIImage imageNamed:@"checkbox_nor"] forState:UIControlStateNormal];
        [btn setImage:[UIImage imageNamed:@"checkbox_sel"] forState:UIControlStateSelected];
        [self.contentView addSubview:btn];
        self.displayBtn = btn;
        [btn mas_makeConstraints:^(MASConstraintMaker *make) {
            make.leading.equalTo(self.contentView).offset(20);
            make.top.equalTo(self.contentView).offset(10);
            make.bottom.equalTo(self.contentView).offset(-10);
            make.width.mas_greaterThanOrEqualTo(62);
        }];
    }
    return self;
}

@end
