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
#import "User.h"
#import "LMHttpClient.h"

@implementation LMRestKitManager

- (void)initializeMappings {
    NSURL *baseURL = [NSURL URLWithString:@"http://lifemax-staging.herokuapp.com"];
    RKObjectManager *objectManager = [RKObjectManager managerWithBaseURL:baseURL];
    
    // Enable Activity Indicator Spinner
    [AFNetworkActivityIndicatorManager sharedManager].enabled = YES;
    
    // Initialize managed object store
    objectManager.requestSerializationMIMEType = RKMIMETypeJSON;
    
    [self initializeStore:objectManager];
    RKManagedObjectStore *managedObjectStore = objectManager.managedObjectStore;
    
    // Setup our object mappings
    /**
     Mapping by entity. Here we are configuring a mapping by targetting a Core Data entity with a specific
     name. This allows us to map back Twitter user objects directly onto NSManagedObject instances --
     there is no backing model class!
     */
    
    
    
    RKEntityMapping *hashtagMapping = [RKEntityMapping mappingForEntityForName:@"Hashtag" inManagedObjectStore:managedObjectStore];
    hashtagMapping.identificationAttributes = @[ @"name" ];
    [hashtagMapping addAttributeMappingsFromDictionary:@{@"hashtag" : @"name", @"imageurl" : @"imageurl"}];
    
    RKEntityMapping *userMapping = [RKEntityMapping mappingForEntityForName:@"User" inManagedObjectStore:managedObjectStore];
    userMapping.identificationAttributes = @[ @"user_id" ];
    [userMapping addAttributeMappingsFromDictionary:@{
                                                      @"id": @"user_id",
                                                      @"name" : @"user_name",
                                                      @"fbid" : @"fbid"
                                                      }];
    // If source and destination key path are the same, we can simply add a string to the array
    
    RKEntityMapping *taskMapping = [RKEntityMapping mappingForEntityForName:@"Task" inManagedObjectStore:managedObjectStore];
    taskMapping.identificationAttributes = @[ @"task_id" ];
    [taskMapping addAttributeMappingsFromDictionary:@{
                                                      @"name" : @"name",
                                                      @"id": @"task_id",
                                                      @"pictureurl" :@"pictureurl",
                                                      @"hashtag" : @"hashtag",
                                                      @"completed" : @"completed",
                                                      @"private" : @"private",
                                                      @"timecompleted" : @"timecompleted",
                                                      @"timecreated" : @"timecreated"
                                                      }];
    
    [taskMapping addPropertyMapping:[RKRelationshipMapping relationshipMappingFromKeyPath:@"user" toKeyPath:@"user" withMapping:userMapping]];
    
    // Register our mappings with the provider
    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:taskMapping
                                                                                            method:RKRequestMethodGET
                                                                                       pathPattern:@"/api/user/:userid/tasks"
                                                                                           keyPath:@"items"
                                                                                       statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful)];
    
    [objectManager addResponseDescriptor:responseDescriptor];
    
    RKResponseDescriptor *postResponse = [RKResponseDescriptor responseDescriptorWithMapping:taskMapping
                                                                                            method:RKRequestMethodPOST
                                                                                       pathPattern:@"/api/user/:userid/tasks"
                                                                                           keyPath:nil
                                                                                       statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful)];
    
    [objectManager addResponseDescriptor:postResponse];
    
    RKResponseDescriptor *updateTaskResponse = [RKResponseDescriptor responseDescriptorWithMapping:taskMapping
                                                                                            method:RKRequestMethodPOST
                                                                                       pathPattern:@"/api/user/:userid/updatetask"
                                                                                           keyPath:nil
                                                                                       statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful)];
    
    [objectManager addResponseDescriptor:updateTaskResponse];
    
    RKResponseDescriptor *feedResponseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:taskMapping
                                                                                                method:RKRequestMethodGET
                                                                                           pathPattern:@"/api/user/:userid/newsfeed"
                                                                                               keyPath:@"items"
                                                                                           statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful)];
    
    [objectManager addResponseDescriptor:feedResponseDescriptor];
    
    
    RKRequestDescriptor *postTask = [RKRequestDescriptor requestDescriptorWithMapping:[taskMapping inverseMapping]
                                                                            objectClass:[Task class]
                                                                            rootKeyPath:nil
                                                                                 method:RKRequestMethodPOST];
    [objectManager addRequestDescriptor:postTask];
    
    
    RKResponseDescriptor *hashtagResponse = [RKResponseDescriptor responseDescriptorWithMapping:hashtagMapping
                                                                                                method:RKRequestMethodGET
                                                                                           pathPattern:@"/api/hashtags"
                                                                                               keyPath:@"hashtags"
                                                                                           statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful)];
    
    [objectManager addResponseDescriptor:hashtagResponse];
    
    
    
    // To perform local orphaned object cleanup
    [objectManager addFetchRequestBlock:^NSFetchRequest *(NSURL *URL) {
        
        RKPathMatcher *pathMatcherTask = [RKPathMatcher pathMatcherWithPattern:@"/api/user/:userid/tasks"];
        BOOL matchTask = [pathMatcherTask matchesPath:[URL relativePath] tokenizeQueryStrings:NO parsedArguments:nil];
        
        if (matchTask) {
            NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Task"];
            return fetchRequest;
        }
        return nil;
    }];
    
    [objectManager addFetchRequestBlock:^NSFetchRequest *(NSURL *URL) {
        
        RKPathMatcher *pathMatcherTask = [RKPathMatcher pathMatcherWithPattern:@"/api/user/:userid/newsfeed"];
        BOOL matchTask = [pathMatcherTask matchesPath:[URL relativePath] tokenizeQueryStrings:NO parsedArguments:nil];
        
        if (matchTask) {
            NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Task"];
            return fetchRequest;
        }
        return nil;
    }];
    
    
    
    /**
     Complete Core Data stack initialization
     */
    
    
    [[NSNotificationCenter defaultCenter] postNotificationName:LIFEMAX_INITIALIZED_CD_KEY object:nil];
    
    [objectManager.HTTPClient setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
        if (status == AFNetworkReachabilityStatusNotReachable) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"No network connection"
                                                            message:@"You must be connected to the internet to use this app. Offline support will be added "
                                                           delegate:nil
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
            [alert show];
            [[NSNotificationCenter defaultCenter] postNotificationName:LIFEMAX_TRIGGER_LOGOUT object:nil userInfo:nil];
        }
    }];
    
}
- (void) initializeStore:(RKObjectManager *)objectManager {
    NSManagedObjectModel *managedObjectModel = [NSManagedObjectModel mergedModelFromBundles:nil];
    RKManagedObjectStore *managedObjectStore = [[RKManagedObjectStore alloc] initWithManagedObjectModel:managedObjectModel];
    objectManager.managedObjectStore = managedObjectStore;
    
    [managedObjectStore createPersistentStoreCoordinator];
    NSString *storePath = [RKApplicationDataDirectory() stringByAppendingPathComponent:@"RKLifemax.sqlite"];
    //    NSString *seedPath = [[NSBundle mainBundle] pathForResource:@"RKSeedDatabase" ofType:@"sqlite"];
    NSError *error;
    NSPersistentStore *persistentStore = [managedObjectStore addSQLitePersistentStoreAtPath:storePath fromSeedDatabaseAtPath:nil withConfiguration:nil options:nil error:&error];
    if (!persistentStore) {
        NSLog(@"[LM-ERROR]: Could not create persistent store, resetting and trying again.");
        //try deleting and going again
        [[NSFileManager defaultManager] removeItemAtPath:storePath error:nil];
        persistentStore = [managedObjectStore addSQLitePersistentStoreAtPath:storePath fromSeedDatabaseAtPath:nil withConfiguration:nil options:nil error:&error];
    }
    NSAssert(persistentStore, @"Failed to add persistent store with error: %@", error);
    
    // Create the managed object contexts
    [managedObjectStore createManagedObjectContexts];
    
    // Configure a managed object cache to ensure we do not create duplicate objects
    managedObjectStore.managedObjectCache = [[RKInMemoryManagedObjectCache alloc] initWithManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext];
}

