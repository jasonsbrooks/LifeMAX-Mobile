//
//  LeaderViewController.m
//  Lifemax
//
//  Created by Charles Jin on 6/25/14.
//  Copyright (c) 2014 YUCG. All rights reserved.
//

#import "LeaderViewController.h"
#import "LMRestKitManager.h"

@implementation LeaderViewController
-(void) viewDidLoad{
    [super viewDidLoad];
    id userid = [[LMRestKitManager sharedManager] defaultUserId];
    [[LMRestKitManager sharedManager] fetchLeaderboardForUser:userid completion:^(NSArray *results, NSError *error) {
        NSLog(@"%@", results);
    }];

}
@end