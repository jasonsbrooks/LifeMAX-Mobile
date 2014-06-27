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
#import <OHAlertView/OHAlertView.h>
#import <OHActionSheet/OHActionSheet.h>
#import "LMRestKitManager.h"

@interface GoalViewController () <UIScrollViewDelegate>
@property (nonatomic, strong) IBOutlet UIScrollView *contentScrollView;
@property (nonatomic, strong) IBOutlet NSLayoutConstraint *heightConstraint;
@property (nonatomic, strong) IBOutlet UIView *overlayView;
@property (nonatomic, strong) NSMutableDictionary *values;
@property (nonatomic, strong) NSDateFormatter *formatter;


@end

@implementation GoalViewController

-(NSMutableDictionary *)values {
    if(!_values)
        _values = [[NSMutableDictionary alloc]init];
    return _values;
}

-(NSDateFormatter *)formatter {
    if(!_formatter) {
        _formatter = [[NSDateFormatter alloc]init];
        _formatter.locale = [NSLocale currentLocale];
        _formatter.timeZone = [NSTimeZone systemTimeZone];
    }
    return _formatter;
}

-(void)setTask:(Task *)task {
    if(_task != task){
        _task = task;
        [self initializeWithTaskValues:task];
    }
}

-(void)initializeWithTaskValues :(Task *)task {
    if(task.name) self.values[@"name"] = task.name;
    if(task.hashtag) self.values[@"hashtag"] = task.hashtag;
    if(task.desc) self.values[@"desc"] = task.desc;
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [((AppDelegate *)([UIApplication sharedApplication].delegate)) disablePanning:self];
    
    self.title = @"Goal";
    
    if (self.values[@"name"]) self.titleLabel.text = self.values[@"name"];
    if (self.values[@"desc"]) self.desc.text = self.values[@"desc"];
    if (self.values[@"hashtag"]) self.subtitleLabel.text = self.values[@"hashtag"];

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
    
//    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Add", nil) style:UIBarButtonItemStyleBordered target:self action:@selector(addPressed:)];
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Back", nil) style:UIBarButtonItemStyleBordered target:self action:@selector(backPressed:)];
    [self.addButton addTarget:self action:@selector(addPressed:) forControlEvents:UIControlEventTouchUpInside];
    [self.doneButton addTarget:self action:@selector(donePressed:) forControlEvents:UIControlEventTouchUpInside];
    
    //configure default hashtags
    
    self.titleLabel.font = [UIFont preferredAvenirNextFontWithTextStyle:UIFontTextStyleHeadline];
    self.desc.font = [UIFont preferredAvenirNextFontWithTextStyle:UIFontTextStyleBody];
    
    self.contentScrollView.alwaysBounceVertical = YES;
    
}

- (void) addPressed:(id)sender {
    [self promtTaskCreationWithComplete:NO];
}

-(void) donePressed:(id)sender {
    [self promtTaskCreationWithComplete:YES];
}

- (void)promtTaskCreationWithComplete:(BOOL)completed {
    
    [OHActionSheet showSheetInView:self.view title:NSLocalizedString(@"New Goal Privacy", nil) cancelButtonTitle:NSLocalizedString(@"Cancel", nil) destructiveButtonTitle:NSLocalizedString(@"Share with friends", nil) otherButtonTitles:@[NSLocalizedString(@"Make Private", nil)] completion:^(OHActionSheet *sheet, NSInteger buttonIndex) {
        if (buttonIndex != sheet.cancelButtonIndex) {
            BOOL private = !(buttonIndex == sheet.destructiveButtonIndex);
            
            dispatch_async(dispatch_get_main_queue(), ^{
                self.values[@"private"] = @(private);
                self.values[@"completed"] = @(completed);
                
                [[LMRestKitManager sharedManager] newTaskForValues:self.values];
            });
        }
    }];
}


- (void) backPressed: (id) sender {
    // just go back
    [self exit];
}

- (void) exit {
    [self.navigationController popViewControllerAnimated:YES];
}


@end