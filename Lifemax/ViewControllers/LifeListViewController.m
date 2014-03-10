//
//  LifeListViewController.m
//  Lifemax
//
//  Created by Micah Rosales on 2/9/14.
//  Copyright (c) 2014 YUCG. All rights reserved.
//

#import "LifeListViewController.h"
#import "SWRevealViewController.h"
#import "LifeListFilter.h"
#import "LifemaxHeaders.h"
#import "LMRestKitManager.h"
#import "TaskCell.h"
#import <RestKit/RestKit.h>
#import "Task.h"
#import "EditTaskViewController.h"


static void RKTwitterShowAlertWithError(NSError *error)
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                    message:[error localizedDescription]
                                                   delegate:nil
                                          cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alert show];
}

@interface LifeListViewController () <LifeListFilterDelegate, NSFetchedResultsControllerDelegate, EditTaskDelegate>
@property (strong, nonatomic) IBOutlet LifeListFilter *tableFilterView;
@property BOOL filterExpanded;
@property NSArray *filterTitles;

@property (strong, nonatomic) NSDateFormatter *formatter;

@property (nonatomic, strong) NSFetchedResultsController *fetchedResultsController;

@end

@implementation LifeListViewController

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

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.locale = [NSLocale currentLocale];
    dateFormatter.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
    dateFormatter.dateFormat = @"yyyy-MM-dd'T'hh:mm:ssZ";
    [self configureFRC];

    self.filterExpanded = NO;
    
    self.filterTitles = [@[@"all"] arrayByAddingObjectsFromArray:LIFEMAX_HASHTAGS];
    
    [self.tableFilterView setTitle:self.filterTitles[0]];

    
    
    [self.tableFilterView.tapgr addTarget:self action:@selector(toggleFilter)];
//    [self.tableFilterView addGestureRecognizer: [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(toggleFilter)]];
    
    SWRevealViewController *revealController = [self revealViewController];
    
    
    [revealController panGestureRecognizer];
    [revealController tapGestureRecognizer];
    
    UIBarButtonItem *revealButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"reveal-icon.png"]
                                                                         style:UIBarButtonItemStyleBordered target:revealController action:@selector(revealToggle:)];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(configureFRC) name:LIFEMAX_INITIALIZED_CD_KEY object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refresh:) name:LIFEMAX_INITIALIZED_CD_KEY object:nil];

    self.navigationItem.leftBarButtonItem = revealButtonItem;
    
    self.refreshControl = [[UIRefreshControl alloc]init];
    [self.refreshControl addTarget:self action:@selector(refresh:) forControlEvents:UIControlEventValueChanged];
    [self filterForHashtag:nil];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self performFetch];
    [self loadData];
}

- (void) configureFRC {
    
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Task"];
    NSSortDescriptor *descriptor = [NSSortDescriptor sortDescriptorWithKey:@"start" ascending:NO];
    fetchRequest.sortDescriptors = @[descriptor];
    NSError *error = nil;
    
    NSManagedObjectContext *ctx = [RKManagedObjectStore defaultStore].mainQueueManagedObjectContext;
    
    if (!ctx) {
        return;
    }
    // Setup fetched results
    self.fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                        managedObjectContext:ctx
                                                                          sectionNameKeyPath:nil
                                                                                   cacheName:nil];
    [self.fetchedResultsController setDelegate:self];
    BOOL fetchSuccessful = [self.fetchedResultsController performFetch:&error];
    
    if (! fetchSuccessful) {
        RKTwitterShowAlertWithError(error);
    }
}


- (void) loadData {
    //NSFetchedResultsController should automatically refresh
    //just trigger the manager to fetch from the server
    [[LMRestKitManager sharedManager] fetchTasksForDefaultUser];
}

- (void) performFetch {
    dispatch_async(dispatch_get_main_queue(), ^{
        BOOL fetchSuccessful = [self.fetchedResultsController performFetch:nil];
        
        if(fetchSuccessful)
            [self.tableView reloadData];
        else
            NSLog(@"ERROR FETCHING!");
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
    self.fetchedResultsController.fetchRequest.predicate = predicate;
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
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
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

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"taskCell";
    
    TaskCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    Task *task = [self.fetchedResultsController objectAtIndexPath:indexPath];

    [cell setCheckboxTarget:self action:@selector(checkboxTapped:)];
    cell.title = task.name ? task.name : @"Task Name";
    cell.subtitle = task.hashtag;
    
    [cell setTaskImageFromUrl: task.pictureurl];
    
    
    [self.formatter setDateFormat:@"MM/dd"];
    if(task.start)
        cell.date = [self.formatter stringFromDate: task.start];
    else
        cell.date = nil;
    
    [self.formatter setDateFormat:@"h:mm a"];
    if(task.start)
        cell.time = [self.formatter stringFromDate:task.start];
    else
        cell.time = nil;
    if(task.pictureurl)
        [cell setTaskImageFromUrl:task.pictureurl];
    
    return cell;
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
//            [(NewsItemCell*)[tableView cellForRowAtIndexPath:indexPath] updateWithNews:[self.fetchedResultsController objectAtIndexPath:indexPath]];
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
 return YES;
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
     editController.task = [self.fetchedResultsController objectAtIndexPath:[self.tableView indexPathForSelectedRow]];
     editController.delegate = self;
 }

#pragma mark - Checkbox target method

- (void) checkboxTapped:(id)sender {
    NSIndexPath *indexpath = [self.tableView indexPathForCell:sender];
    NSLog(@"CheckboxTapped: %@",indexpath );
    
//    [
}

-(void)editor:(EditTaskViewController *)editor didEditTaskFields:(NSDictionary *)values forTask:(Task *)task {
//    if(self.values && [self didInputChange]){
//        NSLog(@"New Task!");
//        [[LMRestKitManager sharedManager] newTaskForValues:self.values];
//        if(self.task)
//            [[LMRestKitManager sharedManager] deleteTask:self.task];
//    }
    
    NSLog(@"Editor Did make changes!: %@", values);
    
    [[LMRestKitManager sharedManager] newTaskForValues:values];
    if(task)
        [[LMRestKitManager sharedManager] deleteTask:task];
    
    [[LMRestKitManager sharedManager] fetchTasksForDefaultUser];

}




@end
