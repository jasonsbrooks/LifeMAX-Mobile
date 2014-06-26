//
//  GoalViewController.m
//  Lifemax
//
//  Created by Charles Jin on 6/26/14.
//  Copyright (c) 2014 YUCG. All rights reserved.
//

#import "GoalViewController.h"
#import "Task.h"
#import "AppDelegate.h"

@interface GoalViewController () <UIScrollViewDelegate>
@property (nonatomic, strong) IBOutlet UIScrollView *contentScrollView;
@property (nonatomic, strong) IBOutlet NSLayoutConstraint *heightConstraint;
@property (nonatomic, strong) IBOutlet UIView *overlayView;
@property (nonatomic, strong) NSMutableDictionary *values;
@end

@implementation GoalViewController

-(void)setTask:(Task *)task {
    if(_task != task){
        _task = task;
        [self initializeWithTaskValues:task];
    }
}

-(void)initializeWithTaskValues :(Task *)task {
    if(task.name) self.values[@"name"] = task.name;
    if(task.hashtag) self.values[@"hashtag"] = task.hashtag;
    if(task.pictureurl) self.values[@"pictureurl"] = task.pictureurl;
    if(task.desc) self.values[@"desc"] = task.desc;
    
//    NSLog(@"%@", task.name);
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [((AppDelegate *)([UIApplication sharedApplication].delegate)) disablePanning:self];
    
    self.title = @"Task";
    
    if (self.values[@"name"]) self.titleLabel.text = self.values[@"name"];
    if (self.values[@"desc"]) self.desc.text = self.values[@"desc"];
    if (self.values[@"hashtag"]) self.subtitleLabel.text = self.values[@"hashtag"];
    // need to set the picture

    
//    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.contentScrollView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:self.view.bounds.size.height]];
    [self.view layoutIfNeeded];
    
}

-(UIView *)overlayView {
    if(!_overlayView) {
        CGRect frame = self.contentScrollView.bounds;
        CGFloat offset = self.titleLabel.frame.origin.y + self.titleLabel.frame.size.height;
        frame.origin.y = offset;
        frame.size.height = frame.size.height - offset;
        _overlayView = [[UIView alloc] initWithFrame:frame];
        _overlayView.backgroundColor = [UIColor colorWithWhite:1 alpha:.3];
    }
    return _overlayView;
}

-(void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
}

-(void)awakeFromNib {
    [super awakeFromNib];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Add", nil) style:UIBarButtonItemStyleBordered target:self action:@selector(addPressed:)];
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Back", nil) style:UIBarButtonItemStyleBordered target:self action:@selector(backPressed:)];
    
    //configure default hashtags
    
    self.titleLabel.font = [UIFont preferredAvenirNextFontWithTextStyle:UIFontTextStyleHeadline];
    self.desc.font = [UIFont preferredAvenirNextFontWithTextStyle:UIFontTextStyleBody];
    
    self.contentScrollView.alwaysBounceVertical = YES;
    
}

- (void) addPressed:(id)sender {
    // segue to add, or just add ?
}

- (void) backPressed: (id) sender {
    // just go back
    [self exit];
}

- (void) exit {
    [self.navigationController popViewControllerAnimated:YES];
}


@end