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
#import "Task.h"
#import "EditTaskViewController.h"
#import "RKTest.h"
#import "NSString+MD5.h"
#import "FeedUserTaskCell.h"

static void RKTwitterShowAlertWithError(NSError *error)
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                    message:[error localizedDescription]
                                                   delegate:nil
                                          cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alert show];
}

@interface NewsFeedViewController () <LifeListFilterDelegate, NSFetchedResultsControllerDelegate, EditTaskDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate>
@property (strong, nonatomic) IBOutlet LifeListFilter *tableFilterView;
@property BOOL filterExpanded;
@property NSArray *filterTitles;

@property (strong, nonatomic) NSDateFormatter *formatter;

@property (nonatomic, strong) NSFetchedResultsController *fetchedResultsController;
@property (nonatomic, strong) NSIndexPath *selectedIndexPath;
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

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = NSLocalizedString(@"News Feed", nil);
    
    [self configureFRC];
    
    self.filterExpanded = NO;
    
    self.filterTitles = [@[@"all"] arrayByAddingObjectsFromArray:LIFEMAX_HASHTAGS];
    
    [self.tableFilterView setTitle:self.filterTitles[0]];
    
    
    
    [self.tableFilterView.tapgr addTarget:self action:@selector(toggleFilter)];
    //    [self.tableFilterView addGestureRecognizer: [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(toggleFilter)]];
    
    SWRevealViewController *revealController = [self revealViewController];
    self.navigationController.navigationBar.translucent = NO;
    
//    [revealController panGestureRecognizer];
    [revealController tapGestureRecognizer];
    
    UIBarButtonItem *revealButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"reveal-icon.png"]
                                                                         style:UIBarButtonItemStyleBordered target:revealController action:@selector(revealToggle:)];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(configureFRC) name:LIFEMAX_INITIALIZED_CD_KEY object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refresh:) name:LIFEMAX_INITIALIZED_CD_KEY object:nil];
    
    self.navigationItem.leftBarButtonItem = revealButtonItem;
    
    self.refreshControl = [[UIRefreshControl alloc]init];
    [self.refreshControl addTarget:self action:@selector(refresh:) forControlEvents:UIControlEventValueChanged];
//    [self filterForHashtag:nil];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self performFetch];
    [self loadData];
}

- (void) configureFRC {
    
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Task"];
    NSSortDescriptor *descriptor = [NSSortDescriptor sortDescriptorWithKey:@"task_id" ascending:NO];
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
    NSDictionary *loginInfo = [[NSUserDefaults standardUserDefaults] objectForKey:LIFEMAX_LOGIN_INFORMATION_KEY];
    id user = [loginInfo objectForKey:@"id"];
    NSString *authToken = [loginInfo objectForKey:@"authToken"];
    [[LMRestKitManager sharedManager] fetchFeedTasksForUser:user hashtag:nil maxResults:50 hashtoken:[authToken md5]];
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

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 300;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    Task *task = [self.fetchedResultsController objectAtIndexPath:indexPath];
    
    
    CellIdentifier = @"user_action";
    FeedUserTaskCell *feedCell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    NSMutableAttributedString *atrTitle = [[NSMutableAttributedString alloc]initWithString:task.user.user_name
                                                                                attributes:@{NSFontAttributeName:
                                                                                                 [UIFont boldSystemFontOfSize:[UIFont systemFontSize]]}];
    NSString *actionstring = [NSString stringWithFormat:@" %@ a goal", [task.completion boolValue] ? @"completed" : @"added" ];
    
    NSDictionary * attributes = @{NSFontAttributeName:
                                      [UIFont systemFontOfSize:[UIFont systemFontSize]]};
    NSAttributedString * subString = [[NSAttributedString alloc] initWithString:actionstring attributes:attributes];
    [atrTitle appendAttributedString:subString];
    
    [feedCell setAttributedAction:atrTitle];
    [feedCell setTimestamp:@"2 hours ago"];
    [feedCell setTitle:task.name];
    [feedCell setSubtitle:task.hashtag];
    
    
    NSArray *imageUrls = @[@"http://twistedsifter.files.wordpress.com/2013/03/full-moon-olympic-rings-london-bridge-2012.jpg",
                           @"http://twistedsifter.files.wordpress.com/2013/03/diver-whale-high-five-perfect-timing.jpg",
                           @"http://twistedsifter.files.wordpress.com/2013/03/just-a-pinch-buddah-perfect-timing.jpg",
                           @"http://twistedsifter.files.wordpress.com/2013/03/lightning-rainbow-perfect-timing.jpg",
                           @"http://twistedsifter.files.wordpress.com/2013/03/underwater-fish-photobomb-animal-photobombs.jpg",
                           @"http://twistedsifter.files.wordpress.com/2013/03/moon-crane-perfect-timing.jpg",
                           @"http://totallycoolpix.com/wp-content/uploads/2013/20131206_top_weird_wonderful_2013/top_weird_2013_002.jpg",
                           ];

    
    NSInteger rnd = arc4random_uniform((u_int32_t)[imageUrls count]);
    
    NSString *randomObject = [imageUrls objectAtIndex:rnd];
    
    [feedCell setImageFromURL:randomObject];
    feedCell.taskImageView.contentMode = UIViewContentModeScaleAspectFill;
    feedCell.layer.masksToBounds = YES;
        return feedCell;
    
    // Configure the cell...
    
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
    editController.task = [self.fetchedResultsController objectAtIndexPath:[self.tableView indexPathForSelectedRow]];
    editController.delegate = self;
}

#pragma mark - Checkbox target method

- (void) checkboxTapped:(id)sender {
    NSIndexPath *indexpath = [self.tableView indexPathForCell:sender];
    //    NSLog(@"CheckboxTapped: %@",indexpath );
    self.selectedIndexPath = indexpath;
    
    [self takePhoto];
    
}

- (IBAction)takePhoto {
    
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.delegate = self;
    picker.allowsEditing = YES;
    picker.sourceType = UIImagePickerControllerSourceTypeCamera;
    
    [self presentViewController:picker animated:YES completion:NULL];
    
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


-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    NSLog(@"Got an image picker: %@", info);
    
    UIImage *pickedImageEdited = [info objectForKey:UIImagePickerControllerEditedImage];
    
    //    TaskCell *cell = [self.tableView cellForRowAtIndexPath:self.selectedIndexPath];
    
    //    [cell setTaskImageFromUrl: task.pictureurl];
    
    NSDictionary *loginInfo = [[NSUserDefaults standardUserDefaults] objectForKey:LIFEMAX_LOGIN_INFORMATION_KEY];
    
    if(loginInfo) {
        NSString *userid = loginInfo[@"id"];
        
        NSString *authToken = loginInfo[@"authToken"];
        
        if (!authToken) return;
        
        NSString *hashToken = [authToken md5];
        
        NSLog(@"ID is: %@", userid);
        NSString *path = [NSString stringWithFormat:@"/api/user/%@/photoupload", userid];
        
        NSDictionary *params = @{@"hashToken": hashToken};
        
        [[RKTest sharedManager] postPath:path parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
            NSLog(@"Response Str: %@", operation.responseString);
            NSLog(@"Result object: %@", responseObject);
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            NSLog(@"Failure error: %@", [error localizedDescription]);
            NSLog(@"Failure Response Str: %@", operation.responseString);
        }];
        
        //        [RKTest sharedManager]
        
        
    }
    
    
    
    
    //do your stuff
    [self dismissViewControllerAnimated:YES completion:^{
        
    }];
}

-(void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    NSLog(@"Canceled image chooser");
    
}


@end
