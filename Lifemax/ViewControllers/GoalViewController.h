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
-(void)initializeWithTaskValues :(Task *)task;

@property (nonatomic, strong) IBOutlet UIImageView *taskImageView;
@property (nonatomic, strong) IBOutlet UILabel *actionLabel;
@property (nonatomic, strong) IBOutlet UILabel *timestampLabel;
@property (nonatomic, strong) IBOutlet UILabel *titleLabel;
@property (nonatomic, strong) IBOutlet UILabel *subtitleLabel;
@property (nonatomic, strong) IBOutlet UILabel *hashtag;
@property (nonatomic, strong) IBOutlet UITextView *desc;

@end