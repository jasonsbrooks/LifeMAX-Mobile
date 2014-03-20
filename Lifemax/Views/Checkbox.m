//
//  Checkbox.m
//  Lifemax
//
//  Created by Micah Rosales on 3/19/14.
//  Copyright (c) 2014 YUCG. All rights reserved.
//

#import "Checkbox.h"
#define CHECKED_IMAGE @"todo-check-box-checked"
#define UNCHECKED_IMAGE @"todo-check-box"

@implementation Checkbox
@synthesize checked=_checked;
- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        [self initialize];
    }
    return self;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    [self initialize];
}

- (void)toggle {
    self.checked = !self.checked;
}

- (void)initialize {
    self.checked = NO;
    [self addTarget:self action:@selector(toggle) forControlEvents:UIControlEventTouchUpInside];
}

-(void)setChecked:(BOOL)checked {
    _checked = checked;
    [self setImage:[UIImage imageNamed:(checked ? CHECKED_IMAGE : UNCHECKED_IMAGE)] forState:UIControlStateNormal];
}

-(BOOL)checked {
    return _checked;
}







/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
