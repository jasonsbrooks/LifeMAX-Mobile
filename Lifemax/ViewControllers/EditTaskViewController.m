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

@interface EditTaskViewController () <UIAlertViewDelegate, UIScrollViewDelegate, UITextFieldDelegate, UITextViewDelegate, HashtagSelectorDelegate>
@property (nonatomic, strong) IBOutlet UIScrollView *hashtagScrollView;
@property (nonatomic, strong) IBOutlet UIView *scrollViewContainer;
@property (nonatomic, strong) IBOutlet UIButton *deleteButton;

@property (nonatomic, weak) id activeTextField;

@property (nonatomic, strong) NSArray *hashtags;
@property (nonatomic, strong) IBOutlet UIPageControl *pagingControl;
@property (nonatomic, strong) NSDateFormatter *formatter;

@property (nonatomic, strong) NSMutableDictionary *values;

@property CGFloat descriptionRowHeight;
@property (nonatomic, strong) IBOutlet NSLayoutConstraint *heightConstraint;

@property BOOL madeEdits;
@property BOOL deleted;

@property BOOL pagingControlUsed;
@end

@implementation EditTaskViewController

-(NSMutableDictionary *)values {
    if(!_values)
        _values = [[NSMutableDictionary alloc]init];
    return _values;
}
- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
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
    if(task.hashtag) self.values[@"hashtag"] = task.hashtag;
    if(task.pictureurl) self.values[@"pictureurl"] = task.pictureurl;

}

- (void) selectActiveTag {
    NSInteger hashtagIndex = [self.hashtags indexOfObject:self.task.hashtag];
    NSInteger numsections = self.hashtags.count / 8 + MIN((self.hashtags.count % 8), 1);
    NSIndexPath *taskIndexPath = [NSIndexPath indexPathForRow: hashtagIndex % numsections inSection: hashtagIndex / numsections];
    
    for (HashtagSelector *selector in self.hashtagScrollView.subviews) {
        NSInteger selectorIndex = selector.tag - 10;
        if (selectorIndex >= 0){
            [selector selectTag:-1];
            if(selectorIndex == taskIndexPath.section) {
                [selector selectTag:taskIndexPath.row];
            }
        }
    }
}

-(void) updateViewForTask {
    [self.tableView reloadData];
   
    self.values[@"name"] = self.task.name ? self.task.name : @"";
    self.values[@"hashtag"] = self.task.hashtag ? self.task.hashtag : @"";
    
    [self selectActiveTag];
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
//    self.navigationItem.rightBarButtonItem = self.editButtonItem;
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
    self.madeEdits = NO;
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
    [self.activeTextField endEditing:YES];
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
    [self fixHashtagSelectorContentSize];
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

- (void)fixHashtagSelectorContentSize {
    NSInteger viewsNeeded = self.hashtags.count / 8 + MIN((self.hashtags.count % 8), 1);
    
    [self.hashtagScrollView setContentSize:CGSizeMake(viewsNeeded * self.hashtagScrollView.bounds.size.width, self.hashtagScrollView.bounds.size.height)];
}

- (void)configureHashtagSelector
{
    NSInteger viewsNeeded = self.hashtags.count / 8 + MIN((self.hashtags.count % 8), 1);
    
    [self.hashtagScrollView setContentSize:CGSizeMake(viewsNeeded * self.hashtagScrollView.bounds.size.width, self.hashtagScrollView.bounds.size.height)];

    self.pagingControl.numberOfPages = viewsNeeded;
    self.pagingControl.currentPage = 0;
    
    
    CGFloat w = self.hashtagScrollView.bounds.size.width;
    CGFloat h = self.hashtagScrollView.bounds.size.height;
    CGSize size = CGSizeMake(w - 40, h);
    
    self.hashtagScrollView.showsVerticalScrollIndicator = NO;
    
    
    for (int i = 0; i < viewsNeeded; i++) {
        CGFloat center = w * i + (w/2);
        CGRect f = CGRectMake(center - size.width / 2, 0, size.width, size.height);
        HashtagSelector *selector = [[HashtagSelector alloc]initWithFrame:f];
        selector.tag = i + 10;
        selector.delegate = self;
        [self.hashtagScrollView addSubview:selector];
        [selector reloadTagNames];
        
        NSInteger hashtagIndex = [self.hashtags indexOfObject:self.task.hashtag];
        NSInteger numsections = self.hashtags.count / 8 + MIN((self.hashtags.count % 8), 1);
        NSIndexPath *taskIndexPath = [NSIndexPath indexPathForRow: hashtagIndex % numsections inSection: hashtagIndex / numsections];
        
        if(i == taskIndexPath.section) {
            [selector selectTag: i % numsections];
        } else {
            [selector selectTag:0];
        }
        
        
    }
    
    UITapGestureRecognizer *gr = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(tapInScrollView)];
    [self.hashtagScrollView addGestureRecognizer:gr];
    [self.scrollViewContainer addGestureRecognizer:gr];
}

