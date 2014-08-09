//
//  LifeListViewController.m
//  Lifemax
//
//  Created by Micah Rosales on 2/9/14.
//  Copyright (c) 2014 YUCG. All rights reserved.
//

#import "NewsFeedViewController.h"
#import "LifeListViewController.h"
#import "SWRevealViewController.h"
#import "LifeListFilter.h"
#import "LifemaxHeaders.h"
#import "LMRestKitManager.h"
#import "TaskCell.h"
#import <RestKit/RestKit.h>
#import "Task+TaskAdditions.h"
#import "User.h"
#import "EditTaskViewController.h"
#import "GoalViewController.h"
#import "LMHttpClient.h"
#import "NSString+MD5.h"
#import "FeedUserTaskCell.h"
#import "Hashtag.h"
#import <OHAlertView/OHAlertView.h>
#import <OHActionSheet/OHActionSheet.h>

@interface NewsFeedViewController () <LifeListFilterDelegate, NSFetchedResultsControllerDelegate, EditTaskDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate>
@property (strong, nonatomic) IBOutlet LifeListFilter *tableFilterView;

@property BOOL filterExpanded;
@property NSArray *filterTitles;
@property (strong, nonatomic) NSDateFormatter *formatter;

@property (nonatomic, strong) NSFetchedResultsController *fetchedResultsController;
@property (nonatomic, strong) NSIndexPath *selectedIndexPath;
@property BOOL selectedUserTask;
@property (nonatomic, strong) NSPredicate *root_predicate;
@property NSInteger lastCell;
@property NSInteger scrollDirection;
@end

@implementation NewsFeedViewController

-(NSDateFormatter *)formatter {
    if (!_formatter) {
        _formatter = [[NSDateFormatter alloc]init];
        _formatter.locale = [NSLocale currentLocale];
    }
    return _formatter;
}

- (id)initWithStyle:(UITableViewStyle)style
{
    
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
    
//    self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier];
//    if (self)
//    {
//        self.contentView.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
//        [self loadViews];
//        [self constrainViews];
//    }
//    return self;
}

