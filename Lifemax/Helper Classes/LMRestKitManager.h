//
//  LMRestKitManager.h
//  Lifemax
//
//  Created by Micah Rosales on 2/24/14.
//  Copyright (c) 2014 YUCG. All rights reserved.
//

#import <Foundation/Foundation.h>
@class Task;
@interface LMRestKitManager : NSObject

- (void) fetchTasksForUser:(NSString *)userid hashtoken:(NSString *)hashtoken;
- (void)initializeMappings;
+ (LMRestKitManager *)sharedManager;

-(void)fetchTasksForDefaultUser;
- (BOOL)deleteTask:(Task *) task;
- (void) newTaskForValues:(NSDictionary *)values;
- (void) fetchFeedTasksForUser:(NSString *)userid hashtag:(NSString *)hashtag maxResults:(NSInteger)maxResults hashtoken:(NSString *)hashtoken ;

- (void) updateTask:(Task *)task withValues:(NSDictionary *)values;
- (NSString *) defaultUserAuthToken;
- (NSString *) defaultUserId;
- (NSString *)defaultUserHashToken;
- (void) uploadPhoto:(UIImage *)image forTask: (Task *)task;


@end
