//
//  MBGenreTableView.m
//  MovieBrowse
//
//  Created by Curtis Jones on 1/29/13.
//  Copyright (c) 2013 Curtis Jones. All rights reserved.
//

#import "MBGenreTableView.h"

@implementation MBGenreTableView

- (CGFloat)yPositionPastLastRow
{
	// Only draw the grid past the last visible row
	NSInteger numberOfRows = self.numberOfRows;
	CGFloat yStart = 0;
	if (numberOfRows > 0) {
		yStart = NSMaxY([self rectOfRow:numberOfRows - 1]);
	}
	return yStart;
}

- (void)drawGridInClipRect:(NSRect)clipRect
{
	// Only draw the grid past the last visible row
	CGFloat yStart = [self yPositionPastLastRow];
	// Draw the first separator one row past the last row
	yStart += self.rowHeight;
	
	// One thing to do is smarter clip testing to see if we actually need to draw!
	NSRect boundsToDraw = self.bounds;
	NSRect separatorRect = boundsToDraw;
	separatorRect.size.height = 1;
	while (yStart < NSMaxY(boundsToDraw)) {
		separatorRect.origin.y = yStart;
		drawSeparatorInRect(separatorRect);
		yStart += self.rowHeight;
	}
}

- (void)setFrameSize:(NSSize)size
{
	[super setFrameSize:size];
	// We need to invalidate more things when live-resizing since we fill with a gradient and stroke
	if ([self inLiveResize]) {
		CGFloat yStart = [self yPositionPastLastRow];
		if (NSHeight(self.bounds) > yStart) {
			// Redraw our horizontal grid lines
			NSRect boundsPastY = self.bounds;
			boundsPastY.size.height -= yStart;
			boundsPastY.origin.y = yStart;
			[self setNeedsDisplayInRect:boundsPastY];
		}
	}
}

static void drawSeparatorInRect (NSRect rect)
{
	static NSGradient *gradient = nil;
	
	if (!gradient)
		gradient = gradientWithTargetColor([NSColor colorWithSRGBRed:.80 green:.80 blue:.80 alpha:1]);
	
	[gradient drawInRect:rect angle:0];
}

static NSGradient* gradientWithTargetColor (NSColor *targetColor)
{
	NSArray *colors = @[[targetColor colorWithAlphaComponent:0], targetColor, targetColor, [targetColor colorWithAlphaComponent:0]];
	const CGFloat locations[4] = { 0.0, 0.35, 0.65, 1.0 };
	return [[NSGradient alloc] initWithColors:colors atLocations:locations colorSpace:[NSColorSpace sRGBColorSpace]];
}

@end
