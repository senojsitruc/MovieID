//
//  MBImageView.m
//  MovieBrowse
//
//  Created by Curtis Jones on 2012.10.18.
//  Copyright (c) 2012 Curtis Jones. All rights reserved.
//

#import "MBImageView.h"

@implementation MBImageView

- (NSMenu *)menuForEvent:(NSEvent *)theEvent
{
	return [self.superview menuForEvent:theEvent];
}

- (void)mouseDown:(NSEvent *)theEvent
{
	NSLog(@"%s.. %@", __PRETTY_FUNCTION__, theEvent);
	[super mouseDown:theEvent];
}

- (BOOL)acceptsFirstResponder
{
	NSLog(@"%s", __PRETTY_FUNCTION__);
	return TRUE;
}

@end
