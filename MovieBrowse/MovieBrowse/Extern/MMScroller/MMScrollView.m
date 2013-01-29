//
//  MMScrollView.m
//  MiniMail
//
//  Created by DINH Viêt Hoà on 24/08/10.
//  Copyright 2011 Sparrow SAS. All rights reserved.
//

#import "MMScrollView.h"

@implementation MMScrollView

- (void)tile
{
	NSRect frame;
	CGFloat height;
	
	self.contentView.frame = self.bounds;
	height = self.bounds.size.height;
	frame = NSMakeRect(self.bounds.size.width - 15, 0, 15, height);
	self.verticalScroller.frame = frame;
	
	(void)self.verticalScroller;
	[self.verticalScroller removeFromSuperview];
	[self addSubview:self.verticalScroller];
	(void)self.verticalScroller;
}

@end
