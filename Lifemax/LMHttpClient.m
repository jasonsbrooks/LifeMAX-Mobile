//
//  RKTest.m
//  Lifemax
//
//  Created by Micah Rosales on 2/20/14.
//  Copyright (c) 2014 YUCG. All rights reserved.
//

#import "LMHttpClient.h"
#import <RestKit/RestKit.h>
#import "LifemaxHeaders.h"

@implementation LMHttpClient

#pragma mark - Methods

- (void)setUsername:(NSString *)username andPassword:(NSString *)password
{
    [self clearAuthorizationHeader];
    [self setAuthorizationHeaderWithUsername:username password:password];
}

//- (void)login:(NSString *)fbAccessToken {
//    self set
//}

#pragma mark - Initialization

- (id)initWithBaseURL:(NSURL *)url
{
    self = [super initWithBaseURL:url];
    if(!self)
        return nil;
    
    [self registerHTTPOperationClass:[AFJSONRequestOperation class]];
    
    [self setDefaultHeader:@"Accept" value:@"application/json"];
    [self setParameterEncoding:AFJSONParameterEncoding];
    
    [[AFNetworkActivityIndicatorManager sharedManager] setEnabled:YES];
    
    return self;
}

#pragma mark - Singleton Methods

+ (LMHttpClient *)sharedManager
{
    static dispatch_once_t pred;
    static LMHttpClient *_sharedManager = nil;
    
    dispatch_once(&pred, ^{ _sharedManager = [[self alloc] initWithBaseURL:[NSURL URLWithString:LIFEMAX_ROOT_URL]]; }); // You should probably make this a constant somewhere
    return _sharedManager;
}

@end
