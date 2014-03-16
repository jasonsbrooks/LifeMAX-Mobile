//
//  WebViewController.m
//  Lifemax
//
//  Created by Micah Rosales on 3/14/14.
//  Copyright (c) 2014 YUCG. All rights reserved.
//

#import "WebViewController.h"

@interface WebViewController ()
@property (nonatomic, strong) IBOutlet UIWebView *webView;
@end

@implementation WebViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        [self configure];
    }
    return self;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    [self configure];
}

- (void) configure {

}

-(void)setUrl:(NSURL *)url {
    if(url != _url) {
        [self loadUrl:url];
        _url = url;
    }
}

- (void)loadUrl:(NSURL *)url {
    //URL Request Object
    NSURLRequest *requestObj = [NSURLRequest requestWithURL:url];
    
    //Load the request in the UIWebView.
    [self.webView loadRequest:requestObj];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if(!self.webView) {
        self.webView = [[UIWebView alloc]initWithFrame:self.view.bounds];
    }
    
    self.webView.scalesPageToFit = NO;
    
    if(self.url) {
        [self loadUrl:self.url];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