- (void) deleteCache {
    [[RKManagedObjectStore defaultStore] resetPersistentStores:nil];
}

- (void) fetchTasksForUser:(id)userid hashtoken:(NSString *)hashtoken completion:(void (^)(BOOL success, NSError *error))completionBlock {
    
    if(!hashtoken || !userid) {
        NSLog(@"[LM-Warning]: Local fetch issue, not logged in yet.");
        return;
    }
    
    NSString *path = [NSString stringWithFormat:@"/api/user/%@/tasks", userid];

    [[RKObjectManager sharedManager] getObjectsAtPath:path parameters:@{@"hashToken" : hashtoken} success:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
        for (Task *task in [mappingResult array]) {
            if(task.timecompleted) task.displaydate = task.timecompleted;
            else task.displaydate = task.timecreated;
            [task.managedObjectContext save:nil];
        }
        if(completionBlock) completionBlock(YES, nil);
        
    } failure:^(RKObjectRequestOperation *operation, NSError *error) {
        NSLog(@"[LM-Error] Tasks Map Failure: %@", operation.HTTPRequestOperation.responseString);
        if(completionBlock) completionBlock(NO, error);
    }];
}

- (void) fetchFeedTasksForUser:(id)userid hashtag:(NSString *)hashtag maxResults:(NSInteger)maxResults hashtoken:(NSString *)hashtoken completion:(void (^)(NSArray *results, NSError *error))onCompletion {
    
    if(!hashtoken || !userid) {
        NSLog(@"[LM-Warning]: Local fetch issue, not logged in yet.");
        return;
    }
    
    
    NSString *path = [NSString stringWithFormat:@"/api/user/%@/newsfeed", userid];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [[RKObjectManager sharedManager] getObjectsAtPath:path parameters:@{@"hashToken" : hashtoken} success:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
            for (Task *task in [mappingResult array]) {
                if(task.timecompleted) task.displaydate = task.timecompleted;
                else task.displaydate = task.timecreated;
                [task.managedObjectContext performBlock:^{
                    [task.managedObjectContext save:nil];
                }];
            }
            if (onCompletion)
                onCompletion([mappingResult array], nil);
            
        } failure:^(RKObjectRequestOperation *operation, NSError *error) {
            NSLog(@"[LM-Error] Feed Map Failure: %@", operation.HTTPRequestOperation.responseString);
            if (onCompletion)
                onCompletion(nil, error);
            
        }];
    });

}

