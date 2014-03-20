//
//  RKTest.h
//  Lifemax
//
//  Created by Micah Rosales on 2/20/14.
//  Copyright (c) 2014 YUCG. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <RestKit/RestKit.h>

@interface LMHttpClient : AFHTTPClient

- (void)setUsername:(NSString *)username andPassword:(NSString *)password;

+ (LMHttpClient *)sharedManager;


@end
