//
//  Task.h
//  Lifemax
//
//  Created by Micah Rosales on 3/19/14.
//  Copyright (c) 2014 YUCG. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class User;

@interface Task : NSManagedObject

@property (nonatomic, retain) NSNumber * completed;
@property (nonatomic, retain) NSString * hashtag;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * pictureurl;
@property (nonatomic, retain) NSNumber * task_id;
@property (nonatomic, retain) NSNumber * private;
@property (nonatomic, retain) NSDate * timecompleted;
@property (nonatomic, retain) User *user;

@end
