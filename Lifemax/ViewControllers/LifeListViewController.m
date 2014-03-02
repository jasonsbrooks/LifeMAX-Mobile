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

@interface LifeListViewController () <LifeListFilterDelegate, NSFetchedResultsControllerDelegate>
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
    [self configureFRC];

    self.filterExpanded = NO;
    
    self.filterTitles = [@[@"all"] arrayByAddingObjectsFromArray:LIFEMAX_HASHTAGS];
    
    [self.tableFilterView setTitle:self.filterTitles[0]];
    
    //FILTER FOR ITEM 0!
    //
    //
    //
    //
    
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
    
//    [self.tableView setEditing:YES animated:YES];
    [self.navigationItem setRightBarButtonItem:self.editButtonItem];
    
}

- (void) configureFRC {
    // Set debug logging level. Set to 'RKLogLevelTrace' to see JSON payload
    RKLogConfigureByName("RestKit/Network", RKLogLevelError);
    RKLogConfigureByName("RestKit/ObjectMapping", RKLogLevelError);

    // Setup View and Table View
    
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
    
//    NSAssert([[self.fetchedResultsController fetchedObjects] count], @"Seeding didn't work...");
    if (! fetchSuccessful) {
        RKTwitterShowAlertWithError(error);
    }
    

}


- (void) loadData {
    //NSFetchedResultsController should automatically refresh
//    [[LMRestKitManager sharedManager] 
//    [[LMRestKitManager sharedManager] fetchTasksForDefaultUser];
}

- (IBAction)refresh:(id)sender
{
    // Load the object model via RestKit
    
    dispatch_async(dispatch_get_main_queue(), ^{
        BOOL fetchSuccessful = [self.fetchedResultsController performFetch:nil];
        NSLog(@"Fetched %d Objects Manually!",[[self.fetchedResultsController fetchedObjects] count] );
        NSLog(@"FRC CONFIG - %d sections", [self.fetchedResultsController.sections count]);
        
        for (Task *obj in [self.fetchedResultsController fetchedObjects]) {
            NSLog(@"Task %@: %@", obj.task_id,obj.name);
        }
        
        
        [self.tableView reloadData];
    });
    

//    [self loadData];
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

#pragma mark - LifeList Filter Delegate
-(void)filter:(LifeListFilter *)filter didSelectRow:(NSInteger)row {
    //DO THE FILTERING HERE!
    
    [self toggleFilter];
    NSLog(@"Selected Row : %d", row);
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
    NSLog(@"%d rows in section %d", [sectionInfo numberOfObjects], section);
    return [sectionInfo numberOfObjects];

}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"taskCell";
    
    
    NSLog(@"Cell for row at indexPath %d - %d", indexPath.section, indexPath.row);
    
    TaskCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    Task *task = [self.fetchedResultsController objectAtIndexPath:indexPath];

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
    
    NSLog(@"Cell for task: %@", task);
    
    // Configure the cell...
    
    return cell;
}

#pragma mark NSFetchedResultsControllerDelegate methods

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    [self.tableView beginUpdates];
}

- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type {
    NSLog(@"%s", __PRETTY_FUNCTION__);
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
    NSLog(@"%s", __PRETTY_FUNCTION__);
    UITableView* tableView = self.tableView;
    switch(type) {
        case NSFetchedResultsChangeInsert:
            [tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
            break;
            
        case NSFetchedResultsChangeDelete:
            [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
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
    NSLog(@"%s", __PRETTY_FUNCTION__);
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
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }
}


/*
 // Override to support rearranging the table view.
 - (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
 {
 }
 */

/*
 // Override to support conditional rearranging of the table view.
 - (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
 {
 // Return NO if you do not want the item to be re-orderable.
 return YES;
 }
 */


 #pragma mark - Navigation
 
 // In a story board-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
 {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
     EditTaskViewController *editController = [segue destinationViewController];
     editController.task = [self.fetchedResultsController objectAtIndexPath:[self.tableView indexPathForSelectedRow]];
     
 }
 




@end
