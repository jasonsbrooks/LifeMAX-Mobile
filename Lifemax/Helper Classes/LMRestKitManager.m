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
    objectManager.requestSerializationMIMEType = RKMIMETypeJSON;
    
    // Setup our object mappings
    /**
     Mapping by entity. Here we are configuring a mapping by targetting a Core Data entity with a specific
     name. This allows us to map back Twitter user objects directly onto NSManagedObject instances --
     there is no backing model class!
     */
    RKEntityMapping *userMapping = [RKEntityMapping mappingForEntityForName:@"User" inManagedObjectStore:managedObjectStore];
    userMapping.identificationAttributes = @[ @"user_id" ];
    [userMapping addAttributeMappingsFromDictionary:@{
                                                      @"id": @"user_id",
                                                      @"name" : @"user_name"
                                                      }];
    // If source and destination key path are the same, we can simply add a string to the array
    
    RKEntityMapping *taskMapping = [RKEntityMapping mappingForEntityForName:@"Task" inManagedObjectStore:managedObjectStore];
    taskMapping.identificationAttributes = @[ @"task_id" ];
    [taskMapping addAttributeMappingsFromDictionary:@{
                                                      @"name" : @"name",
                                                      @"description" :@"task_description",
                                                      @"location": @"location",
                                                      @"id": @"task_id",
                                                      @"start" :@"start",
                                                      @"end" : @"end",
                                                      @"updated": @"updated",
                                                      @"pictureurl" :@"pictureurl",
                                                      @"hashtag" : @"hashtag",
                                                      @"completion" : @"completion"
                                                      }];
    [taskMapping addPropertyMapping:[RKRelationshipMapping relationshipMappingFromKeyPath:@"user" toKeyPath:@"user" withMapping:userMapping]];
    
    
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
                                                                                           keyPath:@"items"
                                                                                       statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful)];
    
    [objectManager addResponseDescriptor:responseDescriptor];
    
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
    
    /**
     Complete Core Data stack initialization
     */
    [managedObjectStore createPersistentStoreCoordinator];
    NSString *storePath = [RKApplicationDataDirectory() stringByAppendingPathComponent:@"RKLifemax.sqlite"];
    //    NSString *seedPath = [[NSBundle mainBundle] pathForResource:@"RKSeedDatabase" ofType:@"sqlite"];
    NSError *error;
    NSPersistentStore *persistentStore = [managedObjectStore addSQLitePersistentStoreAtPath:storePath fromSeedDatabaseAtPath:nil withConfiguration:nil options:nil error:&error];
    if (!persistentStore) {
        NSLog(@"Could not create persistent store");
    }
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
        /*
        NSLog(@"[FETCH-TASKS] Response: %@", operation.HTTPRequestOperation.responseString);
        for(Task *task in [mappingResult array]) {
            NSLog(@"[FETCHED-TASK]: %@", task);
        }*/
        
        
        
    } failure:^(RKObjectRequestOperation *operation, NSError *error) {
        NSLog(@"Map Failure: %@", operation.HTTPRequestOperation.responseString);
    }];
}

- (void) fetchFeedTasksForUser:(NSString *)userid hashtag:(NSString *)hashtag maxResults:(NSInteger)maxResults hashtoken:(NSString *)hashtoken {
    
    NSString *path = [NSString stringWithFormat:@"/api/user/%@/newsfeed", userid];
    
    [[RKObjectManager sharedManager] getObjectsAtPath:path parameters:@{@"hashToken" : hashtoken} success:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
        
        /*
        NSLog(@"[FEED-FETCH-TASKS] Response: %@", operation.HTTPRequestOperation.responseString);
         for(id obj in [mappingResult array]) {
             if ([obj isKindOfClass:[Task class]]){
                 Task * task = obj;
                 NSLog(@"[FEED-FETCHED-TASK]: %@\nUser:%@", task, task.user.user_id);
             }
             else {
                 NSLog(@"Not a task : %@", obj);
             }
         }
         
        */
         
        
    } failure:^(RKObjectRequestOperation *operation, NSError *error) {
        NSLog(@"Operation: %@", [operation HTTPRequestOperation]);
        NSLog(@"Map Failure: %@", operation.HTTPRequestOperation.responseString);
    }];
}

- (void) uploadPhoto:(UIImage *)image forTask:(Task *)task {

    NSData *jpegData = UIImageJPEGRepresentation(image, .6);
    
    
    NSString *path = [NSString stringWithFormat:@"/api/user/%@/photoupload", [self defaultUserId]];
    
    AFHTTPClient *httpClient = [[AFHTTPClient alloc] initWithBaseURL:[NSURL URLWithString:LIFEMAX_ROOT_URL]];
    NSMutableURLRequest *request = [httpClient multipartFormRequestWithMethod:@"POST" path:path parameters:@{@"hashToken" : [[self defaultUserAuthToken] md5] } constructingBodyWithBlock:^(id <AFMultipartFormData>formData) {
        [formData appendPartWithFileData:jpegData
                                    name:@"file"
                                fileName:task.hashtag mimeType:@"image/jpeg"];
    }];
    
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    
    __weak id ws = self;
    
    NSDictionary *response = @{@"success": @(1), @"imageurl": @"http://twistedsifter.files.wordpress.com/2013/03/lightning-rainbow-perfect-timing.jpg"};
    
    
    LMRestKitManager *ss = ws;
    
    if (response[@"success"] && [response[@"success"] boolValue]) {
        NSString *imgurl = response[@"imageurl"];
        [ss updateTask:task withValues:@{@"pictureurl" : imgurl}];
    }
    
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"upload photo success: %@", operation.responseString);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Upload photo failed : %@", operation.responseString);
    
        
        
    }];
    // if you want progress updates as it's uploading, uncomment the following:
    //
    
    [operation setUploadProgressBlock:^(NSUInteger bytesWritten,
    long long totalBytesWritten,
    long long totalBytesExpectedToWrite) {
             NSLog(@"Sent %lld of %lld bytes", totalBytesWritten, totalBytesExpectedToWrite);
    }];
    
        
