//
//  TaskCell.m
//  Lifemax
//
//  Created by Micah Rosales on 2/9/14.
//  Copyright (c) 2014 YUCG. All rights reserved.
//

#import "TaskCell.h"

@interface TaskCell ()
@property (nonatomic, weak) IBOutlet UILabel *titleLabel;
@property (nonatomic, weak) IBOutlet UILabel *subtitleLabel;
@property (nonatomic, weak) IBOutlet UILabel *dateLabel;
@property (nonatomic, weak) IBOutlet UILabel *timeLabel;

@property (nonatomic, weak) IBOutlet UIButton *checkbox;

@end

@implementation TaskCell

@synthesize title=_title;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

-(NSString *)title {
    return self.titleLabel.text;
}

-(void)setTitle:(NSString *)title {
    self.titleLabel.text = title;
}

-(NSString *)subtitle {
    return self.subtitleLabel.text;
}
-(void)setSubtitle:(NSString *)subtitle {
    self.subtitleLabel.text = subtitle;
}

-(NSString *)date {
    return self.dateLabel.text;
}
-(void)setDate:(NSString *)date {
    self.dateLabel.text = date;
}

-(NSString *)time {
    return self.timeLabel.text;
}
-(void)setTime:(NSString *)time {
    self.timeLabel.text = time;
}

-(UIImage *)image {
    return [self.checkbox backgroundImageForState:UIControlStateNormal];
}
-(void)setImage:(UIImage *)image {
    [self.checkbox setBackgroundImage:image forState:UIControlStateNormal];
}


@end
