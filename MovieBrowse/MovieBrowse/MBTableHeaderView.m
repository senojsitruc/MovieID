//
//  MBPopUpTableHeaderView.m
//  MovieBrowse
//
//  Created by Curtis Jones on 2012.10.22.
//  Copyright (c) 2012 Curtis Jones. All rights reserved.
//
//  http://forums.macnn.com/t/304072/problem-of-nspopupbuttoncell-within-nstableheaderview
//

#import "MBTableHeaderView.h"

@implementation MBTableHeaderView

- (void)mouseDown:(NSEvent *)theEvent
{
	// Figure which column, if any, was clicked
	NSPoint clickedPoint = [self convertPoint:theEvent.locationInWindow fromView:nil];
	NSInteger columnIndex = [self columnAtPoint:clickedPoint];
	
	if (columnIndex < 0)
		return [super mouseDown:theEvent];
	
	NSRect columnRect = [self headerRectOfColumn:columnIndex];
	
	// I want to preserve column resizing. If you do not, remove this
	if (![self mouse:clickedPoint inRect:NSInsetRect(columnRect, 3, 0)])
		return [super mouseDown:theEvent];
	
	// Now, pop the cell's menu
	[[[self.tableView.tableColumns objectAtIndex:columnIndex] headerCell] performClickWithFrame:columnRect inView:self];
}

- (BOOL)isOpaque;
{
	return FALSE;
}

@end
