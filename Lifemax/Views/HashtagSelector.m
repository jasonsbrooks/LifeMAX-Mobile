//
//  HashtagSelector.m
//  Lifemax
//
//  Created by Micah Rosales on 2/22/14.
//  Copyright (c) 2014 YUCG. All rights reserved.
//

#import "HashtagSelector.h"

@interface HashtagSelector ()
@property (nonatomic, strong) UIView *shadowView;
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
-(UIView *)shadowView {
    if (!_shadowView) {
        _shadowView = [[UIView alloc] initWithFrame:CGRectZero];
        _shadowView.backgroundColor = [UIColor colorWithWhite:.5 alpha:.3];
        _shadowView.layer.masksToBounds = YES;
        [self addSubview:_shadowView];
        [self sendSubviewToBack:_shadowView];

    }
    return _shadowView;
}

- (void) reloadTagNames {
    for (UIButton *button in self.subviews) {
        NSString *title = [self.delegate hashtagSelector:self titleForButtonIndex:button.tag - HASHTAG_BUTTON_INDEX_OFFSET];
        [button setTitle:title forState:UIControlStateNormal];
    }
}

- (void)selectTag:(NSInteger) tag {
    tag = tag + HASHTAG_BUTTON_INDEX_OFFSET;
    UIButton *button = (UIButton *)[self viewWithTag:tag];
    if([button isKindOfClass:[UIButton class]]) {
        self.shadowView.frame = button.frame;
        self.shadowView.layer.cornerRadius = button.frame.size.height/2;
    }
    else {
        self.shadowView.frame = CGRectZero;
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
