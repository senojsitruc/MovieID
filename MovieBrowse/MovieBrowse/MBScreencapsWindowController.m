//
//  MBScreencapsWindowController.m
//  MovieBrowse
//
//  Created by Curtis Jones on 2012.12.16.
//  Copyright (c) 2012 Curtis Jones. All rights reserved.
//

#import "MBScreencapsWindowController.h"
#import "MBScreencapsThumbnailView.h"
#import "MBAppDelegate.h"
#import "MBMovie.h"
#import "MBDownloadQueue.h"
#import "NSThread+Additions.h"

NSString * const MBScreencapsKeyDuration = @"duration";
NSString * const MBScreencapsKeyWidth = @"width";
NSString * const MBScreencapsKeyHeight = @"height";

@interface MBScreencapsWindowController ()
{
	NSUInteger mCurPage;
	
	NSUInteger mGranularity;
	NSUInteger mNumOfImages;
	NSUInteger mNumOfPages;
	
	NSUInteger mInfoDuration;
	NSUInteger mInfoWidth;
	NSUInteger mInfoHeight;
	
	NSUInteger mTransactionId;
	NSMutableDictionary *mImageCache;
	NSMutableArray *mImageViews;
}
@end

@implementation MBScreencapsWindowController

/**
 *
 *
 */
- (id)init
{
	self = [super initWithWindowNibName:@"MBScreencapsWindowController"];
	
	if (self) {
		mGranularity = 60;
		mImageCache = [[NSMutableDictionary alloc] init];
		mImageViews = [[NSMutableArray alloc] init];
		
		(void)self.window;
	}
	
	return self;
}

/**
 *
 *
 */
- (void)windowDidLoad
{
	[super windowDidLoad];
	
	[mImageViews addObject:_thumbnailRow0Col0];
	[mImageViews addObject:_thumbnailRow0Col1];
	[mImageViews addObject:_thumbnailRow0Col2];
	[mImageViews addObject:_thumbnailRow0Col3];
	
	[mImageViews addObject:_thumbnailRow1Col0];
	[mImageViews addObject:_thumbnailRow1Col1];
	[mImageViews addObject:_thumbnailRow1Col2];
	[mImageViews addObject:_thumbnailRow1Col3];
	
	[mImageViews addObject:_thumbnailRow2Col0];
	[mImageViews addObject:_thumbnailRow2Col1];
	[mImageViews addObject:_thumbnailRow2Col2];
	[mImageViews addObject:_thumbnailRow2Col3];
	
	[mImageViews addObject:_thumbnailRow3Col0];
	[mImageViews addObject:_thumbnailRow3Col1];
	[mImageViews addObject:_thumbnailRow3Col2];
	[mImageViews addObject:_thumbnailRow3Col3];
}





#pragma mark - Accessors

/**
 *
 *
 */
- (void)showInWindow:(NSWindow *)parentWindow forMovie:(MBMovie *)mbmovie
{
	_movie = mbmovie;
	mCurPage = 0;
	[_prevBtn setEnabled:FALSE];
	[_nextBtn setEnabled:FALSE];
	[mImageCache removeAllObjects];
	[self clearThumbnails];
	[self serverGetScreencapsInfo];
	[NSApp beginSheet:self.window modalForWindow:parentWindow modalDelegate:self didEndSelector:nil contextInfo:nil];
	[self loadPage:1];
}

/**
 *
 *
 */
- (void)hide
{
	[NSApp endSheet:self.window];
	[self.window orderOut:nil];
}





#pragma mark - Private

/**
 *
 *
 */
- (void)clearThumbnails
{
	[mImageViews enumerateObjectsUsingBlock:^ (id imageViewObj, NSUInteger imageViewNdx, BOOL *imageViewStop) {
		((MBScreencapsThumbnailView *)imageViewObj).timestamp = nil;
		((MBScreencapsThumbnailView *)imageViewObj).loading = FALSE;
		((MBScreencapsThumbnailView *)imageViewObj).image = nil;
	}];
}

/**
 *
 *
 */
