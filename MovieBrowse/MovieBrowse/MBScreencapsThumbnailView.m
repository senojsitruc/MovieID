//
//  MBScreencapsThumbnailView.m
//  MovieBrowse
//
//  Created by Curtis Jones on 2012.12.16.
//  Copyright (c) 2012 Curtis Jones. All rights reserved.
//

#import "MBScreencapsThumbnailView.h"

@interface MBScreencapsThumbnailView ()
{
	NSImage *mImage;
	NSImageView *mImageView;
	NSProgressIndicator *mProgressView;
	NSString *mTimestamp;
}
@end

@implementation MBScreencapsThumbnailView

#pragma mark - NSView

/**
 *
 *
 */
- (void)awakeFromNib
{
	mImageView = [[NSImageView alloc] initWithFrame:NSMakeRect(0, 0, NSWidth(self.frame), NSHeight(self.frame))];
	mImageView.imageFrameStyle = NSImageFrameNone;
	mImageView.imageScaling = NSScaleProportionally;
	mImageView.imageAlignment = NSImageAlignCenter;
	[mImageView setEditable:FALSE];
//[self addSubview:mImageView];
	
	mProgressView = [[NSProgressIndicator alloc] initWithFrame:NSMakeRect(NSMidX(self.frame)-10, NSMidY(self.frame)-10, 20, 20)];
	mProgressView.style = NSProgressIndicatorSpinningStyle;
	mProgressView.controlSize = NSRegularControlSize;
	[mProgressView setHidden:TRUE];
	[self addSubview:mProgressView];
}

/**
 *
 *
 */
- (void)drawRect:(NSRect)dirtyRect
{
	NSRect frame = self.frame;
	
	[[NSColor whiteColor] setFill];
	[NSBezierPath fillRect:NSMakeRect(0, 0, frame.size.width, frame.size.height)];
	
	[super drawRect:dirtyRect];
	[mImageView drawRect:dirtyRect];
	
	[[NSColor blackColor] setStroke];
	[NSBezierPath strokeRect:NSMakeRect(0, 0, frame.size.width, frame.size.height)];
	
	if (mTimestamp) {
		[mTimestamp drawInRect:NSMakeRect(5, 5, 200, 15) withAttributes:@{
			NSFontAttributeName: [NSFont systemFontOfSize:12],
			NSForegroundColorAttributeName: [NSColor blackColor]
//		NSStrokeWidthAttributeName: @(1.0),
//		NSStrokeColorAttributeName: [NSColor blackColor]
		}];
	}
}





#pragma mark - Accessors

/**
 *
 *
 */
- (void)setLoading:(BOOL)loading
{
	if (loading) {
		[mProgressView setHidden:FALSE];
		[mProgressView startAnimation:nil];
	}
	else {
		[mProgressView setHidden:TRUE];
		[mProgressView stopAnimation:nil];
	}
}

/**
 *
 *
 */
- (BOOL)loading
{
	return ![mProgressView isHidden];
}

/**
 *
 *
 */
- (NSImage *)image
{
	return mImage;
}

/**
 *
 *
 */
- (void)setImage:(NSImage *)image
{
	mImageView.image = (mImage = image);
	[self setNeedsDisplay:TRUE];
}

/**
 *
 *
 */
- (NSString *)timestamp
{
	return mTimestamp;
}

/**
 *
 *
 */
- (void)setTimestamp:(NSString *)timestamp
{
	mTimestamp = timestamp;
}

@end
