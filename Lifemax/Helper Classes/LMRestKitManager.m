//
//  LMRestKitManager.m
//  Lifemax
//
//  Created by Micah Rosales on 2/24/14.
//  Copyright (c) 2014 YUCG. All rights reserved.
//

#import "LMRestKitManager.h"
#import <RestKit/RestKit.h>
#import "LifemaxHeaders.h"
#import "NSString+MD5.h"
@implementation LMRestKitManager

- (void)initializeMappings {
    NSURL *baseURL = [NSURL URLWithString:@"http://lifemax-staging.herokuapp.com"];
    RKObjectManager *objectManager = [RKObjectManager managerWithBaseURL:baseURL];
    
    // Enable Activity Indicator Spinner
    [AFNetworkActivityIndicatorManager sharedManager].enabled = YES;
    
    // Initialize managed object store
    NSManagedObjectModel *managedObjectModel = [NSManagedObjectModel mergedModelFromBundles:nil];
    RKManagedObjectStore *managedObjectStore = [[RKManagedObjectStore alloc] initWithManagedObjectModel:managedObjectModel];
    objectManager.managedObjectStore = managedObjectStore;
    
    // Setup our object mappings
    /**
     Mapping by entity. Here we are configuring a mapping by targetting a Core Data entity with a specific
     name. This allows us to map back Twitter user objects directly onto NSManagedObject instances --
     there is no backing model class!
     */
    RKEntityMapping *userMapping = [RKEntityMapping mappingForEntityForName:@"User" inManagedObjectStore:managedObjectStore];
    userMapping.identificationAttributes = @[ @"user_id" ];
    [userMapping addAttributeMappingsFromDictionary:@{
                                                      @"self": @"user_id",
                                                      }];
    // If source and destination key path are the same, we can simply add a string to the array
    //    [userMapping addAttributeMappingsFromArray:@[ @"name" ]];
    
    RKEntityMapping *taskMapping = [RKEntityMapping mappingForEntityForName:@"Task" inManagedObjectStore:managedObjectStore];
    taskMapping.identificationAttributes = @[ @"task_id" ];
    [taskMapping addAttributeMappingsFromDictionary:@{
                                                      @"summary" : @"name",
                                                      @"description" :@"task_description",
                                                      @"location": @"location",
                                                      @"id": @"task_id",
                                                      @"start.dateTime" :@"start",
                                                      @"end.dateTime" : @"end",
                                                      @"updated": @"updated",
                                                      @"extendedProperties.shared.pictureurl" :@"pictureurl",
                                                      @"extendedProperties.shared.hashtag" : @"hashtag",
                                                      }];
    [taskMapping addPropertyMapping:[RKRelationshipMapping relationshipMappingFromKeyPath:@"organizer" toKeyPath:@"user" withMapping:userMapping]];
    
    // Update date format so that we can parse Twitter dates properly
    // Wed Sep 29 15:31:08 +0000 2010
    NSDateFormatter *dateFormatter = [NSDateFormatter new];
    dateFormatter.dateFormat = @"yyyy-MM-ddThh:mm:ssZ";
    dateFormatter.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
    [[RKValueTransformer defaultValueTransformer] insertValueTransformer:dateFormatter atIndex:0];
    
    // Register our mappings with the provider
    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:taskMapping
                                                                                            method:RKRequestMethodGET
                                                                                       pathPattern:nil
                                                                                           keyPath:nil
                                                                                       statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful)];
    [objectManager addResponseDescriptor:responseDescriptor];
    
    
    /**
     Complete Core Data stack initialization
     */
    [managedObjectStore createPersistentStoreCoordinator];
    NSString *storePath = [RKApplicationDataDirectory() stringByAppendingPathComponent:@"RKLifemax.sqlite"];
    //    NSString *seedPath = [[NSBundle mainBundle] pathForResource:@"RKSeedDatabase" ofType:@"sqlite"];
    NSError *error;
    NSPersistentStore *persistentStore = [managedObjectStore addSQLitePersistentStoreAtPath:storePath fromSeedDatabaseAtPath:nil withConfiguration:nil options:nil error:&error];
    NSAssert(persistentStore, @"Failed to add persistent store with error: %@", error);
    
    // Create the managed object contexts
    [managedObjectStore createManagedObjectContexts];
    
    // Configure a managed object cache to ensure we do not create duplicate objects
    managedObjectStore.managedObjectCache = [[RKInMemoryManagedObjectCache alloc] initWithManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:LIFEMAX_INITIALIZED_CD_KEY object:nil];
    
}

- (void) fetchTasksForUser:(NSString *)userid hashtoken:(NSString *)hashtoken {
    
    NSString *path = [NSString stringWithFormat:@"/api/user/%@/tasks", userid];
    RKLogConfigureByName("RestKit/CoreData", RKLogLevelOff);
    RKLogConfigureByName("RestKit/Network", RKLogLevelOff);
    RKLogConfigureByName("RestKit", RKLogLevelOff);

    [[RKObjectManager sharedManager] getObjectsAtPath:path parameters:@{@"hashToken" : hashtoken} success:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
        NSLog(@"OP Path : %@", [[operation.HTTPRequestOperation  request] URL]);
        NSArray *objs =  [mappingResult array];
        for (NSManagedObject *obj in objs) {
            NSLog(@"Mapped :%@", obj);
        }
    } failure:^(RKObjectRequestOperation *operation, NSError *error) {
        NSLog(@"Map Failure: %@", [error localizedDescription]);
    }];
}

-(void)fetchTasksForDefaultUser {
    NSUserDefaults *stdDefaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *loginInfo = [stdDefaults objectForKey:LIFEMAX_LOGIN_INFORMATION_KEY];
    
    if (!loginInfo) return;
    
    [self fetchTasksForUser:loginInfo[@"id"] hashtoken:[(loginInfo[@"authToken"]) md5]];
}


#pragma mark - Singleton Methods

+ (LMRestKitManager *)sharedManager
{
    static dispatch_once_t pred;
    static LMRestKitManager *_sharedManager = nil;
    
    dispatch_once(&pred, ^{ _sharedManager = [[LMRestKitManager alloc] init]; }); // You should probably make this a constant somewhere
    return _sharedManager;
}

@end