- (void) uploadPhoto:(UIImage *)image forTask:(Task *)task {

    NSData *jpegData = UIImageJPEGRepresentation(image, .6);
    NSString *hashToken = [self defaultUserHashToken];
    NSNumber *userid = [self defaultUserId];
    
    if (!userid || !hashToken) {
        NSLog(@"[LM-ERROR]: Error uploading photo - Not logged in");
        return;
    }
    
    NSString *path = [NSString stringWithFormat:@"/api/user/%@/photoupload", userid];
    
    AFHTTPClient *httpClient = [LMHttpClient sharedManager];
    
    NSMutableURLRequest *request = [httpClient multipartFormRequestWithMethod:@"POST" path:path parameters:@{@"hashToken" :  hashToken} constructingBodyWithBlock:^(id <AFMultipartFormData>formData) {
        [formData appendPartWithFileData:jpegData
                                    name:@"photo"
                                fileName:@"uploadedImage.jpg" mimeType:@"image/jpeg"];
    }];
    
    __weak id ws = self;

    
    AFJSONRequestOperation *jsonOp = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        
        LMRestKitManager *ss = ws;
        if ([JSON objectForKey: @"success"] && [[JSON objectForKey: @"success"] boolValue]) {
            NSString *imgurl = JSON[@"imageurl"];
            [ss updateTask:task withValues:@{@"pictureurl" : imgurl, @"completed" : @(1)}];
        }

    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        NSLog(@"[LM-ERROR]: Upload photo failed : %d", response.statusCode);
    }];
    
    
//    NSDictionary *response = @{@"success": @(1), @"imageurl": @"http://twistedsifter.files.wordpress.com/2013/03/lightning-rainbow-perfect-timing.jpg"};
    

    // if you want progress updates as it's uploading, uncomment the following:
        
    [httpClient enqueueHTTPRequestOperation:jsonOp];
}

-(void) deleteTaskFromLocalStore:(Task *)task {
    dispatch_async(dispatch_get_main_queue(), ^{
        [[RKObjectManager sharedManager].managedObjectStore.mainQueueManagedObjectContext deleteObject:task];
        
        NSError *error = nil;
        [[RKObjectManager sharedManager].managedObjectStore.mainQueueManagedObjectContext save:&error];
    });
}

- (BOOL)deleteTask:(Task *) task {
    NSNumber *task_id = task.task_id;

    NSLog(@"Delete Task");
    NSString *deleteTasksPath = [NSString stringWithFormat:@"/api/user/%@/deletetasks", [self defaultUserId]];
    
    NSString *tok = [self defaultUserHashToken];
    
    [[LMHttpClient sharedManager] postPath:deleteTasksPath parameters:@{@"hashToken" : tok, @"taskId" : task_id} success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        [self deleteTaskFromLocalStore:task];
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if(operation.response.statusCode == 200) {
            [self deleteTaskFromLocalStore:task];
        } else {
            NSLog(@"[LM-ERROR]: Delete Response: %@", operation.responseString);
        }
    }];
    return YES;
}