- (void)tapInScrollView {
    [self.activeTextField endEditing:YES];
}

-(void)scrollViewDidScroll:(UIScrollView *)scrollView {
    
    if (self.pagingControlUsed) return;
    
    [self.activeTextField endEditing:YES];
    // Switch the indicator when more than 50% of the previous/next page is visible
    CGFloat w = self.hashtagScrollView.bounds.size.width;
    int page = floor((self.hashtagScrollView.contentOffset.x -  w/ 2) / (w - 40)) + 1;
    self.pagingControl.currentPage = page;
}


// At the begin of scroll dragging, reset the boolean used when scrolls originate from the UIPageControl
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    self.pagingControlUsed = NO;
}

// At the end of scroll animation, reset the boolean used when scrolls originate from the UIPageControl
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    self.pagingControlUsed = NO;
}

- (IBAction)changePage:(id)sender
{
    NSInteger page = self.pagingControl.currentPage;
    
    // update the scroll view to the appropriate page
    CGRect frame = self.hashtagScrollView.frame;
    frame.origin.x = frame.size.width * page;
    frame.origin.y = 0;
    [self.hashtagScrollView scrollRectToVisible:frame animated:YES];
    
    // Set the boolean used when scrolls originate from the UIPageControl. See scrollViewDidScroll: above.
    self.pagingControlUsed = YES;
}

-(void)textFieldDidBeginEditing:(UITextField *)textField {
    self.activeTextField = textField;
//    [self enableTaskEditing];
    [UIView animateWithDuration:.5 animations:^{
        self.hashtagScrollView.alpha = .5;
    } completion:nil];
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    if([textField.inputView isKindOfClass:[UIDatePicker class]])
        return NO;
    
    self.madeEdits = YES;
    return YES;
}

-(void)textFieldDidEndEditing:(UITextField *)textField {
    self.activeTextField = nil;
    
    self.hashtagScrollView.hidden = NO;
    [UIView animateWithDuration:.5 animations:^{
        self.hashtagScrollView.alpha = 1;
    } completion:^(BOOL finished) {
    }];
    
    NSString *key = nil;
    if(textField.tag == 0) key = @"name";
    else if (textField.tag == 1) key = @"task_description";

    if(textField.tag < 2 && key) [self.values setObject:textField.text forKey:key];
    
}



-(BOOL)textFieldShouldEndEditing:(UITextField *)textField {
    return YES;
}
- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return TRUE;
}

-(void)hashtagSelector:(HashtagSelector *)selector buttonSelectedAtIndex:(NSInteger)index {
    [self tapInScrollView];
    NSString *hashtag = [self hashtagSelector:selector titleForButtonIndex:index];
    
    for (HashtagSelector *tagselector in self.hashtagScrollView.subviews) {
        NSInteger selectorIndex = tagselector.tag - 10;
        if (selectorIndex >= 0){
            [tagselector selectTag:-1];
            if(tagselector == selector) {
                [selector selectTag:index];
            }
        }
    }
    
    self.madeEdits = YES;
    
    [self.values setObject:hashtag forKey:@"hashtag"];
}

-(NSString *)hashtagSelector:(HashtagSelector *)selector titleForButtonIndex:(NSInteger)index {
    
    NSInteger page = selector.tag - 10;
    index = (page * 8) + index;
    if(index < [self.hashtags count])
        return self.hashtags[index];
    return nil;
}



- (IBAction) dateValueChanged:(UIDatePicker *)sender{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
    [dateFormatter setDoesRelativeDateFormatting:YES];
    
    [self.values setObject:sender.date forKey:@"start"];
    self.madeEdits = YES;

    [self.activeTextField setText: [dateFormatter stringFromDate:[sender date]]];
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

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return 3;
}


