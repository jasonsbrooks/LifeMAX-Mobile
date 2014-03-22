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
#import "Hashtag.h"
#import "EditTaskViewController.h"
#import "LMHttpClient.h"
#import "NSString+MD5.h"
#import <OHActionSheet/OHActionSheet.h>
#import <OHAlertView/OHAlertView.h>
#import "NSObject+ObjCSwitch.h"

@interface LifeListViewController () <LifeListFilterDelegate, NSFetchedResultsControllerDelegate, EditTaskDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate>
@property (strong, nonatomic) IBOutlet LifeListFilter *tableFilterView;
@property BOOL filterExpanded;
@property NSArray *filterTitles;

@property (strong, nonatomic) NSDateFormatter *formatter;

@property (nonatomic, strong) NSFetchedResultsController *fetchedResultsController;
@property (nonatomic, strong) NSIndexPath *selectedIndexPath;
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
    
    self.title = NSLocalizedString(@"Things I Want To Do", nil);
    
    [self fetchedResultsController];
    
    //filter view
    self.filterExpanded = NO;
    [self fetchHashTags:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(fetchHashTags:) name:LIFEMAX_NOTIFICATION_HASHTAG_RETRIEVE_SUCCESS object:nil];
    [self.tableFilterView setTitle:self.filterTitles[0]];
    [self.tableFilterView.tapgr addTarget:self action:@selector(toggleFilter)];
    
    SWRevealViewController *revealController = [self revealViewController];
    
    
//    [revealController panGestureRecognizer];
    [revealController tapGestureRecognizer];
    
    UIBarButtonItem *revealButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"reveal-icon.png"]
                                                                         style:UIBarButtonItemStyleBordered target:revealController action:@selector(revealToggle:)];

    self.navigationItem.leftBarButtonItem = revealButtonItem;

    self.navigationController.navigationBar.translucent = NO;
    
    self.refreshControl = [[UIRefreshControl alloc]init];
    [self.refreshControl addTarget:self action:@selector(refresh:) forControlEvents:UIControlEventValueChanged];

}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(performFetch) name:LIFEMAX_NOTIFICATION_NAME_LOGIN_SUCCESS object:nil];
}

- (NSFetchedResultsController *) fetchedResultsController {
    if(!_fetchedResultsController) {
        id user_id = [[LMRestKitManager sharedManager] defaultUserId];;
        
        if(!user_id) return nil;
        
        NSFetchRequest *userFetch = [NSFetchRequest fetchRequestWithEntityName:@"User"];
        userFetch.predicate = [NSPredicate predicateWithFormat:@"user_id = %@", user_id];
        
        NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Task"];
        NSSortDescriptor *descriptor1 = [NSSortDescriptor sortDescriptorWithKey:@"completed" ascending:YES];
        NSSortDescriptor *descriptor2 = [NSSortDescriptor sortDescriptorWithKey:@"displaydate" ascending:NO];
        NSSortDescriptor *descriptor3 = [NSSortDescriptor sortDescriptorWithKey:@"task_id" ascending:NO];
        
        fetchRequest.sortDescriptors = @[descriptor1,descriptor2, descriptor3];
        NSError *error = nil;
        
        NSManagedObjectContext *ctx = [RKManagedObjectStore defaultStore].mainQueueManagedObjectContext;
        
        if (!ctx) {
            return nil;
        }
        
        fetchRequest.predicate = [NSPredicate predicateWithFormat:@"user.user_id = %@", user_id];
        
        
        // Setup fetched results
        _fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                        managedObjectContext:ctx
                                                                          sectionNameKeyPath:nil
                                                                                   cacheName:nil];
        [_fetchedResultsController setDelegate:self];
        
        BOOL fetchSuccessful = [_fetchedResultsController performFetch:&error];
        
        if (! fetchSuccessful) {
//            NSLog(@"Prefetch did not work.");
        }
    }
    
    return _fetchedResultsController;
    
}


