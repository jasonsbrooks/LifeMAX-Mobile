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
                                                      @"timecompleted" : @"timecompleted"
                                                      }];
    [taskMapping addPropertyMapping:[RKRelationshipMapping relationshipMappingFromKeyPath:@"user" toKeyPath:@"user" withMapping:userMapping]];
    
    RKDotNetDateFormatter *formatter = [RKDotNetDateFormatter dotNetDateFormatterWithTimeZone:[NSTimeZone defaultTimeZone]];
    [[RKValueTransformer defaultValueTransformer] insertValueTransformer: formatter atIndex:0];
    
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
        }
        */
        
        
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
    
    AFHTTPClient *httpClient = [RKTest sharedManager];
    
    NSMutableURLRequest *request = [httpClient multipartFormRequestWithMethod:@"POST" path:path parameters:@{@"hashToken" : [self defaultUserHashToken] } constructingBodyWithBlock:^(id <AFMultipartFormData>formData) {
        [formData appendPartWithFileData:jpegData
                                    name:@"photo"
                                fileName:@"uploadedImage.jpg" mimeType:@"image/jpeg"];
    }];
    
    __weak id ws = self;

    
    AFJSONRequestOperation *jsonOp = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        NSLog(@"upload photo success: %@", JSON );
        
        LMRestKitManager *ss = ws;
        if ([JSON objectForKey: @"success"] && [[JSON objectForKey: @"success"] boolValue]) {
            NSString *imgurl = JSON[@"imageurl"];
            NSLog(@"imgurl: %@", imgurl);
            [ss updateTask:task withValues:@{@"pictureurl" : imgurl, @"completed" : @(1)}];
        }

    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        NSLog(@"Upload photo failed : %d", response.statusCode);
    }];
    
    
//    NSDictionary *response = @{@"success": @(1), @"imageurl": @"http://twistedsifter.files.wordpress.com/2013/03/lightning-rainbow-perfect-timing.jpg"};
    

    // if you want progress updates as it's uploading, uncomment the following:
    
    [jsonOp setUploadProgressBlock:^(NSUInteger bytesWritten,
    long long totalBytesWritten,
    long long totalBytesExpectedToWrite) {
             NSLog(@"Sent %lld of %lld bytes", totalBytesWritten, totalBytesExpectedToWrite);
    }];
    
        
    [httpClient enqueueHTTPRequestOperation:jsonOp];
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

    
    NSString *deleteTasksPath = [NSString stringWithFormat:@"/api/user/%@/deletetasks", [self defaultUserId]];
    
    NSString *tok = [self defaultUserHashToken];
    
    [[RKTest sharedManager] postPath:deleteTasksPath parameters:@{@"hashToken" : tok, @"taskId" : task_id} success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
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
    if(values[@"hashtag"])
        task.hashtag = values[@"hashtag"];
    if(values[@"completed"])
        task.completed = values[@"completed"];
    if(values[@"pictureurl"])
        task.pictureurl = values[@"pictureurl"];
    if(values[@"private"])
        task.private = values[@"private"];

    NSLog(@"Uploading Task: %@", task);
    
    NSString *postPath = [NSString stringWithFormat:@"/api/user/%@/updatetask", [self defaultUserId]];
    
    [[RKObjectManager sharedManager] postObject:task
                                           path:postPath
                                     parameters:@{ @"hashToken" : [self defaultUserHashToken] }
                                        success:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
                                            NSLog(@"Post Data: %@", [[NSString alloc] initWithData:operation.HTTPRequestOperation.request.HTTPBody encoding:NSUTF8StringEncoding]);
                                            NSLog(@"Post response: %@", operation.HTTPRequestOperation.responseString);
                                            NSLog(@"Post success response: %@", mappingResult);
                                            
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
- (NSString *)defaultUserHashToken {
    return [[self defaultUserAuthToken] md5];
}


- (void) newTaskForValues:(NSDictionary *)values {
    if(values) {
        
        NSDateFormatter *dateFormatter = [NSDateFormatter new];
        dateFormatter.dateFormat = @"yyyy-MM-dd'T'hh:mm:ssZ";
        dateFormatter.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];

        NSString *name = values[@"name"];
        name = name ? name : @"new task";
        
        NSString *hashtag = values[@"hashtag"];
        hashtag = hashtag ? hashtag : @"#personal";
        
        NSNumber *private = values[@"private"];
        private = private ? private : @(0);
        
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        [dict setObject:@"" forKey:@"pictureurl"];
        [dict setObject:name forKey:@"name"];
        [dict setObject:hashtag forKey:@"hashtag"];
        

        NSString *hashTok = [self defaultUserHashToken];
        if(!hashTok)
            return;
        
        
        NSString *path = [NSString stringWithFormat:@"/api/user/%@/tasks", [self defaultUserId]];
        
        [dict setObject:hashTok forKey:@"hashToken"];
        
        [[RKTest sharedManager] postPath:path parameters:dict success:^(AFHTTPRequestOperation *operation, id responseObject) {
            NSLog(@"Post success: %@", responseObject);
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            NSLog(@"Data : %@", [[NSString alloc]initWithData:[operation responseData] encoding:NSUTF8StringEncoding]);
        }];
        

    }
}

-(void)fetchTasksForDefaultUser {
    
    [self fetchTasksForUser:[self defaultUserId] hashtoken:[self defaultUserHashToken]];
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
