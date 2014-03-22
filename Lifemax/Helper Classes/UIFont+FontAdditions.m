//
//  UIFont+FontAdditions.m
//  Lifemax
//
//  Created by Micah Rosales on 3/21/14.
//  Copyright (c) 2014 YUCG. All rights reserved.
//

#import "UIFont+FontAdditions.h"

@implementation UIFont (FontAdditions)

+(UIFont *)preferredAvenirNextFontWithTextStyle:(NSString *)style {
    return [UIFont fontWithDescriptor:[UIFontDescriptor preferredAvenirNextFontDescriptorWithTextStyle:style] size: 0];
}

@end