- (void) fetchHashTags:(id)sender {
    NSFetchRequest *hashtagfetch = [[NSFetchRequest alloc] initWithEntityName:@"Hashtag"];
    NSArray *hashtagObjs = [[RKManagedObjectStore defaultStore].mainQueueManagedObjectContext executeFetchRequest:hashtagfetch error:nil];
    NSMutableArray *hashtags = [NSMutableArray array];
    for (Hashtag *tag in hashtagObjs) {
        [hashtags addObject:tag.name];
    }
    
    self.filterTitles = [@[@"Show Everything"] arrayByAddingObjectsFromArray:hashtags];
    [self.tableFilterView reload];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.scrollDirection = 0;
    self.lastCell = 0;
    if (self.isStoryController)
        self.title = NSLocalizedString(@"My Story", nil);
    else if (self.isSuggestionsController)
        self.title = NSLocalizedString(@"Max Suggests", nil);
    else
        self.title = NSLocalizedString(@"News Feed", nil);

//    self.tableView.tableHeaderView.translatesAutoresizingMaskIntoConstraints = NO;
    
    //filter view
    self.filterExpanded = NO;
    [self fetchHashTags:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(fetchHashTags:) name:LIFEMAX_NOTIFICATION_HASHTAG_RETRIEVE_SUCCESS object:nil];
    [self.tableFilterView setTitle:self.filterTitles[0]];
    [self.tableFilterView.tapgr addTarget:self action:@selector(toggleFilter)];
    
    
    SWRevealViewController *revealController = [self revealViewController];
    self.navigationController.navigationBar.translucent = NO;
    
//    if (!self.isSuggestionsController) {
        self.tableView.contentInset = UIEdgeInsetsMake(0, 0, -60, 0);
//    }
    
    [revealController tapGestureRecognizer];
    
    UIBarButtonItem *revealButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"reveal-icon.png"]
                                                                         style:UIBarButtonItemStyleBordered target:revealController action:@selector(revealToggle:)];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addbuttonPressed:)];
    
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(configureFRC) name:LIFEMAX_INITIALIZED_CD_KEY object:nil];
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refresh:) name:LIFEMAX_INITIALIZED_CD_KEY object:nil];
    
    self.navigationItem.leftBarButtonItem = revealButtonItem;
    
    self.refreshControl = [[UIRefreshControl alloc]init];
    [self.refreshControl addTarget:self action:@selector(refresh:) forControlEvents:UIControlEventValueChanged];
}
- (void)loginSuccess:(id)object {
    [self loadData];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loginSuccess:) name:LIFEMAX_NOTIFICATION_NAME_LOGIN_SUCCESS object:nil];
    [self performFetch];
    [self loadData];
}
-(void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

//- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
//    if ([scrollView.panGestureRecognizer translationInView:scrollView.superview].y < 0) {
//        self.scrollDirection = 1;
//    } else {
//        self.scrollDirection = -1;
//    }
//}
//
//- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
//    if (self.isSuggestionsController && decelerate == NO) {
//        [self centerTable];
//    }
//}
//
//- (void)scrollViewWillBeginDecelerating:(UIScrollView *)scrollView {
//    if (self.isSuggestionsController) {
//        [self centerTable];
//    }
//}

//- (void)centerTable {
//    NSIndexPath *newIndexPath = [self.tableView indexPathForRowAtPoint:CGPointMake(CGRectGetMidX(self.tableView.bounds), CGRectGetMidY(self.tableView.bounds))];
//    
//    if (self.scrollDirection > 0){
//        NSInteger count = (int) [[self tableView] numberOfRowsInSection:0]-1;
//        if (self.lastCell < count) {
//            newIndexPath = [NSIndexPath indexPathForRow:self.lastCell + 1 inSection:0];
//        }
//    } else if (self.scrollDirection < 0) {
//        newIndexPath = [NSIndexPath indexPathForRow:self.lastCell - 1 inSection:0];
//    }
//
//    if (self.lastCell != 0 || self.scrollDirection >= 0){
//        [self.tableView scrollToRowAtIndexPath:newIndexPath atScrollPosition:UITableViewScrollPositionBottom animated:YES];
//        self.lastCell = newIndexPath.row;
//    }
//    self.scrollDirection = 0;
//}


- (NSFetchedResultsController *) fetchedResultsController {
    if(!_fetchedResultsController) {
        NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Task"];
        NSSortDescriptor *descriptor1 = [NSSortDescriptor sortDescriptorWithKey:@"displaydate" ascending:NO];
        NSSortDescriptor *descriptor2 = [NSSortDescriptor sortDescriptorWithKey:@"task_id" ascending:NO];
        fetchRequest.sortDescriptors = @[descriptor1, descriptor2];
        if(self.isStoryController) {
            id userid = [[LMRestKitManager sharedManager] defaultUserId];
            if (!userid) return nil;
            fetchRequest.predicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[[NSPredicate predicateWithFormat:@"user.user_id = %@", userid], [NSPredicate predicateWithFormat:@"completed = %@", @(YES)]]];
            self.root_predicate = fetchRequest.predicate;
        }else if (self.isSuggestionsController) {
            fetchRequest.predicate = [NSPredicate predicateWithFormat:@"user.user_id = 0"];
            self.root_predicate = fetchRequest.predicate;
        }else {
            fetchRequest.predicate = [NSPredicate predicateWithFormat:@"completed = %@", @(YES)];
            self.root_predicate = fetchRequest.predicate;

        }
        NSError *error = nil;
        
        NSManagedObjectContext *ctx = [RKManagedObjectStore defaultStore].mainQueueManagedObjectContext;
        
        if (!ctx) {
            return nil;
        }
        // Setup fetched results
        _fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                        managedObjectContext:ctx
                                                                          sectionNameKeyPath:nil
                                                                                   cacheName:nil];
        [_fetchedResultsController setDelegate:self];
        BOOL fetchSuccessful = [_fetchedResultsController performFetch:&error];
        
        if (! fetchSuccessful) {
            //NSLog(@"ERROR prefetching content");
        }

    }
    return _fetchedResultsController;
}


