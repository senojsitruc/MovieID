//
//  MBScroller.m
//  MovieBrowse
//
//  Created by Curtis Jones on 1/28/13.
//  Copyright (c) 2013 Curtis Jones. All rights reserved.
//

#import "MBScroller.h"

@implementation MBScroller

- (id)initWithFrame:(NSRect)frame
{
	self = [super initWithFrame:frame];
	
	if (self) {
		// Initialization code here.
	}
	
	return self;
}

- (void)drawRect:(NSRect)dirtyRect
{
	NSLog(@"%s.. %@, %@, %@", __PRETTY_FUNCTION__, NSStringFromRect(dirtyRect), NSStringFromRect(self.bounds), self.superview);
	
	[super drawRect:dirtyRect];
//NSLog(@"%s.. %@", __PRETTY_FUNCTION__, NSStringFromRect(dirtyRect));
	
	[[NSColor blackColor] setStroke];
	NSBezierPath *path = [NSBezierPath bezierPath];
	[path moveToPoint:NSMakePoint(self.bounds.size.width-1.5, 0)];
	[path lineToPoint:NSMakePoint(self.bounds.size.width-1.5, self.bounds.size.height)];
	[path setLineWidth:1];
	[path stroke];
}

@end
