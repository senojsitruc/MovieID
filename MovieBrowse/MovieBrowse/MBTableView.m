//
//  MBTableView.m
//  MovieBrowse
//
//  Created by Curtis Jones on 2012.12.22.
//  Copyright (c) 2012 Curtis Jones. All rights reserved.
//

#import "MBTableView.h"

@implementation MBTableView

/**
 * http://stackoverflow.com/a/13431004/157141
 *
 */
- (NSView *)hitTest:(NSPoint)aPoint
{
	NSInteger column = [self columnAtPoint: aPoint];
	NSInteger row = [self rowAtPoint: aPoint];
	
	// Give cell view a chance to override table hit testing
	if (row != -1 && column != -1) {
		NSView *cell = [self viewAtColumn:column row:row makeIfNecessary:NO];
		
		// Use cell frame, since convertPoint: doesn't always seem to work.
		NSRect frame = [self frameOfCellAtColumn:column row:row];
		NSView *hit = [cell hitTest: NSMakePoint(aPoint.x + frame.origin.x, aPoint.y + frame.origin.y)];
		
		if (hit)
			return hit;
	}
	
	return [super hitTest: aPoint];
}

@end
