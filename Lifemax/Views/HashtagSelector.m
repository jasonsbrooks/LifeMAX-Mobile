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
@property (nonatomic, strong) IBOutlet UIButton *dropdownButton;
@property (nonatomic, strong) IBOutlet UIButton *lastButton;
@property (nonatomic, strong) IBOutlet NSLayoutConstraint *bottomConstraint;

@end

@implementation HashtagSelector
@synthesize expanded = _expanded;

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
    button.titleLabel.font = [UIFont preferredAvenirNextFontWithTextStyle:UIFontTextStyleCaption1];

    [button setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [button setTitleColor: LIFEMAX_LIGHT_GRAY_COLOR forState:UIControlStateHighlighted];
    

    button.titleLabel.adjustsFontSizeToFitWidth = YES;
    button.titleLabel.minimumScaleFactor = .5;
    
    [button addTarget:self action:@selector(tagSelected:) forControlEvents:UIControlEventTouchUpInside];
//    button.showsTouchWhenHighlighted = YES;
    return button;
}

- (void) initialize {
    for (UIView *view in self.subviews) {
        [view removeFromSuperview];
    }
    NSInteger numtags = [self.delegate hashtagSelectorNumberOfTags:self];
    
    CGSize size = CGSizeMake((self.bounds.size.width - 20) / 2, 37);
    self.translatesAutoresizingMaskIntoConstraints = NO;
    
    UIButton *dropdown = [UIButton buttonWithType:UIButtonTypeCustom];
    dropdown.translatesAutoresizingMaskIntoConstraints = NO;
    UILabel *titleLabel = [[UILabel alloc]initWithFrame:CGRectZero];
    titleLabel.text = @"Select Hashtag";
    [titleLabel sizeToFit];
    titleLabel.tag = 11;
    UIImageView *dropdownhandle = [[UIImageView alloc]initWithImage:[UIImage imageNamed:@"list-dropdown"]];
    [dropdown sizeToFit];
    dropdownhandle.contentMode = UIViewContentModeCenter;
    titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    dropdownhandle.translatesAutoresizingMaskIntoConstraints = NO;
    
    [dropdown addSubview:titleLabel]; [dropdown addSubview:dropdownhandle];
    [dropdown addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[title]-(>=10)-[icon(==iconw)]-15-|" options:NSLayoutFormatAlignAllCenterY metrics:@{@"iconw" : @(dropdownhandle.bounds.size.width)} views:@{@"title" : titleLabel, @"icon" : dropdownhandle}]];
    [dropdown addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[title]|" options:0 metrics:nil views:@{@"title" : titleLabel, @"icon" : dropdownhandle}]];
    
    [dropdown addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[icon]|" options:0 metrics:nil views:@{@"title" : titleLabel, @"icon" : dropdownhandle}]];
    [self addSubview:dropdown];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[dropdown]|" options:NSLayoutFormatAlignAllCenterY metrics:nil views:NSDictionaryOfVariableBindings(dropdown)]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[dropdown(28)]" options:0 metrics:nil views:NSDictionaryOfVariableBindings(dropdown)]];
    
    dropdown.showsTouchWhenHighlighted = YES;
    [dropdown addTarget:self action:@selector(toggleDropdown:) forControlEvents:UIControlEventTouchUpInside];
    UIFont *dropdownFont = [UIFont preferredAvenirNextFontWithTextStyle:UIFontTextStyleBody];
;
    [titleLabel setFont:dropdownFont];
    
    self.dropdownButton = dropdown;
    
    UIView *ref = dropdown;
    NSNumber *verticalSpacing = @(10);

    for (int i = 0; i < numtags; i+=2) {
        if(i == 0) {
            UIButton *button1 = [self newTaskButtonWithHeight:size.height];
            UIButton *button2 = [self newTaskButtonWithHeight:size.height];
            NSString *title1 = [self.delegate hashtagSelector:self titleForButtonIndex:i];
            NSString *title2 = [self.delegate hashtagSelector:self titleForButtonIndex:i + 1];
            [button1 setTitle:title1 forState:UIControlStateNormal];
            [button2 setTitle:title2 forState:UIControlStateNormal];
            button1.tag = i + HASHTAG_BUTTON_INDEX_OFFSET;
            button2.tag = i + 1 + HASHTAG_BUTTON_INDEX_OFFSET;

            [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[ref]-(vspace)-[button1]"
                                                                         options:0
                                                                         metrics:@{@"vspace" : verticalSpacing}
                                                                           views:NSDictionaryOfVariableBindings(button1, ref)]];
            
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
            
        
            [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[ref]-(vspace)-[button1]"
                                                                         options:0
                                                                         metrics:@{@"vspace" : verticalSpacing}
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

            
            [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[ref]-(vspace)-[button1]"
                                                                         options:0
                                                                         metrics:@{@"vspace" : verticalSpacing}
                                                                           views:NSDictionaryOfVariableBindings(button1, ref)]];
            
            [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[button1(==ref)]"
                                                                         options:0
                                                                         metrics:nil
                                                                           views:NSDictionaryOfVariableBindings(button1, ref)]];
            ref = button1;
        }
    }
    self.lastButton = (UIButton *)ref;

    self.bottomConstraint = [NSLayoutConstraint constraintWithItem:ref attribute:NSLayoutAttributeBottom
                                                         relatedBy:NSLayoutRelationEqual
                                                            toItem:self
                                                         attribute:NSLayoutAttributeBottom
                                                        multiplier:1
                                                          constant:0];
    [self addConstraint:self.bottomConstraint];
}
- (void) toggleDropdown:(id)sender {
    self.expanded = !self.expanded;
}

-(BOOL)expanded {
    return _expanded;
}

- (void) setExpanded:(BOOL)expanded {
    [self layoutIfNeeded];
    [UIView animateWithDuration:.4 animations:^{
        [self removeConstraint:self.bottomConstraint];
        id seconditem = expanded ? self.lastButton : self.dropdownButton;
        self.bottomConstraint = [NSLayoutConstraint constraintWithItem:seconditem attribute:NSLayoutAttributeBottom
                                                             relatedBy:NSLayoutRelationEqual
                                                                toItem:self
                                                             attribute:NSLayoutAttributeBottom
                                                            multiplier:1
                                                              constant:0];
        [self addConstraint:self.bottomConstraint];
        [self layoutIfNeeded];

    } completion:^(BOOL finished) {
    }];
    
    _expanded = expanded;
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
        [button setTitleColor: (button.tag == tag) ? [UIColor whiteColor] : [UIColor blackColor] forState:UIControlStateNormal];
        if(button.tag == tag) ((UILabel *)[self.dropdownButton viewWithTag:11]).text = [self.delegate hashtagSelector:self titleForButtonIndex:index];
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
