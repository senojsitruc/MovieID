//
//  NSPopUpButton+Additions.m
//  MovieBrowse
//
//  Created by Curtis Jones on 2012.12.29.
//  Copyright (c) 2012 Curtis Jones. All rights reserved.
//

#import "NSPopUpButton+Additions.h"

@implementation NSPopUpButton (Additions)

/**
 *
 *
 */
- (void)addItemWithTitle:(NSString *)title andTag:(NSInteger)tag
{
	[self.menu addItemWithTitle:title action:nil keyEquivalent:@""].tag = tag;
}

@end
