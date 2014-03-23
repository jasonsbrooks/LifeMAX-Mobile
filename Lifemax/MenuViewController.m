//
//  MenuViewController.m
//  RevealControllerStoryboardExample
//
//  Created by Nick Hodapp on 1/9/13.
//  Copyright (c) 2013 CoDeveloper. All rights reserved.
//

#import "MenuViewController.h"
#import "SWRevealViewController.h"
#import "NewsFeedViewController.h"
#import "Flurry.h"
@implementation SWUITableViewCell
@end

@implementation MenuViewController

- (void) prepareForSegue: (UIStoryboardSegue *) segue sender: (id) sender
{
    // configure the destination view controller:
    /*if ( [segue.destinationViewController isKindOfClass: [ColorViewController class]] &&
        [sender isKindOfClass:[UITableViewCell class]] )
    {
        UILabel* c = [(SWUITableViewCell *)sender label];
        ColorViewController* cvc = segue.destinationViewController;
        
        cvc.color = c.textColor;
        cvc.text = c.text;
    }*/

    // configure the segue.
    if ( [segue isKindOfClass: [SWRevealViewControllerSegue class]] )
    {
        SWRevealViewControllerSegue* rvcs = (SWRevealViewControllerSegue*) segue;
        
        SWRevealViewController* rvc = self.revealViewController;
        NSAssert( rvc != nil, @"oops! must have a revealViewController" );
        
        NSAssert( [rvc.frontViewController isKindOfClass: [UINavigationController class]], @"oops!  for this segue we want a permanent navigation controller in the front!" );

        rvcs.performBlock = ^(SWRevealViewControllerSegue* rvc_segue, UIViewController* svc, UIViewController* dvc)
        {
            UINavigationController* nc = [[UINavigationController alloc] initWithRootViewController:dvc];
            [Flurry logAllPageViews:nc];

            [rvc setFrontViewController:nc animated:YES];
        };
    }
    
    if([segue.identifier isEqualToString:@"my-story"]) {
        NewsFeedViewController *feed = segue.destinationViewController;
        feed.isStoryController = YES;
    }
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.clearsSelectionOnViewWillAppear = NO;
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if(section == 0) return 3;
    else if(section == 1) return 1;
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{

    
    static NSString *CellIdentifier = @"Cell";

    if(indexPath.section == 0) {
        if(indexPath.row == 0) CellIdentifier = @"feed";
        else if(indexPath.row == 1) CellIdentifier = @"lifelist";
        else CellIdentifier = @"story";
    } else {
        if(indexPath.row == 0) CellIdentifier = @"settings";
        
    }


    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier: CellIdentifier forIndexPath: indexPath];
    UIView * selectedBackgroundView = [[UIView alloc] initWithFrame:cell.bounds];
    [selectedBackgroundView setBackgroundColor:[UIColor colorWithRed:44.0/255 green:62.0/255 blue:80.0/255 alpha:0.7]]; // set color here
    
    CGFloat radius = 5;
    UIView *circleView = [[UIView alloc] initWithFrame:CGRectMake(-radius, selectedBackgroundView.bounds.size.height / 2 - radius, 2* radius, 2*radius)];
    circleView.layer.cornerRadius = radius;
    circleView.layer.masksToBounds = YES;
    circleView.backgroundColor = [UIColor colorWithWhite:1 alpha:.8];
    
    [selectedBackgroundView addSubview:circleView];
    
    [cell setSelectedBackgroundView:selectedBackgroundView];
    
    
    for (UIView *v in cell.contentView.subviews) {
        if([v isKindOfClass:[UILabel class]])
            ((UILabel *)v).font = [UIFont preferredAvenirNextFontWithTextStyle:UIFontTextStyleSubheadlineBold];
    }
    
    return cell;
}

-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if(section == 0) return @"Tasks";
    else if(section == 1) return @"Menu";
    return @"";
}


@end
