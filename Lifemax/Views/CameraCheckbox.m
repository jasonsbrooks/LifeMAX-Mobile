//
//  CameraCheckbox.m
//  Lifemax
//
//  Created by Micah Rosales on 2/9/14.
//  Copyright (c) 2014 YUCG. All rights reserved.
//

#import "CameraCheckbox.h"
#import "UIImageView+AFNetworking.h"
#import <Crashlytics/Crashlytics.h>
@interface CameraCheckbox ()
@property (nonatomic, strong) UIImageView *backgroundImageView;
@property (nonatomic, strong) UIImageView *cameraCheckboxImageView;
@property (nonatomic, strong) UITapGestureRecognizer *tapgr;
@property (nonatomic, weak) id target;
@property (nonatomic) SEL action;

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
        self.backgroundImageView = [[UIImageView alloc]initWithFrame:self.bounds];
        self.backgroundImageView.layer.cornerRadius = 10;
        self.backgroundImageView.layer.masksToBounds = YES;
        self.backgroundImageView.contentMode = UIViewContentModeScaleAspectFill;
        [self addSubview:self.backgroundImageView];
    }
    if(!self.cameraCheckboxImageView) {
        self.cameraCheckboxImageView = [[UIImageView alloc]initWithImage:[UIImage imageNamed:@"todo-camera.png"] highlightedImage:[UIImage imageNamed:@"todo-camera-dark.png"]];
        self.cameraCheckboxImageView.contentMode = UIViewContentModeCenter;
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
    
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[background]|"
                                                                options:0 metrics:nil views:@{@"background" : self.backgroundImageView}]];
    
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[background]|"
                                                                 options:0 metrics:nil views:@{@"background" : self.backgroundImageView}]];
    
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
//    NSLog(@"Touches Began!");
    [self.cameraCheckboxImageView setHighlighted:YES];
}
-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    [self tap:nil];
    [self.cameraCheckboxImageView setHighlighted:NO];


}
-(void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
//    NSLog(@"Touches Canceled");
    [self.cameraCheckboxImageView setHighlighted:NO];
}

- (void)tap:(UITapGestureRecognizer *)tapgr
{
//    NSLog(@"Tap Detected!");

    if(self.target && self.action) {
        [self.target performSelector:self.action withObject:nil afterDelay:0];
    }
}

- (void) addTapTarget:(id) target action:(SEL)action {
    self.target = target;
    self.action = action;
}

- (void) setBackgroundImage:(UIImage *) image {
    [self.backgroundImageView setImage:image];
}

- (void) setBackgroundImageFromUrl:(NSString *)imageUrl {
    if(imageUrl && imageUrl.length > 0){
        [self.backgroundImageView setImageWithURL:[NSURL URLWithString:imageUrl]];
    } else {
        [self.backgroundImageView setImage:nil];
    }
}

- (void) setCompleted:(BOOL)completed {
    if (completed) {
        NSString *highlightImage = self.backgroundImageView.image ? @"todo-check-dark" : @"todo-check";
        NSString *regularImage = !self.backgroundImageView.image ? @"todo-check-dark" : @"todo-check";
        
        [self.cameraCheckboxImageView setImage:[UIImage imageNamed:regularImage]];
        [self.cameraCheckboxImageView setHighlightedImage:[UIImage imageNamed:highlightImage]];
    } else {
        [self.cameraCheckboxImageView setImage:[UIImage imageNamed:@"todo-camera"]];
        [self.cameraCheckboxImageView setHighlightedImage:[UIImage imageNamed:@"todo-camera-dark"]];
    }
}

@end
