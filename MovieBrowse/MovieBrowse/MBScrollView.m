//
//  MBScrollView.m
//  MovieBrowse
//
//  Created by Curtis Jones on 1/28/13.
//  Copyright (c) 2013 Curtis Jones. All rights reserved.
//

#import "MBScrollView.h"

@implementation MBScrollView

- (void)tile
{
	if ([self.documentView isKindOfClass:NSTableView.class]) {
		NSTableView *tableView = self.documentView;
		NSTableHeaderView *headerView = tableView.headerView;
		
		NSRect contentFrame = self.bounds;
		contentFrame.origin.y = headerView.frame.size.height;
		contentFrame.size.height -= headerView.frame.size.height;
		
		if (NSEqualRects(self.contentView.frame, contentFrame))
			return;
		
		self.contentView.frame = contentFrame;
		
		{
			NSView *contentView = self.contentView;
			__block NSView *someView = nil;
			
			[self.subviews enumerateObjectsUsingBlock:^ (NSView *subview, NSUInteger ndx, BOOL *stop) {
				if (subview != contentView && [subview isKindOfClass:NSClipView.class])
					someView = subview;
			}];
			
			if (someView && someView.subviews.count) {
				[someView.subviews[0] removeFromSuperview];
				[someView addSubview:headerView];
				someView.frame = headerView.bounds;
			}
		}
		
		{
			self.verticalScroller.frame = NSMakeRect(contentFrame.size.width-15, 27, 15, contentFrame.size.height);
			(void)self.verticalScroller;
			[self.verticalScroller removeFromSuperview];
			[self addSubview:self.verticalScroller];
			(void)self.verticalScroller;
			[self.verticalScroller setHidden:FALSE];
		}
	}
}

@end
