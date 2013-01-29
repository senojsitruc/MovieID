//
//  MBGenreRowView.m
//  MovieBrowse
//
//  Created by Curtis Jones on 1/29/13.
//  Copyright (c) 2013 Curtis Jones. All rights reserved.
//

#import "MBGenreRowView.h"

@interface MBGenreRowView ()
{
	BOOL mMouseInside;
	NSTrackingArea *mTrackingArea;
}
@end

@implementation MBGenreRowView





#pragma mark - NSResponder

- (void)setMouseInside:(BOOL)value
{
	if (mMouseInside != value) {
		mMouseInside = value;
		[self setNeedsDisplay:TRUE];
	}
}

- (BOOL)mouseInside
{
	return mMouseInside;
}

- (void)ensureTrackingArea
{
	if (mTrackingArea == nil)
		mTrackingArea = [[NSTrackingArea alloc] initWithRect:NSZeroRect options:NSTrackingInVisibleRect | NSTrackingActiveAlways | NSTrackingMouseEnteredAndExited owner:self userInfo:nil];
}

- (void)updateTrackingAreas
{
	[super updateTrackingAreas];
	[self ensureTrackingArea];
	
	if (![[self trackingAreas] containsObject:mTrackingArea])
		[self addTrackingArea:mTrackingArea];
}

- (void)mouseEntered:(NSEvent *)theEvent
{
	self.mouseInside = TRUE;
}

- (void)mouseExited:(NSEvent *)theEvent
{
	self.mouseInside = FALSE;
}





#pragma mark - NSTableRowView

/**
 * interiorBackgroundStyle is normaly "dark" when the selection is drawn (self.selected == YES) and
 * we are in a key window (self.emphasized == YES). However, we always draw a light selection, so we
 * override this method to always return a light color.
 */
- (NSBackgroundStyle)interiorBackgroundStyle
{
	return NSBackgroundStyleLight;
}

/**
 *
 *
 */
- (void)drawBackgroundInRect:(NSRect)dirtyRect
{
	// fill with the background color
	[self.backgroundColor set];
	NSRectFill(self.bounds);
	
	// Draw a white/alpha gradient
	if (self.mouseInside) {
		NSGradient *gradient = gradientWithTargetColor([NSColor whiteColor]);
		[gradient drawInRect:self.bounds angle:0];
	}
}

/**
 * Only called if the 'selected' property is yes.
 *
 */
- (void)drawSelectionInRect:(NSRect)dirtyRect
{
	// Check the selectionHighlightStyle, in case it was set to None
	if (self.selectionHighlightStyle != NSTableViewSelectionHighlightStyleNone) {
		NSRect selectionBounds = self.bounds;
		selectionBounds.size.width -= 2;
		NSRect selectionRect = NSInsetRect(selectionBounds, 2.5, 0.5);
		
		if (self.superview == self.window.firstResponder)
			[[NSColor colorWithCalibratedWhite:.52 alpha:1.0] setStroke];
		else
			[[NSColor colorWithCalibratedWhite:.72 alpha:1.0] setStroke];
		
		[[NSColor colorWithCalibratedWhite:.82 alpha:1.0] setFill];
		NSBezierPath *selectionPath = [NSBezierPath bezierPathWithRoundedRect:selectionRect xRadius:8 yRadius:8];
		[selectionPath fill];
		[selectionPath stroke];
	}
}

/**
 *
 *
 */
- (void)setFrame:(NSRect)frameRect
{
	[super setFrame:frameRect];
	
	// We need to invalidate more things when live-resizing since we fill with a gradient and stroke
	if ([self inLiveResize]) {
		// Redraw everything if we are using a gradient
		if (self.selected || self.mouseInside) {
			[self setNeedsDisplay:YES];
		} else {
			// Redraw our horizontal grid line, which is a gradient
			[self setNeedsDisplayInRect:[self separatorRect]];
		}
	}
}

/**
 *
 *
 */
- (void)drawSeparatorInRect:(NSRect)dirtyRect
{
	NSRect rect = self.separatorRect;
	static NSGradient *gradient = nil;
	
	if (!gradient)
		gradient = gradientWithTargetColor([NSColor colorWithSRGBRed:.80 green:.80 blue:.80 alpha:1]);
	
	[gradient drawInRect:rect angle:0];
}





#pragma mark - Private

/**
 *
 *
 */
- (NSRect)separatorRect
{
	NSRect separatorRect = self.bounds;
	separatorRect.origin.y = NSMaxY(separatorRect) - 1;
	separatorRect.size.height = 1;
	return separatorRect;
}

/**
 *
 *
 */
static NSGradient* gradientWithTargetColor (NSColor *targetColor)
{
	NSArray *colors = @[[targetColor colorWithAlphaComponent:0], targetColor, targetColor, [targetColor colorWithAlphaComponent:0]];
	const CGFloat locations[4] = { 0.0, 0.35, 0.65, 1.0 };
	return [[NSGradient alloc] initWithColors:colors atLocations:locations colorSpace:[NSColorSpace sRGBColorSpace]];
}

@end
