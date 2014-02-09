//
//  LifeListFilter.m
//  Lifemax
//
//  Created by Micah Rosales on 2/9/14.
//  Copyright (c) 2014 YUCG. All rights reserved.
//

#import "LifeListFilter.h"

@interface LifeListFilter () <UIPickerViewDataSource, UIPickerViewDelegate>
@property (nonatomic) IBOutlet UILabel *titleLabel;
@property (nonatomic) IBOutlet UIPickerView *picker;
@end

@implementation LifeListFilter

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

-(void)awakeFromNib {
    [self collapseView];
}

- (void) expandView {
    
    CGFloat endTopLabel = self.titleLabel.frame.origin.y + self.titleLabel.bounds.size.height;
    
    self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y, self.frame.size.width, endTopLabel + self.picker.bounds.size.height );
    self.picker.frame = CGRectMake(self.picker.frame.origin.x, endTopLabel, self.picker.frame.size.width, self.picker.frame.size.height);
    self.picker.alpha = 1;
    
    NSLog(@"Frame is : (%f, %f) %f x %f)", self.picker.frame.origin.x, self.picker.frame.origin.y,
          self.picker.frame.size.width, self.picker.frame.size.height);
}

- (void) collapseView{
    self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y, self.frame.size.width, 44);
    self.picker.alpha = 0;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

-(void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    self.titleLabel.text = [self.delegate filter:self titleForRow:row];
    [self.delegate filter:self didSelectRow:row];
}

-(NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    return [self.delegate numberOfRowsInFilter:self];
}

-(NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 1;
}

-(NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    return [self.delegate filter:self titleForRow:row];
}

@end
