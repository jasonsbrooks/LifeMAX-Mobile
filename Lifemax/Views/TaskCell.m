//
//  TaskCell.m
//  Lifemax
//
//  Created by Micah Rosales on 2/9/14.
//  Copyright (c) 2014 YUCG. All rights reserved.
//

#import "TaskCell.h"
#import "CameraCheckbox.h"
#import "Task.h"
@interface TaskCell ()
@property (nonatomic, weak) IBOutlet UILabel *titleLabel;
@property (nonatomic, weak) IBOutlet UILabel *subtitleLabel;

@property (nonatomic, weak) IBOutlet CameraCheckbox *checkbox;

@property (nonatomic, weak) id checkboxTarget;
@property (nonatomic) SEL checkboxAction;

@end

@implementation TaskCell

@synthesize title=_title;
@synthesize desc=_desc;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
        [self configure];
    }
    return self;
}

-(void)awakeFromNib {
    [super awakeFromNib];
    [self configure];
}

- (void)updateWithTask:(Task *)task {
    self.title = task.name ? task.name : @"Task Name";
    self.desc = task.desc;
    self.subtitle = task.hashtag;
//    [self.titleLabel sizeToFit];
    [self.subtitleLabel sizeToFit];
    [self layoutIfNeeded];
    
    if(task.pictureurl && task.pictureurl.length > 0)
        [self setTaskImageFromUrl: task.pictureurl];
    else
        [self setTaskImage:nil];

    if(task.pictureurl)
        [self setTaskImageFromUrl:task.pictureurl];

    //must be after set picture url b/c color depends on image
    [self.checkbox setCompleted:task.completed.boolValue];


}

- (void) configure {
    [self.checkbox addTapTarget:self action:@selector(checkboxTapped)];
    self.titleLabel.font = [UIFont preferredAvenirNextFontWithTextStyle:UIFontTextStyleHeadline];
    self.subtitleLabel.font = [UIFont preferredAvenirNextFontWithTextStyle:UIFontTextStyleCaption1];
    self.titleLabel.minimumScaleFactor = .8;
}

- (void) checkboxTapped {
    if(self.checkboxAction && self.checkboxTarget) {
        [self.checkboxTarget performSelector:self.checkboxAction withObject:self afterDelay:0];
    }
}

- (void) setCheckboxTarget:(id) target action:(SEL) action {
    self.checkboxTarget = target;
    self.checkboxAction = action;
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

- (void) setTaskImage:(UIImage *)image {
    [self.checkbox setBackgroundImage:image];
}
- (void) setTaskImageFromUrl : (NSString *)imageUrl {
    [self.checkbox setBackgroundImageFromUrl:imageUrl];
}


@end