//    [httpClient enqueueHTTPRequestOperation:operation];
}

-(void) deleteTaskFromLocalStore:(Task *)task {
    dispatch_async(dispatch_get_main_queue(), ^{
        [[RKObjectManager sharedManager].managedObjectStore.mainQueueManagedObjectContext deleteObject:task];
        
        NSError *error = nil;
        [[RKObjectManager sharedManager].managedObjectStore.mainQueueManagedObjectContext save:&error];
        
        NSLog(@"Delete Successful!");
    });
}

- (BOOL)deleteTask:(Task *) task {
    NSNumber *task_id = task.task_id;

    
    NSUserDefaults *stdDefaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *loginInfo = [stdDefaults objectForKey:LIFEMAX_LOGIN_INFORMATION_KEY];
    
    if (!loginInfo) return NO;
    
    NSString *deleteTasksPath = [NSString stringWithFormat:@"/api/user/%@/deletetasks", [loginInfo objectForKey:@"id"]];
    
    NSString *tok = [loginInfo objectForKey:@"authToken"];
    
    [[RKTest sharedManager] postPath:deleteTasksPath parameters:@{@"hashToken" : [tok md5], @"taskId" : task_id} success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        [self deleteTaskFromLocalStore:task];
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if(operation.response.statusCode == 200) {
            [self deleteTaskFromLocalStore:task];
            NSLog(@"Delete Response: %@", operation.responseString);

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

- (void) updateTask:(Task *)task withValues:(NSDictionary *)values {
    if(values[@"name"])
        task.name = values[@"name"];
    if(values[@"description"])
        task.task_description = values[@"description"];
    if(values[@"hashtag"])
        task.hashtag = values[@"hashtag"];
    if(values[@"start"])
        task.start = values[@"start"];
    if(values[@"completion"])
        task.completion = values[@"completion"];
    if(values[@"pictureurl"])
        task.pictureurl = values[@"pictureurl"];
    
    NSString *postPath = [NSString stringWithFormat:@"/api/user/%@/updatetask", [self defaultUserId]];
    
    [[RKObjectManager sharedManager] postObject:task
                                           path:postPath
                                     parameters:@{ @"hashToken" : [[self defaultUserAuthToken] md5] }
                                        success:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
                                            NSLog(@"Post success response");
                                            
                                        }
                                        failure:^(RKObjectRequestOperation *operation, NSError *error) {
                                            NSLog(@"Update Failed: %@", operation.HTTPRequestOperation.responseString);
                                            NSLog(@"Update Error : %@", [error localizedDescription]);
                                            NSLog(@"Update URL : %@", operation.HTTPRequestOperation.request.URL);
                                            NSLog(@"Update Request: %@", [[NSString alloc]initWithData:operation.HTTPRequestOperation.request.HTTPBody encoding:NSUTF8StringEncoding] );
                                        }];
    [task.managedObjectContext save:nil];
}

- (NSDictionary *)loginInfo {
    return [[NSUserDefaults standardUserDefaults] objectForKey:LIFEMAX_LOGIN_INFORMATION_KEY];
}
- (NSString *) defaultUserAuthToken {
    return [self loginInfo][@"authToken"];
}
- (NSString *) defaultUserId {
    return [self loginInfo][@"id"];
}


- (void) newTaskForValues:(NSDictionary *)values {
    if(values) {
        
        NSDateFormatter *dateFormatter = [NSDateFormatter new];
        dateFormatter.dateFormat = @"yyyy-MM-dd'T'hh:mm:ssZ";
        dateFormatter.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];

        NSString *name = [values objectForKey:@"name"];
        name = name ? name : @"new task";
        
        NSString *hashtag = [values objectForKey:@"hashtag"];
        hashtag = hashtag ? hashtag : @"#personal";
        
        NSString *description = [values objectForKey:@"task_description"];
        description = description ? description : @"";
        
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        [dict setObject:@"" forKey:@"location"];
        [dict setObject:@"" forKey:@"pictureurl"];
        
        [dict setObject:name forKey:@"name"];
        
        [dict setObject:hashtag forKey:@"hashtag"];

        
        [dict setObject:[dateFormatter stringFromDate:[NSDate date]] forKey:@"starttime"];
        [dict setObject:[dateFormatter stringFromDate:[NSDate dateWithTimeInterval:100 sinceDate:[NSDate date]]] forKey:@"endtime"];
        [dict setObject:description forKey:@"description"];
        
        NSDictionary *loginInfo = [[NSUserDefaults standardUserDefaults] objectForKey:LIFEMAX_LOGIN_INFORMATION_KEY];
        
        NSString *tok = [loginInfo objectForKey:@"authToken"];
        if(!tok)
            return;
        
        
        NSString *path = [NSString stringWithFormat:@"/api/user/%@/tasks", loginInfo[@"id"]];
        
        [dict setObject:[tok md5] forKey:@"hashToken"];
        
//        NSLog(@"params: %@", dict);
        
        
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
