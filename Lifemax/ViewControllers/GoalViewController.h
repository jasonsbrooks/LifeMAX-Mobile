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
-(void)setTask:(Task *)task;

@property (nonatomic, strong) IBOutlet UIImageView *taskImageView;
@property (nonatomic, strong) IBOutlet UILabel *titleLabel;
@property (nonatomic, strong) IBOutlet UILabel *subtitleLabel;
@property (nonatomic, strong) IBOutlet UITextView *desc;
@property (nonatomic, strong) IBOutlet UIButton *addButton;
@property (nonatomic, strong) IBOutlet UIButton *doneButton;

@end