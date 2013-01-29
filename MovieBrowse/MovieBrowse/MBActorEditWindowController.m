//
//  MBActorEditWindowController.m
//  MovieBrowse
//
//  Created by Curtis Jones on 2012.12.29.
//  Copyright (c) 2012 Curtis Jones. All rights reserved.
//

#import "MBActorEditWindowController.h"
#import "MBAppDelegate.h"
#import "MBDataManager.h"
#import "MBDownloadQueue.h"
#import "MBGoogleImageSearch.h"
#import "MBImageCache.h"
#import "MBGenre.h"
#import "MBMovie.h"
#import "MBPerson.h"
#import "NSPopUpButton+Additions.h"
#import "NSThread+Additions.h"
#import <objc/runtime.h>

@interface MBActorEditWindowController ()
{
	MBPerson *mPerson;
	NSData *mImageData;
	MBGoogleImageSearch *mImageSearch;
}
@end

@implementation MBActorEditWindowController

#pragma mark - Structors

/**
 *
 *
 */
- (id)init
{
	self = [super initWithWindowNibName:@"MBActorEditWindowController"];
	
	if (self) {
		mImageSearch = [[MBGoogleImageSearch alloc] init];
		
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
	
	// date of birth
	{
		[_dobYearBtn removeAllItems];
		[_dobMonthBtn removeAllItems];
		[_dobDayBtn removeAllItems];
		
		[_dobYearBtn addItemWithTitle:@"--" andTag:0];
		[_dobMonthBtn addItemWithTitle:@"--" andTag:0];
		[_dobDayBtn addItemWithTitle:@"--" andTag:0];
		
		for (int i = 1850; i <= 2050; ++i)
			[_dobYearBtn addItemWithTitle:@(i).stringValue andTag:i];
		
		for (int i = 1; i <= 12; ++i)
			[_dobMonthBtn addItemWithTitle:[NSString stringWithFormat:@"%02d", (int)@(i).integerValue] andTag:i];
		
		for (int i = 1; i <= 31; ++i)
			[_dobDayBtn addItemWithTitle:[NSString stringWithFormat:@"%02d", (int)@(i).integerValue] andTag:i];
	}
	
	// date of death
	{
		[_dodYearBtn removeAllItems];
		[_dodMonthBtn removeAllItems];
		[_dodDayBtn removeAllItems];
		
		[_dodYearBtn addItemWithTitle:@"--" andTag:0];
		[_dodMonthBtn addItemWithTitle:@"--" andTag:0];
		[_dodDayBtn addItemWithTitle:@"--" andTag:0];
		
		for (int i = 1850; i <= 2050; ++i)
			[_dodYearBtn addItemWithTitle:@(i).stringValue andTag:i];
		
		for (int i = 1; i <= 12; ++i)
			[_dodMonthBtn addItemWithTitle:[NSString stringWithFormat:@"%02d", (int)@(i).integerValue] andTag:i];
		
		for (int i = 1; i <= 31; ++i)
			[_dodDayBtn addItemWithTitle:[NSString stringWithFormat:@"%02d", (int)@(i).integerValue] andTag:i];
	}
}





#pragma mark - Accessors

/**
 *
 *
 */
- (void)showInWindow:(NSWindow *)parentWindow forPerson:(MBPerson *)mbperson
{
	if (mbperson != mPerson) {
		mPerson = mbperson;
		mImageData = nil;
		[self loadPosterForPerson:mPerson];
	}
	
	_nameTxt.stringValue = mPerson.name ? mPerson.name : @"";
	_webTxt.stringValue = mPerson.web ? mPerson.web : @"";
	_imdbTxt.stringValue = mPerson.imdbId ? mPerson.imdbId : @"";
	_tmdbTxt.stringValue = mPerson.tmdbId ? mPerson.tmdbId : @"";
	_rtidTxt.stringValue = mPerson.rtId ? mPerson.rtId : @"";
	_bioTxt.stringValue = mPerson.bio ? mPerson.bio : @"";
	
	// date of birth
	{
		NSArray *parts = [mPerson.dob componentsSeparatedByString:@"-"];
		NSInteger y=0, m=0, d=0;
		
		if (parts.count >= 1) y = ((NSNumber *)parts[0]).integerValue;
		if (parts.count >= 2) m = ((NSNumber *)parts[1]).integerValue;
		if (parts.count >= 3) d = ((NSNumber *)parts[2]).integerValue;
		
		[_dobYearBtn selectItemWithTag:y];
		[_dobMonthBtn selectItemWithTag:m];
		[_dobDayBtn selectItemWithTag:d];
	}
	
	// date of death
	{
		NSArray *parts = [mPerson.dod componentsSeparatedByString:@"-"];
		NSInteger y=0, m=0, d=0;
		
		if (parts.count >= 1) y = ((NSNumber *)parts[0]).integerValue;
		if (parts.count >= 2) m = ((NSNumber *)parts[1]).integerValue;
		if (parts.count >= 3) d = ((NSNumber *)parts[2]).integerValue;
		
		[_dodYearBtn selectItemWithTag:y];
		[_dodMonthBtn selectItemWithTag:m];
		[_dodDayBtn selectItemWithTag:d];
	}
	
	[NSApp beginSheet:self.window modalForWindow:parentWindow modalDelegate:nil didEndSelector:nil contextInfo:nil];
}





#pragma mark - Private

/**
 *
 *
 */
- (void)loadPosterForPerson:(MBPerson *)mbperson
{
	NSString *imageId = mbperson.imageId;
	CGFloat height = _posterImg.frame.size.height;
	CGFloat width = _posterImg.frame.size.width;
	NSImage *image = [[MBImageCache sharedInstance] cachedImageWithId:imageId andHeight:height];
	
	_posterImg.image = nil;
	[_posterImg setToolTip:@""];
	[_posterPrg stopAnimation:self];
	
	//
	// load current image
	//
	if (imageId.length) {
		[_posterImg setToolTip:imageId];
		[_posterPrg stopAnimation:self];
		
		if (!image) {
			[_posterPrg startAnimation:self];
			
			[[MBDownloadQueue sharedInstance] dispatchBeg:^{
				NSImage *image = [[MBImageCache sharedInstance] actorImageWithId:imageId width:width height:height];
				
				if (!image) {
					[[NSThread mainThread] performBlock:^{
						if (mbperson == mPerson)
							[_posterPrg stopAnimation:self];
					}];
					return;
				}
				
				image.size = NSMakeSize((NSUInteger)(image.size.width * (height / image.size.height)), height);
				[[MBImageCache sharedInstance] cacheImage:image withId:imageId andHeight:height];
				
				if (mbperson != mPerson)
					return;
				
				[[NSThread mainThread] performBlock:^{
					if (mbperson == mPerson) {
						[_posterPrg stopAnimation:self];
						_posterImg.image = image;
					}
				}];
			}];
		}
		else
			_posterImg.image = image;
	}
	
	//
	// find alternate images
	//
	{
		NSString *query = mbperson.name;
		CGRect myFrame = _postersView.frame;
		NSView *documentView = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, 0, 0)];
		
		_postersView.documentView = documentView;
		
		[[MBDownloadQueue sharedInstance] dispatchBeg:^{
			__block CGFloat hoffset = 0.;
			
			[mImageSearch imagesForQuery:query offset:0 count:10 handler:^ (NSURL *url, NSInteger _width, NSInteger _height, BOOL *_stop) {
				NSLog(@"url=%@, width=%ld, height=%ld", url, _width, _height);
				
				if (mPerson != mbperson) {
					*_stop = TRUE;
					return;
				}
				
				NSData *imageData = [NSData dataWithContentsOfURL:url];
				
				if (!imageData) {
					NSLog(@"%s.. [%@] no image data", __PRETTY_FUNCTION__, url);
					return;
				}
				
				NSImage *image = [[NSImage alloc] initWithData:imageData];
				
				if (!image) {
					NSLog(@"%s.. [%@] no image", __PRETTY_FUNCTION__, url);
					return;
				}
				
				CGSize fullImageSize = image.size;
				CGFloat width = (NSUInteger)(image.size.width * (myFrame.size.height / image.size.height));
				image.size = NSMakeSize(width, myFrame.size.height);
				
				NSButton *imageBtn = [[NSButton alloc] initWithFrame:NSMakeRect(hoffset, 0, image.size.width, image.size.height)];
				[imageBtn setButtonType:NSMomentaryPushInButton];
				[imageBtn setBordered:FALSE];
				[imageBtn setImage:image];
				[imageBtn setToolTip:[NSString stringWithFormat:@"%@ [w=%d, h=%d]", url, (int)fullImageSize.width, (int)fullImageSize.height]];
				[imageBtn setTarget:self];
				[imageBtn setAction:@selector(doActionPosterSelect:)];
				objc_setAssociatedObject(imageBtn, "imageData", imageData, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
				
				[[NSThread mainThread] performBlock:^{
					documentView.frame = NSMakeRect(0, 0, hoffset, myFrame.size.height);
					[documentView addSubview:imageBtn];
				}];
				
				hoffset += image.size.width;
			}];
		}];
	}
}

