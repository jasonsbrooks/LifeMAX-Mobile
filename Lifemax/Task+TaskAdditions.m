//
//  Task+TaskAdditions.m
//  Lifemax
//
//  Created by Micah Rosales on 3/19/14.
//  Copyright (c) 2014 YUCG. All rights reserved.
//

#import "Task+TaskAdditions.h"
#import "Hashtag.h"
@implementation Task (TaskAdditions)

- (NSString *)defaultImageUrl {
    NSFetchRequest *fetch = [[NSFetchRequest alloc] initWithEntityName:@"Hashtag"];
    fetch.predicate = [NSPredicate predicateWithFormat:@"name = %@", self.hashtag];
    
    NSError *error = nil;
    Hashtag *hashtag = [[self.managedObjectContext executeFetchRequest:fetch error:&error] lastObject];
    if(error || !hashtag)
        NSLog(@"Error Fetching hashtag!");
    return hashtag.imageurl;
}

- (NSString *)imageurlOrDefault {
    if (self.pictureurl && self.pictureurl.length > 0)
        return self.pictureurl;
    return [self defaultImageUrl];
}

- (NSDate *)dateToDisplay {
    if([self.completed boolValue] && self.timecompleted)
        return self.timecompleted;
    return self.timecreated;
}

@end
