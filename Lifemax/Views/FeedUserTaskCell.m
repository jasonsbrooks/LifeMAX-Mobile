//
//  FeedUserTaskCell.m
//  Lifemax
//
//  Created by Micah Rosales on 2/9/14.
//  Copyright (c) 2014 YUCG. All rights reserved.
//

#import "FeedUserTaskCell.h"
//#import "UIImageView+URLDownload.h"
#import "UIImageView+AFNetworking.h"

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

@end
