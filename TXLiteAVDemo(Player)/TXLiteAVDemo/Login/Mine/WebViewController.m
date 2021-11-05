//
//  WebViewController.m
//  TXLiteAVDemo_Enterprise
//
//  Created by peterwtma on 2021/7/21.
//  Copyright © 2021 Tencent. All rights reserved.
//

#import "WebViewController.h"
#import <WebKit/WebKit.h>
#import "ColorMacro.h"
#import <Masonry.h>


@interface WebViewController()<WKNavigationDelegate>
@property (nonatomic, strong, readwrite) WKWebView *webView;
@property (nonatomic, strong) NSString *url;
@property (nonatomic, strong) NSString *titleString;
@property (nonatomic, strong) UIButton *backBtn;
@end

@implementation WebViewController

- (instancetype)initWithUrlString:(NSString*)urlString
                  withTitleString:(NSString*)titleString{
    self = [super init];
    if(self) {
        self.url = urlString;
        self.titleString = titleString;
    }
    return self;
}

- (void) viewWillAppear:(BOOL)animated{
    [self.navigationController setNavigationBarHidden:FALSE];
}

- (void) viewWillDisappear:(BOOL)animated{
    [self.navigationController setNavigationBarHidden:TRUE];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = UIColorFromRGB(0xF4F6F9);
    self.webView = [[WKWebView alloc] initWithFrame:CGRectZero];
    [self.webView setOpaque:false];
    self.webView.backgroundColor = [UIColor clearColor];
    self.webView.navigationDelegate = self;
    
    
    [self configNav];
    [self.view addSubview:self.webView];
    //生成布局间约束
    [self addConstraint];
    
    [self.webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:self.url]]];
}

- (void)addConstraint{
    [self.webView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.webView.superview);
    }];
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(null_unspecified WKNavigation *)navigation {
}

- (void)configNav {
    self.title = self.titleString;
    
    self.navigationController.navigationBar.titleTextAttributes = @{NSFontAttributeName:[UIFont systemFontOfSize:18], NSForegroundColorAttributeName:[UIColor blackColor]};
    
    self.navigationController.navigationBar.barTintColor = [UIColor whiteColor];
    [self.navigationController.navigationBar setTranslucent:false];
    
    self.backBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.backBtn setImage:[UIImage imageNamed:@"main_mine_about_back"] forState:normal];
    [self.backBtn addTarget:self action:@selector(backBtnClick) forControlEvents:UIControlEventTouchUpInside];
    [self.backBtn sizeToFit];
    UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithCustomView:_backBtn];
    item.tintColor = [UIColor blackColor];
    self.navigationItem.leftBarButtonItem = item;
}

- (void)backBtnClick {
    [self.navigationController popViewControllerAnimated:TRUE];
}
@end
