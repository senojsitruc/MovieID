//
//  MBScreencapsTableView.m
//  MovieBrowse
//
//  Created by Curtis Jones on 2013.02.01.
//  Copyright (c) 2013 Curtis Jones. All rights reserved.
//

#import "MBScreencapsTableView.h"

@interface MBScreencapsTableView ()
{
	NSEvent *mLastMouseDownEvent;
	NSUInteger mLastMouseDownFlags;
}
@end

@implementation MBScreencapsTableView

@synthesize lastMouseDownEvent = mLastMouseDownEvent;
@synthesize lastMouseDownFlags = mLastMouseDownFlags;

/**
 * http://stackoverflow.com/a/13431004/157141
 *
 */
- (NSView *)hitTest:(NSPoint)aPoint
{
	NSInteger column = [self columnAtPoint:aPoint];
	NSInteger row = [self rowAtPoint:aPoint];
	
	if (row != -1 && column != -1) {
		NSView *cell = [self viewAtColumn:column row:row makeIfNecessary:FALSE];
		
		if (cell)
			return cell;
	}
	
	return [super hitTest:aPoint];
}

/**
 *
 *
 */
- (void)mouseDown:(NSEvent *)theEvent
{
	mLastMouseDownEvent = theEvent;
	mLastMouseDownFlags = [NSEvent modifierFlags];
	[super mouseDown:theEvent];
}

@end
