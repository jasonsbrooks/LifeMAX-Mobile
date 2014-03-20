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
#import "Hashtag.h"
#import "AppDelegate.h"
#import "UIAlertView+NSCookbook.h"
#import <RestKit/RestKit.h>
#import "LMRestKitManager.h"
#import "Checkbox.h"
#define DESCRIPTION_PLACEHOLDER_TEXT @"description"

@interface EditTaskViewController () <UIScrollViewDelegate, UITextFieldDelegate, HashtagSelectorDelegate>
@property (nonatomic, strong) IBOutlet UIScrollView *contentScrollView;
@property (nonatomic, strong) IBOutlet UIButton *deleteButton;
@property (nonatomic, strong) IBOutlet UITextField *nameField;
@property (nonatomic, strong) IBOutlet Checkbox *privacyCheckbox;
@property (nonatomic, strong) IBOutlet Checkbox *completedCheckbox;

@property (nonatomic, strong) IBOutlet HashtagSelector *hashtagSelector;

@property (nonatomic, strong) NSArray *hashtags;

@property (nonatomic, strong) NSDateFormatter *formatter;

@property (nonatomic, strong) NSMutableDictionary *values;

@property (nonatomic, strong) IBOutlet NSLayoutConstraint *heightConstraint;
@property (nonatomic, strong) IBOutlet UIView *overlayView;

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
        [self initializeWithTaskValues:task];
    }
}

-(void)initializeWithTaskValues :(Task *)task {
    NSLog(@"initialize for task: %@", task);
    if(task.name) self.values[@"name"] = task.name;
    if(task.hashtag) self.values[@"hashtag"] = task.hashtag;
//    if(task.pictureurl) self.values[@"pictureurl"] = task.pictureurl;

    if(task.private) self.values[@"private"] = task.private;
    if(task.completed) self.values[@"completed"] = task.completed;
    
    NSLog(@"Private : %@", self.values[@"private"]);
    [self updateViewForTask];
}

- (void) selectActiveTag {
    NSInteger hashtagIndex = [self.hashtags indexOfObject:self.values[@"hashtag"]];
    [self.hashtagSelector selectTag:hashtagIndex];
    
}

-(void) updateViewForTask {
    self.nameField.text = self.values[@"name"];
    self.privacyCheckbox.checked = ![self.values[@"private"] boolValue];
    self.completedCheckbox.checked = [self.values[@"completed"] boolValue];
    [self selectActiveTag];
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    [((AppDelegate *)([UIApplication sharedApplication].delegate)) disablePanning:self];
    [self updateViewForTask];
}

-(UIView *)overlayView {
    if(!_overlayView) {
        CGRect frame = self.contentScrollView.bounds;
        CGFloat offset = self.nameField.frame.origin.y + self.nameField.frame.size.height;
        frame.origin.y = offset;
        frame.size.height = frame.size.height - offset;
        _overlayView = [[UIView alloc] initWithFrame:frame];
        _overlayView.backgroundColor = [UIColor colorWithWhite:1 alpha:.3];
         UITapGestureRecognizer *tapBehind = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapInScrollView)];
        [_overlayView addGestureRecognizer:tapBehind];
    }
    return _overlayView;
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
    
    NSFetchRequest *hashtagfetch = [[NSFetchRequest alloc] initWithEntityName:@"Hashtag"];
    NSArray *hashtagObjs = [[RKObjectManager sharedManager].managedObjectStore.mainQueueManagedObjectContext executeFetchRequest:hashtagfetch error:nil];
    NSMutableArray *hashtags = [NSMutableArray array];
    for (Hashtag *tag in hashtagObjs) {
        [hashtags addObject:tag.name];
    }
    self.hashtags = hashtags;
    self.contentScrollView.translatesAutoresizingMaskIntoConstraints = NO;
    self.view.translatesAutoresizingMaskIntoConstraints = NO;
    self.hashtagSelector.translatesAutoresizingMaskIntoConstraints = NO;
    [self configureHashtagSelector];
    
    self.contentScrollView.alwaysBounceVertical = YES;
    [self.completedCheckbox addTarget:self action:@selector(completedChanged:) forControlEvents:UIControlEventTouchUpInside];
    [self.privacyCheckbox addTarget:self action:@selector(privacyChanged:) forControlEvents:UIControlEventTouchUpInside];

}

- (void)completedChanged:(Checkbox *)sender {
    BOOL completed = sender.checked;
    self.values[@"completed"] = @(completed);
}

- (void)privacyChanged:(Checkbox *)sender {
    BOOL private = !sender.checked;
    self.values[@"private"] = @(private);
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
    [self.nameField endEditing:YES];
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
    [self.hashtagSelector initialize];
}

- (void)tapInScrollView {
    NSLog(@"Tap in scroll view");
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
    [self.view addSubview:self.overlayView];
//    [self enableTaskEditing];
    [UIView animateWithDuration:.5 animations:^{
        self.hashtagSelector.alpha = .5;
    } completion:nil];
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    return YES;
}

-(void)textFieldDidEndEditing:(UITextField *)textField {
    [self.overlayView removeFromSuperview];
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
    NSString *hashtag = [self hashtagSelector:selector titleForButtonIndex:index];
    NSLog(@"Selected Hashtag: %@", hashtag);
    [self.values setObject:hashtag forKey:@"hashtag"];
}

-(NSString *)hashtagSelector:(HashtagSelector *)selector titleForButtonIndex:(NSInteger)index {
    if(index < [self.hashtags count])
        return self.hashtags[index];
    return @"";
}

-(NSInteger)hashtagSelectorNumberOfTags:(HashtagSelector *)selector {
    return [self.hashtags count];
}



- (BOOL) didInputChange {
    return
    (self.values[@"hashtag"] && ![self.values[@"hashtag"] isEqualToString:self.task.hashtag]) ||
    (self.values[@"name"] && ![self.values[@"name"] isEqualToString:self.task.name]) ||
    (self.values[@"private"] && [self.task.private boolValue] != [self.values[@"private"] boolValue]) ;
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
