//
//  MBScreencapsWindowController.m
//  MovieBrowse
//
//  Created by Curtis Jones on 2012.12.16.
//  Copyright (c) 2012 Curtis Jones. All rights reserved.
//

#import "MBScreencapsWindowController.h"
#import "MBScreencapsTableView.h"
#import "MBScreencapsThumbnailCellView.h"
#import "MBAppDelegate.h"
#import "MBMovie.h"
#import "MBDownloadQueue.h"
#import "NSThread+Additions.h"

NSString * const MBScreencapsKeyDuration = @"duration";
NSString * const MBScreencapsKeyWidth = @"width";
NSString * const MBScreencapsKeyHeight = @"height";

@interface MBScreencapsWindowController ()
{
	NSUInteger mGranularity;
	NSUInteger mNumOfImages;
	
	NSUInteger mInfoDuration;
	NSUInteger mInfoWidth;
	NSUInteger mInfoHeight;
	
	NSUInteger mTransactionId;
	NSMutableDictionary *mImageCache;
	
	MBMovie *mMovie;
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
	
	// click a table cell to show a full size screencap
	_tableView.target = self;
	_tableView.action = @selector(doActionThumbnailTableClicked:);
}





#pragma mark - Accessors

/**
 *
 *
 */
- (void)showInWindow:(NSWindow *)parentWindow forMovie:(MBMovie *)mbmovie
{
	if (mMovie != mbmovie) {
		mMovie = mbmovie;
		mNumOfImages = 0;
		[mImageCache removeAllObjects];
		[self clearThumbnails];
		[self serverGetScreencapsInfo];
		((NSScrollView *)_tableView.superview.superview).verticalScroller.floatValue = 0;
		[((NSScrollView *)_tableView.superview.superview).contentView scrollToPoint:NSMakePoint(0,0)];
	}
	
	[NSApp beginSheet:self.window modalForWindow:parentWindow modalDelegate:self didEndSelector:nil contextInfo:nil];
}

/**
 *
 *
 */
