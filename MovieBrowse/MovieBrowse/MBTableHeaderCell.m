//
//  MBTableHeaderCell.m
//  MovieBrowse
//
//  Created by Curtis Jones on 2012.10.22.
//  Copyright (c) 2012 Curtis Jones. All rights reserved.
//

#import "MBTableHeaderCell.h"

@implementation MBTableHeaderCell

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
	[[NSColor whiteColor] setFill];
	[NSBezierPath fillRect:cellFrame];
	
	[[NSColor blackColor] setStroke];
	NSBezierPath *path = [NSBezierPath bezierPath];
	[path moveToPoint:NSMakePoint(cellFrame.origin.x, cellFrame.origin.y + cellFrame.size.height)];
	[path lineToPoint:NSMakePoint(cellFrame.origin.x + cellFrame.size.width, cellFrame.origin.y + cellFrame.size.height)];
	[path stroke];
	
	NSDictionary *textAttrs = @{
		NSFontAttributeName: [NSFont boldSystemFontOfSize:10]
	};
	
	if (!self.label)
		self.label = @"";
	
	NSSize textSize = [self.label sizeWithAttributes:textAttrs];
	NSRect textFrame = NSMakeRect(cellFrame.origin.x+5, cellFrame.origin.y+((cellFrame.size.height-textSize.height)/2), cellFrame.size.width-10, textSize.height);
	
	[self.label drawInRect:textFrame withAttributes:textAttrs];
}

- (void)performClickWithFrame:(NSRect)frame inView:(NSView *)controlView
{
	
}

@end