- (void) loadData {
    //NSFetchedResultsController should automatically refresh
    //just trigger the manager to fetch from the server
    dispatch_async(dispatch_get_main_queue(), ^{
        id user = [[LMRestKitManager sharedManager] defaultUserId];
        NSString *hashToken = [[LMRestKitManager sharedManager] defaultUserHashToken];
        __weak id ws = self;
        
        NSString *type = self.isSuggestionsController ? NSLocalizedString(@"maxsuggests", nil) : NSLocalizedString(@"newsfeed", nil);

        [[LMRestKitManager sharedManager] fetchFeedTasksForUser:user hashtag:nil maxResults:50 hashtoken:hashToken type:type completion:^(NSArray *results, NSError *error) {
            id ss = ws;
            [ss performSelector:@selector(performFetch) withObject:nil afterDelay:.05];
        }];
    });

}

- (void) performFetch {
    dispatch_async(dispatch_get_main_queue(), ^{
        BOOL fetchSuccessful = [self.fetchedResultsController performFetch:nil];
        
        if(fetchSuccessful){
//            self.tableView.tableFooterView.hidden = !([self.fetchedResultsController.fetchedObjects count] == 0); //JASONJASONJASON
            if ([self.fetchedResultsController.fetchedObjects count] != 0){
                self.tableView.tableFooterView.hidden = TRUE;
                self.tableView.rowHeight = self.view.bounds.size.height - 45;
            } else {
                self.tableView.tableFooterView.hidden = FALSE;
                self.tableView.rowHeight = 100;
            }
            [self.tableView reloadData];
        }
        else{
            NSLog(@"ERROR FETCHING!");
        }
    });
}


- (IBAction)refresh:(id)sender
{
    // Load the object model via RestKit
    if (self.refreshControl.refreshing) {
        
        //prefetch the cached data, then load from server
        [self performFetch];
        [self loadData];
        //end the spinner after a shory timeout
        [self.refreshControl performSelector:@selector(endRefreshing) withObject:nil afterDelay:.4];
    }
    else {
        [self.refreshControl endRefreshing];
    }
}



- (void)toggleFilter
{
    [self.tableView beginUpdates];
    [self.tableView setTableHeaderView:self.tableFilterView];
    
    [UIView animateWithDuration:.5f animations:^{
        if (self.filterExpanded) {
            [self.tableFilterView collapseView];
            [self.tableView setScrollEnabled:YES];
        }
        else {
            [self.tableFilterView expandViewToFill:self.tableView];
            [self.tableView setScrollEnabled:NO];
        }
        [self.tableView setTableHeaderView:self.tableFilterView];
    }];
    [self.tableView endUpdates];
    
    self.filterExpanded = !self.filterExpanded;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void) filterForHashtag:(NSString *)hashtag {
    NSPredicate *predicate = nil;
    if (hashtag) {
        predicate = [NSPredicate predicateWithFormat:@"hashtag = %@", hashtag];
    }
    if (predicate) {
        if(self.root_predicate)
            self.fetchedResultsController.fetchRequest.predicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[self.root_predicate, predicate]];
        else     self.fetchedResultsController.fetchRequest.predicate = predicate;

    } else if(self.root_predicate)
        self.fetchedResultsController.fetchRequest.predicate = self.root_predicate;
    else self.fetchedResultsController.fetchRequest.predicate = nil;


    [self performFetch];
}


#pragma mark - LifeList Filter Delegate
-(void)filter:(LifeListFilter *)filter didSelectRow:(NSInteger)row {
    if(row > 0)
        [self filterForHashtag:[self filter:filter titleForRow:row]];
    else
        [self filterForHashtag:nil];
    
    [self toggleFilter];
}

-(NSInteger)numberOfRowsInFilter:(LifeListFilter *)filter {
    return self.filterTitles.count;
}

-(NSString *)filter:(LifeListFilter *)filter titleForRow:(NSInteger)row {
    if (row < self.filterTitles.count) {
        return self.filterTitles[row];
    }
    return @"";
}