- (void)hide
{
	[self clearThumbnails];
	
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
	@synchronized (mImageCache) {
		[mImageCache removeAllObjects];
	}
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
	
	if (imageHost.length) {
		NSMutableString *urlString = [[NSMutableString alloc] initWithString:imageHost];
		
		[urlString appendString:@"/Screencaps/"];
		[urlString appendString:[mMovie.dirpath.lastPathComponent stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
		[urlString appendString:@"/info"];
		
		NSURL *url = [NSURL URLWithString:urlString];
		NSData *data = [NSData dataWithContentsOfURL:url];
		NSDictionary *info = nil;
		
		@try {
			info = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
		}
		@catch (NSException *e) {
			NSLog(@"%s.. failed to JSONObjectWithData(), %@", __PRETTY_FUNCTION__, e.reason);
			NSLog(@"%@", e.callStackSymbols);
			NSLog(@"%@", url);
			return;
		}
		
		mInfoDuration = ((NSNumber *)info[MBScreencapsKeyDuration]).integerValue;
		mInfoWidth = ((NSNumber *)info[MBScreencapsKeyWidth]).integerValue;
		mInfoHeight = ((NSNumber *)info[MBScreencapsKeyHeight]).integerValue;
		
		mNumOfImages = mInfoDuration / mGranularity;
	}
	else {
		mInfoDuration = 0;
		mInfoWidth = 0;
		mInfoHeight = 0;
		
		mNumOfImages = 0;
	}
	
	[_tableView reloadData];
}

/**
 * Offset is expressed in seconds.
 *
 */
- (NSImage *)serverGetImageAtOffset:(NSUInteger)offset withSize:(NSSize)size
{
	NSImage *image = nil;
	NSString *key = [NSString stringWithFormat:@"%lu--png--%d--%d", offset, (int)size.width, (int)size.height];
	
	@synchronized (self) {
		if ((image = mImageCache[key]))
			return image;
	}
	
	NSString *imageHost = [[NSUserDefaults standardUserDefaults] stringForKey:MBDefaultsKeyImageHost];
	
	if (imageHost.length) {
		NSMutableString *urlString = [[NSMutableString alloc] initWithString:imageHost];
		
		[urlString appendString:@"/Screencaps/"];
		[urlString appendString:[mMovie.dirpath.lastPathComponent stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
		[urlString appendString:@"/image--"];
		[urlString appendString:key];
		
		image = [[NSImage alloc] initWithContentsOfURL:[NSURL URLWithString:urlString]];
		
		if (image) {
			@synchronized (self) {
				mImageCache[key] = image;
			}
		}
	}
	
	return image;
}





#pragma mark - Actions

/**
 *
 *
 */
- (IBAction)doActionClose:(id)sender
{
	mTransactionId += 1;
	[self hide];
}

/**
 *
 *
 */
- (void)doActionThumbnailTableClicked:(id)sender
{
	NSInteger row = _tableView.clickedRow;
	NSInteger col = _tableView.clickedColumn;
	
	if (row == -1 || col == -1)
		return;
	
	NSUInteger imageNdx = (row * 5) + col;
	NSUInteger timeOffset = 60 * imageNdx;
	
	// get the frame of the cell in the table in its window coordinates and then convert it to screen
	// coordinates
	NSRect cellFrame = [_tableView convertRect:[_tableView frameOfCellAtColumn:col row:row] toView:nil];
	cellFrame.origin.x += self.window.frame.origin.x;
	cellFrame.origin.y += self.window.frame.origin.y;
	
	// this is the frame of the screen we're going to display the image on
	NSRect screenFrame = self.window.screen.visibleFrame;
	
	// the default image width/height is its native width/height
	CGFloat picWidth=mInfoWidth, picHeight=mInfoHeight;
	
	// the screen width is the "effective screen width", which accounst for any border around the
	// image inside its window
	CGFloat screenWidth = screenFrame.size.width - (_bigWin.frame.size.width - _bigImg.frame.size.width);
	CGFloat screenHeight = screenFrame.size.height - (_bigWin.frame.size.height - _bigImg.frame.size.height);
	
	// determine which dimension of the image is most constrained by the dimensions of the screen and
	// adjust both dimensions of the image to fit inside the screen while maintaining the image's
	// aspect ratio.
	if (screenWidth < mInfoWidth || screenHeight < mInfoHeight) {
		if (screenWidth / (CGFloat)mInfoWidth < screenHeight / (CGFloat)mInfoHeight) {
			picWidth = screenWidth;
			picHeight = (CGFloat)mInfoHeight * (screenWidth / (CGFloat)mInfoWidth);
		}
		else {
			picHeight = screenHeight;
			picWidth = (CGFloat)mInfoWidth * (screenHeight / (CGFloat)mInfoHeight);
		}
	}
	
	// account for the window possibly have a horizontal and/or vertical border surrounding the image
	CGFloat winWidth = picWidth + (_bigWin.frame.size.width - _bigImg.frame.size.width);
	CGFloat winHeight = picHeight + (_bigWin.frame.size.height - _bigImg.frame.size.height);
	
	// center the big-image window on the screen
	NSRect winFrame = NSMakeRect((screenFrame.size.width-winWidth)/2, (screenFrame.size.height-winHeight)/2, winWidth, winHeight);
	
	// clear out the previous image (if any) and start the progress indicator
	_bigImg.image = nil;
	[_bigPrg startAnimation:sender];
	
	// the window title includes the movie title and the time offset for the screencap
	_bigWin.title = [NSString stringWithFormat:@"%@ | %@", mMovie.title, [self humanReadableCode:timeOffset]];
	
	// set the window to the position of the table cell, then show the window, then animate the window
	// to the appropriate size and position for the image we're about to show.
	[_bigWin setFrame:cellFrame display:TRUE animate:FALSE];
	[_bigWin makeKeyAndOrderFront:sender];
	[_bigWin setFrame:winFrame display:TRUE animate:TRUE];
	
	[[MBDownloadQueue sharedInstance] dispatchBeg:^{
		NSImage *image = [self serverGetImageAtOffset:timeOffset withSize:NSMakeSize(mInfoWidth, mInfoHeight)];
		image.size = NSMakeSize(picWidth, picHeight);
		
		[[NSThread mainThread] performBlock:^{
			[_bigPrg stopAnimation:sender];
			_bigImg.image = image;
		}];
	}];
}





#pragma mark - NSTableViewDelegate

/**
 *
 *
 */
- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
	NSUInteger colIndex = 0;
	NSString *colIdentifier = tableColumn.identifier;
	
	if ([colIdentifier isEqualToString:@"1"])
		colIndex = 0;
	else if ([colIdentifier isEqualToString:@"2"])
		colIndex = 1;
	else if ([colIdentifier isEqualToString:@"3"])
		colIndex = 2;
	else if ([colIdentifier isEqualToString:@"4"])
		colIndex = 3;
	else if ([colIdentifier isEqualToString:@"5"])
		colIndex = 4;
	
	NSUInteger imageIndex = (row * 5) + colIndex;
	NSUInteger timeOffset = mGranularity * imageIndex;
	MBScreencapsThumbnailCellView *view = (MBScreencapsThumbnailCellView *)[tableView makeViewWithIdentifier:tableColumn.identifier owner:self];
	
	view.imageView.image = nil;
	view.loadImage = ^ NSImage* () {
		return [self serverGetImageAtOffset:timeOffset withSize:NSMakeSize(210,150)];
	};
	view.toolTip = [self humanReadableCode:timeOffset];
	view.objectValue = @(imageIndex);
	
	return view;
}

/**
 * Each row can represent more than one image, so we should never use the default row selection
 * functionality.
 */
- (BOOL)tableView:(NSTableView *)aTableView shouldSelectRow:(NSInteger)rowIndex
{
	return FALSE;
}





#pragma mark - NSTableViewDataSource

/**
 *
 *
 */
- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
	NSUInteger total = mNumOfImages;
	NSInteger rows = total / 5;
	
	if (rows * 5 < total)
		rows += 1;
	
	return rows;
}

/**
 *
 *
 */
- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)rowIndex
{
	NSUInteger colIndex = 0;
	NSString *colIdentifier = tableColumn.identifier;
	
	if ([colIdentifier isEqualToString:@"1"])
		colIndex = 0;
	else if ([colIdentifier isEqualToString:@"2"])
		colIndex = 1;
	else if ([colIdentifier isEqualToString:@"3"])
		colIndex = 2;
	else if ([colIdentifier isEqualToString:@"4"])
		colIndex = 3;
	else if ([colIdentifier isEqualToString:@"5"])
		colIndex = 4;
	
	NSUInteger imageNdx = (rowIndex * 5) + colIndex;
	
	if (imageNdx < mNumOfImages)
		return @(imageNdx);
	else
		return nil;
}

@end
