//
//  AppDelegate.m
//  Lifemax
//
//  Created by Micah Rosales on 2/9/14.
//  Copyright (c) 2014 YUCG. All rights reserved.
//

#import "AppDelegate.h"
#import "SWRevealViewController.h"
#import "MenuViewController.h"
#import "LifeListViewController.h"
#import <FacebookSDK/FacebookSDK.h>

#import "RKTest.h"

#import "NSString+MD5.h"

#import "LMRestKitManager.h"
#import "LifemaxHeaders.h"

@interface AppDelegate () <SWRevealViewControllerDelegate>
@property BOOL dismissing;
@end

@implementation AppDelegate

@synthesize window = _window;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.dismissing = NO;
    [FBLoginView class];
    
    RKLogConfigureByName("RestKit", RKLogLevelCritical);
    //    RKLogConfigureByName("RestKit/ObjectMapping", RKLogLevelTrace);
    RKLogConfigureByName("RestKit/Network", RKLogLevelCritical);
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(facebookLoginSuccess) name:@"FACEBOOK_DID_LOGIN_NOTIFICATION" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(triggerLogout:) name:LIFEMAX_TRIGGER_LOGOUT object:nil];
    
	UIWindow *window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
	self.window = window;
    
    NSString *storyboardName  = [[NSBundle mainBundle].infoDictionary objectForKey:@"UIMainStoryboardFile"];
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:storyboardName bundle:[NSBundle mainBundle]];
    
    
	LifeListViewController *frontViewController = [storyboard instantiateViewControllerWithIdentifier:@"LifeListViewController"];
	MenuViewController *rearViewController = [storyboard instantiateViewControllerWithIdentifier:@"MenuViewController"];
	
	UINavigationController *frontNavigationController = [[UINavigationController alloc] initWithRootViewController:frontViewController];
    UINavigationController *rearNavigationController = [[UINavigationController alloc] initWithRootViewController:rearViewController];
	
	SWRevealViewController *revealController = [[SWRevealViewController alloc] initWithRearViewController:rearNavigationController frontViewController:frontNavigationController];
    revealController.delegate = self;
    
    
    self.revealViewController = revealController;
    
    //revealController.bounceBackOnOverdraw=NO;
    //revealController.stableDragOnOverdraw=YES;
    
    
    [[UINavigationBar appearance] setTitleTextAttributes:@{
                                                           NSForegroundColorAttributeName: [UIColor colorWithRed:255.0/255.0 green:255.0/255.0 blue:255.0/255.0 alpha:1.0],
                                                           NSFontAttributeName: [UIFont fontWithName:@"Georgia-Bold" size:0.0],
                                                           }];
    
    [[UINavigationBar appearance] setBarTintColor:[UIColor colorWithRed:52/255.0 green:152/255.0 blue:219/255.0 alpha:1]];
    [[UINavigationBar appearance] setTintColor:[UIColor colorWithRed:236/255.0 green:240/255.0 blue:241/255.0 alpha:1]];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
    
	
	self.window.rootViewController = self.revealViewController;
	[self.window makeKeyAndVisible];
    
    
    [[LMRestKitManager sharedManager] initializeMappings];

    
	return YES;
}

- (void) disablePanning:(id) sender {
    self.revealViewController.panGestureRecognizer.enabled = NO;
}
- (void) enablePanning:(id) sender {
    self.revealViewController.panGestureRecognizer.enabled = YES;
}


- (BOOL)application:(UIApplication *)application
            openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication
         annotation:(id)annotation {
    
    // Call FBAppCall's handleOpenURL:sourceApplication to handle Facebook app responses
    BOOL wasHandled = [FBAppCall handleOpenURL:url sourceApplication:sourceApplication];
    if(wasHandled && !self.dismissing) [self checkLogin];
    // You can add your app-specific url handling code here if needed
    
    return wasHandled;
}

-(void)applicationDidBecomeActive:(UIApplication *)application {
    [self checkLogin];
}

-(void)applicationWillEnterForeground:(UIApplication *)application
{
//    [self checkLogin];
}

-(void)checkLogin
{
    BOOL loggedIn = NO;
    if (FBSession.activeSession.isOpen)
    {
        loggedIn = YES;
    } else {
        // try to open session with existing valid token
        NSArray *permissions = nil;
        FBSession *session = [[FBSession alloc] initWithPermissions:permissions];
        [FBSession setActiveSession:session];
        if([FBSession openActiveSessionWithAllowLoginUI:NO]) {
            loggedIn = YES;
        } else {
            loggedIn = NO;
            
        }
    }
    
    if(!loggedIn)
    {
        NSLog(@"Check Login, Not Logged in : %@", self.window.rootViewController);
        [self performSelector:@selector(presentLoginController) withObject:nil afterDelay:.2];
    }
    else
        [self facebookLoginSuccess];
}

