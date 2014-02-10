//
//  LifeListFilter.m
//  Lifemax
//
//  Created by Micah Rosales on 2/9/14.
//  Copyright (c) 2014 YUCG. All rights reserved.
//

#import "LifeListFilter.h"

@interface LifeListFilter () <UITableViewDataSource, UITableViewDelegate>
@property (nonatomic) IBOutlet UILabel *titleLabel;
@property (nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic) IBOutlet UIView *topContainerView;
@end

@implementation LifeListFilter

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

-(void)awakeFromNib {
    [super awakeFromNib];
    [self.tableView setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self collapseView];
}

-(void)setTitle:(NSString *)title
{
    self.titleLabel.text = title;
}



- (void) expandViewToFill : (UIView *)superview{
    CGFloat tableHeight = superview.bounds.origin.y + superview.bounds.size.height;

    self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y, self.frame.size.width, tableHeight );
    self.tableView.alpha = 1;
}

- (void) collapseView{
    self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y, self.frame.size.width, 44);
    self.tableView.alpha = 0;
}


#pragma mark - Table view Delegate
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    self.titleLabel.text = [self.delegate filter:self titleForRow:indexPath.row];
    [self.delegate filter:self didSelectRow:indexPath.row];
    
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"goal_cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    cell.textLabel.text = [self.delegate filter:self titleForRow:indexPath.row];
    
    // Configure the cell...
    
    UIView * selectedBackgroundView = [[UIView alloc] initWithFrame:cell.bounds];
    [selectedBackgroundView setBackgroundColor:[UIColor colorWithRed:44.0/255 green:62.0/255 blue:80.0/255 alpha:0.7]]; // set color here
    
    [cell setSelectedBackgroundView:selectedBackgroundView];
    
    return cell;
}

#pragma mark - Table view datasource
-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.delegate numberOfRowsInFilter:self];
}
@end
