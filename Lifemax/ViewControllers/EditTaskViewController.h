//
//  EditTaskViewController.h
//  Lifemax
//
//  Created by Micah Rosales on 2/22/14.
//  Copyright (c) 2014 YUCG. All rights reserved.
//

#import <UIKit/UIKit.h>

@class EditTaskViewController;
@class Task;

@protocol EditTaskDelegate <NSObject>

-(void)editor:(EditTaskViewController *)editor didEditTaskFields:(NSDictionary *)values forTask:(Task *)task;
@end

@interface EditTaskViewController : UIViewController
@property (nonatomic, retain) Task *task;
@property (nonatomic, weak) id<EditTaskDelegate> delegate;

-(void)initializeWithTaskValues :(Task *)task fromFeed:(BOOL)fromFeed;

@end
