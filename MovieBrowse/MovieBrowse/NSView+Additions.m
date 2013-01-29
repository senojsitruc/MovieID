//
//  NSView+Additions.m
//  Atelier for Mac
//
//  Created by Curtis Jones on 2013.01.14.
//  Copyright (c) 2013 Curtis Jones. All rights reserved.
//

#import "NSView+Additions.h"

@implementation NSView (Additions)

- (void)removeAllSubviews
{
	[self.subviews enumerateObjectsUsingBlock:^ (id viewObj, NSUInteger viewNdx, BOOL *viewStop) {
		[(NSView *)viewObj removeFromSuperview];
	}];
}

@end