/**
 *
 *
 */
- (void)hide
{
	[NSApp endSheet:self.window];
	[self.window orderOut:self];
}





#pragma mark - Actions

/**
 *
 *
 */
- (IBAction)doActionPosterSelect:(NSButton *)posterBtn
{
	CGFloat height = _posterImg.frame.size.height;
	NSData *imageData = objc_getAssociatedObject(posterBtn, "imageData");
	
	if (!imageData) {
		NSLog(@"%s.. no image data!", __PRETTY_FUNCTION__);
		return;
	}
	
	NSImage *image = [[NSImage alloc] initWithData:imageData];
	
	if (!image) {
		NSLog(@"%s.. no image!", __PRETTY_FUNCTION__);
		return;
	}
	
	mImageData = imageData;
	image.size = NSMakeSize((NSUInteger)(image.size.width * (height / image.size.height)), height);
	_posterImg.image = image;
}

/**
 *
 *
 */
- (IBAction)doActionSave:(id)sender
{
	MBAppDelegate *appDelegate = (MBAppDelegate *)[NSApp delegate];
	MBDataManager *dataManager = appDelegate.dataManager;
	NSString *dobStr=@"", *dodStr=@"";
	
	NSInteger dob_y = _dobYearBtn.selectedTag;
	NSInteger dob_m = _dobMonthBtn.selectedTag;
	NSInteger dob_d = _dobDayBtn.selectedTag;
	NSInteger dod_y = _dodYearBtn.selectedTag;
	NSInteger dod_m = _dodMonthBtn.selectedTag;
	NSInteger dod_d = _dodDayBtn.selectedTag;
	
//NSString *name = _nameTxt.stringValue;
	
	if (dob_y && dob_m && dob_d)
		dobStr = [NSString stringWithFormat:@"%04d-%02d-%02d", (int)dob_y, (int)dob_m, (int)dob_d];
	else if (dob_y)
		dobStr = @(dob_y).stringValue;
	
	if (dod_y && dod_m && dod_d)
		dodStr = [NSString stringWithFormat:@"%04d-%02d-%02d", (int)dod_y, (int)dod_m, (int)dod_d];
	else if (dod_y)
		dodStr = @(dod_y).stringValue;
	
//if (name.length && ![mPerson.name isEqualToString:name])
//	[dataManager person:mPerson updateWithName:name];
	
	[dataManager person:mPerson updateWithValues:@{
	     @"bio": _bioTxt.stringValue,
	     @"dob": dobStr,
	     @"dod": dodStr,
	     @"web": _webTxt.stringValue,
	    @"imdb": _imdbTxt.stringValue,
	    @"tmdb": _tmdbTxt.stringValue,
	    @"rtid": _rtidTxt.stringValue,
	  @"poster": mImageData.length ? mImageData : [NSNull null]
	}];
	
	[_posterImg setToolTip:mPerson.imageId];
	[mPerson updateInfoText];
	[[MBImageCache sharedInstance] clearActorCacheForId:mPerson.imageId];
	
	[self hide];
}

/**
 *
 *
 */
- (IBAction)doActionDelete:(id)sender
{
	//[[MBAppDelegate sharedInstance].dataManager deleteMovie:mMovie];
}

/**
 *
 *
 **/
- (IBAction)doActionClose:(id)sender
{
	[self hide];
}

@end