-(void) presentLoginController {
    NSString *storyboardName  = [[NSBundle mainBundle].infoDictionary objectForKey:@"UIMainStoryboardFile"];
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:storyboardName bundle:[NSBundle mainBundle]];
    
    UIViewController * loginController = [storyboard instantiateViewControllerWithIdentifier:@"LoginController"];
    [self.window.rootViewController presentViewController:loginController animated:YES completion:nil];
}

- (void)facebookLoginSuccess {
    NSString *token = [[[FBSession activeSession] accessTokenData] accessToken];
    NSLog(@"Facebook Login Success!");
    
    [self triggerLMLoginWithToken:token];
    
    if (self.revealViewController.presentedViewController && !self.dismissing) {
        self.dismissing = YES;
        [self dismissLoginController];
    }
}

- (void)triggerLMLoginWithToken:(NSString *)fbAccessToken {
    
    [[RKTest sharedManager] getPath:@"/api/login" parameters:@{ @"userToken": fbAccessToken} success:^(AFHTTPRequestOperation *operation, id jsonResponse) {
        [self saveLifemaxLogin:jsonResponse];
        [[LMRestKitManager sharedManager] fetchTasksForDefaultUser];
        NSLog(@"Lifemax Login Success!");
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if ([operation.responseString isEqualToString:@"Error: User does not exist!"] ) {
            [[RKTest sharedManager] postPath:@"/api/register" parameters:@{@"shortToken" : fbAccessToken, @"privacy" : @(0) } success:^(AFHTTPRequestOperation *operation, id responseObject) {
                NSLog(@"Register success!");
                NSLog(@"REgister Response: %@", responseObject);
                [self triggerLMLoginWithToken:fbAccessToken];
            } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                NSLog(@"Lifemax failed to register an acount: %@", [error localizedDescription]);
                NSLog(@"Register Response: %@", operation.responseString);
            }];
        } else {
            NSLog(@"[LM-Login] Error : %@", [error localizedDescription]);
            NSLog(@"[LM-Login] Response : %@", operation.responseString);
            NSLog(@"[LM-Login] Request : %@", operation.request.URL);
        }
    }];
}

-(void)triggerLogout:(id)sender {
    [FBSession.activeSession closeAndClearTokenInformation ];
    [self checkLogin];
}

- (void) saveLifemaxLogin:(id)loginResponse {
    NSUserDefaults *stdDefaults = [NSUserDefaults standardUserDefaults];
    [stdDefaults setObject:loginResponse forKey:LIFEMAX_LOGIN_INFORMATION_KEY];
    [stdDefaults synchronize];
    
    
    [[NSNotificationCenter defaultCenter] postNotificationName:LIFEMAX_LOGGED_IN object:loginResponse];
    
    NSString *tok = [loginResponse objectForKey:@"authToken"];
    NSString *tasksPath = [NSString stringWithFormat:@"/api/user/%@/tasks", [loginResponse objectForKey:@"id"]];
//    NSString *deleteTasksPath = [NSString stringWithFormat:@"/api/user/%@/deletetasks", [loginResponse objectForKey:@"id"]];
    
    NSDictionary *postparams = @{
                                 @"description": @"code lifemax app",
                                 @"endtime": @"2014-02-24T02:00:00Z",
                                 @"hashToken": [tok md5],
                                 @"hashtag": @"#raging",
                                 @"location": @"zoo",
                                 @"name": @"CodeCodeCode",
                                 @"pictureurl": @"",
                                 @"recurrence": @"RRULE:FREQ=WEEKLY;UNTIL=20140701T100000-07:00",
                                 @"starttime": @"2014-02-23T19:25:00Z"
                                 };
    
    BOOL post = NO;
    
    if(post) {
        [[RKTest sharedManager] postPath:tasksPath parameters:postparams success:^(AFHTTPRequestOperation *operation, id responseObject) {
            NSLog(@"Post success: %@", responseObject);
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            NSLog(@"Data : %@", [[NSString alloc]initWithData:[operation responseData] encoding:NSUTF8StringEncoding]);
        }];

    } else {
        
        [[LMRestKitManager sharedManager] fetchFeedTasksForUser:[loginResponse objectForKey:@"id"] hashtag:nil maxResults:50 hashtoken:[tok md5]];
        
//        [[LMRestKitManager sharedManager] fetchTasksForDefaultUser];

        /*
        [[RKTest sharedManager] getPath:tasksPath parameters:params success:^(AFHTTPRequestOperation *operation, id jsonResponse) {
            NSDictionary *task = [jsonResponse lastObject];
            
            
            if(task) {
                NSDictionary *extendedProps = task[@"extendedProperties"][@"shared"];
                
                NSLog(@"TaskDescription: %@", [task objectForKey:@"description"]);
                NSLog(@"Task ID: %@", [task objectForKey:@"id"]);
                NSLog(@"Task Summary: %@", [task objectForKey:@"summary"]);
                NSLog(@"Extended Props: %@", extendedProps);
                NSLog(@"Starts : %@", task[@"start"][@"dateTime"]);
                NSLog(@"ends : %@", task[@"end"][@"dateTime"]);
                NSLog(@"Updated : %@", task[@"updated"]);
            }

            
         
             NSDictionary * task1 = [jsonResponse lastObject];
             NSLog(@"Fetch Headers : %@", [operation.request allHTTPHeaderFields]);
             if (task1) {
             [[RKTest sharedManager] postPath:deleteTasksPath parameters:@{@"hashToken" : [tok md5], @"eventId" : task1[@"id"]} success:^(AFHTTPRequestOperation *operation, id responseObject) {
             NSLog(@"Delete Successful! : %@", responseObject);
             } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
             NSLog(@"Delete Headers : %@", [operation.request allHTTPHeaderFields]);
             NSLog(@"Delete Response: %@", operation.responseString);
             }];
             }
            
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            NSLog(@"Error : %@", operation.responseString);
            NSLog(@"Operation path: %@ ", operation.request.URL);
        }];
    */
    }
    
    
    
    

     
    
    
    
    
}

