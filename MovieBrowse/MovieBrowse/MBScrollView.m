//
//  MBScrollView.m
//  MovieBrowse
//
//  Created by Curtis Jones on 1/28/13.
//  Copyright (c) 2013 Curtis Jones. All rights reserved.
//

#import "MBScrollView.h"
#import "NSView+Additions.h"

@implementation MBScrollView

- (void)tile
{
	// all of this tiling work is only relevant if we're scrolling through a table view
	if ([self.documentView isKindOfClass:NSTableView.class]) {
		NSTableView *tableView = self.documentView;
		NSTableHeaderView *headerView = tableView.headerView;
		
		NSRect contentFrame = self.bounds;
		contentFrame.origin.y = headerView.frame.size.height;
		contentFrame.size.height -= headerView.frame.size.height;
		
		// very important: tile is always called again after we make any changes. so, before we go any
		// further, if the frame we're about to use is the same as the frame we've already got, then
		// just return.
		if (NSEqualRects(self.contentView.frame, contentFrame))
			return;
		
		self.contentView.frame = contentFrame;
		
		// there's an extra clip view amongst the scroll view's subviews. find this clip view (which is
		// not the content view clip view), remove its NSTableHeaderView and insert the header view
		// from the table.
		{
			NSView *contentView = self.contentView;
			__block NSView *someView = nil;
			
			[self.subviews enumerateObjectsUsingBlock:^ (NSView *subview, NSUInteger ndx, BOOL *stop) {
				if (subview != contentView && [subview isKindOfClass:NSClipView.class])
					someView = subview;
			}];
			
			if (someView) {
				__block NSTableHeaderView *oldHeaderView = nil;
				
				[someView.subviews enumerateObjectsUsingBlock:^ (id _view, NSUInteger ndx, BOOL *stop) {
					if ([_view isKindOfClass:NSTableHeaderView.class] && _view != headerView) {
						oldHeaderView = _view;
						*stop = TRUE;
					}
				}];
				
				if (oldHeaderView) {
					[oldHeaderView removeFromSuperview];
					[someView addSubview:headerView];
					someView.frame = headerView.bounds;
				}
			}
		}
		
		// we don't want our content resized to make room for the scrollers; we want the scrollers on
		// top of the content.
		//
		// the scrollers provide a vertical rule, so we want them to always be visible. the scroller
		// subclass will take care of hiding the scroller knob based on mouse tracking.
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
