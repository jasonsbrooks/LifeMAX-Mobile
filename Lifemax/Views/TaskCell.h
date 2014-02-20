//
//  TaskCell.h
//  Lifemax
//
//  Created by Micah Rosales on 2/9/14.
//  Copyright (c) 2014 YUCG. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TaskCell : UITableViewCell

@property (nonatomic, strong) IBOutlet NSString *title;
@property (nonatomic, readwrite) IBOutlet NSString *subtitle;
@property (nonatomic, readwrite) IBOutlet NSString *date;
@property (nonatomic, readwrite) IBOutlet NSString *time;


- (void) setTaskImage:(UIImage *)image;
- (void) setTaskImageFromUrl : (NSString *)imageUrl;
- (void) setCheckboxTarget:(id) target action:(SEL) action;


@end