#pragma mark - Table view delegate

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    Task *task = [self.fetchedResultsController objectAtIndexPath:indexPath];
    self.selectedIndexPath = indexPath;
    if([task.user.user_id isEqualToNumber:[[LMRestKitManager sharedManager] defaultUserId]]) {
        [self performSegueWithIdentifier:@"edit_task" sender:task];
    } else {
        [self performSegueWithIdentifier:@"view_task" sender:self];
    }
    
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}

-(void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
    
    
}


- (IBAction)addbuttonPressed:(id)sender {
    
    if([sender isKindOfClass:[UIBarButtonItem class]]){
        //dont do anything
        self.selectedIndexPath = nil;
        [self performSegueWithIdentifier:@"edit_task" sender:self];
    } else {
        self.selectedIndexPath = [NSIndexPath indexPathForRow:[sender tag] inSection:0];
        [self promtTaskCreationWithComplete:NO];
    }
    
}
- (IBAction)donebuttonPressed:(id)sender {
    self.selectedIndexPath = [NSIndexPath indexPathForRow:[sender tag] inSection:0];
    [self promtTaskCreationWithComplete:YES];
}

- (IBAction)removebuttonPressed:(id)sender {
    self.selectedIndexPath = [NSIndexPath indexPathForRow:[sender tag] inSection:0];
    [self promtTaskDeletion];
}

- (void)promtTaskDeletion {
    [OHActionSheet showSheetInView:self.view
                             title:NSLocalizedString(@"Remove Task from Suggestions", nil)
                 cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
            destructiveButtonTitle:NSLocalizedString(@"Remove Forever", nil)
                otherButtonTitles:nil
                        completion:^(OHActionSheet *sheet, NSInteger buttonIndex)
    {
        if (buttonIndex != sheet.cancelButtonIndex) {
            
            Task *task = [self.fetchedResultsController objectAtIndexPath:self.selectedIndexPath];
            if (task){
                [task.managedObjectContext deleteObject:task];
                [[LMRestKitManager sharedManager] hideSuggestion:task];
            }
            
        }
    }];
}


- (void)promtTaskCreationWithComplete:(BOOL)completed {
    
    [OHActionSheet showSheetInView:self.view title:NSLocalizedString(@"New Goal Privacy", nil) cancelButtonTitle:NSLocalizedString(@"Cancel", nil) destructiveButtonTitle:NSLocalizedString(@"Share with friends", nil) otherButtonTitles:@[NSLocalizedString(@"Make Private", nil)] completion:^(OHActionSheet *sheet, NSInteger buttonIndex) {
        if (buttonIndex != sheet.cancelButtonIndex) {
            BOOL private = !(buttonIndex == sheet.destructiveButtonIndex);
            
            dispatch_async(dispatch_get_main_queue(), ^{
                Task *task = [self.fetchedResultsController objectAtIndexPath:self.selectedIndexPath];
                NSMutableDictionary *values = [NSMutableDictionary dictionary];
                if(task.name) values[@"name"] = task.name;
                if(task.hashtag) values[@"hashtag"] = task.hashtag;
                if(task.desc) values[@"desc"] = task.desc;
                if(task.pictureurl) values[@"pictureurl"] = task.pictureurl;
//                if(task.private) values[@"private"] = @(private);

                values[@"private"] = @(private);
                values[@"completed"] = @(completed);
                
                [[LMRestKitManager sharedManager] newTaskForValues:values];
            });
            
            Task *task = [self.fetchedResultsController objectAtIndexPath:self.selectedIndexPath];
            if (task){
                [task.managedObjectContext deleteObject:task];
                [[LMRestKitManager sharedManager] hideSuggestion:task];
            }
        }
    }];
}

