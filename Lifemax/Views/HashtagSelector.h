//
//  HashtagSelector.h
//  Lifemax
//
//  Created by Micah Rosales on 2/22/14.
//  Copyright (c) 2014 YUCG. All rights reserved.
//

#import <UIKit/UIKit.h>

#define HASHTAG_BUTTON_INDEX_OFFSET 20

@class HashtagSelector;
@protocol HashtagSelectorDelegate <NSObject>

- (NSString *)hashtagSelector:(HashtagSelector *)selector titleForButtonIndex:(NSInteger)index;
- (void)hashtagSelector:(HashtagSelector *)selector buttonSelectedAtIndex:(NSInteger)index;

@end

@interface HashtagSelector : UIView

@property (nonatomic, weak) IBOutlet id <HashtagSelectorDelegate> delegate;
- (void) reloadTagNames;
- (void)selectTag:(NSInteger) tag;

@end
