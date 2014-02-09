//
//  LifeListFilter.h
//  Lifemax
//
//  Created by Micah Rosales on 2/9/14.
//  Copyright (c) 2014 YUCG. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol LifeListFilterDelegate;

@interface LifeListFilter : UIView

@property (nonatomic, weak) IBOutlet id <LifeListFilterDelegate> delegate;
- (void) expandView;
- (void) collapseView;

@end

@protocol LifeListFilterDelegate <NSObject>

- (void) filter:(LifeListFilter *) filter didSelectRow:(NSInteger)row;
- (NSString *) filter: (LifeListFilter * ) filter titleForRow:(NSInteger) row;
- (NSInteger) numberOfRowsInFilter:(LifeListFilter *) filter;

@end