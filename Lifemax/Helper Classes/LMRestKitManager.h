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

- (void) fetchTasksForUser:(id)userid hashtoken:(NSString *)hashtoken completion:(void (^)(BOOL success, NSError *error))completionBlock;

- (void)initializeMappings;
+ (LMRestKitManager *)sharedManager;
- (void) deleteCache;
-(void)fetchTasksForDefaultUserOnCompletion:(void (^)(BOOL success, NSError *error))completionBlock;

- (BOOL)deleteTask:(Task *) task;
- (void) newTaskForValues:(NSDictionary *)values;
- (void) fetchFeedTasksForUser:(id)userid hashtag:(NSString *)hashtag maxResults:(NSInteger)maxResults hashtoken:(NSString *)hashtoken type:(NSString *)type completion:(void (^)(NSArray *results, NSError *error))onCompletion;

- (void) updateTask:(Task *)task withValues:(NSDictionary *)values;
- (NSString *) defaultUserAuthToken;
- (NSNumber *) defaultUserId;
- (NSString *)defaultUserHashToken;
- (void) uploadPhoto:(UIImage *)image forTask: (Task *)task;

- (void)fetchHashtagListOnCompletion:(void (^)(NSArray *, NSError *))completionBlock;


@end
