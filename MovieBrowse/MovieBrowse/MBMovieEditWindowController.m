//
//  MBMovieEditWindowController.m
//  MovieBrowse
//
//  Created by Curtis Jones on 2012.12.28.
//  Copyright (c) 2012 Curtis Jones. All rights reserved.
//

#import "MBMovieEditWindowController.h"
#import "MBAppDelegate.h"
#import "MBDataManager.h"
#import "MBDownloadQueue.h"
#import "MBGoogleImageSearch.h"
#import "MBImageCache.h"
#import "MBGenre.h"
#import "MBMovie.h"
#import "MBPerson.h"
#import "NSThread+Additions.h"
#import <objc/runtime.h>

@interface MBMovieEditWindowController ()
{
	MBMovie *mMovie;
	NSData *mImageData;
	MBGoogleImageSearch *mImageSearch;
	NSMutableArray *mGenres;
	NSMutableArray *mLanguages;
	NSMutableArray *mActors;
}
@end

@implementation MBMovieEditWindowController

/**
 *
 *
 */
- (id)init
{
	self = [super initWithWindowNibName:@"MBMovieEditWindowController"];
	
	if (self) {
		mImageSearch = [[MBGoogleImageSearch alloc] init];
		
		mGenres = [[NSMutableArray alloc] init];
		mLanguages = [[NSMutableArray alloc] init];
		mActors = [[NSMutableArray alloc] init];
		
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
}




#pragma mark - Accessors

/**
 *
 *
 */
- (void)showInWindow:(NSWindow *)parentWindow forMovie:(MBMovie *)mbmovie
{
	if (mbmovie != mMovie) {
		mMovie = mbmovie;
		mImageData = nil;
		[self loadPosterForMovie:mMovie];
	}
	
	_titleTxt.stringValue = mMovie.title ? mMovie.title : @"";
	_yearTxt.stringValue = mMovie.year.integerValue ? mMovie.year.stringValue : @"";
	_ratingTxt.stringValue = mMovie.rating ? mMovie.rating : @"";
	_pathTxt.stringValue = mMovie.dirpath ? mMovie.dirpath : @"";
	_descriptionTxt.stringValue = mMovie.synopsis ? mMovie.synopsis : @"";
	
	// duration
	{
		NSInteger hours, minutes, seconds;
		
		if (!(seconds = mMovie.duration.integerValue))
			seconds = mMovie.runtime.integerValue;
		
		hours = seconds / 60 / 60;
		seconds -= (hours * 60 * 60);
		minutes = seconds / 60;
		seconds -= (minutes * 60);
		
		[_durationHrBtn selectItemAtIndex:hours];
		[_durationMinBtn selectItemAtIndex:minutes];
		[_durationSecBtn selectItemAtIndex:seconds];
	}
	
	[_scoreBtn selectItemAtIndex:mMovie.score.integerValue];
	
	[_genreArrayController removeObjects:_genreArrayController.arrangedObjects];
	[_languageArrayController removeObjects:_languageArrayController.arrangedObjects];
	[_actorArrayController removeObjects:_actorArrayController.arrangedObjects];
	
	[_genreArrayController addObjects:mMovie.genres.allValues];
	[_languageArrayController addObjects:mMovie.languages];
	
	MBAppDelegate *appDelegate = (MBAppDelegate *)[NSApp delegate];
	MBDataManager *dataManager = appDelegate.dataManager;
																
	[mMovie.actors.allKeys enumerateObjectsUsingBlock:^ (id actorObj, NSUInteger actorNdx, BOOL *actorStop) {
		[_actorArrayController addObject:[dataManager personWithKey:actorObj]];
	}];
	
	[_genreArrayController setSortDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"name" ascending:TRUE]]];
	[_genreArrayController rearrangeObjects];
	[_actorArrayController setSortDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"name" ascending:TRUE]]];
	[_actorArrayController rearrangeObjects];
	
	[_genreTbl reloadData];
	[_languageTbl reloadData];
	[_actorTbl reloadData];
	
	[NSApp beginSheet:self.window modalForWindow:parentWindow modalDelegate:nil didEndSelector:nil contextInfo:nil];
}





