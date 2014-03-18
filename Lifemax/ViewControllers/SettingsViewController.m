//
//  SettingsViewController.m
//  Lifemax
//
//  Created by Micah Rosales on 2/17/14.
//  Copyright (c) 2014 YUCG. All rights reserved.
//

#import "SettingsViewController.h"
#import "SWRevealViewController.h"
#import "LifemaxHeaders.h"
#import "UIAlertView+NSCookbook.h"
#import "WebViewController.h"
@interface SettingsViewController ()

@end

@implementation SettingsViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    SWRevealViewController *revealController = [self revealViewController];
    
    
    [revealController panGestureRecognizer];
    [revealController tapGestureRecognizer];
    
    UIBarButtonItem *revealButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"reveal-icon.png"]
                                                                         style:UIBarButtonItemStyleBordered target:revealController action:@selector(revealToggle:)];
    
    self.navigationItem.leftBarButtonItem = revealButtonItem;
    self.navigationController.navigationBar.translucent = NO;
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if(indexPath.section == 1 && indexPath.row == 0) {
        UIAlertView *logoutAlert = [[UIAlertView alloc]initWithTitle:NSLocalizedString(@"Logout", nil)
                                                             message:NSLocalizedString(@"Are you sure?", nil)
                                                            delegate:nil cancelButtonTitle:NSLocalizedString(@"Cancel", nil) otherButtonTitles:NSLocalizedString(@"OK", nil), nil];
        
        [logoutAlert showWithCompletion:^(UIAlertView *alertView, NSInteger buttonIndex) {
            if(buttonIndex) {
                [[NSNotificationCenter defaultCenter] postNotificationName:LIFEMAX_TRIGGER_LOGOUT object:nil];
            }
        }];
   }
   [self.tableView deselectRowAtIndexPath:indexPath animated:YES];

}


#pragma mark - Navigation

// In a story board-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    if([segue.identifier isEqualToString:@"about_identifier"]) {
        WebViewController *web = [segue destinationViewController];
        web.title = NSLocalizedString(@"About", nil);
        NSURL *helpUrl = [[NSBundle mainBundle] URLForResource:@"about_lifemax" withExtension:@"html"];
        web.url = helpUrl;
    }
}


@end
