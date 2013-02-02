//
//  MBScreencapsThumbnailView.m
//  MovieBrowse
//
//  Created by Curtis Jones on 2012.12.16.
//  Copyright (c) 2012 Curtis Jones. All rights reserved.
//

#import "MBScreencapsThumbnailCellView.h"
#import "MBDownloadQueue.h"
#import "MBImageView.h"
#import "NSThread+Additions.h"

@interface MBScreencapsThumbnailCellView ()
{
	NSUInteger mTransId;
	
	NSObject *mObjVal;
	NSImageView *mImageView;
	NSProgressIndicator *mProgressView;
	NSString *mTimestamp;
}
@end

@implementation MBScreencapsThumbnailCellView





#pragma mark - NSView

/**
 *
 *
 */
- (void)awakeFromNib
{
	mImageView = [[MBImageView alloc] initWithFrame:self.bounds];
	mImageView.imageFrameStyle = NSImageFrameNone;
	mImageView.imageScaling = NSScaleProportionally;
	mImageView.imageAlignment = NSImageAlignCenter;
	[mImageView setEditable:FALSE];
	[self addSubview:mImageView];
	
	mProgressView = [[NSProgressIndicator alloc] initWithFrame:NSMakeRect(self.frame.size.width/2-10, self.frame.size.height/2-10, 20, 20)];
	mProgressView.style = NSProgressIndicatorSpinningStyle;
	mProgressView.controlSize = NSRegularControlSize;
	[mProgressView setDisplayedWhenStopped:FALSE];
	[self addSubview:mProgressView];
}

/**
 *
 *
 */
- (void)setObjectValue:(id)objectValue
{
	[super setObjectValue:objectValue];
	
	NSUInteger transId = ++mTransId;
	mObjVal = objectValue;
	mImageView.image = nil;
	NSImage* (^loadImage)() = _loadImage;
	
	[mProgressView startAnimation:nil];
	
	if (loadImage) {
		[[MBDownloadQueue sharedInstance] dispatchBeg:^{
			NSImage *image = loadImage();
			if (transId == mTransId) {
				[[NSThread mainThread] performBlock:^{
					if (transId == mTransId) {
						[mProgressView stopAnimation:nil];
						mImageView.image = image;
					}
				}];
			}
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
