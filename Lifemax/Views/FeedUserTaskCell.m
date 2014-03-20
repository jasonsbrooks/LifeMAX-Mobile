//
//  FeedUserTaskCell.m
//  Lifemax
//
//  Created by Micah Rosales on 2/9/14.
//  Copyright (c) 2014 YUCG. All rights reserved.
//

#import "FeedUserTaskCell.h"
#import "UIImageView+AFNetworking.h"
#import "Task+TaskAdditions.h"
#import "User.h"

@interface FeedUserTaskCell ()
@property (nonatomic, strong) IBOutlet UILabel *actionLabel;
@property (nonatomic, strong) IBOutlet UILabel *timestampLabel;
@property (nonatomic, strong) IBOutlet UILabel *titleLabel;
@property (nonatomic, strong) IBOutlet UILabel *subtitleLabel;
@property (nonatomic, strong) IBOutlet UIImageView *taskImageView;

@end

@implementation FeedUserTaskCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}
-(void)awakeFromNib
{
    [super awakeFromNib];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

-(void)setTitle:(NSString *)title {
    self.titleLabel.text = title;
}
- (void) setAttributedAction:(NSAttributedString *)attributedAction {
    self.actionLabel.attributedText = attributedAction;
}
-(void)setSubtitle:(NSString *)subtitle {
    self.subtitleLabel.text = subtitle;
}
-(void)setFeedAction:(NSString *)description {
    self.actionLabel.text = description;
}
-(void)setTimestamp:(NSString *)timestamp {
    self.timestampLabel.text = timestamp;
}
-(void)setImageFromURL:(NSString *)imageURL {
    [self.taskImageView setImageWithURL:[NSURL URLWithString:imageURL] placeholderImage:[UIImage imageNamed:@"max-placeholder"]];
}

-(void)updateForTask: (Task *)task {
    BOOL suggestion = [task.user.user_id isEqualToNumber:@(0)];
    if (!suggestion) {
        NSMutableAttributedString *atrTitle = [[NSMutableAttributedString alloc]initWithString:task.user.user_name
                                                                                    attributes:@{NSFontAttributeName:
                                                                                                     [UIFont boldSystemFontOfSize:[UIFont systemFontSize]]}];
        NSString *actionstring = [NSString stringWithFormat:@" %@ a goal", [task.completed boolValue] ? @"completed" : @"added" ];
        
        NSDictionary * attributes = @{NSFontAttributeName:
                                          [UIFont systemFontOfSize:[UIFont systemFontSize]]};
        NSAttributedString * subString = [[NSAttributedString alloc] initWithString:actionstring attributes:attributes];
        [atrTitle appendAttributedString:subString];
        
        [self setAttributedAction:atrTitle];
        
        [self setTimestamp:[self dateDiff:[task dateToDisplay]]];
        
    }
    
    [self setTitle:task.name];
    [self setSubtitle:task.hashtag];
    
    [self setImageFromURL:[task imageurlOrDefault]];
}

-(NSString *)dateDiff:(NSDate *)origDate {
    NSDate *todayDate = [NSDate date];
    double ti = [origDate timeIntervalSinceDate:todayDate];
    ti = ti * -1;
    if(ti < 1) {
    	return @"never";
    } else 	if (ti < 60) {
    	return @"less than a minute ago";
    } else if (ti < 3600) {
    	int diff = round(ti / 60);
    	return [NSString stringWithFormat:@"%d minutes ago", diff];
    } else if (ti < 86400) {
    	int diff = round(ti / 60 / 60);
    	return[NSString stringWithFormat:@"%d hours ago", diff];
    } else if (ti < 2629743) {
    	int diff = round(ti / 60 / 60 / 24);
    	return[NSString stringWithFormat:@"%d days ago", diff];
    } else {
    	return @"never";
    }
}

@end
