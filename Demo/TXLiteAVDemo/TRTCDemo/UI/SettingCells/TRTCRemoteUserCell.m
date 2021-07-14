/*
* Module:   TRTCRemoteUserCell
*
* Function: 远端用户列表页的用户Cell
*
*    1. TRTCRemoteUserItem中保存设置给Cell的用户数据
*
*/

#import "TRTCRemoteUserCell.h"
#import "Masonry.h"

@interface TRTCRemoteUserCell ()

@property (strong, nonatomic) UIImageView *videoIconView;
@property (strong, nonatomic) UIImageView *audioIconView;

@end

@implementation TRTCRemoteUserCell

- (void)setupUI {
    [super setupUI];
    
    self.videoIconView = [[UIImageView alloc] init];
    self.videoIconView.contentMode = UIViewContentModeScaleAspectFit;
    [self.contentView addSubview:self.videoIconView];

    self.audioIconView = [[UIImageView alloc] init];
    self.audioIconView.contentMode = UIViewContentModeScaleAspectFit;
    [self.contentView addSubview:self.audioIconView];

    UIImageView *arrowView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"arrow"]];
    [self.contentView addSubview:arrowView];
    self.titleLabel.adjustsFontSizeToFitWidth = true;
    
    [self.videoIconView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.contentView);
        make.trailing.equalTo(self.audioIconView.mas_leading).offset(-20);
        make.size.mas_equalTo(CGSizeMake(30, 30));
    }];
    [self.audioIconView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.contentView);
        make.trailing.equalTo(arrowView.mas_leading).offset(-20);
        make.size.mas_equalTo(CGSizeMake(30, 30));
    }];
    [arrowView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.contentView);
        make.trailing.equalTo(self.contentView).offset(-18);
        make.width.mas_equalTo(10);
    }];
    [self.titleLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.contentView);
        make.leading.equalTo(self.contentView).offset(18);
        make.trailing.equalTo(self.videoIconView.mas_leading).offset(-10);
    }];

}

- (void)didUpdateItem:(TRTCSettingsBaseItem *)item {
    if ([item isKindOfClass:[TRTCRemoteUserItem class]]) {
        TRTCRemoteUserItem *memberItem = (TRTCRemoteUserItem *)item;
        self.titleLabel.text = memberItem.userId;
        self.videoIconView.image = [UIImage imageNamed:!memberItem.memberSettings.isVideoMuted ? @"camera_nol" : @"camera_dis"];
        self.audioIconView.image = [UIImage imageNamed:!memberItem.memberSettings.isAudioMuted ? @"sound" : @"sound_dis"];
    }
}

@end


@implementation TRTCRemoteUserItem

- (instancetype)initWithUser:(NSString *)userId settings:(TRTCRemoteUserConfig *)memberSettings {
    if (self = [super init]) {
        _userId = userId;
        _memberSettings = memberSettings;
    }
    return self;
}

+ (Class)bindedCellClass {
    return [TRTCRemoteUserCell class];
}

- (NSString *)bindedCellId {
    return [TRTCRemoteUserItem bindedCellId];
}

@end
