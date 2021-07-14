/*
* Module:   TRTCPKSettingsViewController
*
* Function: 跨房PK页
*
*    1. 通过TRTCCloudManager来开启关闭跨房连麦。
*
*/

#import "TRTCPKSettingsViewController.h"
#import "UIButton+TRTC.h"
#import "ColorMacro.h"
#import "Masonry.h"
#import "AppLocalized.h"

@interface TRTCPKSettingsViewController ()

@property (strong, nonatomic) TRTCSettingsLargeInputItem* roomItem;
@property (strong, nonatomic) TRTCSettingsLargeInputItem* nameItem;
@property (strong, nonatomic) UIButton *actionButton;

@end

@implementation TRTCPKSettingsViewController


- (NSString *)title {
    return @"pk";
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSMutableArray *array = [NSMutableArray array];
    self.roomItem = [[TRTCSettingsLargeInputItem alloc] initWithTitle:TRTCLocalize(@"Demo.TRTC.Live.remoteRoomId")
                                                          placeHolder:@""];
    [array addObject:self.roomItem];
    self.roomItem.maxLength = 10;
    
    self.nameItem = [[TRTCSettingsLargeInputItem alloc] initWithTitle:TRTCLocalize(@"Demo.TRTC.Live.remoteUserId")
                                                          placeHolder:@""];
    [array addObject:self.nameItem];
    self.nameItem.maxLength = 40;
    
    self.items = array;

    
    self.actionButton = [UIButton trtc_cellButtonWithTitle:TRTCLocalize(@"Demo.TRTC.Live.startPk")];
    [self.actionButton setTitle:TRTCLocalize(@"Demo.TRTC.Live.stopPk") forState:UIControlStateSelected];
    [self.view addSubview:self.actionButton];
    [self.actionButton addTarget:self action:@selector(onClickActionButton:) forControlEvents:UIControlEventTouchDown];
    [self.actionButton setHighlighted:NO];

    [self.actionButton mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(self.view).offset(40);
        make.trailing.equalTo(self.view).offset(-40);
        make.bottom.equalTo(self.view).offset(-40);
        make.height.mas_equalTo(49);
    }];
    
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self syncButtonStatus];
}

- (void)syncButtonStatus {
    self.actionButton.selected = self.trtcCloudManager.isCrossingRoom;
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self.view endEditing:NO];
}

#pragma mark - Actions

- (IBAction)onClickActionButton:(UIButton *)button {
    if (self.trtcCloudManager.isCrossingRoom) {
        [self stopPK];
    } else {
        [self startPK];
    }
}

- (void)startPK {
    if (self.roomItem.content.length == 0 || self.nameItem.content.length == 0) {
        return;
    }
    self.actionButton.selected = !self.actionButton.isSelected;
    [self.trtcCloudManager startCrossRoom:self.roomItem.content userId:self.nameItem.content];
    [self.view endEditing:YES];
}

- (void)stopPK {
    self.actionButton.selected = !self.actionButton.isSelected;
    [self.trtcCloudManager stopCrossRomm];
}


@end
