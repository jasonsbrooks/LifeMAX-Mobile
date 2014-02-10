//
//  CameraCheckbox.m
//  Lifemax
//
//  Created by Micah Rosales on 2/9/14.
//  Copyright (c) 2014 YUCG. All rights reserved.
//

#import "CameraCheckbox.h"

@interface CameraCheckbox ()
@property (nonatomic, strong) UIImageView *backgroundImageView;
@property (nonatomic, strong) UIImageView *cameraCheckboxImageView;
@property (nonatomic, strong) UITapGestureRecognizer *tapgr;

@end

@implementation CameraCheckbox

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        [self configure];
    }
    return self;
}

-(void)awakeFromNib {
    [super awakeFromNib];
    
    [self configure];
    
}
-(void) configure {
    if (!self.backgroundImageView){
//        self.backgroundImageView = [[UIButton alloc] initWithFrame:self.bounds];
//        [self.backgroundImageView addTarget:self action:@selector(tap:) forControlEvents:UIControlEventTouchUpInside];
//        self.backgroundImageView.adjustsImageWhenHighlighted = YES;
//        self.backgroundImageView.showsTouchWhenHighlighted = YES;
        self.backgroundImageView = [[UIImageView alloc]initWithFrame:self.bounds];
        self.backgroundImageView.layer.cornerRadius = 5;
        self.backgroundImageView.layer.masksToBounds = YES;
        [self addSubview:self.backgroundImageView];
    }
    if(!self.cameraCheckboxImageView) {
        self.cameraCheckboxImageView = [[UIImageView alloc]initWithImage:[UIImage imageNamed:@"todo-camera.png"] highlightedImage:[UIImage imageNamed:@"todo-camera-dark.png"]];
        [self.backgroundImageView addSubview:self.cameraCheckboxImageView];
    }
    if(!self.tapgr) {
        self.tapgr = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(tap:)];
//        [self addGestureRecognizer:self.tapgr];
//        self.tapgr.cancelsTouchesInView = YES;
    }
    self.userInteractionEnabled = YES;

    CGSize cameraSize = CGSizeMake(25,18.75);
    self.translatesAutoresizingMaskIntoConstraints = NO;
    self.backgroundImageView.translatesAutoresizingMaskIntoConstraints = NO;
    self.cameraCheckboxImageView.translatesAutoresizingMaskIntoConstraints = NO;
    
    [self addConstraint:[NSLayoutConstraint constraintWithItem:self
                                                     attribute:NSLayoutAttributeLeft
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:self.backgroundImageView
                                                     attribute:NSLayoutAttributeLeft
                                                    multiplier:1
                                                      constant:0]];
    [self addConstraint:[NSLayoutConstraint constraintWithItem:self
                                                     attribute:NSLayoutAttributeRight
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:self.backgroundImageView
                                                     attribute:NSLayoutAttributeRight
                                                    multiplier:1
                                                      constant:0]];
    [self addConstraint:[NSLayoutConstraint constraintWithItem:self
                                                     attribute:NSLayoutAttributeTop
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:self.backgroundImageView
                                                     attribute:NSLayoutAttributeTop
                                                    multiplier:1
                                                      constant:0]];
    [self addConstraint:[NSLayoutConstraint constraintWithItem:self
                                                     attribute:NSLayoutAttributeBottom
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:self.backgroundImageView
                                                     attribute:NSLayoutAttributeBottom
                                                    multiplier:1
                                                      constant:0]];
    
    [self addConstraint:[NSLayoutConstraint constraintWithItem:self.cameraCheckboxImageView
                                                     attribute:NSLayoutAttributeWidth
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:nil
                                                     attribute:NSLayoutAttributeNotAnAttribute
                                                    multiplier:1
                                                      constant:cameraSize.width]];
    [self addConstraint:[NSLayoutConstraint constraintWithItem:self.cameraCheckboxImageView
                                                     attribute:NSLayoutAttributeHeight
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:nil
                                                     attribute:NSLayoutAttributeNotAnAttribute
                                                    multiplier:1
                                                      constant:cameraSize.height]];
    
    [self addConstraint:[NSLayoutConstraint constraintWithItem:self
                                                     attribute:NSLayoutAttributeCenterX
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:self.cameraCheckboxImageView
                                                     attribute:NSLayoutAttributeCenterX
                                                    multiplier:1
                                                      constant:0]];
    
    [self addConstraint:[NSLayoutConstraint constraintWithItem:self
                                                     attribute:NSLayoutAttributeCenterY
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:self.cameraCheckboxImageView
                                                     attribute:NSLayoutAttributeCenterY
                                                    multiplier:1
                                                      constant:0]];
    
    
    
    


    
}
-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event{
    NSLog(@"Touches Began!");
    [self.cameraCheckboxImageView setHighlighted:YES];
}
-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    [self tap:nil];
    [self.cameraCheckboxImageView setHighlighted:NO];


}
-(void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    NSLog(@"Touches Canceled");
    [self.cameraCheckboxImageView setHighlighted:NO];
}

- (void)tap:(UITapGestureRecognizer *)tapgr
{
    NSLog(@"Tap Detected!");
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