- (void) updateTask:(Task *)task withValues:(NSDictionary *)values {
    [task.managedObjectContext performBlock:^{
        if(values[@"name"])
            task.name = values[@"name"];
        if(values[@"hashtag"])
            task.hashtag = values[@"hashtag"];
        if(values[@"completed"])
            task.completed = values[@"completed"];
        if(values[@"pictureurl"])
            task.pictureurl = values[@"pictureurl"];
        if(values[@"private"])
            task.private = values[@"private"];
        
        NSString *hashToken = [self defaultUserHashToken];
        if(!hashToken) {
            NSLog(@"[LM-WARNING: Attempting to update task but not logged in");
        }
        
        NSString *postPath = [NSString stringWithFormat:@"/api/user/%@/updatetask", [self defaultUserId]];
        
        [[RKObjectManager sharedManager] postObject:task
                                               path:postPath
                                         parameters:@{ @"hashToken" : hashToken }
                                            success:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
                                                Task *t = [mappingResult firstObject];
                                                if(t.timecompleted) t.displaydate = t.timecompleted;
                                                else t.displaydate = t.timecreated;
                                                NSError *error = nil;
                                                [t.managedObjectContext saveToPersistentStore:&error];
                                                if(error)
                                                    NSLog(@"[LM-ERROR]: Failed saving task to persistent store after update");
                                                
                                            }
                                            failure:^(RKObjectRequestOperation *operation, NSError *error) {
                                                NSLog(@"[LM-ERROR]: Update Task Failed: %@", operation.HTTPRequestOperation.responseString);
                                                NSLog(@"[LM-ERROR]: Update Request Body: %@", [[NSString alloc]initWithData:operation.HTTPRequestOperation.request.HTTPBody encoding:NSUTF8StringEncoding] );
                                            }];
        NSError *error = nil;
        [task.managedObjectContext saveToPersistentStore:&error];
        if(error)
            NSLog(@"[LM-ERROR]: Failed saving task to persistent store");
    }];
}

- (NSDictionary *)loginInfo {
    return [[NSUserDefaults standardUserDefaults] objectForKey:LIFEMAX_LOGIN_INFORMATION_KEY];
}
- (NSString *) defaultUserAuthToken {
    return [self loginInfo][@"authToken"];
}
- (NSNumber *) defaultUserId {
    return [self loginInfo][@"id"];
}
- (NSString *)defaultUserHashToken {
    return [[self defaultUserAuthToken] md5];
}


- (void) newTaskForValues:(NSDictionary *)values {
    if(values) {
        NSString *name = values[@"name"];
        name = name ? name : @"new task";
        
        NSString *hashtag = values[@"hashtag"];
        hashtag = hashtag ? hashtag : @"#yalebucketlist";
        
        NSNumber *private = values[@"private"];
        private = private ? private : @(NO);
        NSNumber *completed = values[@"completed"];
        completed = completed ? completed : @(NO);
        
        NSManagedObjectContext *ctx = [RKManagedObjectStore defaultStore].mainQueueManagedObjectContext;
        
        [ctx performBlock:^{
            Task *task =  [ctx insertNewObjectForEntityForName:@"Task"];
            task.name = name;
            task.hashtag = hashtag;
            task.private = private;
            task.completed = completed;
            task.pictureurl = nil;
            [task.managedObjectContext saveToPersistentStore:nil];
            
            NSString *hashTok = [self defaultUserHashToken];
            if(!hashTok)
                return;
            
            NSString *path = [NSString stringWithFormat:@"/api/user/%@/tasks", [self defaultUserId]];
            
            NSDictionary *params = @{@"hashToken": hashTok};
            
            [[RKObjectManager sharedManager] postObject:task path:path parameters:params success:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
                Task *task = [mappingResult firstObject];
                if(task.timecompleted) task.displaydate = task.timecompleted;
                else task.displaydate = task.timecreated;
                [task.managedObjectContext saveToPersistentStore:nil];
            } failure:^(RKObjectRequestOperation *operation, NSError *error) {
                NSLog(@"[LM-ERROR]: New Task Mapping Failed: %@ - %@", [error localizedDescription], operation.HTTPRequestOperation.responseString);
            }];
        }];
    }
}

-(void)fetchTasksForDefaultUserOnCompletion:(void (^)(BOOL success, NSError *error))completionBlock {
    [self fetchTasksForUser: [self defaultUserId] hashtoken:[self defaultUserHashToken] completion:completionBlock];
}


- (void)fetchHashtagListOnCompletion:(void (^)(NSArray *, NSError *))completionBlock {
    [[RKObjectManager sharedManager] getObjectsAtPath:@"/api/hashtags"
                                           parameters:nil
                                              success:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
                                                  [[NSNotificationCenter defaultCenter] postNotificationName:LIFEMAX_NOTIFICATION_HASHTAG_RETRIEVE_SUCCESS object:[mappingResult array] userInfo:nil];
                                                  
                                                  if(completionBlock)
                                                      completionBlock([mappingResult array], nil);
                                              } failure:^(RKObjectRequestOperation *operation, NSError *error) {
                                                  NSLog(@"[LM-ERROR]: Fetched Hashtags Failure: %@\n%@", [error localizedDescription], operation.HTTPRequestOperation.responseString);

                                                  if(completionBlock)
                                                      completionBlock(nil, error);
                                              }];
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