- (void)loadPage:(NSUInteger)pageNum
{
	__block NSUInteger timeOffset = (16 * 60) + ((pageNum - 1) * 16 * 60);
	
	NSUInteger transactionId = (mTransactionId += 1);
	NSUInteger duration = mInfoDuration;
	mCurPage = pageNum;
	
	[_prevBtn setEnabled:mCurPage > 1];
	[_nextBtn setEnabled:mCurPage < mNumOfPages];
	
	[self clearThumbnails];
	
	_infoTxt.stringValue = [NSString stringWithFormat:@"Page %lu of %lu", mCurPage, mNumOfPages];
	
	[mImageViews enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^ (id imageViewObj, NSUInteger imageViewNdx, BOOL *imageViewStop) {
		if (timeOffset < duration) {
			NSUInteger _timeOffset = timeOffset;
			((MBScreencapsThumbnailView *)imageViewObj).loading = TRUE;
			[[MBDownloadQueue sharedInstance] dispatchBeg:^{
				if (transactionId != mTransactionId)
					return;
				NSImage *image = [self serverGetImageAtOffset:_timeOffset];
				NSString *timestamp = [self humanReadableCode:_timeOffset];
				[[NSThread mainThread] performBlock:^{
					if (transactionId == mTransactionId) {
						((MBScreencapsThumbnailView *)imageViewObj).loading = FALSE;
						((MBScreencapsThumbnailView *)imageViewObj).timestamp = timestamp;
						((MBScreencapsThumbnailView *)imageViewObj).image = image;
					}
				}];
			}];
		}
		timeOffset -= 60;
	}];
}

/**
 *
 *
 */
- (NSString *)humanReadableCode:(NSUInteger)timeOffset
{
	NSUInteger hours=0, minutes=0, seconds=0;
	
	if (timeOffset >= 3600) {
		hours = timeOffset / 3600;
		timeOffset -= (hours * 3600);
	}
	
	if (timeOffset >= 60) {
		minutes = timeOffset / 60;
		timeOffset -= (minutes * 60);
	}
	
	seconds = timeOffset;
	
	return [NSString stringWithFormat:@"%02lu:%02lu:%02lu", hours, minutes, seconds];
}





#pragma mark - Server

/**
 *
 *
 */
- (void)serverGetScreencapsInfo
{
	NSString *imageHost = [[NSUserDefaults standardUserDefaults] stringForKey:MBDefaultsKeyImageHost];
	NSMutableString *urlString = [[NSMutableString alloc] initWithString:imageHost];
	
	[urlString appendString:@"/Screencaps/"];
	[urlString appendString:[_movie.dirpath.lastPathComponent stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
	[urlString appendString:@"/info"];
	
	NSURL *url = [NSURL URLWithString:urlString];
	NSData *data = [NSData dataWithContentsOfURL:url];
	NSDictionary *info = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
	
	mInfoDuration = ((NSNumber *)info[MBScreencapsKeyDuration]).integerValue;
	mInfoWidth = ((NSNumber *)info[MBScreencapsKeyWidth]).integerValue;
	mInfoHeight = ((NSNumber *)info[MBScreencapsKeyHeight]).integerValue;
	
	mNumOfImages = mInfoDuration / mGranularity;
	mNumOfPages = mNumOfImages / 16;
	
	if (mNumOfPages * 16 < mNumOfImages)
		mNumOfPages += 1;
	
	_infoTxt.stringValue = [NSString stringWithFormat:@"Page 0 of %lu", mNumOfPages];
}

/**
 * Offset is expressed in seconds.
 *
 */
- (NSImage *)serverGetImageAtOffset:(NSUInteger)offset
{
	NSImage *image = nil;
	
	@synchronized (self) {
		if ((image = mImageCache[@(offset)]))
			return image;
	}
	
	NSString *imageHost = [[NSUserDefaults standardUserDefaults] stringForKey:MBDefaultsKeyImageHost];
	NSMutableString *urlString = [[NSMutableString alloc] initWithString:imageHost];
	
	[urlString appendString:@"/Screencaps/"];
	[urlString appendString:[_movie.dirpath.lastPathComponent stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
	[urlString appendString:@"/image--"];
	[urlString appendFormat:@"%lu", offset];
	[urlString appendString:@"--png--200--150"];
	
	image = [[NSImage alloc] initWithContentsOfURL:[NSURL URLWithString:urlString]];
	
	@synchronized (self) {
		if (image)
			mImageCache[@(offset)] = image;
	}
	
	return image;
}





#pragma mark - Actions

/**
 *
 *
 */
- (IBAction)doActionPrev:(id)sender
{
	[self loadPage:mCurPage - 1];
}

/**
 *
 *
 */
- (IBAction)doActionNext:(id)sender
{
	[self loadPage:mCurPage + 1];
}

/**
 *
 *
 */
- (IBAction)doActionClose:(id)sender
{
	mTransactionId += 1;
	[self hide];
}

@end
