//
//  Task+TaskAdditions.h
//  Lifemax
//
//  Created by Micah Rosales on 3/19/14.
//  Copyright (c) 2014 YUCG. All rights reserved.
//

#import "Task.h"

@interface Task (TaskAdditions)
- (NSString *)defaultImageUrl;
- (NSString *)imageurlOrDefault;
- (NSDate *)dateToDisplay;
@end
