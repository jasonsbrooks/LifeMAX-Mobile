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
#import "Task.h"
#import "RKTest.h"
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
                                                                                       pathPattern:@"/api/user/:userid/tasks"
                                                                                           keyPath:nil
                                                                                       statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful)];
    
    [objectManager addResponseDescriptor:responseDescriptor];
    
    RKResponseDescriptor *postTask = [RKResponseDescriptor responseDescriptorWithMapping:[taskMapping inverseMapping]
                                                                                  method:RKRequestMethodPOST
                                                                             pathPattern:@"/api/user/:userid/tasks"
                                                                                 keyPath:nil
                                                                             statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful)];
    [objectManager addResponseDescriptor:postTask];
    
    
    // To perform local orphaned object cleanup
    [objectManager addFetchRequestBlock:^NSFetchRequest *(NSURL *URL) {
        
        RKPathMatcher *pathMatcherTask = [RKPathMatcher pathMatcherWithPattern:@"/api/user/:userid/tasks"];
        BOOL matchTask = [pathMatcherTask matchesPath:[URL relativePath] tokenizeQueryStrings:NO parsedArguments:nil];
        
        if (matchTask) {
            NSLog(@"Pattern matched left.json!");
            NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Task"];
            return fetchRequest;
        }
        return nil;
    }];
    
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

-(void) deleteTaskFromLocalStore:(Task *)task {
    dispatch_async(dispatch_get_main_queue(), ^{
        [[RKObjectManager sharedManager].managedObjectStore.mainQueueManagedObjectContext deleteObject:task];
        
        NSError *error = nil;
        [[RKObjectManager sharedManager].managedObjectStore.mainQueueManagedObjectContext save:&error];
        
        NSLog(@"Delete Successful!: %@",  [error localizedDescription]);
    });
}

- (BOOL)deleteTask:(Task *) task {
    NSString *task_id = task.task_id;

    
    NSUserDefaults *stdDefaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *loginInfo = [stdDefaults objectForKey:LIFEMAX_LOGIN_INFORMATION_KEY];
    
    if (!loginInfo) return NO;
    
    NSString *deleteTasksPath = [NSString stringWithFormat:@"/api/user/%@/deletetasks", [loginInfo objectForKey:@"id"]];
    
    NSString *tok = [loginInfo objectForKey:@"authToken"];
    
    [[RKTest sharedManager] postPath:deleteTasksPath parameters:@{@"hashToken" : [tok md5], @"eventId" : task_id} success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        [self deleteTaskFromLocalStore:task];
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
//        NSLog(@"Delete Headers : %@", [operation.request allHTTPHeaderFields]);
        if(operation.response.statusCode == 200) {
            [self deleteTaskFromLocalStore:task];
        } else {
            NSLog(@"Delete Response: %@", operation.responseString);

        }
    }];
    return YES;
}

/*
- (BOOL) deleteTask:(Task *)task {
    if(!task)
        return NO;
    [[RKObjectManager sharedManager] deleteObject:task path:@"" parameters:nil success:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
        NSLog(@"Delete Success!");
    } failure:^(RKObjectRequestOperation *operation, NSError *error) {
        NSLog(@"Delete Failure: %@", operation.responseDescriptors);
    }];
    return YES;
}
*/
- (void) newTaskForValues:(NSDictionary *)values {
    if(values) {
        /*
        NSManagedObjectContext *childMoc = [[NSManagedObjectContext alloc]initWithConcurrencyType:NSMainQueueConcurrencyType];
        childMoc.parentContext = [RKObjectManager sharedManager].managedObjectStore.mainQueueManagedObjectContext;
        
        Task *task = [NSEntityDescription insertNewObjectForEntityForName:@"Task" inManagedObjectContext:childMoc];
                      
        
        if([[values allKeys] containsObject:@"name"])
            task.name = values[@"name"];
        if([[values allKeys] containsObject:@"task_description"])
            task.task_description = values[@"task_description"];
        if([[values allKeys] containsObject:@"start"])
            task.start = values[@"start"];
        if([[values allKeys] containsObject:@"hashtag"])
            task.hashtag = values[@"hashtag"];
        
        task.end = [NSDate date];
        task.location= @"buttery";
        task.pictureurl = @"";
        */
        
        NSDateFormatter *dateFormatter = [NSDateFormatter new];
        dateFormatter.dateFormat = @"yyyy-MM-dd'T'hh:mm:ssZ";
        dateFormatter.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];

        
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        [dict setObject:@"buttery" forKey:@"location"];
        [dict setObject:@"" forKey:@"pictureurl"];
        [dict setObject:[values objectForKey:@"name"] forKey:@"name"];
        [dict setObject:[values objectForKey:@"hashtag"] forKey:@"hashtag"];

        
        [dict setObject:[dateFormatter stringFromDate:[NSDate date]] forKey:@"starttime"];
        [dict setObject:[dateFormatter stringFromDate:[NSDate dateWithTimeInterval:100 sinceDate:[NSDate date]]] forKey:@"endtime"];
        [dict setObject:[values objectForKey:@"task_description"] forKey:@"description"];
        
        NSDictionary *loginInfo = [[NSUserDefaults standardUserDefaults] objectForKey:LIFEMAX_LOGIN_INFORMATION_KEY];
        
        NSString *tok = [loginInfo objectForKey:@"authToken"];
        if(!tok)
            return;
        
        
        NSString *path = [NSString stringWithFormat:@"/api/user/%@/tasks", loginInfo[@"id"]];
        
        [dict setObject:[tok md5] forKey:@"hashToken"];
        
        NSLog(@"params: %@", dict);
        
        
        [[RKTest sharedManager] postPath:path parameters:dict success:^(AFHTTPRequestOperation *operation, id responseObject) {
            NSLog(@"Post success: %@", responseObject);
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            NSLog(@"Data : %@", [[NSString alloc]initWithData:[operation responseData] encoding:NSUTF8StringEncoding]);
        }];
        

    }
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
