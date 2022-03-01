//
//  MainTableViewCell.m
//  RTMPiOSDemo
//
//  Created by rushanting on 2017/5/3.
//  Copyright © 2017年 tencent. All rights reserved.
//

#import "MainTableViewCell.h"

#import "ColorMacro.h"

@interface                           CellInfo ()
@property(nonatomic, copy) NSString *controllerClassName;
@property(copy, nonatomic) UIViewController * (^controllerCreator)(void);
@property(readwrite, nonatomic) CellInfoType type;
@property(copy, nonatomic) void (^action)(void);
@end

@implementation CellInfo
- (id)init {
    self = [super init];

    return self;
}

+ (instancetype)cellInfoWithTitle:(NSString *)title controllerClassName:(NSString *)className {
    CellInfo *info           = [[CellInfo alloc] init];
    info.title               = title;
    info.controllerClassName = className;
    info.type                = CellInfoTypeEntry;
    return info;
}

+ (instancetype)cellInfoWithTitle:(NSString *)title controllerCreationBlock:(UIViewController * (^)(void))creator {
    CellInfo *info         = [[CellInfo alloc] init];
    info.title             = title;
    info.controllerCreator = creator;
    info.type              = CellInfoTypeEntry;
    return info;
}

+ (instancetype)cellInfoWithTitle:(NSString *)title actionBlock:(void (^)(void))action {
    CellInfo *info = [[CellInfo alloc] init];
    info.title     = title;
    info.action    = action;
    info.type      = CellInfoTypeAction;
    return info;
}

- (UIViewController *)createEntryController {
    if (self.controllerClassName) {
        return [[NSClassFromString(self.controllerClassName) alloc] init];
    } else if (self.controllerCreator) {
        return self.controllerCreator();
    }
    return nil;
}

- (void)performAction {
    if (self.action) {
        self.action();
    }
}

@end

@interface MainTableViewCell () {
    UIView *     _backgroundView;
    UIImageView *_iconImageView;
    UILabel *    _titleLabel;
    UIImageView *_detailImageView;
}

@end

@implementation MainTableViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        self.backgroundColor = UIColor.clearColor;
        self.selectionStyle  = UITableViewCellSelectionStyleNone;

        _backgroundView = [[UIView alloc] init];
        [self addSubview:_backgroundView];

        _iconImageView             = [[UIImageView alloc] init];
        _iconImageView.contentMode = UIViewContentModeScaleAspectFit;
        [_backgroundView addSubview:_iconImageView];

        _titleLabel               = [[UILabel alloc] init];
        _titleLabel.textAlignment = NSTextAlignmentLeft;
        _titleLabel.font          = [UIFont systemFontOfSize:18];
        _titleLabel.textColor     = UIColor.whiteColor;
        [_backgroundView addSubview:_titleLabel];

        _detailImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"arrow"]];
        [_backgroundView addSubview:_detailImageView];
        _detailImageView.hidden = YES;
    }

    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];

    if (_cellData.subCells.count > 0) {
        _backgroundView.frame   = CGRectMake(0, 10, self.frame.size.width, 55);
        _iconImageView.hidden   = NO;
        _detailImageView.hidden = YES;
        _titleLabel.font        = [UIFont systemFontOfSize:18];
    } else {
        _backgroundView.frame   = CGRectMake(0, 0, self.frame.size.width, 50);
        _iconImageView.hidden   = YES;
        _detailImageView.hidden = NO;
        _titleLabel.font        = [UIFont systemFontOfSize:16];
    }
    [_titleLabel sizeToFit];
    _titleLabel.center      = CGPointMake(_titleLabel.center.x, _titleLabel.superview.frame.size.height / 2);
    _titleLabel.frame       = CGRectMake(10, _titleLabel.frame.origin.y, _titleLabel.frame.size.width, _titleLabel.frame.size.height);
    _iconImageView.center   = (CGPointMake(_backgroundView.frame.size.width - 41, _backgroundView.frame.size.height / 2));
    _detailImageView.center = (CGPointMake(_backgroundView.frame.size.width - 41, _backgroundView.frame.size.height / 2));
}

- (void)setCellData:(CellInfo *)cellInfo {
    _cellData            = cellInfo;
    UIImage *image       = cellInfo.iconName != nil ? [UIImage imageNamed:cellInfo.iconName] : nil;
    _iconImageView.image = image;
    [_iconImageView sizeToFit];
    _titleLabel.text = cellInfo.title;
    [_titleLabel sizeToFit];
    self.highLight = _cellData.isUnFold;
}

- (void)setHighLight:(BOOL)highLight {
    if (highLight) {
        _backgroundView.backgroundColor = UIColorFromRGB(0x173370);
    } else {
        _backgroundView.backgroundColor = UIColorFromRGB(0x0D2C5B);
    }
    _highLight = highLight;
}

@end