-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if(indexPath.row == 1 && self.descriptionRowHeight > 0) return self.descriptionRowHeight;
    return CELL_HEIGHT;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"editFieldCell";
    
    if(indexPath.row != 1) {
        CellIdentifier = @"editFieldCell";
        EditFieldCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
        cell.textField.delegate = self;
        cell.textField.inputView = nil;
        cell.textField.text = nil;
        NSInteger row = indexPath.row;
        cell.textField.tag = row;
        
        if(row == 0) {
            cell.textField.placeholder = @"task";
            if(self.values[@"name"]){
                cell.textField.text = self.values[@"name"];
            }
        } else if(row == 2) {
            cell.textField.placeholder = @"date";
            if(self.values[@"date"]){
                [self.formatter setDateStyle:NSDateFormatterMediumStyle];
                [self.formatter setDoesRelativeDateFormatting:YES];
                NSString *str = [self.formatter stringFromDate:self.values[@"date"]];
                cell.textField.text = str;
            }
            UIDatePicker * dp = [[UIDatePicker alloc]init];
            [dp addTarget:self action:@selector(dateValueChanged:) forControlEvents:UIControlEventValueChanged];
            dp.minimumDate = [NSDate date];
            dp.datePickerMode = UIDatePickerModeDate;
            cell.textField.inputView = dp;
        }
        // Configure the cell...
        
        return cell;

    } else {
        CellIdentifier = @"editDescriptionCell";
        EditDescriptionCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
        cell.contentView.translatesAutoresizingMaskIntoConstraints = NO;
        cell.textView.translatesAutoresizingMaskIntoConstraints = NO;
        cell.textView.delegate = self;
        cell.textView.inputView = nil;
        cell.textView.text = nil;
        NSInteger row = indexPath.row;
        cell.textView.tag = row;
        cell.textView.scrollEnabled = NO;
        cell.textView.textColor = [UIColor lightGrayColor];
        cell.textView.text = DESCRIPTION_PLACEHOLDER_TEXT;
        NSString *desc = self.values[@"description"];
        if(desc && desc > 0){
            cell.textView.textColor = [UIColor darkTextColor];
            cell.textView.text = desc;
            [cell.textView sizeThatFits:cell.textView.contentSize];
            
            
            [self textView:cell.textView shouldChangeTextInRange: NSMakeRange(0, desc.length) replacementText:self.values[@"description"]];
        }
        return cell;
    }
}

#pragma mark - UITextViewDelegate
- (void)textViewDidBeginEditing:(UITextView *)textView
{
    //so we can stop editing when something else is clicked
    self.activeTextField = textView;

    [self resizeTextView:textView];
    
    //placeholder text hack
    if ([textView.text isEqualToString:DESCRIPTION_PLACEHOLDER_TEXT]) {
        textView.text = @"";
        textView.textColor = [UIColor blackColor]; //optional
    }
    [textView becomeFirstResponder];
}

- (void)resizeTextView:(UITextView *)textView {
    [self.tableView beginUpdates];
    
    [textView sizeThatFits:textView.contentSize];
    CGFloat newHeight = textView.contentSize.height + textView.contentInset.top;
    newHeight = MAX(newHeight, CELL_HEIGHT);
    self.descriptionRowHeight = newHeight;

    CGRect footerFrame = self.tableView.tableFooterView.frame;
    footerFrame.size.height = [self footerHeight];
    self.tableView.tableFooterView.frame = footerFrame;
    [self.tableView endUpdates];
}

- (CGFloat) footerHeight {
    CGFloat selectorSize = 238;
    CGFloat contentsize = self.tableView.contentSize.height - self.tableView.tableFooterView.frame.size.height;
    if (contentsize < self.tableView.bounds.size.height) {
        return self.tableView.bounds.size.height - contentsize;
    } else return selectorSize;
}

-(BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    
    [self resizeTextView:textView];
    
    NSLog(@"Hashtag selector content width: %f", self.hashtagScrollView.contentSize.width);
    
    return YES;
}

-(void)textViewDidChange:(UITextView *)textView {
    self.madeEdits = YES;
}

-(BOOL)textViewShouldEndEditing:(UITextView *)textView {
    [textView resignFirstResponder];
    return YES;
}

-(void)textViewDidEndEditing:(UITextView *)textView {
    self.activeTextField = nil;
    
    self.hashtagScrollView.hidden = NO;
    [UIView animateWithDuration:.5 animations:^{
        self.hashtagScrollView.alpha = 1;
    } completion:^(BOOL finished) {
    }];
    
    NSString *key = nil;
    if (textView.tag == 1) key = @"task_description";
    
    if(textView.tag < 2 && key) [self.values setObject:textView.text forKey:key];


    //placeholder text hack
    if ([textView.text isEqualToString:@""]) {
        textView.text = DESCRIPTION_PLACEHOLDER_TEXT;
        textView.textColor = [UIColor lightGrayColor]; //optional
    }
    [textView resignFirstResponder];
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
