//
//  MBActorImageView.m
//  MovieBrowse
//
//  Created by Curtis Jones on 2012.10.22.
//  Copyright (c) 2012 Curtis Jones. All rights reserved.
//

#import "MBActorImageView.h"

@implementation MBActorImageView

- (void)drawRect:(NSRect)dirtyRect
{
	NSRect frame = self.frame;
	
	[[NSColor whiteColor] setFill];
	[NSBezierPath fillRect:NSMakeRect(0, 0, frame.size.width, frame.size.height)];
	
	[super drawRect:dirtyRect];
	
	[[NSColor blackColor] setStroke];
	[NSBezierPath strokeRect:NSMakeRect(0, 0, frame.size.width, frame.size.height)];
}

@end