#pragma mark - Private

/**
 *
 *
 */
- (void)loadPosterForMovie:(MBMovie *)mbmovie
{
	NSString *imageId = mbmovie.posterId;
	CGFloat height = _posterImg.frame.size.height;
	NSImage *image = [[MBImageCache sharedInstance] cachedImageWithId:imageId andHeight:height];
	
	_posterImg.image = nil;
	[_posterImg setToolTip:@""];
	
	//
	// load current image
	//
	if (imageId.length) {
		[_posterImg setToolTip:imageId];
		[_posterPrg stopAnimation:self];
		
		if (!image) {
			[_posterPrg startAnimation:self];
			
			[[MBDownloadQueue sharedInstance] dispatchBeg:^{
				NSImage *image = [[MBImageCache sharedInstance] movieImageWithId:imageId width:0 height:height];
				
				if (!image) {
					[[NSThread mainThread] performBlock:^{
						if (mbmovie == mMovie)
							[_posterPrg stopAnimation:self];
					}];
					return;
				}
				
				image.size = NSMakeSize((NSUInteger)(image.size.width * (height / image.size.height)), height);
				[[MBImageCache sharedInstance] cacheImage:image withId:imageId andHeight:height];
				
				if (mbmovie != mMovie)
					return;
				
				[[NSThread mainThread] performBlock:^{
					if (mbmovie == mMovie) {
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
		NSString *query = [mbmovie.title stringByAppendingString:@" movie poster "];
		CGRect myFrame = _postersView.frame;
		NSView *documentView = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, 0, 0)];
		
		if (mbmovie.year.integerValue)
			query = [query stringByAppendingString:mbmovie.year.stringValue];
		
		_postersView.documentView = documentView;
		
		[[MBDownloadQueue sharedInstance] dispatchBeg:^{
			__block CGFloat hoffset = 0.;
			
			[mImageSearch imagesForQuery:query offset:0 count:10 handler:^ (NSURL *url, NSInteger _width, NSInteger _height, BOOL *_stop) {
				NSLog(@"url=%@, width=%ld, height=%ld", url, _width, _height);
				
				if (mMovie != mbmovie) {
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
	
	NSInteger hours = _durationHrBtn.indexOfSelectedItem;
	NSInteger minutes = _durationMinBtn.indexOfSelectedItem;
	NSInteger seconds = _durationSecBtn.indexOfSelectedItem;
	NSString *title = _titleTxt.stringValue;
	
	if (title.length && ![mMovie.title isEqualToString:title])
		[dataManager movie:mMovie updateWithTitle:title];
	
	[dataManager movie:mMovie updateWithValues:@{
	      @"year": @(_yearTxt.integerValue),
	    @"rating": _ratingTxt.stringValue,
	   @"dirpath": _pathTxt.stringValue,
	  @"synopsis": _descriptionTxt.stringValue,
	  @"duration": @((hours*60*60) + (minutes*60) + seconds),
	     @"score": @(_scoreBtn.indexOfSelectedItem),
	    @"poster": mImageData.length ? mImageData : [NSNull null]
	}];
	
	[_posterImg setToolTip:mMovie.posterId];
	[mMovie updateInfoText];
	
	// TODO: clear out on-disk and in-memory cache for the poster image (if any)
	
	[self hide];
}

/**
 *
 *
 */
- (IBAction)doActionClose:(id)sender
{
	[self hide];
}

/**
 *
 *
 */
- (IBAction)doActionDelete:(id)sender
{
	
}

/**
 *
 *
 */
- (IBAction)doActionGenreAdd:(id)sender
{
	
}

/**
 *
 *
 */
- (IBAction)doActionGenreDel:(id)sender
{
	
}

/**
 *
 *
 */
- (IBAction)doActionLanguageAdd:(id)sender
{
	
}

/**
 *
 *
 */
- (IBAction)doActionLanguageDel:(id)sender
{
	
}

/**
 *
 *
 */
- (IBAction)doActionActorAdd:(id)sender
{
	
}

/**
 *
 *
 */
- (IBAction)doActionActorDel:(id)sender
{
	
}

@end
