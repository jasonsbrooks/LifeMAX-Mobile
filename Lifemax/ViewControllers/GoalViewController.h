//
//  GoalViewController.h
//  Lifemax
//
//  Created by Charles Jin on 6/26/14.
//  Copyright (c) 2014 YUCG. All rights reserved.
//

#import <UIKit/UIKit.h>

@class GoalViewController;
@class Task;

@interface GoalViewController : UIViewController

@property (nonatomic, retain) Task *task;
-(void)initializeWithTaskValues :(Task *)task fromFeed:(BOOL)fromFeed;
@end