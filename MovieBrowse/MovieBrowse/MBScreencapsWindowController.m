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
#import "MBURLConnection.h"
#import "MBAppDelegate.h"
#import "MBMovie.h"
#import "MBDownloadQueue.h"
#import "MBFileMetadata.h"
#import "NSThread+Additions.h"
#import "NSProgress.h"
#import <QuartzCore/QuartzCore.h>

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
	
	NSUInteger mDraggedImageIndex;
	
	NSUInteger mTransId;
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
	
	// we can drag thumbnails to the finder (or other apss)
	[_tableView setDraggingSourceOperationMask:NSDragOperationCopy forLocal:FALSE];
	
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

/**
 *
 *
 */
- (NSImage *)thumbnailImageForRow:(NSUInteger)row column:(NSUInteger)col
{
	NSImage *image = nil;
	NSString *key = [NSString stringWithFormat:@"%lu--png--210--150", 60*((5*row)+col)];
	
	@synchronized (mImageCache) {
		image = mImageCache[key];
	}
	
	return image;
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
	
	return [NSString stringWithFormat:@"%02lu.%02lu.%02lu", hours, minutes, seconds];
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

/**
 * Offset is expressed in seconds.
 *
 */
- (NSData *)serverGetDataForImageAtOffset:(NSUInteger)offset withSize:(NSSize)size
{
	NSData *data = nil;
	NSString *key = [NSString stringWithFormat:@"%lu--png--%d--%d", offset, (int)size.width, (int)size.height];
	NSString *imageHost = [[NSUserDefaults standardUserDefaults] stringForKey:MBDefaultsKeyImageHost];
	
	if (imageHost.length) {
		NSMutableString *urlString = [[NSMutableString alloc] initWithString:imageHost];
		
		[urlString appendString:@"/Screencaps/"];
		[urlString appendString:[mMovie.dirpath.lastPathComponent stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
		[urlString appendString:@"/image--"];
		[urlString appendString:key];
		
		data = [[NSData alloc] initWithContentsOfURL:[NSURL URLWithString:urlString]];
	}
	
	return data;
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
	NSString *imageHost = [[NSUserDefaults standardUserDefaults] stringForKey:MBDefaultsKeyImageHost];
	MBMovie *mbmovie = mMovie;
	
	if (!imageHost.length) {
		NSLog(@"%s.. no image host!", __PRETTY_FUNCTION__);
		return;
	}
	
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
	_bigPrg.doubleValue = 0.1;
	_bigPrg.layer.opacity = 0.6;
	_bigTxt.layer.opacity = 0.8;
	_bigImg.layer.opacity = 0.0;
	_bigTxt.stringValue = @"Loading...";
	
	// the window title includes the movie title and the time offset for the screencap
	_bigWin.title = [NSString stringWithFormat:@"%@ | %@", mMovie.title, [self humanReadableCode:timeOffset]];
	
	// set the window to the position of the table cell, then show the window, then animate the window
	// to the appropriate size and position for the image we're about to show.
	[_bigWin setFrame:cellFrame display:TRUE animate:FALSE];
	[_bigWin makeKeyAndOrderFront:sender];
	[_bigWin setFrame:winFrame display:TRUE animate:TRUE];
	
	[[MBDownloadQueue sharedInstance] dispatchBeg:^{
		NSString *key = [NSString stringWithFormat:@"%lu--png--%d--%d", timeOffset, (int)mInfoWidth, (int)mInfoHeight];
		NSMutableString *urlString = [[NSMutableString alloc] init];
		
		[urlString appendString:imageHost];
		[urlString appendString:@"/Screencaps/"];
		[urlString appendString:[mbmovie.dirpath.lastPathComponent stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
		[urlString appendString:@"/image--"];
		[urlString appendString:key];
		
		NSURL *url = [[NSURL alloc] initWithString:urlString];
		NSMutableURLRequest *urlRequest = [[NSMutableURLRequest alloc] initWithURL:url];
		
		[urlRequest setHTTPMethod:@"GET"];
		[urlRequest setHTTPShouldHandleCookies:TRUE];
		[urlRequest setHTTPShouldUsePipelining:TRUE];
		
		MBURLConnectionProgressHandler progressHandler = ^ (long long _bytesSoFar, long long _bytesTotal, NSString *_fileName, NSString *_mimeType, NSString *_textEncoding, NSURL *_url, NSData *_data) {
			[[NSThread mainThread] performBlock:^{
				_bigPrg.doubleValue = 100. * (double)_bytesSoFar / (double)_bytesTotal;
				_bigTxt.stringValue = [NSString stringWithFormat:@"%llu of %llu", _bytesSoFar, _bytesTotal];
			}];
		};
		
		MBURLConnectionDataHandler dataHandler = ^ (NSNumber *_status, NSDictionary *_headers, NSData *_data) {
			NSImage *image = [[NSImage alloc] initWithData:_data];
			image.size = NSMakeSize(picWidth, picHeight);
			
			[[NSThread mainThread] performBlock:^{
				CABasicAnimation *fadeOut = [CABasicAnimation animationWithKeyPath:@"opacity"];
				fadeOut.fromValue = @(0.8);
				fadeOut.toValue = @(0.0);
				fadeOut.duration = 0.75;
				fadeOut.delegate = self;
				fadeOut.removedOnCompletion = FALSE;
				[fadeOut setValue:@"fadeOut" forKey:@"type"];
				[_bigPrg.layer addAnimation:fadeOut forKey:@"opacity"];
				[_bigTxt.layer addAnimation:fadeOut forKey:@"opacity"];
				
				_bigImg.image = image;
				CABasicAnimation *fadeIn = [CABasicAnimation animationWithKeyPath:@"opacity"];
				fadeIn.fromValue = @(0.0);
				fadeIn.toValue = @(1.0);
				fadeIn.duration = 0.75;
				fadeIn.delegate = self;
				fadeIn.removedOnCompletion = FALSE;
				[fadeOut setValue:@"fadeIn" forKey:@"type"];
				[_bigImg.layer addAnimation:fadeOut forKey:@"fadeIn"];
			}];
		};
		
		MBURLConnection *urlConnection = [[MBURLConnection alloc] initWithRequest:urlRequest progressHandler:progressHandler dataHandler:dataHandler];
		[urlConnection runInBackground:FALSE];
	}];
}

/**
 *
 *
 */
- (void)animationDidStop:(CAAnimation *)theAnimation finished:(BOOL)flag
{
	NSString *type = [theAnimation valueForKey:@"type"];
	
	if ([type isEqualToString:@"fadeOut"]) {
		_bigPrg.layer.opacity = 0.;
		[_bigPrg.layer removeAnimationForKey:@"opacity"];
		
		_bigTxt.layer.opacity = 0.;
		[_bigTxt.layer removeAnimationForKey:@"opacity"];
	}
	else if ([type isEqualToString:@"fadeIn"]) {
		_bigImg.layer.opacity = 1.;
		[_bigTxt.layer removeAnimationForKey:@"opacity"];
	}
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





#pragma mark - NSTableViewDataSource - Drag-n-Drop

/**
 *
 *
 */
- (BOOL)tableView:(NSTableView *)tableView writeRowsWithIndexes:(NSIndexSet *)rowIndexes toPasteboard:(NSPasteboard *)pboard
{
	NSPoint point = [_tableView convertPoint:_tableView.lastMouseDownEvent.locationInWindow fromView:nil];
	NSInteger row = [_tableView rowAtPoint:point];
	NSInteger col = [_tableView columnAtPoint:point];
	
	mDraggedImageIndex = (row * 5) + col;
	
	[pboard declareTypes:@[NSFilesPromisePboardType] owner:self];
	[pboard setPropertyList:@[@"png"] forType:NSFilesPromisePboardType];
	
	return TRUE;
}

/**
 *
 *
 */
- (NSArray *)tableView:(NSTableView *)aTableView namesOfPromisedFilesDroppedAtDestination:(NSURL *)dropDestination forDraggedRowsWithIndexes:(NSIndexSet *)indexSet
{
	NSString *fileName = [NSString stringWithFormat:@"%@ - %@.png", mMovie.title, [self humanReadableCode:mGranularity*mDraggedImageIndex]];
	NSString *filePath = [[dropDestination.path stringByAppendingPathComponent:fileName] stringByAppendingPathExtension:@"download"];
	NSString *imageHost = [[NSUserDefaults standardUserDefaults] stringForKey:MBDefaultsKeyImageHost];
	NSFileManager *fileManager = [[NSFileManager alloc] init];
	NSOutputStream *outputStream = [NSOutputStream outputStreamToFileAtPath:filePath append:TRUE];
	NSMutableURLRequest *urlRequest = nil;
	MBMovie *mbmovie = mMovie;
	NSProgress *progress = nil;
	
	// if there's no image host, then we don't know where to get the image from
	if (!imageHost.length)
		return @[fileName];
	
	[outputStream open];
	
	// construct the request url and the progress. the progress object will reflect our download
	// progress in the dock and in the finder.
	{
		NSUInteger timeOffset = mGranularity * mDraggedImageIndex;
		NSString *key = [NSString stringWithFormat:@"%lu--png--%d--%d", timeOffset, (int)mInfoWidth, (int)mInfoHeight];
		NSMutableString *urlString = [[NSMutableString alloc] init];
		
		[urlString appendString:imageHost];
		[urlString appendString:@"/Screencaps/"];
		[urlString appendString:[mbmovie.dirpath.lastPathComponent stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
		[urlString appendString:@"/image--"];
		[urlString appendString:key];
		
		NSURL *url = [[NSURL alloc] initWithString:urlString];
		
		urlRequest = [[NSMutableURLRequest alloc] initWithURL:url];
		[urlRequest setHTTPMethod:@"GET"];
		[urlRequest setHTTPShouldHandleCookies:TRUE];
		[urlRequest setHTTPShouldUsePipelining:TRUE];
		
		NSDictionary *userInfo = @{ @"NSProgressFileDownloadingSourceURL": url,
																@"NSProgressFileLocationCanChange": @(TRUE),
																@"NSProgressFileOperationKind": @"NSProgressFileOperationKindDownloading",
																@"NSProgressFileURL": [NSURL fileURLWithPath:filePath] };
		
		progress = [[NSProgress alloc] initWithParent:nil userInfo:userInfo];
		progress.kind = @"NSProgressKindFile";
		progress.pausable = TRUE;
		progress.cancellable = TRUE;
		progress.totalUnitCount = 1;
		progress.completedUnitCount = 0;
		[progress publish];
	}
	
	// the progress handler receives data as the sender sends it to us. we append it to the file
	MBURLConnectionProgressHandler progressHandler = ^ (long long _bytesSoFar, long long _bytesTotal, NSString *_fileName, NSString *_mimeType, NSString *_textEncoding, NSURL *_url, NSData *_data) {
		if (_data) {
			[outputStream write:_data.bytes maxLength:_data.length];
			progress.totalUnitCount = _bytesTotal;
			progress.completedUnitCount = _bytesSoFar;
		}
	};
	
	// the data handler is called when the response is complete. close the file.
	MBURLConnectionDataHandler dataHandler = ^ (NSNumber *_status, NSDictionary *_headers, NSData *_data) {
		[fileManager moveItemAtPath:filePath toPath:[filePath stringByDeletingPathExtension] error:nil];
		[outputStream close];
		[progress unpublish];
	};
	
	MBURLConnection *urlConnection = [[MBURLConnection alloc] initWithRequest:urlRequest progressHandler:progressHandler dataHandler:dataHandler];
	[urlConnection runInBackground:TRUE];
	
	return @[fileName];
}

@end
