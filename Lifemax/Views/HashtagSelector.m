//
//  HashtagSelector.m
//  Lifemax
//
//  Created by Micah Rosales on 2/22/14.
//  Copyright (c) 2014 YUCG. All rights reserved.
//

#import "HashtagSelector.h"

#import "LifemaxHeaders.h"

@interface HashtagSelector ()

@end

@implementation HashtagSelector

- (id)initWithFrame:(CGRect)frame
{
    self = [[[NSBundle mainBundle] loadNibNamed:@"HashtagSelector" owner:self options:nil] objectAtIndex:0] ;
    if (self) {
        // Initialization code
        self.frame = CGRectMake(frame.origin.x, frame.origin.y, frame.size.width, frame.size.height);
    }
    return self;
}

- (UIButton *) newTaskButtonWithSize:(CGSize)size {
    UIButton * button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.layer.cornerRadius = size.height / 2;
    button.layer.borderColor = LIFEMAX_MEDIUM_GRAY_COLOR.CGColor;
    button.layer.borderWidth = 2;
    
    return button;
}

- (void) initialize {
    for (UIView *view in self.subviews) {
        [view removeFromSuperview];
    }
    NSInteger numtags = [self.delegate hashtagSelectorNumberOfTags:self];
    NSInteger numrows = numtags / 2 + numtags % 2;
    
    CGFloat width = (self.bounds.size.width - 20) / 2;
    self.translatesAutoresizingMaskIntoConstraints = NO;
    if(numtags > 0) {
        
        for (int i = 0; i < numtags; i++) {
            UIButton *taskButton = [self newTaskButtonWithSize:CGSizeMake(width, 37)];
        }
    }

    
}

- (void) reload{
    for (UIButton *button in self.subviews) {
        NSString *title = [self.delegate hashtagSelector:self titleForButtonIndex:button.tag - HASHTAG_BUTTON_INDEX_OFFSET];
        [button setTitle:title forState:UIControlStateNormal];
    }
}

- (void)selectTag:(NSInteger) index {
    NSInteger tag = index + HASHTAG_BUTTON_INDEX_OFFSET;
    for (UIButton * button in self.subviews) {
        button.layer.backgroundColor = (button.tag == tag) ?LIFEMAX_MEDIUM_GRAY_COLOR.CGColor : [UIColor clearColor].CGColor;
    }
}


- (IBAction)tagSelected:(UIButton *)sender {
    //tags are padded by 1 because default is 0
    NSInteger tag = sender.tag - HASHTAG_BUTTON_INDEX_OFFSET;
    
    if(tag >= 0) {
        [self.delegate hashtagSelector:self buttonSelectedAtIndex:tag];
        [self selectTag:tag];
    }
}


@end
