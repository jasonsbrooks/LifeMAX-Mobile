//
//  LeaderViewController.m
//  Lifemax
//
//  Created by Charles Jin on 6/25/14.
//  Copyright (c) 2014 YUCG. All rights reserved.
//

#import "LifemaxHeaders.h"
#import "LeaderViewController.h"
#import "LMRestKitManager.h"
#import "SWRevealViewController.h"
#import "UIAlertView+NSCookbook.h"
#import "User.h"
#import "LeaderboardCell.h"
#import "UIImageView+AFNetworking.h"

@implementation LeaderViewController

-(NSMutableArray *)leaders {
    if (!_leaders) {
        _leaders = [[NSMutableArray alloc]init];
    }
    return _leaders;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}
-(void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}

-(void) viewDidLoad{
    [super viewDidLoad];
    
    self.title = NSLocalizedString(@"Leaderboard", nil);
    
    [self loadData];
    
    //filter view
    
    SWRevealViewController *revealController = [self revealViewController];
    
    
    //    [revealController panGestureRecognizer];
    [revealController tapGestureRecognizer];
    
    UIBarButtonItem *revealButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"reveal-icon.png"]
                                                                         style:UIBarButtonItemStyleBordered target:revealController action:@selector(revealToggle:)];
    
    self.navigationItem.leftBarButtonItem = revealButtonItem;
    
    self.navigationController.navigationBar.translucent = NO;
}

-(void) exit {
//    [self.navigationController popViewControllerAnimated:YES];
}

-(void) loadData {
    id userid = [[LMRestKitManager sharedManager] defaultUserId];
    [[LMRestKitManager sharedManager] fetchLeaderboardForUser:userid completion:^(NSArray *results, NSError *error) {
        if (results){
            self.leaders = [results mutableCopy];
            [self.tableView reloadData];
        } else {
            UIAlertView *errorAlert = [[UIAlertView alloc]initWithTitle:NSLocalizedString(@"Error loading data...", nil)
                                                                 message:@"Please try again later."
                                                                delegate:nil cancelButtonTitle:NSLocalizedString(@"Okay", nil) otherButtonTitles:nil, nil];
            [errorAlert showWithCompletion:^(UIAlertView *alertView, NSInteger buttonIndex) {
                [self exit];
            }];
        }
    }];
}

#pragma mark - Table view data source


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (self.leaders) return [self.leaders count];
    return 0;
    
}

-(User*) userAtIndex: (NSInteger) index
{
    return [self.leaders objectAtIndex:index] ;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 80;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"LeaderCell";
    LeaderboardCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    User* u = [self userAtIndex: indexPath.row];
    
    cell.titleLabel.font = [UIFont preferredAvenirNextFontWithTextStyle:UIFontTextStyleHeadline];
    cell.placeLabel.font = [UIFont preferredAvenirNextFontWithTextStyle:UIFontTextStyleHeadline];
    cell.scoreLabel.font = [UIFont preferredAvenirNextFontWithTextStyle:UIFontTextStyleHeadline];
    
    cell.titleLabel.text = u.user_name;
    cell.placeLabel.text = [@(indexPath.row + 1) stringValue];
    cell.scoreLabel.text = u.score ? u.score : @"???";
    [cell.profilePicture setImageWithURL:[NSURL URLWithString:u.picture_url] placeholderImage:[UIImage imageNamed:@"max-suggests"]];
    
    [cell configureImage];
    
    return cell;
}

@end