//
//  LMRestKitManager.h
//  Lifemax
//
//  Created by Micah Rosales on 2/24/14.
//  Copyright (c) 2014 YUCG. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LMRestKitManager : NSObject

- (void) fetchTasksForUser:(NSString *)userid hashtoken:(NSString *)hashtoken;
- (void)initializeMappings;
+ (LMRestKitManager *)sharedManager;

-(void)fetchTasksForDefaultUser;

@end