#pragma mark - Table view data source


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return [self.fetchedResultsController.sections count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    id<NSFetchedResultsSectionInfo> sectionInfo = [self.fetchedResultsController.sections objectAtIndex:section];
    return [sectionInfo numberOfObjects];
    
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
//    if (self.isSuggestionsController){
//        if (indexPath.row == 0){
//            return self.view.bounds.size.height - 45;
//        } else {
//            return self.view.bounds.size.height;
//        }
//    } else {
        return 300;
//    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    Task *task = [self.fetchedResultsController objectAtIndexPath:indexPath];
    
    //user id == 0 means it is a suggestion
    BOOL suggestion = [task.user.user_id isEqualToNumber:@(0)];
    CellIdentifier = (suggestion) ? @"feed-suggestion":  @"feed-user";
    
    
    FeedUserTaskCell *feedCell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    BOOL usermatch = [task.user.user_id isEqualToNumber:[[LMRestKitManager sharedManager] defaultUserId]];

    feedCell.selectionStyle = usermatch ? UITableViewCellSelectionStyleDefault : UITableViewCellSelectionStyleNone;
    
    [feedCell.addButton addTarget:self action:@selector(addbuttonPressed:) forControlEvents:UIControlEventTouchUpInside];
    feedCell.addButton.tag = indexPath.row;
    
    [feedCell.doneButton addTarget:self action:@selector(donebuttonPressed:) forControlEvents:UIControlEventTouchUpInside];
    feedCell.doneButton.tag = indexPath.row;
    
    [feedCell.removeButton addTarget:self action:@selector(removebuttonPressed:) forControlEvents:UIControlEventTouchUpInside];
    feedCell.removeButton.tag = indexPath.row;
    
    if ([feedCell.addButton.superview.gestureRecognizers count] == 0) {
        UIGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:nil action:nil];
        tap.cancelsTouchesInView = YES;
        UIGestureRecognizer *press = [[UILongPressGestureRecognizer alloc] initWithTarget:nil action:nil];
        press.cancelsTouchesInView = YES;
        [press setDelaysTouchesBegan:YES];
        UIGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:nil action:nil];
        pan.cancelsTouchesInView = YES;
        
        [feedCell.addButton.superview addGestureRecognizer:tap];
        [feedCell.addButton.superview addGestureRecognizer:press];
        [feedCell.addButton.superview addGestureRecognizer:pan];
    }
    
    
    [feedCell updateForTask:task];
    
    return feedCell;
}

#pragma mark NSFetchedResultsControllerDelegate methods

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
    [self.tableView beginUpdates];
}

- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type {
    switch(type) {
        case NSFetchedResultsChangeInsert:
            [self.tableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationAutomatic];
            break;
        case NSFetchedResultsChangeDelete:
            [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationAutomatic];
            break;
    }
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath*)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath*)newIndexPath {
    
    UITableView* tableView = self.tableView;
    tableView.userInteractionEnabled = NO;
    switch(type) {
        case NSFetchedResultsChangeInsert:
            [tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeUpdate:
            [tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];

            break;
            
        case NSFetchedResultsChangeMove:
            [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
            if (newIndexPath.row >= 0) {
                [tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
            }
            break;
    }
    tableView.userInteractionEnabled = YES;
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    [self.tableView endUpdates];
}



// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return NO;
}



// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        Task *t = [self.fetchedResultsController objectAtIndexPath:indexPath];
        [[LMRestKitManager sharedManager] deleteTask:t];
    }
}

#pragma mark - Navigation

// In a story board-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    if ([segue.identifier isEqualToString:@"edit_task"]){
        EditTaskViewController *editController = [segue destinationViewController];
        if(self.selectedIndexPath){
            if ([sender isKindOfClass:[Task class]]) {
                [editController setTask:sender];
            }else {
                [editController initializeWithTaskValues:[self.fetchedResultsController objectAtIndexPath:self.selectedIndexPath] fromFeed:YES];

            }
        }
        editController.delegate = self;
    } else if ([segue.identifier isEqualToString:@"view_task"]){
        GoalViewController *goalController = [segue destinationViewController];
        if(self.selectedIndexPath){
            if ([sender isKindOfClass:[Task class]]) {
                [goalController setTask:sender];
            }else {
                [goalController initializeWithTaskValues:[self.fetchedResultsController objectAtIndexPath:self.selectedIndexPath]];
                
            }
        }
//        goalController.delegate = self;
    }
}

#pragma mark - Edit Task Delegate method

-(void)editor:(EditTaskViewController *)editor didEditTaskFields:(NSDictionary *)values forTask:(Task *)task {
    if(task)
        [[LMRestKitManager sharedManager] updateTask:task withValues:values];
    else
        [[LMRestKitManager sharedManager] newTaskForValues:values];
    
}


@end
