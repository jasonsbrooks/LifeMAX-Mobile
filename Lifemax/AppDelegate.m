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
#import "NewsFeedViewController.h"
#import <FacebookSDK/FacebookSDK.h>

#import "LMHttpClient.h"

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
    
    
	NewsFeedViewController *frontViewController = [storyboard instantiateViewControllerWithIdentifier:@"news_feed"];
	MenuViewController *rearViewController = [storyboard instantiateViewControllerWithIdentifier:@"MenuViewController"];
	
	UINavigationController *frontNavigationController = [[UINavigationController alloc] initWithRootViewController:frontViewController];
    UINavigationController *rearNavigationController = [[UINavigationController alloc] initWithRootViewController:rearViewController];

    frontNavigationController.navigationBar.translucent = NO;
    rearNavigationController.navigationBar.translucent = NO;

	SWRevealViewController *revealController = [[SWRevealViewController alloc] initWithRearViewController:rearNavigationController frontViewController:frontNavigationController];
    revealController.delegate = self;
    
    
    self.revealViewController = revealController;
    
    //revealController.bounceBackOnOverdraw=NO;
    //revealController.stableDragOnOverdraw=YES;
    
    
    [[UINavigationBar appearance] setTitleTextAttributes:@{
                                                           NSForegroundColorAttributeName: [UIColor colorWithRed:255.0/255.0 green:255.0/255.0 blue:255.0/255.0 alpha:1.0],
                                                           NSFontAttributeName: [UIFont fontWithName:@"Georgia-Bold" size:0.0],
                                                           }];
    
    [[UINavigationBar appearance] setBarTintColor:LIFEMAX_ROOT_COLOR];
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
    
    [[LMHttpClient sharedManager] getPath:@"/api/login" parameters:@{ @"userToken": fbAccessToken} success:^(AFHTTPRequestOperation *operation, id jsonResponse) {
        [self saveLifemaxLogin:jsonResponse];
        [[LMRestKitManager sharedManager] fetchHashtagListOnCompletion:^(NSArray *hashtags, NSError *error) {
//            NSLog(@"Do something with these hashtags: %@", hashtags);
        }];

        [[LMRestKitManager sharedManager] fetchTasksForDefaultUserOnCompletion:^(BOOL success, NSError *error) {
            NSLog(@"Finished Initial task fetch!");
        } ];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if ([operation.responseString isEqualToString:@"Error: User does not exist!"] ) {
            [[LMHttpClient sharedManager] postPath:@"/api/register" parameters:@{@"shortToken" : fbAccessToken, @"privacy" : @(0) } success:^(AFHTTPRequestOperation *operation, id responseObject) {
                [[NSNotificationCenter defaultCenter] postNotificationName:LIFEMAX_NOTIFICATION_NAME_REGISTER_SUCCESS object:responseObject];
                
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
    
    if(loginResponse)
        [[NSNotificationCenter defaultCenter] postNotificationName:LIFEMAX_NOTIFICATION_NAME_LOGIN_SUCCESS object:loginResponse];
    
}

-(void)dismissLoginController {
    if(self.window.rootViewController.presentedViewController)
        [self.window.rootViewController dismissViewControllerAnimated:YES completion:^{
            self.dismissing = NO;
        }];
    
}

- (void)revealController:(SWRevealViewController *)revealController willMoveToPosition:(FrontViewPosition)position
{
    UINavigationController *navController = (UINavigationController *)revealController.frontViewController;

    if (position == FrontViewPositionRight) {               // Menu will get revealed
        revealController.tapGestureRecognizer.enabled = YES;                 // Enable the tap gesture Recognizer
        
        navController.interactivePopGestureRecognizer.enabled = NO;        // Prevents the iOS7's pan gesture
        navController.topViewController.view.userInteractionEnabled = NO;       // Disable the topViewController's interaction
    }
    else if (position == FrontViewPositionLeft){      // Menu will close
        revealController.tapGestureRecognizer.enabled = NO;
        navController.interactivePopGestureRecognizer.enabled = YES;
        navController.topViewController.view.userInteractionEnabled = YES;

    }
    
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