-(void)dismissLoginController {
    if(self.window.rootViewController.presentedViewController)
        [self.window.rootViewController dismissViewControllerAnimated:YES completion:^{
            self.dismissing = NO;
        }];
    
}

#define LogDelegates 0

#if LogDelegates
- (NSString*)stringFromFrontViewPosition:(FrontViewPosition)position
{
    NSString *str = nil;
    if ( position == FrontViewPositionLeftSideMostRemoved ) str = @"FrontViewPositionLeftSideMostRemoved";
    if ( position == FrontViewPositionLeftSideMost) str = @"FrontViewPositionLeftSideMost";
    if ( position == FrontViewPositionLeftSide) str = @"FrontViewPositionLeftSide";
    if ( position == FrontViewPositionLeft ) str = @"FrontViewPositionLeft";
    if ( position == FrontViewPositionRight ) str = @"FrontViewPositionRight";
    if ( position == FrontViewPositionRightMost ) str = @"FrontViewPositionRightMost";
    if ( position == FrontViewPositionRightMostRemoved ) str = @"FrontViewPositionRightMostRemoved";
    return str;
}


- (void)revealController:(SWRevealViewController *)revealController willMoveToPosition:(FrontViewPosition)position
{
    NSLog( @"%@: %@", NSStringFromSelector(_cmd), [self stringFromFrontViewPosition:position]);
}

- (void)revealController:(SWRevealViewController *)revealController didMoveToPosition:(FrontViewPosition)position
{
    NSLog( @"%@: %@", NSStringFromSelector(_cmd), [self stringFromFrontViewPosition:position]);
}

- (void)revealController:(SWRevealViewController *)revealController animateToPosition:(FrontViewPosition)position
{
    NSLog( @"%@: %@", NSStringFromSelector(_cmd), [self stringFromFrontViewPosition:position]);
}

- (void)revealControllerPanGestureBegan:(SWRevealViewController *)revealController;
{
    NSLog( @"%@", NSStringFromSelector(_cmd) );
}

- (void)revealControllerPanGestureEnded:(SWRevealViewController *)revealController;
{
    NSLog( @"%@", NSStringFromSelector(_cmd) );
}

- (void)revealController:(SWRevealViewController *)revealController panGestureBeganFromLocation:(CGFloat)location progress:(CGFloat)progress
{
    NSLog( @"%@: %f, %f", NSStringFromSelector(_cmd), location, progress);
}

- (void)revealController:(SWRevealViewController *)revealController panGestureMovedToLocation:(CGFloat)location progress:(CGFloat)progress
{
    NSLog( @"%@: %f, %f", NSStringFromSelector(_cmd), location, progress);
}

- (void)revealController:(SWRevealViewController *)revealController panGestureEndedToLocation:(CGFloat)location progress:(CGFloat)progress
{
    NSLog( @"%@: %f, %f", NSStringFromSelector(_cmd), location, progress);
}

#endif

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}


- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
