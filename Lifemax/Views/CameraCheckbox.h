//
//  CameraCheckbox.h
//  Lifemax
//
//  Created by Micah Rosales on 2/9/14.
//  Copyright (c) 2014 YUCG. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CameraCheckbox : UIView

- (void) addTapTarget:(id) target action:(SEL)action ;

- (void) setBackgroundImage:(UIImage *) image;
- (void) setBackgroundImageFromUrl:(NSString *)imageUrl;

@end
