//
//  EditTaskViewController.m
//  Lifemax
//
//  Created by Micah Rosales on 2/22/14.
//  Copyright (c) 2014 YUCG. All rights reserved.
//

#import "EditTaskViewController.h"
#import "HashtagSelector.h"
#import "EditFieldCell.h"
#import "EditDescriptionCell.h"
#import "LifemaxHeaders.h"
#import "Task.h"
#import "AppDelegate.h"
#import "UIAlertView+NSCookbook.h"
#import <RestKit/RestKit.h>
#import "LMRestKitManager.h"

#define DESCRIPTION_PLACEHOLDER_TEXT @"description"
#define CELL_HEIGHT 55

@interface EditTaskViewController () <UIScrollViewDelegate, UITextFieldDelegate, HashtagSelectorDelegate>
@property (nonatomic, strong) IBOutlet UIScrollView *contentScrollView;
@property (nonatomic, strong) IBOutlet UIButton *deleteButton;
@property (nonatomic, strong) IBOutlet UITextField *nameField;

@property (nonatomic, strong) IBOutlet HashtagSelector *hashtagSelector;

@property (nonatomic, strong) NSArray *hashtags;

@property (nonatomic, strong) NSDateFormatter *formatter;

@property (nonatomic, strong) NSMutableDictionary *values;

@property (nonatomic, strong) IBOutlet NSLayoutConstraint *heightConstraint;

@property BOOL deleted;

@end

@implementation EditTaskViewController

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
        [self updateViewForTask];
    }
}

-(void)initializeWithTaskValues :(Task *)task {
    if(task.name) self.values[@"name"] = task.name;
    if(task.task_description) self.values[@"description"] = task.task_description;
    if(task.hashtag) self.values[@"hashtag"] = task.hashtag;
    if(task.start) self.values[@"start"] = task.start;
    if(task.pictureurl) self.values[@"pictureurl"] = task.pictureurl;

}

- (void) selectActiveTag {
    NSInteger hashtagIndex = [self.hashtags indexOfObject:self.task.hashtag];

    
}

-(void) updateViewForTask {
    
    self.values[@"name"] = self.task.name ? self.task.name : @"";
    self.values[@"hashtag"] = self.task.hashtag ? self.task.hashtag : @"";
//    self.values[@"private"] = self.task.privacy
    
    self.nameField.text = self.values[@"name"];
    
    [self selectActiveTag];
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    [((AppDelegate *)([UIApplication sharedApplication].delegate)) disablePanning:self];
}



-(void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [((AppDelegate *)([UIApplication sharedApplication].delegate)) enablePanning:self];
}

-(void)awakeFromNib {
    [super awakeFromNib];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.deleted = NO;
    
    self.title = NSLocalizedString(@"Edit Task", nil);
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Save", nil) style:UIBarButtonItemStyleBordered target:self action:@selector(savePressed:)];
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Cancel", nil) style:UIBarButtonItemStyleBordered target:self action:@selector(cancelPressed:)];
    
    //configure default hashtags
    self.hashtags = LIFEMAX_HASHTAGS;
    
    [self configureHashtagSelector];
    
}

- (BOOL) validateInput
{
    if(self.values && [self.values objectForKey:@"name"] && [[self.values objectForKey:@"name"] length] > 0) {
        return YES;
    }

    return NO;
}

- (void) savePressed:(id)sender {
    [self.nameField endEditing:YES];
    BOOL validated = [self validateInput];
    if(validated) {
        [self.delegate editor:self didEditTaskFields:self.values forTask:self.task];
        [self exit];
    }
    else if ([self didInputChange]){
        UIAlertView *warn = [[UIAlertView alloc]initWithTitle:NSLocalizedString(@"Incomplete", nil)
                                                      message:NSLocalizedString(@"A task must have a title", nil)
                                                     delegate:nil
                                            cancelButtonTitle:@"OK"
                                            otherButtonTitles:nil];
        [warn show];
    } else [self exit];
}

