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

@implementation LeaderViewController
-(void) viewDidLoad{
    [super viewDidLoad];
    
    self.title = NSLocalizedString(@"Leaderboard", nil);
    
    //filter view
    
    SWRevealViewController *revealController = [self revealViewController];
    
    
    //    [revealController panGestureRecognizer];
    [revealController tapGestureRecognizer];
    
    UIBarButtonItem *revealButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"reveal-icon.png"]
                                                                         style:UIBarButtonItemStyleBordered target:revealController action:@selector(revealToggle:)];
    
    self.navigationItem.leftBarButtonItem = revealButtonItem;
    
    self.navigationController.navigationBar.translucent = NO;
    
    [self loadData];

}

- (void)viewWillAppear:(BOOL)animated
{
//    [super viewWillAppear:animated];
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(performFetch) name:LIFEMAX_NOTIFICATION_NAME_LOGIN_SUCCESS object:nil];
}


-(void) loadData {
    id userid = [[LMRestKitManager sharedManager] defaultUserId];
    [[LMRestKitManager sharedManager] fetchLeaderboardForUser:userid completion:^(NSArray *results, NSError *error) {
        NSLog(@"%@", results);
    }];
}
@end