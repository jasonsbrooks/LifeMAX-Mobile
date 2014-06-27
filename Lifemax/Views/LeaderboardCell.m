//
//  LeaderboardCell.m
//  Lifemax
//
//  Created by Charles Jin on 6/27/14.
//  Copyright (c) 2014 YUCG. All rights reserved.
//

#import "LeaderboardCell.h"

@implementation LeaderboardCell

-(void) configureImage{
    self.profilePicture.layer.cornerRadius = self.profilePicture.frame.size.width / 2;
    self.profilePicture.clipsToBounds = YES;
    
//    self.profilePicture.layer.borderWidth = 3.0f;
//    self.profilePicture.layer.borderColor = [UIColor blackColor].CGColor;
    
    self.contentMode = UIViewContentModeScaleAspectFill;
    self.autoresizingMask = (UIViewAutoresizingFlexibleBottomMargin|UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleWidth);
}

@end
