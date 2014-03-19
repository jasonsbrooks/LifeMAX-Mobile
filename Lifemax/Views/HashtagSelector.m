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


- (UIButton *) newTaskButtonWithHeight:(CGFloat)height {
    UIButton * button = [[UIButton alloc]initWithFrame:CGRectZero];
    button.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:button];
    [self addConstraint:[NSLayoutConstraint constraintWithItem:button
                                                     attribute:NSLayoutAttributeHeight
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:nil
                                                     attribute:NSLayoutAttributeNotAnAttribute
                                                    multiplier:1
                                                      constant:height]];
    
    button.layer.cornerRadius = height / 2;
    button.layer.borderColor = LIFEMAX_MEDIUM_GRAY_COLOR.CGColor;
    button.layer.borderWidth = 2;
    [button setTitle:@"" forState:UIControlStateNormal];
    button.titleLabel.font = [UIFont systemFontOfSize:16];

    [button setTitleColor:[UIColor darkTextColor] forState:UIControlStateNormal];
    [button setTitleColor: LIFEMAX_LIGHT_GRAY_COLOR forState:UIControlStateHighlighted];

    [button addTarget:self action:@selector(tagSelected:) forControlEvents:UIControlEventTouchUpInside];
//    button.showsTouchWhenHighlighted = YES;
    return button;
}

- (void) initialize {
    for (UIView *view in self.subviews) {
        [view removeFromSuperview];
    }
    NSInteger numtags = [self.delegate hashtagSelectorNumberOfTags:self];
//    NSInteger numrows = numtags / 2 + numtags % 2;
    
    CGSize size = CGSizeMake((self.bounds.size.width - 20) / 2, 37);
    self.translatesAutoresizingMaskIntoConstraints = NO;
    
    UIView *ref = nil;
    
    for (int i = 0; i <= numtags; i+=2) {
        if(i == 0) {
            UIButton *button1 = [self newTaskButtonWithHeight:size.height];
            UIButton *button2 = [self newTaskButtonWithHeight:size.height];
            NSString *title1 = [self.delegate hashtagSelector:self titleForButtonIndex:i];
            NSString *title2 = [self.delegate hashtagSelector:self titleForButtonIndex:i + 1];
            [button1 setTitle:title1 forState:UIControlStateNormal];
            [button2 setTitle:title2 forState:UIControlStateNormal];
            button1.tag = i + HASHTAG_BUTTON_INDEX_OFFSET;
            button2.tag = i + 1 + HASHTAG_BUTTON_INDEX_OFFSET;

            [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[button1]"
                                                                         options:0
                                                                         metrics:nil
                                                                           views:NSDictionaryOfVariableBindings(button1)]];
            
            [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[button1]-[button2(==button1)]|"
                                                                         options:NSLayoutFormatAlignAllCenterY
                                                                         metrics:nil
                                                                           views:NSDictionaryOfVariableBindings(button1, button2)]];
            ref = button1;
        } else if( i < numtags - 1) {
            UIButton *button1 = [self newTaskButtonWithHeight:size.height];
            UIButton *button2 = [self newTaskButtonWithHeight:size.height];
            NSString *title1 = [self.delegate hashtagSelector:self titleForButtonIndex:i];
            NSString *title2 = [self.delegate hashtagSelector:self titleForButtonIndex:i + 1];
            [button1 setTitle:title1 forState:UIControlStateNormal];
            [button2 setTitle:title2 forState:UIControlStateNormal];
            button1.tag = i + HASHTAG_BUTTON_INDEX_OFFSET;
            button2.tag = i + 1 + HASHTAG_BUTTON_INDEX_OFFSET;

        
            [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[ref]-(5)-[button1]"
                                                                         options:0
                                                                         metrics:nil
                                                                           views:NSDictionaryOfVariableBindings(button1, ref)]];
            
            [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[button1]-[button2(==button1)]|"
                                                                         options:NSLayoutFormatAlignAllCenterY
                                                                         metrics:nil
                                                                           views:NSDictionaryOfVariableBindings(button1, button2)]];
            ref = button1;
        } else  {
            //only 1 in this row
            UIButton *button1 = [self newTaskButtonWithHeight:size.height];
            NSString *title1 = [self.delegate hashtagSelector:self titleForButtonIndex:i];
            [button1 setTitle:title1 forState:UIControlStateNormal];
            button1.tag = i + HASHTAG_BUTTON_INDEX_OFFSET;

            
            [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[ref]-(5)-[button1]"
                                                                         options:0
                                                                         metrics:nil
                                                                           views:NSDictionaryOfVariableBindings(button1, ref)]];
            
            [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[button1(==ref)]"
                                                                         options:0
                                                                         metrics:nil
                                                                           views:NSDictionaryOfVariableBindings(button1, ref)]];
            ref = button1;
        }
    }
    [self addConstraint:[NSLayoutConstraint constraintWithItem:ref attribute:NSLayoutAttributeBottom
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:self
                                                     attribute:NSLayoutAttributeBottom
                                                    multiplier:1
                                                      constant:0]];
    
    

    
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