- (void) cancelPressed: (id) sender {
    UIAlertView *cancelAlert = [[UIAlertView alloc]initWithTitle:NSLocalizedString(@"Cancel", nil)
                                                         message:@"Are you sure?\nYour changes will be lost."
                                                        delegate:nil cancelButtonTitle:NSLocalizedString(@"Cancel", nil) otherButtonTitles:NSLocalizedString(@"Discard", nil), nil];
    if([self didInputChange]) {
        [cancelAlert showWithCompletion:^(UIAlertView *alertView, NSInteger buttonIndex) {
            if(buttonIndex)
                [self exit];
        }];
    } else [self exit];

}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}


- (IBAction)deletePressed:(id)sender {
    UIAlertView *cancelAlert = [[UIAlertView alloc]initWithTitle:NSLocalizedString(@"Delete", nil)
                                                         message:@"Are you sure?\nThis cannot be undone."
                                                        delegate:nil cancelButtonTitle:NSLocalizedString(@"Cancel", nil) otherButtonTitles:NSLocalizedString(@"OK", nil), nil];
    
    [cancelAlert showWithCompletion:^(UIAlertView *alertView, NSInteger buttonIndex) {
        NSLog(@"Delete Dat!");
       
        if(self.task){
            [[LMRestKitManager sharedManager] deleteTask:self.task];
            self.deleted = YES;
            [self exit];
        }
        
    }];
}



- (void)configureHashtagSelector
{
    NSInteger viewsNeeded = self.hashtags.count / 8 + MIN((self.hashtags.count % 8), 1);
    
}

- (void)tapInScrollView {
    [self.nameField endEditing:YES];
}

-(void)scrollViewDidScroll:(UIScrollView *)scrollView {
    [self.nameField endEditing:YES];
}


// At the begin of scroll dragging, reset the boolean used when scrolls originate from the UIPageControl
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    

}

// At the end of scroll animation, reset the boolean used when scrolls originate from the UIPageControl
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    
}

-(void)textFieldDidBeginEditing:(UITextField *)textField {
    self.nameField = textField;
//    [self enableTaskEditing];
    [UIView animateWithDuration:.5 animations:^{
        self.hashtagSelector.alpha = .5;
    } completion:nil];
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    return YES;
}

-(void)textFieldDidEndEditing:(UITextField *)textField {
    
    [UIView animateWithDuration:.5 animations:^{
        self.hashtagSelector.alpha = 1;
    } completion:^(BOOL finished) {
    }];
    
    if(textField == self.nameField) {
        self.values[@"name"] = textField.text;
    }
}



-(BOOL)textFieldShouldEndEditing:(UITextField *)textField {
    return YES;
}
- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return YES;
}

-(void)hashtagSelector:(HashtagSelector *)selector buttonSelectedAtIndex:(NSInteger)index {
    [self tapInScrollView];
    NSString *hashtag = [self hashtagSelector:selector titleForButtonIndex:index];
    [self.values setObject:hashtag forKey:@"hashtag"];
}

-(NSString *)hashtagSelector:(HashtagSelector *)selector titleForButtonIndex:(NSInteger)index {
    if(index < [self.hashtags count])
        return self.hashtags[index];
    return @"";
}



- (BOOL) didInputChange {
    if([[self.values allKeys] containsObject:@"hashtag"]) {
        if ([self.values objectForKey:@"hashtag"] != self.task.hashtag) {
            NSLog(@"Hashtag is not equal : %@ != %@", self.values[@"hashtag"], self.task.hashtag);
            return YES;
        }
    } if([[self.values allKeys] containsObject:@"name"]) {
        if ([self.values objectForKey:@"name"] != self.task.name) {
            NSLog(@"name is not equal : %@ != %@", self.values[@"name"], self.task.name);
            return YES;
        }
    }
    NSLog(@"INPUT HAS NOT CHANGED.");
    return NO;
}
- (void) exit {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a story board-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}

 */

@end
