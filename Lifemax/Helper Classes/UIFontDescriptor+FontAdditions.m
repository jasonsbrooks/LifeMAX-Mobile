//
//  UIFontDescriptor+FontAdditions.m
//  Lifemax
//
//  Created by Micah Rosales on 3/21/14.
//  Copyright (c) 2014 YUCG. All rights reserved.
//

#import "UIFontDescriptor+FontAdditions.h"
@implementation UIFontDescriptor (FontAdditions)
+(UIFontDescriptor *)preferredAvenirNextFontDescriptorWithTextStyle:(NSString *)style {
    static dispatch_once_t onceToken;
    static NSDictionary *fontSizeTable;
    dispatch_once(&onceToken, ^{
        fontSizeTable = @{
                          UIFontTextStyleHeadline: @{UIContentSizeCategoryExtraExtraExtraLarge: @(26),
                                                     UIContentSizeCategoryExtraExtraLarge: @(24),
                                                     UIContentSizeCategoryExtraLarge: @(22),
                                                     UIContentSizeCategoryLarge: @(20),
                                                     UIContentSizeCategoryMedium: @(18),
                                                     UIContentSizeCategorySmall: @(16),
                                                     UIContentSizeCategoryExtraSmall: @(14),},
                          
                          UIFontTextStyleHeadlineBold: @{UIContentSizeCategoryExtraExtraExtraLarge: @(26),
                                                     UIContentSizeCategoryExtraExtraLarge: @(24),
                                                     UIContentSizeCategoryExtraLarge: @(22),
                                                     UIContentSizeCategoryLarge: @(20),
                                                     UIContentSizeCategoryMedium: @(18),
                                                     UIContentSizeCategorySmall: @(16),
                                                     UIContentSizeCategoryExtraSmall: @(14),},
                          
                          UIFontTextStyleSubheadline: @{UIContentSizeCategoryExtraExtraExtraLarge: @(22),
                                                        UIContentSizeCategoryExtraExtraLarge: @(20),
                                                        UIContentSizeCategoryExtraLarge: @(17),
                                                        UIContentSizeCategoryLarge: @(16),
                                                        UIContentSizeCategoryMedium: @(14),
                                                        UIContentSizeCategorySmall: @(13),
                                                        UIContentSizeCategoryExtraSmall: @(12),},
                          
                          UIFontTextStyleSubheadlineBold : @{UIContentSizeCategoryExtraExtraExtraLarge: @(22),
                                                        UIContentSizeCategoryExtraExtraLarge: @(20),
                                                        UIContentSizeCategoryExtraLarge: @(17),
                                                        UIContentSizeCategoryLarge: @(16),
                                                        UIContentSizeCategoryMedium: @(14),
                                                        UIContentSizeCategorySmall: @(13),
                                                        UIContentSizeCategoryExtraSmall: @(12),},
                          
                          UIFontTextStyleBody: @{UIContentSizeCategoryExtraExtraExtraLarge: @(24),
                                                 UIContentSizeCategoryExtraExtraLarge: @(22),
                                                 UIContentSizeCategoryExtraLarge: @(21),
                                                 UIContentSizeCategoryLarge: @(20),
                                                 UIContentSizeCategoryMedium: @(18),
                                                 UIContentSizeCategorySmall: @(16),
                                                 UIContentSizeCategoryExtraSmall: @(14),},
                          
                          UIFontTextStyleCaption1: @{UIContentSizeCategoryExtraExtraExtraLarge: @(20),
                                                     UIContentSizeCategoryExtraExtraLarge: @(18),
                                                     UIContentSizeCategoryExtraLarge: @(15),
                                                     UIContentSizeCategoryLarge: @(14),
                                                     UIContentSizeCategoryMedium: @(13),
                                                     UIContentSizeCategorySmall: @(12),
                                                     UIContentSizeCategoryExtraSmall: @(11),},
                          
                          UIFontTextStyleCaption2: @{UIContentSizeCategoryExtraExtraExtraLarge: @(19),
                                                     UIContentSizeCategoryExtraExtraLarge: @(17),
                                                     UIContentSizeCategoryExtraLarge: @(14),
                                                     UIContentSizeCategoryLarge: @(13),
                                                     UIContentSizeCategoryMedium: @(12),
                                                     UIContentSizeCategorySmall: @(12),
                                                     UIContentSizeCategoryExtraSmall: @(11),},
                          
                          
                          UIFontTextStyleFootnote: @{UIContentSizeCategoryExtraExtraExtraLarge: @(17),
                                                     UIContentSizeCategoryExtraExtraLarge: @(15),
                                                     UIContentSizeCategoryExtraLarge: @(12),
                                                     UIContentSizeCategoryLarge: @(12),
                                                     UIContentSizeCategoryMedium: @(11),
                                                     UIContentSizeCategorySmall: @(10),
                                                     UIContentSizeCategoryExtraSmall: @(10),},
                          };
    });
    
    
    NSString *contentSize = [UIApplication sharedApplication].preferredContentSizeCategory;
    
    if([style isEqualToString:(NSString *)UIFontTextStyleSubheadlineBold] ||
       [style isEqualToString:(NSString *)UIFontTextStyleHeadlineBold]) {
        return [UIFontDescriptor fontDescriptorWithName:@"AvenirNext-Bold" size:((NSNumber *)fontSizeTable[style][contentSize]).floatValue];
    }
    
    return [UIFontDescriptor fontDescriptorWithName:@"AvenirNext-Medium" size:((NSNumber *)fontSizeTable[style][contentSize]).floatValue];
}

@end
