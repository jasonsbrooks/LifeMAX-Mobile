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
#import "LifemaxHeaders.h"
#import "Task.h"


@interface EditTaskViewController () <UIAlertViewDelegate, UIScrollViewDelegate, UITextFieldDelegate, HashtagSelectorDelegate>
@property (nonatomic, strong) IBOutlet UIScrollView *hashtagScrollView;
@property (nonatomic, strong) IBOutlet UIView *scrollViewContainer;

@property (nonatomic, weak) UITextField *activeTextField;

@property (nonatomic, strong) NSArray *hashtags;
@property (nonatomic, strong) IBOutlet UIPageControl *pagingControl;
@property (nonatomic, strong) NSDateFormatter *formatter;

@property (nonatomic, strong) NSMutableArray *values;


@property BOOL pagingControlUsed;
@end

@implementation EditTaskViewController

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

- (void) selectActiveTag {
    NSInteger hashtagIndex = [self.hashtags indexOfObject:self.task.hashtag];
    NSInteger numsections = self.hashtags.count / 8 + MIN((self.hashtags.count % 8), 1);
    NSIndexPath *taskIndexPath = [NSIndexPath indexPathForRow: hashtagIndex % numsections inSection: hashtagIndex / numsections];
    NSLog(@"select task index : %@", taskIndexPath);
    
    for (HashtagSelector *selector in self.hashtagScrollView.subviews) {
        NSInteger selectorIndex = self.hashtagScrollView.tag - 10;
        if (selectorIndex >= 0){
            NSLog(@"Configuring view :%d", selectorIndex);
            if(selectorIndex == taskIndexPath.section) {
                [selector selectTag:taskIndexPath.row];
            } else {
                [selector selectTag:0];
            }
        }
    }
}

-(void) updateViewForTask {
    [self.tableView reloadData];
   
    [self selectActiveTag];
}

-(void)viewWillAppear:(BOOL)animated {
    self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = NSLocalizedString(@"Edit Task", nil);
    
    //replace the back button with a cancel one that requires confirmation
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                         target:self
                                                                                         action:@selector(confirmCancel)];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                                         target:self
                                                                                         action:@selector(donePressed)];

    

    //configure default hashtags -> should probably go in a constant somewhere
    self.hashtags = LIFEMAX_HASHTAGS;
    
    [self configureHashtagSelector];
    
}

- (void)donePressed {
    NSDictionary *taskValues = @{@"taskTitle": (self.values[0] ? self.values[0] : @""),
                             @"description": (self.values[1] ? self.values[1] : @""),
                             @"date": (self.values[2] ? self.values[1] : @"")};
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
        NSLog(@"select task index : %@", taskIndexPath);
        
        if(i == taskIndexPath.section) {
            [selector selectTag: i % numsections];
        } else {
            [selector selectTag:0];
        }
        
        for (HashtagSelector *selector in self.hashtagScrollView.subviews) {
            NSInteger selectorIndex = self.hashtagScrollView.tag - 10;
            if (selectorIndex >= 0){
                NSLog(@"Configuring view :%d", selectorIndex);
                
            }
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
    int page = self.pagingControl.currentPage;
    
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
    self.hashtagScrollView.alpha = 0;
    [UIView animateWithDuration:.5 animations:^{
        self.hashtagScrollView.alpha = 0;
    } completion:^(BOOL finished) {
        self.hashtagScrollView.hidden = YES;
    }];
}
-(void)textFieldDidEndEditing:(UITextField *)textField {
    self.activeTextField = nil;
    
    self.hashtagScrollView.hidden = NO;
    [UIView animateWithDuration:.5 animations:^{
        self.hashtagScrollView.alpha = 1;
    } completion:^(BOOL finished) {
    }];
    NSLog(@"Index : %d", textField.tag);
    if(textField.tag < 2) [self.values setObject:textField.text atIndexedSubscript:textField.tag];
    
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
}

-(NSString *)hashtagSelector:(HashtagSelector *)selector titleForButtonIndex:(NSInteger)index {
    
    NSInteger page = selector.tag - 10;
    index = (page * 8) + index;
    if(index < [self.hashtags count])
        return self.hashtags[index];
    return nil;
}
- (void)alertView:(UIAlertView *)alertView willDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (buttonIndex)
    {
        // The didn't press "no", so pop that view!
        [self exit];
    }
}

- (IBAction) dateValueChanged:(UIDatePicker *)sender{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
    [dateFormatter setDoesRelativeDateFormatting:YES];
    
    [self.values setObject:sender.date atIndexedSubscript:2];
    self.activeTextField.text = [dateFormatter stringFromDate:[sender date]];
}

- (BOOL) didInputChange {
    if([self.values count] > 3) {
        if ([self.values objectAtIndex:3] && [self.values objectAtIndex:3] != self.task.hashtag) {
            return YES;
        }
    } else if([self.values count] > 2) {
        if ([self.values objectAtIndex:2] && [self.values objectAtIndex:2] != self.task.start) {
            return YES;
        }
    } else if([self.values count] > 1) {
        if ([self.values objectAtIndex:1] && [self.values objectAtIndex:1] != self.task.task_description) {
            return YES;
        }
    } else if([self.values count] > 0) {
        if ([self.values objectAtIndex:0] && [self.values objectAtIndex:0] != self.task.name) {
            return YES;
        }
    }
    return NO;
}

- (void) exit {
    NSLog(@"Values: %@", self.values);
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)confirmCancel
{
    // Do whatever confirmation logic you want here, the example is a simple alert view
    
    BOOL inputChanged = [self didInputChange];
    if (!inputChanged) {
        [self exit];
        return;
    }
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Warning"
                                                    message:@"Are you sure you want to cancel?"
                                                   delegate:self
                                          cancelButtonTitle:@"No"
                                          otherButtonTitles:@"Yes", nil];
    [alert show];
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

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"editFieldCell";
    EditFieldCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    cell.textField.delegate = self;
    cell.textField.inputView = nil;
    cell.textField.text = nil;
    NSInteger row = indexPath.row;
    cell.textField.tag = row;

    if(row == 0) {
        cell.textField.placeholder = @"task";
        if(self.task){
            cell.textField.text = self.task.name;
        }
    } else if(row == 1) {
        cell.textField.placeholder = @"description";
        if(self.task){
            cell.textField.text = self.task.task_description;
        }
    } else if(row == 2) {
        cell.textField.placeholder = @"date";
        if(self.task){
            [self.formatter setDateStyle:NSDateFormatterMediumStyle];
            [self.formatter setDoesRelativeDateFormatting:YES];
            NSString *str = [self.formatter stringFromDate:self.task.start];
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
