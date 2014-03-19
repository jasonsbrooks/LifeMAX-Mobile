//
//  TaskCell.h
//  Lifemax
//
//  Created by Micah Rosales on 2/9/14.
//  Copyright (c) 2014 YUCG. All rights reserved.
//

#import <UIKit/UIKit.h>
@class Task;
@interface TaskCell : UITableViewCell

@property (nonatomic, strong)  NSString *title;
@property (nonatomic, readwrite)  NSString *subtitle;



- (void) setTaskImage:(UIImage *)image;
- (void) setTaskImageFromUrl : (NSString *)imageUrl;
- (void) setCheckboxTarget:(id) target action:(SEL) action;
- (void)updateWithTask:(Task *)task ;


@end
