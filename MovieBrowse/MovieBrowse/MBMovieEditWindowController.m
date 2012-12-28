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
#import "MBImageCache.h"
#import "MBGenre.h"
#import "MBMovie.h"
#import "MBPerson.h"
#import "NSThread+Additions.h"

@interface MBMovieEditWindowController ()
{
	MBMovie *mMovie;
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
		
		seconds = mMovie.duration.integerValue;
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
	
	/*
	[mGenres setArray:[mMovie.genres.allValues sortedArrayUsingComparator:^ NSComparisonResult (id genre1, id genre2) {
		return [((MBGenre *)genre1).name caseInsensitiveCompare:((MBGenre *)genre2).name];
	}]];
	
	[mLanguages setArray:[mMovie.languages sortedArrayUsingComparator:^ NSComparisonResult (id language1, id language2) {
		return [language1 compare:language2];
	}]];
	
	[mActors setArray:[mMovie.actors.allValues sortedArrayUsingComparator:^ NSComparisonResult (id actor1, id actor2) {
		return [((MBPerson *)actor1).name compare:((MBPerson *)actor2).name];
	}]];
	*/
	
	[_genreArrayController setSortDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"name" ascending:TRUE]]];
//[_languageArrayController setSortDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"name" ascending:TRUE]]];
	[_actorArrayController setSortDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"name" ascending:TRUE]]];
	
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
	
	[_posterPrg stopAnimation:self];
	
	if (!image) {
		_posterImg.image = nil;
		[_posterPrg startAnimation:self];
		
		[[MBDownloadQueue sharedInstance] dispatchBeg:^{
			NSImage *image = [[MBImageCache sharedInstance] movieImageWithId:imageId width:0 height:height];
			
			if (!image)
				return;
			
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





#pragma mark - Actions

- (IBAction)doActionClose:(id)sender
{
	[NSApp endSheet:self.window];
	[self.window orderOut:sender];
}

- (IBAction)doActionGenreAdd:(id)sender
{
	
}

- (IBAction)doActionGenreDel:(id)sender
{
	
}

- (IBAction)doActionLanguageAdd:(id)sender
{
	
}

- (IBAction)doActionLanguageDel:(id)sender
{
	
}

- (IBAction)doActionActorAdd:(id)sender
{
	
}

- (IBAction)doActionActorDel:(id)sender
{
	
}

@end
