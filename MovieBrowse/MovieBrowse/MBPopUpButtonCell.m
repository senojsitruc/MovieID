//
//  MBPopUpButtonCell.m
//  MovieBrowse
//
//  Created by Curtis Jones on 2012.10.22.
//  Copyright (c) 2012 Curtis Jones. All rights reserved.
//

#import "MBPopUpButtonCell.h"

@implementation MBPopUpButtonCell

/**
 * The controlView should be an MBTableHeaderView. It's superview is an NSClipView and its superview
 * is the NSScrollView.
 */
- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
	[[NSColor whiteColor] setFill];
	[NSBezierPath fillRect:cellFrame];
	
	[[NSColor blackColor] setStroke];
	NSBezierPath *path = [NSBezierPath bezierPath];
	[path moveToPoint:NSMakePoint(cellFrame.origin.x, cellFrame.origin.y + cellFrame.size.height)];
	[path lineToPoint:NSMakePoint(cellFrame.origin.x + cellFrame.size.width, cellFrame.origin.y + cellFrame.size.height)];
	[path stroke];
	
	NSDictionary *textAttrs = @{ NSFontAttributeName:[NSFont boldSystemFontOfSize:10] };
	
	if (!self.label)
		self.label = @"";
	
	NSSize textSize = [self.label sizeWithAttributes:textAttrs];
	NSRect textFrame = NSMakeRect(cellFrame.origin.x+5, cellFrame.origin.y+((cellFrame.size.height-textSize.height)/2), cellFrame.size.width-10, textSize.height);
	
	[self.label drawInRect:textFrame withAttributes:textAttrs];
	
	NSImage *image = [NSImage imageNamed:@"UpDownArrow.png"];
	[image drawAtPoint:NSMakePoint(cellFrame.origin.x+5+textSize.width+5, cellFrame.origin.y+9) fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1];
}

/**
 *
 *
 */
- (void)performClickWithFrame:(NSRect)frame inView:(NSView *)controlView
{
	if (_willDisplayHandler)
		_willDisplayHandler();
	
	NSEvent *event = [NSEvent mouseEventWithType:NSLeftMouseUp
																			location:[controlView.window.contentView convertPoint:frame.origin fromView:controlView.superview]
																 modifierFlags:0
																		 timestamp:NSTimeIntervalSince1970
																	windowNumber:controlView.window.windowNumber
																			 context:nil
																	 eventNumber:0
																		clickCount:0
																			pressure:0.1];
	
	[NSMenu popUpContextMenu:self.menu withEvent:event forView:controlView.window.contentView];
}

@end
