//
//  FeedUserTaskCell.h
//  Lifemax
//
//  Created by Micah Rosales on 2/9/14.
//  Copyright (c) 2014 YUCG. All rights reserved.
//

#import <UIKit/UIKit.h>
@class Task;
@interface FeedUserTaskCell : UITableViewCell

- (void) setTitle:(NSString *)title;
- (void) setAttributedAction:(NSAttributedString *)attributedAction;
- (void) setTimestamp: (NSString *)timestamp;
- (void) setFeedAction: (NSString *)description;
- (void) setImageFromURL:(NSString *)imageURL;
- (void) setSubtitle: (NSString *) subtitle;

-(UIImageView *)taskImageView;
-(void)updateForTask: (Task *)task ;
@property (nonatomic, strong) IBOutlet UIButton *addButton;
@property (nonatomic, strong) IBOutlet UIButton *doneButton;
@property (nonatomic, strong) IBOutlet UIButton *removeButton;

@end