- (void) loadData {
    //NSFetchedResultsController should automatically refresh
    //just trigger the manager to fetch from the server
    [[LMRestKitManager sharedManager] fetchTasksForDefaultUserOnCompletion:^(BOOL success, NSError *error) {
        if (success) {
            [self performFetch];
        }
    }];
}

- (void) performFetch {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSError *error = nil;
        BOOL fetchSuccessful = [self.fetchedResultsController performFetch:&error];
        
        if(fetchSuccessful)
            [self.tableView reloadData];
        else
            NSLog(@"[LM-ERROR]: Core Data fetch error: %@", [error localizedDescription]);
    });
}


- (IBAction)refresh:(id)sender
{
    // Load the object model via RestKit
    if (self.refreshControl.refreshing) {
        
        //prefetch the cached data, then load from server
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
    [cell updateWithTask:task];
    [cell setCheckboxTarget:self action:@selector(checkboxTapped:)];
        
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
            [(TaskCell *)[tableView cellForRowAtIndexPath:indexPath] updateWithTask:[self.fetchedResultsController objectAtIndexPath:indexPath]];
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
    self.selectedIndexPath = indexpath;
    
    [self takePhoto];
    
}

- (IBAction)takePhoto {
    
    
    [OHActionSheet showSheetInView:self.view
                             title:NSLocalizedString(@"Choose photo", nil)
                 cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
            destructiveButtonTitle:NSLocalizedString(@"Camera", nil)
                 otherButtonTitles:@[NSLocalizedString(@"Camera roll", nil), NSLocalizedString(@"No photo", nil) ]
                        completion:^(OHActionSheet *sheet, NSInteger buttonIndex) {
                            
                            if(sheet.cancelButtonIndex == buttonIndex) {

                            } else if (sheet.destructiveButtonIndex == buttonIndex) {
                                

                                if([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
                                    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
                                    picker.delegate = self;
                                    picker.allowsEditing = YES;
                                    
                                    picker.sourceType = UIImagePickerControllerSourceTypeCamera;
                    
                                    [self presentViewController:picker animated:YES completion:NULL];
                                } else {
                                    [OHAlertView showAlertWithTitle:@"Camera not supported" message:@"Sorry, this device does not support the usage of a camera." dismissButton:@"OK"];
                                }
                            } else if ((buttonIndex - sheet.firstOtherButtonIndex) == 0) {
                                UIImagePickerController *picker = [[UIImagePickerController alloc] init];
                                picker.delegate = self;
                                picker.allowsEditing = YES;
                                picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
                                
                                [self presentViewController:picker animated:YES completion:NULL];
                            } else if ((buttonIndex - sheet.firstOtherButtonIndex) == 1) {
                                [self imagePickerController:nil didFinishPickingMediaWithInfo:nil];
                            }
                            
                        }];
    

    
}

-(void)editor:(EditTaskViewController *)editor didEditTaskFields:(NSDictionary *)values forTask:(Task *)task {
    
    if(task)
        [[LMRestKitManager sharedManager] updateTask:task withValues:values];
    else
        [[LMRestKitManager sharedManager] newTaskForValues:values];
    
}


-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    Task *task = [self.fetchedResultsController objectAtIndexPath:self.selectedIndexPath];

    if(info) {
        UIImage *pickedImageEdited = [info objectForKey:UIImagePickerControllerEditedImage];
        [[LMRestKitManager sharedManager] uploadPhoto:pickedImageEdited forTask:task];
        
        
        //do your stuff
        [self dismissViewControllerAnimated:YES completion:nil];

    } else {
        //chose no photo, just mark as complete
        [[LMRestKitManager sharedManager] updateTask:task withValues:@{@"completed" : @(YES), @"pictureurl" : @""}];
    }
    
}

-(void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [self dismissViewControllerAnimated:YES completion:nil];
}


@end
