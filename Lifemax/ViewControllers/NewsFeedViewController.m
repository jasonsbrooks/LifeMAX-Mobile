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
#import "LMHttpClient.h"
#import "NSString+MD5.h"
#import "FeedUserTaskCell.h"
#import "Hashtag.h"


@interface NewsFeedViewController () <LifeListFilterDelegate, NSFetchedResultsControllerDelegate, EditTaskDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate>
@property (strong, nonatomic) IBOutlet LifeListFilter *tableFilterView;

@property BOOL filterExpanded;
@property NSArray *filterTitles;
@property (strong, nonatomic) NSDateFormatter *formatter;

@property (nonatomic, strong) NSFetchedResultsController *fetchedResultsController;
@property (nonatomic, strong) NSIndexPath *selectedIndexPath;
@property BOOL selectedUserTask;
@property (nonatomic, strong) NSPredicate *root_predicate;
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
    
    self.title = self.isStoryController ?  NSLocalizedString(@"My Story", nil) :  NSLocalizedString(@"News Feed", nil);

    
    //filter view
    self.filterExpanded = NO;
    [self fetchHashTags:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(fetchHashTags:) name:LIFEMAX_NOTIFICATION_HASHTAG_RETRIEVE_SUCCESS object:nil];
    [self.tableFilterView setTitle:self.filterTitles[0]];
    [self.tableFilterView.tapgr addTarget:self action:@selector(toggleFilter)];
    
    
    SWRevealViewController *revealController = [self revealViewController];
    self.navigationController.navigationBar.translucent = NO;
    
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


- (NSFetchedResultsController *) fetchedResultsController {
    if(!_fetchedResultsController) {
        NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Task"];
        NSSortDescriptor *descriptor1 = [NSSortDescriptor sortDescriptorWithKey:@"displaydate" ascending:NO];
        NSSortDescriptor *descriptor2 = [NSSortDescriptor sortDescriptorWithKey:@"task_id" ascending:NO];
        fetchRequest.sortDescriptors = @[descriptor1, descriptor2];
        if(self.isStoryController) {
            id userid = [[LMRestKitManager sharedManager] defaultUserId];
            if (!userid) return nil;
            fetchRequest.predicate = [NSPredicate predicateWithFormat:@"user.user_id = %@", userid];
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
        
        [[LMRestKitManager sharedManager] fetchFeedTasksForUser:user hashtag:nil maxResults:50 hashtoken:hashToken completion:^(NSArray *results, NSError *error) {
            id ss = ws;
            [ss performSelector:@selector(performFetch) withObject:nil afterDelay:.05];
        }];
    });

}

- (void) performFetch {
    dispatch_async(dispatch_get_main_queue(), ^{
        BOOL fetchSuccessful = [self.fetchedResultsController performFetch:nil];
        
        if(fetchSuccessful)
            [self.tableView reloadData];
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
    }
    
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}

-(void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
    
    
}


- (IBAction)addbuttonPressed:(id)sender {
    
    if([sender isKindOfClass:[UIBarButtonItem class]]){
        //dont do anything
        self.selectedIndexPath = nil;
    } else {
        NSIndexPath *selectedPath = [NSIndexPath indexPathForRow:[sender tag] inSection:0];
        self.selectedIndexPath = selectedPath;
    }
    
    [self performSegueWithIdentifier:@"edit_task" sender:self];
    
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
    return 300;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    Task *task = [self.fetchedResultsController objectAtIndexPath:indexPath];
    
    //user id == 0 means it is a suggestion
    BOOL suggestion = [task.user.user_id isEqualToNumber:@(0)];
    CellIdentifier = (suggestion) ?@"feed-suggestion":  @"feed-user";
    
    
    FeedUserTaskCell *feedCell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    BOOL usermatch = [task.user.user_id isEqualToNumber:[[LMRestKitManager sharedManager] defaultUserId]];

    feedCell.selectionStyle = usermatch ? UITableViewCellSelectionStyleDefault : UITableViewCellSelectionStyleNone;
    
    [feedCell.addButton addTarget:self action:@selector(addbuttonPressed:) forControlEvents:UIControlEventTouchUpInside];
    feedCell.addButton.tag = indexPath.row;
    
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
    switch(type) {
        case NSFetchedResultsChangeInsert:
            [tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeUpdate:
            [(FeedUserTaskCell *)[tableView cellForRowAtIndexPath:indexPath] updateForTask:[self.fetchedResultsController objectAtIndexPath:indexPath]];
            break;
            
        case NSFetchedResultsChangeMove:
            [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
            [tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
            break;
    }
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
        // Delete the row from the data source
        //        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
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
    EditTaskViewController *editController = [segue destinationViewController];

    if(self.selectedIndexPath){
        if ([sender isKindOfClass:[Task class]]) {
            [editController setTask:sender];
        }else {
            [editController initializeWithTaskValues:[self.fetchedResultsController objectAtIndexPath:self.selectedIndexPath] fromFeed:YES];

        }
    }

    editController.delegate = self;
}

#pragma mark - Edit Task Delegate method


-(void)editor:(EditTaskViewController *)editor didEditTaskFields:(NSDictionary *)values forTask:(Task *)task {    
    [[LMRestKitManager sharedManager] newTaskForValues:values];
    if(task)
        [[LMRestKitManager sharedManager] deleteTask:task];
    
}


@end
