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
    self.titleLabel.font = [UIFont preferredAvenirNextFontWithTextStyle:UIFontTextStyleCaption2];
    [self collapseView];
}

-(void)setTitle:(NSString *)title
{
    self.titleLabel.text = title;
}

- (void) reload {
    [self.tableView reloadData];
}



- (void) expandViewToFill : (UIView *)superview{
    CGFloat tableHeight = superview.bounds.origin.y + superview.bounds.size.height;

    self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y, self.frame.size.width, tableHeight );
    self.tableView.alpha = 1;
}

- (void) collapseView{
    [self.titleLabel sizeToFit];
    [self layoutIfNeeded];

    self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y, self.frame.size.width, self.topContainerView.bounds.size.height);
    
    self.tableView.alpha = 0;
}


#pragma mark - Table view Delegate
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    self.titleLabel.text = [self.delegate filter:self titleForRow:indexPath.row];
    [self.delegate filter:self didSelectRow:indexPath.row];
    
    [self.tableView reloadData];
    
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"goal_cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    NSString *title = [self.delegate filter:self titleForRow:indexPath.row];
    
    UILabel *label = (UILabel *)[cell.contentView viewWithTag:10];
    label.text = title;
    label.font = [UIFont preferredAvenirNextFontWithTextStyle:UIFontTextStyleCaption2];
    
    UIView *imageview = [cell.contentView viewWithTag:11];
    imageview.hidden = (![self.titleLabel.text isEqualToString: title]);
    // Configure the cell...
    
    
    return cell;
}

-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    UILabel *label = (UILabel *)[cell.contentView viewWithTag:10];
    UIView *imageview = [cell.contentView viewWithTag:11];
    imageview.hidden = (![self.titleLabel.text isEqualToString: label.text]);
}

#pragma mark - Table view datasource
-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.delegate numberOfRowsInFilter:self];
}
@end
