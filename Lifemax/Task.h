//
//  Task.h
//  Lifemax
//
//  Created by Micah Rosales on 2/27/14.
//  Copyright (c) 2014 YUCG. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "User.h"

@interface Task : NSManagedObject


@property (nonatomic, retain) NSDate * end;
@property (nonatomic, retain) NSString * hashtag;
@property (nonatomic, retain) NSString * location;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * pictureurl;
@property (nonatomic, retain) NSDate * start;
@property (nonatomic, retain) NSString * task_description;
@property (nonatomic, retain) NSNumber * task_id;
@property (nonatomic, retain) NSDate * updated;
@property (nonatomic, retain) User *user;
@property (nonatomic, retain) NSNumber *completion;

@end
