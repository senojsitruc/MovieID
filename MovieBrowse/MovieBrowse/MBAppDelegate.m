//
//  MBAppDelegate.m
//  MovieBrowse
//
//  Created by Curtis Jones on 2012.09.05.
//  Copyright (c) 2012 Curtis Jones. All rights reserved.
//

#import "MBAppDelegate.h"
#import "MBGenre.h"
#import "MBMovie.h"
#import "MBPerson.h"
#import "MBStuff.h"
#import "MBDataManager.h"
#import "MBActorMovieView.h"
#import "MBImageCache.h"
#import <MovieID/IDMediaInfo.h>
#import <MovieID/IDSearch.h>
#import "NSThread+Additions.h"
#import "MBTableHeaderView.h"
#import "MBPopUpButtonCell.h"
#import "MBTableHeaderCell.h"
#import "MBDownloadQueue.h"
#import "MBImportViewController.h"
#import "NSString+Additions.h"

NSString * const MBDefaultsKeyImageHost = @"MBDefaultsKeyImageHost";
NSString * const MBDefaultsKeyImageCache = @"MBDefaultsKeyImageCache";
NSString * const MBDefaultsKeySources = @"MBDefaultsKeySources";
NSString * const MBDefaultsKeySourcesPath = @"path";
NSString * const MBDefaultsKeyApiTmdb = @"MBDefaultsKeyApiTmdb";
NSString * const MBDefaultsKeyApiImdb = @"MBDefaultsKeyApiImdb";
NSString * const MBDefaultsKeyApiRt = @"MBDefaultsKeyApiRt";
NSString * const MBDefaultsKeyMoviesSort = @"MBDefaultsKeyMoviesSort";
NSString * const MBDefaultsKeyMoviesShowHidden = @"MBDefaultsKeyMoviesShowHidden";
NSString * const MBDefaultsKeyGenreMulti = @"MBDefaultsKeyGenreMulti";
NSString * const MBDefaultsKeyActorShow = @"MBDefaultsKeyActorShow";
NSString * const MBDefaultsKeyActorSort = @"MBDefaultsKeyActorSort";
NSString * const MBDefaultsKeyActorSelection = @"MBDefaultsKeyActorSelection";
NSString * const MBDefaultsKeyGenreSelection = @"MBDefaultsKeyGenreSelection";
NSString * const MBDefaultsKeyMovieSelection = @"MBDefaultsKeyMovieSelection";

static MBAppDelegate *gAppDelegate;

@interface MBAppDelegate ()
{
	dispatch_queue_t mImageQueue;
	
	MBDataManager *mDataManager;
	BOOL mIsDoneLoading;
	
	MBPerson *mActorSelection;
	NSMutableDictionary *mGenreSelections;
	MBMovie *mMovieSelection;
	
	NSUInteger mActorWindowTransId;
	
	/**
	 * Movie Table
	 */
	MBPopUpButtonCell *mMovieHeaderCell;
	NSMenu *mMovieHeaderMenu;
	NSMenuItem *mMovieHeaderMenuSortByTitleItem;
	NSMenuItem *mMovieHeaderMenuSortByYearItem;
	NSMenuItem *mMovieHeaderMenuSortByScoreItem;
	NSMenuItem *mMovieHeaderMenuSortByRuntimeItem;
	NSMenuItem *mMovieHeaderMenuShowHidden;
	BOOL mShowHiddenMovies;
	
	/**
	 * Genre Table
	 */
	MBPopUpButtonCell *mGenreHeaderCell;
	NSMenu *mGenreHeaderMenu;
	NSMenuItem *mGenreHeaderMenuMultiOrItem;
	NSMenuItem *mGenreHeaderMenuMultiAndItem;
	NSMenuItem *mGenreHeaderMenuMultiNotOrItem;
	NSMenuItem *mGenreHeaderMenuMultiNotAndItem;
	
	/**
	 * Actor Table
	 */
	MBPopUpButtonCell *mActorHeaderCell;
	NSMenu *mActorHeaderMenu;
	NSMenuItem *mActorHeaderMenuShowAllItem;
	NSMenuItem *mActorHeaderMenuShowPopularItem;
	NSMenuItem *mActorHeaderMenuSortByName;
	NSMenuItem *mActorHeaderMenuSortByAge;
	NSMenuItem *mActorHeaderMenuSortByMovies;
}
@end

@implementation MBAppDelegate

@synthesize dataManager = mDataManager;

/**
 *
 *
 */
- (void)awakeFromNib
{
	gAppDelegate = self;
	mShowHiddenMovies = FALSE;
	mIsDoneLoading = FALSE;
	mDataManager = [[MBDataManager alloc] init];
	mGenreSelections = [[NSMutableDictionary alloc] init];
	
	self.actorsArray = [[NSMutableArray alloc] init];
	self.genresArray = [[NSMutableArray alloc] init];
	self.moviesArray = [[NSMutableArray alloc] init];
	self.searchArray = [[NSMutableArray alloc] init];
	
	// user defaults
	{
		NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
		
		[defaults registerDefaults:@{
				MBDefaultsKeyImageHost: @"http://home.stygian.net:20080",
			 MBDefaultsKeyImageCache: @"~/Library/Application Support/MovieBrowse/Cache",
					MBDefaultsKeySources: [[NSMutableArray alloc] initWithArray:@[
																 @{MBDefaultsKeySourcesPath:@"/Volumes/bigger/Media/Movies/1"},
																 @{MBDefaultsKeySourcesPath:@"/Volumes/bigger/Media/Movies/2"},
																 @{MBDefaultsKeySourcesPath:@"/Volumes/bigger/Media/Movies/3"},
																 @{MBDefaultsKeySourcesPath:@"/Volumes/bigger/Media/Movies/4"},
																 @{MBDefaultsKeySourcesPath:@"/Volumes/bigger/Media/Movies/5"},
																 @{MBDefaultsKeySourcesPath:@"/Volumes/bigger/Media/Movies/6"},
																 @{MBDefaultsKeySourcesPath:@"/Volumes/bigger/Media/Movies/7"},
																 @{MBDefaultsKeySourcesPath:@"/Volumes/bigger/Media/Movies/8"},
																 @{MBDefaultsKeySourcesPath:@"/Volumes/bigger/Media/Movies/9"},
																 @{MBDefaultsKeySourcesPath:@"/Volumes/bigger/Media/Movies/A"},
																 @{MBDefaultsKeySourcesPath:@"/Volumes/bigger/Media/Movies/B"},
																 @{MBDefaultsKeySourcesPath:@"/Volumes/bigger/Media/Movies/C"},
																 @{MBDefaultsKeySourcesPath:@"/Volumes/bigger/Media/Movies/D"},
																 @{MBDefaultsKeySourcesPath:@"/Volumes/bigger/Media/Movies/E"},
																 @{MBDefaultsKeySourcesPath:@"/Volumes/bigger/Media/Movies/F"},
																 @{MBDefaultsKeySourcesPath:@"/Volumes/bigger/Media/Movies/G"},
																 @{MBDefaultsKeySourcesPath:@"/Volumes/bigger/Media/Movies/H"},
																 @{MBDefaultsKeySourcesPath:@"/Volumes/bigger/Media/Movies/I"},
																 @{MBDefaultsKeySourcesPath:@"/Volumes/bigger/Media/Movies/J"},
																 @{MBDefaultsKeySourcesPath:@"/Volumes/bigger/Media/Movies/K"},
																 @{MBDefaultsKeySourcesPath:@"/Volumes/bigger/Media/Movies/L"},
																 @{MBDefaultsKeySourcesPath:@"/Volumes/bigger/Media/Movies/M"},
																 @{MBDefaultsKeySourcesPath:@"/Volumes/bigger/Media/Movies/N"},
																 @{MBDefaultsKeySourcesPath:@"/Volumes/bigger/Media/Movies/O"},
																 @{MBDefaultsKeySourcesPath:@"/Volumes/bigger/Media/Movies/P"},
																 @{MBDefaultsKeySourcesPath:@"/Volumes/bigger/Media/Movies/Q"},
																 @{MBDefaultsKeySourcesPath:@"/Volumes/bigger/Media/Movies/R"},
																 @{MBDefaultsKeySourcesPath:@"/Volumes/bigger/Media/Movies/S"},
																 @{MBDefaultsKeySourcesPath:@"/Volumes/bigger/Media/Movies/T"},
																 @{MBDefaultsKeySourcesPath:@"/Volumes/bigger/Media/Movies/U"},
																 @{MBDefaultsKeySourcesPath:@"/Volumes/bigger/Media/Movies/V"},
																 @{MBDefaultsKeySourcesPath:@"/Volumes/bigger/Media/Movies/W"},
																 @{MBDefaultsKeySourcesPath:@"/Volumes/bigger/Media/Movies/X"},
																 @{MBDefaultsKeySourcesPath:@"/Volumes/bigger/Media/Movies/Y"},
																 @{MBDefaultsKeySourcesPath:@"/Volumes/bigger/Media/Movies/Z"}
																]],
					MBDefaultsKeyApiTmdb: @"",
					MBDefaultsKeyApiImdb: @"",
						MBDefaultsKeyApiRt: @"",
			 MBDefaultsKeyMoviesSort: @"Title",
 MBDefaultsKeyMoviesShowHidden: @(0),
			 MBDefaultsKeyGenreMulti: @"Or",
				MBDefaultsKeyActorShow: @"Popular",
				MBDefaultsKeyActorSort: @"Name",
	 MBDefaultsKeyActorSelection: @[],
	 MBDefaultsKeyGenreSelection: @[],
	 MBDefaultsKeyMovieSelection: @[]
		}];
	}
	
	//
	// movie table customizations
	//
	{
		NSTableColumn *column = [self.movieTable tableColumnWithIdentifier:@"Movies"];
		MBTableHeaderView *headerView = [[MBTableHeaderView alloc] init];
		MBPopUpButtonCell *headerCell = [[MBPopUpButtonCell alloc] initTextCell:@"MoviesCell"];
		
		NSMenu *menu = [[NSMenu alloc] initWithTitle:@"Movie Menu"];
		
		NSRect headerFrame = self.movieTable.headerView.frame;
		headerFrame.size.height += 10;
		headerView.frame = headerFrame;
		
		[menu addItemWithTitle:@"Sort" action:nil keyEquivalent:@""];
		NSMenuItem *sortByTitle = [menu addItemWithTitle:@"  Movie by Title" action:@selector(doActionMoviesSortByTitle:) keyEquivalent:@""];
		NSMenuItem *sortByYear = [menu addItemWithTitle:@"  Movie by Year" action:@selector(doActionMoviesSortByYear:) keyEquivalent:@""];
		NSMenuItem *sortByScore = [menu addItemWithTitle:@"  Movie by Score" action:@selector(doActionMoviesSortByScore:) keyEquivalent:@""];
		NSMenuItem *sortByRuntime = [menu addItemWithTitle:@"  Movie by Runtime" action:@selector(doActionMoviesSortByRuntime:) keyEquivalent:@""];
		[menu addItem:[NSMenuItem separatorItem]];
		NSMenuItem *showHidden = [menu addItemWithTitle:@"Show Hidden" action:@selector(doActionMoviesShowHidden:) keyEquivalent:@""];
		
		sortByTitle.target = self;
		sortByYear.target = self;
		sortByScore.target = self;
		sortByRuntime.target = self;
		showHidden.target = self;
		
		headerCell.menu = menu;
		column.headerCell = headerCell;
		
		self.movieTable.headerView = headerView;
		
		mMovieHeaderCell = headerCell;
		mMovieHeaderMenu = menu;
		mMovieHeaderMenuSortByTitleItem = sortByTitle;
		mMovieHeaderMenuSortByYearItem = sortByYear;
		mMovieHeaderMenuSortByScoreItem = sortByScore;
		mMovieHeaderMenuSortByRuntimeItem = sortByRuntime;
		mMovieHeaderMenuShowHidden = showHidden;
	}
	
	//
	// genre table customizations
	//
	{
		NSTableColumn *column = [self.genreTable tableColumnWithIdentifier:@"Genre"];
		MBTableHeaderView *headerView = [[MBTableHeaderView alloc] init];
		MBPopUpButtonCell *headerCell = [[MBPopUpButtonCell alloc] initTextCell:@"GenresCell"];
		headerCell.label = @"Genre";
		
		NSMenu *menu = [[NSMenu alloc] initWithTitle:@"Genre Menu"];
		
		NSRect headerFrame = self.genreTable.headerView.frame;
		headerFrame.size.height += 10;
		headerView.frame = headerFrame;
		
		[menu addItemWithTitle:@"Multi Select" action:nil keyEquivalent:@""];
		NSMenuItem *multiOr = [menu addItemWithTitle:@"  Movies in Any" action:@selector(doActionGenresMultiOr:) keyEquivalent:@""];
		NSMenuItem *multiAnd = [menu addItemWithTitle:@"  Movies in All" action:@selector(doActionGenresMultiAnd:) keyEquivalent:@""];
		NSMenuItem *multiNotOr = [menu addItemWithTitle:@"  Movies not in Any" action:@selector(doActionGenresMultiNotOr:) keyEquivalent:@""];
		NSMenuItem *multiNotAnd = [menu addItemWithTitle:@"  Movies not in All" action:@selector(doActionGenresMultiNotAnd:) keyEquivalent:@""];
		
		multiOr.target = self;
		multiAnd.target = self;
		
		headerCell.menu = menu;
		column.headerCell = headerCell;
		
		self.genreTable.headerView = headerView;
		
		mGenreHeaderCell = headerCell;
		mGenreHeaderMenu = menu;
		mGenreHeaderMenuMultiOrItem = multiOr;
		mGenreHeaderMenuMultiAndItem = multiAnd;
		mGenreHeaderMenuMultiNotOrItem = multiNotOr;
		mGenreHeaderMenuMultiNotAndItem = multiNotAnd;
	}
	
	//
	// actor table customizations
	//
	{
		NSTableColumn *column = [self.actorTable tableColumnWithIdentifier:@"Actor"];
		MBTableHeaderView *headerView = [[MBTableHeaderView alloc] init];
		MBPopUpButtonCell *headerCell = [[MBPopUpButtonCell alloc] initTextCell:@"ActorsCell"];
		headerCell.label = @"Actor";
		
		NSMenu *menu = [[NSMenu alloc] initWithTitle:@"Actor Menu"];
		
		NSRect headerFrame = self.actorTable.headerView.frame;
		headerFrame.size.height += 10;
		headerView.frame = headerFrame;
		
		[menu addItemWithTitle:@"Show" action:nil keyEquivalent:@""];
		NSMenuItem *showAll = [menu addItemWithTitle:@"  All" action:@selector(doActionActorsShowAll:) keyEquivalent:@""];
		NSMenuItem *showPopular = [menu addItemWithTitle:@"  Popular" action:@selector(doActionActorsShowPopular:) keyEquivalent:@""];
		[menu addItem:[NSMenuItem separatorItem]];
		
		[menu addItemWithTitle:@"Sort" action:nil keyEquivalent:@""];
		NSMenuItem *sortByName = [menu addItemWithTitle:@"  Actor by Name" action:@selector(doActionActorsSortByName:) keyEquivalent:@""];
		NSMenuItem *sortByAge = [menu addItemWithTitle:@"  Actor by Age" action:@selector(doActionActorsSortByAge:) keyEquivalent:@""];
		NSMenuItem *sortByMovies = [menu addItemWithTitle:@"  Actor by Movies" action:@selector(doActionActorsSortByMovies:) keyEquivalent:@""];
		
		showAll.target = self;
		showPopular.target = self;
		sortByName.target = self;
		sortByAge.target = self;
		sortByMovies.target = self;
		
		headerCell.menu = menu;
		column.headerCell = headerCell;
		
		self.actorTable.headerView = headerView;
		
		mActorHeaderCell = headerCell;
		mActorHeaderMenu = menu;
		mActorHeaderMenuShowAllItem = showAll;
		mActorHeaderMenuShowPopularItem = showPopular;
		mActorHeaderMenuSortByName = sortByName;
		mActorHeaderMenuSortByAge = sortByAge;
		mActorHeaderMenuSortByMovies = sortByMovies;
	}
	
	mImageQueue = dispatch_queue_create("image-queue", DISPATCH_QUEUE_CONCURRENT);
}

/**
 *
 *
 */
- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	// register api keys
	[IDSearch setTmdbApiKey:[[NSUserDefaults standardUserDefaults] stringForKey:MBDefaultsKeyApiTmdb]];
	[IDSearch setImdbApiKey:[[NSUserDefaults standardUserDefaults] stringForKey:MBDefaultsKeyApiImdb]];
	[IDSearch setRtApiKey:  [[NSUserDefaults standardUserDefaults] stringForKey:MBDefaultsKeyApiRt  ]];
	
	// table selection changed notifications
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(doNotificationActorSelectionChanged:) name:NSTableViewSelectionDidChangeNotification object:self.actorTable];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(doNotificationGenreSelectionChanged:) name:NSTableViewSelectionDidChangeNotification object:self.genreTable];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(doNotificationMovieSelectionChanged:) name:NSTableViewSelectionDidChangeNotification object:self.movieTable];
	
	// actor - double click action
	self.actorTable.target = self;
	self.actorTable.doubleAction = @selector(doActionActorDoubleClick:);
	self.actorDescScroll.frame = NSMakeRect(423, 49, 425, 400);
	[self.actorWindow.contentView addSubview:self.actorDescScroll];
	
	//
	// reinstate saved sort orders
	//
	{
		// actors
		{
			NSString *sort = [[NSUserDefaults standardUserDefaults] stringForKey:MBDefaultsKeyActorSort];
			
			if ([sort isEqualToString:@"Name"])
				[self doActionActorsSortByName:mActorHeaderMenuSortByName];
			else if ([sort isEqualToString:@"Age"])
				[self doActionActorsSortByAge:mActorHeaderMenuSortByAge];
			else if ([sort isEqualToString:@"Movies"])
				[self doActionActorsSortByMovies:mActorHeaderMenuSortByMovies];
		}
		
		// genres
		[self.genresArrayController setSortDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"name" ascending:TRUE]]];
		
		// movies
		{
			NSString *sort = [[NSUserDefaults standardUserDefaults] stringForKey:MBDefaultsKeyMoviesSort];
			
			if ([sort isEqualToString:@"Title"])
				[self doActionMoviesSortByTitle:mMovieHeaderMenuSortByTitleItem];
			else if ([sort isEqualToString:@"Year"])
				[self doActionMoviesSortByYear:mMovieHeaderMenuSortByYearItem];
			else if ([sort isEqualToString:@"Score"])
				[self doActionMoviesSortByScore:mMovieHeaderMenuSortByScoreItem];
			else if ([sort isEqualToString:@"Runtime"])
				[self doActionMoviesSortByRuntime:mMovieHeaderMenuSortByRuntimeItem];
		}
	}
	
	//
	// reinstate "show hidden" state
	//
	{
		BOOL showHidden = [[NSUserDefaults standardUserDefaults] boolForKey:MBDefaultsKeyMoviesShowHidden];
		mShowHiddenMovies = showHidden;
		mMovieHeaderMenuShowHidden.state = showHidden ? NSOnState : NSOffState;
	}
	
	//
	// reinstate genre multi-select behavior
	//
	{
		NSString *multi = [[NSUserDefaults standardUserDefaults] stringForKey:MBDefaultsKeyGenreMulti];
		
		if ([multi isEqualToString:@"Or"]) {
			mGenreHeaderMenuMultiOrItem.state = NSOnState;
			mGenreHeaderMenuMultiAndItem.state = NSOffState;
			mGenreHeaderMenuMultiNotOrItem.state = NSOffState;
			mGenreHeaderMenuMultiNotAndItem.state = NSOffState;
		}
		else if ([multi isEqualToString:@"And"]) {
			mGenreHeaderMenuMultiOrItem.state = NSOffState;
			mGenreHeaderMenuMultiAndItem.state = NSOnState;
			mGenreHeaderMenuMultiNotOrItem.state = NSOffState;
			mGenreHeaderMenuMultiNotAndItem.state = NSOffState;
		}
		else if ([multi isEqualToString:@"NotOr"]) {
			mGenreHeaderMenuMultiOrItem.state = NSOffState;
			mGenreHeaderMenuMultiAndItem.state = NSOffState;
			mGenreHeaderMenuMultiNotOrItem.state = NSOnState;
			mGenreHeaderMenuMultiNotAndItem.state = NSOffState;
		}
		else if ([multi isEqualToString:@"NotAnd"]) {
			mGenreHeaderMenuMultiOrItem.state = NSOffState;
			mGenreHeaderMenuMultiAndItem.state = NSOffState;
			mGenreHeaderMenuMultiNotOrItem.state = NSOffState;
			mGenreHeaderMenuMultiNotAndItem.state = NSOnState;
		}
	}
	
	//
	// reinstate actor "show" behavior
	{
		NSString *show = [[NSUserDefaults standardUserDefaults] stringForKey:MBDefaultsKeyActorShow];
		
		if ([show isEqualToString:@"All"]) {
			mActorHeaderMenuShowAllItem.state = NSOnState;
			mActorHeaderMenuShowPopularItem.state = NSOffState;
		}
		else if ([show isEqualToString:@"Popular"]) {
			mActorHeaderMenuShowAllItem.state = NSOffState;
			mActorHeaderMenuShowPopularItem.state = NSOnState;
		}
	}
	
	//
	// load data
	//
	{
		NSMutableArray *actorsArray = [[NSMutableArray alloc] init];
		NSMutableArray *genresArray = [[NSMutableArray alloc] init];
		NSMutableArray *moviesArray = [[NSMutableArray alloc] init];
		
		[mDataManager enumerateGenres:^ (MBGenre *mbgenre, NSUInteger count, BOOL *stop) { [genresArray addObject:mbgenre]; }];
		[mDataManager enumerateActors:^ (MBPerson *mbactor, NSUInteger count, BOOL *stop) { [actorsArray addObject:mbactor]; }];
		[mDataManager enumerateMovies:^ (MBMovie *mbmovie, BOOL *stop) { [moviesArray addObject:mbmovie]; }];
		
		[self.actorsArrayController addObjects:actorsArray];
		[self.genresArrayController addObjects:genresArray];
		[self.moviesArrayController addObjects:moviesArray];
		
		mIsDoneLoading = TRUE;
		
		[self updateActorFilter];
		[self updateGenreFilter];
		[self updateMovieFilter];
		
		[self updateWindowTitle];
	}
	
	//
	// reinstate actor selection
	//
	{
		NSArray *selection = [[NSUserDefaults standardUserDefaults] arrayForKey:MBDefaultsKeyActorSelection];
		
		if (selection.count) {
			MBPerson *mbperson = [mDataManager personWithKey:selection[0]];
			
			if (mbperson) {
				[self.actorsArrayController setSelectedObjects:@[mbperson]];
				[self doNotificationActorSelectionChanged:nil];
				[self.actorTable scrollRowToVisible:self.actorTable.selectedRow];
			}
		}
	}
	
	//
	// reinstate genre selection
	//
	{
		NSArray *selection = [[NSUserDefaults standardUserDefaults] arrayForKey:MBDefaultsKeyGenreSelection];
		
		if (selection.count) {
			[selection enumerateObjectsUsingBlock:^ (id genreKey, NSUInteger genreNdx, BOOL *genreStop) {
				MBGenre *mbgenre = [mDataManager genreWithKey:genreKey];
				
				if (mbgenre)
					mGenreSelections[mbgenre.name] = mbgenre;
			}];
			
			if (mGenreSelections.count == 1)
				mGenreHeaderCell.label = [NSString stringWithFormat:@"Genre (%@)", ((MBGenre *)mGenreSelections.allValues[0]).name];
			else
				mGenreHeaderCell.label = [NSString stringWithFormat:@"Genre (%lu selected)", mGenreSelections.count];
			
			[self.genresArrayController setSelectedObjects:mGenreSelections.allValues];
		}
		else
			mGenreHeaderCell.label = @"Genre";
	}
	
	//
	// reinstate movie selection
	//
	{
		NSArray *selection = [[NSUserDefaults standardUserDefaults] arrayForKey:MBDefaultsKeyMovieSelection];
		
		if (selection.count) {
			MBMovie *mbmovie = [mDataManager movieWithKey:selection[0]];
			
			if (mbmovie) {
				[self.moviesArrayController setSelectedObjects:@[mbmovie]];
				[self doNotificationMovieSelectionChanged:nil];
				[self.movieTable scrollRowToVisible:self.movieTable.selectedRow];
			}
		}
	}
	
	[NSThread performBlockInBackground:^{
		
		/*
		[[mDataManager findMissingFiles] enumerateObjectsUsingBlock:^ (id movie, NSUInteger movieNdx, BOOL *movieStop) {
			MBMovie *mbmovie = (MBMovie *)movie;
			
			if ([mbmovie.dirpath rangeOfString:@"Varg "].location == NSNotFound) {
				NSLog(@"%@", mbmovie.dirpath);
				[mDataManager deleteMovie:mbmovie];
			}
		}];
		*/
		
		//[mDataManager updateFileStats];
		
	}];
}

/**
 *
 *
 */
- (void)applicationWillTerminate:(NSNotification *)aNotification
{
	[mDataManager closeDb];
}

/**
 *
 *
 */
+ (MBAppDelegate *)sharedInstance
{
	return gAppDelegate;
}

/**
 *
 *
 */
- (void)updateWindowTitle
{
	NSMutableString *title = [[NSMutableString alloc] init];
	
	if (mActorSelection) {
		if (title.length)
			[title appendString:@", "];
		[title appendString:mActorSelection.name];
	}
	
	if (mGenreSelections.count) {
		if (title.length)
			[title appendString:@", "];
		if (mGenreSelections.count == 1)
			[title appendString:((MBGenre *)mGenreSelections.allValues[0]).name];
		else
			[title appendFormat:@"%lu genres", mGenreSelections.count];
	}
	
	if (mMovieSelection) {
		if (title.length)
			[title appendString:@", "];
		[title appendString:mMovieSelection.title];
	}
	
	{
		NSUInteger movieCount = ((NSArray *)self.moviesArrayController.arrangedObjects).count;
		
		if (title.length)
			[title appendString:@" - "];
		
		[title appendString:@"("];
		[title appendString:@(movieCount).stringValue];
		
		if (movieCount == 1)
			[title appendString:@" movie)"];
		else
			[title appendString:@" movies)"];
	}
	
	self.window.title = [@"MovieBrowse - " stringByAppendingString:title];
}

/**
 *
 *
 */
- (dispatch_queue_t)imageQueue
{
	return mImageQueue;
}





#pragma mark - Selection Handling

/**
 *
 *
 */
- (void)doNotificationActorSelectionChanged:(NSNotification *)notification
{
	NSArray *selectedObjects = self.actorsArrayController.selectedObjects;
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	
	if (selectedObjects.count == 0) {
		mActorSelection = nil;
		[defaults setObject:@[] forKey:MBDefaultsKeyActorSelection];
	}
	else if (mActorSelection == selectedObjects[0])
		return;
	else {
		mActorSelection = selectedObjects[0];
		[defaults setObject:@[mActorSelection.name] forKey:MBDefaultsKeyActorSelection];
	}
	
	[self updateActorsHeaderLabel];
	[self updateGenreFilter];
	[self updateMovieFilter];
}

/**
 *
 *
 */
- (void)doNotificationGenreSelectionChanged:(NSNotification *)notification
{
	NSArray *selectedObjects = self.genresArrayController.selectedObjects;
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	
	[mGenreSelections removeAllObjects];
	
	if (selectedObjects.count == 0) {
		mGenreHeaderCell.label = @"Genre";
		[defaults setObject:@[] forKey:MBDefaultsKeyGenreSelection];
	}
	else {
		[selectedObjects enumerateObjectsUsingBlock:^ (id obj, NSUInteger ndx, BOOL *stop) {
			mGenreSelections[((MBGenre *)obj).name] = obj;
		}];
		if (selectedObjects.count == 1)
			mGenreHeaderCell.label = [NSString stringWithFormat:@"Genre (%@)", ((MBGenre *)mGenreSelections.allValues[0]).name];
		else
			mGenreHeaderCell.label = [NSString stringWithFormat:@"Genre (%lu selected)", selectedObjects.count];
		[defaults setObject:[NSArray arrayWithArray:mGenreSelections.allKeys] forKey:MBDefaultsKeyGenreSelection];
	}
	
	[self.genreTable.headerView setNeedsDisplay:TRUE];
	
	[self updateActorFilter];
	[self updateMovieFilter];
}

/**
 *
 *
 */
- (void)doNotificationMovieSelectionChanged:(NSNotification *)notification
{
	NSArray *selectedObjects = self.moviesArrayController.selectedObjects;
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	
	if (selectedObjects.count == 0) {
		mMovieSelection = nil;
		[defaults setObject:@[] forKey:MBDefaultsKeyMovieSelection];
	}
	else if (mMovieSelection == selectedObjects[0])
		return;
	else {
		mMovieSelection = selectedObjects[0];
		[defaults setObject:@[mMovieSelection.dbkey] forKey:MBDefaultsKeyMovieSelection];
	}
	
	[self updateMoviesHeaderLabel];
	[self updateActorFilter];
	[self updateGenreFilter];
}





#pragma mark - Actors

/**
 *
 *
 */
- (void)doActionActorDoubleClick:(NSTableView *)tableView
{
	NSInteger row = tableView.selectedRow;
	
	if (row < 0)
		return;
	
	MBPerson *mbperson = [[self.actorsArrayController arrangedObjects] objectAtIndex:row];
	
	if (mbperson)
		[self showActor:mbperson];
}

/**
 *
 *
 */
- (IBAction)doActionActorClose:(id)sender
{
	[NSApp endSheet:self.actorWindow];
	[self.actorWindow orderOut:sender];
}

/**
 *
 *
 */
- (void)showActor:(MBPerson *)mbperson
{
	NSUInteger actorWindowTransId = ++mActorWindowTransId;
	
	self.actorWindowName.stringValue = mbperson.name ? mbperson.name : @"";
	self.actorWindowInfo.stringValue = mbperson.info ? mbperson.info : @"";
	self.actorMovies.person = mbperson;
	self.actorWindowImage.image = nil;
	
	[self.actorDescTxt setEditable:TRUE];
	[self.actorDescTxt insertText:(mbperson.bio ? [[NSAttributedString alloc] initWithString:mbperson.bio] : @"Nothing!")];
	[self.actorDescTxt setEditable:FALSE];
	
	if (mbperson.bio)
		[self.actorDescTxt.textStorage replaceCharactersInRange:NSMakeRange(0, self.actorDescTxt.textStorage.length) withString:mbperson.bio];
	else
		[self.actorDescTxt.textStorage replaceCharactersInRange:NSMakeRange(0, self.actorDescTxt.textStorage.length) withString:@""];
	
	[self.actorDescScroll.contentView scrollToPoint:NSMakePoint(0,0)];
	self.actorDescScroll.horizontalScroller.floatValue = 0;
	
	[self.actorImagePrg startAnimation:self];
	
	[[MBDownloadQueue sharedInstance] dispatchBeg:^{
		NSImage *image = [[MBImageCache sharedInstance] actorImageWithId:mbperson.imageId];
		
		if (actorWindowTransId != mActorWindowTransId)
			return;
		
		[[NSThread mainThread] performBlock:^{
			[self.actorImagePrg stopAnimation:self];
			
			if (actorWindowTransId != mActorWindowTransId)
				return;
			
			self.actorWindowImage.image = image;
		}];
	}];
	
	[NSApp beginSheet:self.actorWindow modalForWindow:self.window modalDelegate:nil didEndSelector:nil contextInfo:nil];
}





#pragma mark - Movies Header Menu

/**
 *
 *
 */
- (void)updateMoviesHeaderLabel
{
	NSString *prefix = @"";
	
	if (mMovieHeaderMenuSortByTitleItem.state == NSOnState)
		prefix = @"Movie by Title";
	else if (mMovieHeaderMenuSortByYearItem.state == NSOnState)
		prefix = @"Movie by Year";
	else if (mMovieHeaderMenuSortByScoreItem.state == NSOnState)
		prefix = @"Movie by Score";
	else if (mMovieHeaderMenuSortByRuntimeItem.state == NSOnState)
		prefix = @"Movie by Runtime";
	
	if (mMovieSelection)
		mMovieHeaderCell.label = [NSString stringWithFormat:@"%@ (%@)", prefix, mMovieSelection.title];
	else
		mMovieHeaderCell.label = prefix;
	
	[self.movieTable.headerView setNeedsDisplay:TRUE];
}

/**
 *
 *
 */
- (void)doActionMoviesSortByTitle:(id)sender
{
	mMovieHeaderMenuSortByTitleItem.state = NSOnState;
	mMovieHeaderMenuSortByYearItem.state = NSOffState;
	mMovieHeaderMenuSortByScoreItem.state = NSOffState;
	mMovieHeaderMenuSortByRuntimeItem.state = NSOffState;
	
	[[NSUserDefaults standardUserDefaults] setObject:@"Title" forKey:MBDefaultsKeyMoviesSort];
	
	[self updateMoviesHeaderLabel];
	[self.moviesArrayController setSortDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"sortTitle" ascending:TRUE]]];
	
	if (mMovieSelection)
		[self.movieTable scrollRowToVisible:self.movieTable.selectedRow];
	else {
		((NSScrollView *)self.movieTable.superview.superview).verticalScroller.floatValue = 0;
		[((NSScrollView *)self.movieTable.superview.superview).contentView scrollToPoint:NSMakePoint(0,0)];
	}
}

/**
 *
 *
 */
- (void)doActionMoviesSortByYear:(id)sender
{
	mMovieHeaderMenuSortByTitleItem.state = NSOffState;
	mMovieHeaderMenuSortByYearItem.state = NSOnState;
	mMovieHeaderMenuSortByScoreItem.state = NSOffState;
	mMovieHeaderMenuSortByRuntimeItem.state = NSOffState;
	
	[[NSUserDefaults standardUserDefaults] setObject:@"Year" forKey:MBDefaultsKeyMoviesSort];
	
	[self updateMoviesHeaderLabel];
	[self.moviesArrayController setSortDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"year" ascending:FALSE], [NSSortDescriptor sortDescriptorWithKey:@"sortTitle" ascending:TRUE]]];
	
	if (mMovieSelection)
		[self.movieTable scrollRowToVisible:self.movieTable.selectedRow];
	else {
		((NSScrollView *)self.movieTable.superview.superview).verticalScroller.floatValue = 0;
		[((NSScrollView *)self.movieTable.superview.superview).contentView scrollToPoint:NSMakePoint(0,0)];
	}
}

/**
 *
 *
 */
- (void)doActionMoviesSortByScore:(id)sender
{
	mMovieHeaderMenuSortByTitleItem.state = NSOffState;
	mMovieHeaderMenuSortByYearItem.state = NSOffState;
	mMovieHeaderMenuSortByScoreItem.state = NSOnState;
	mMovieHeaderMenuSortByRuntimeItem.state = NSOffState;
	
	[[NSUserDefaults standardUserDefaults] setObject:@"Score" forKey:MBDefaultsKeyMoviesSort];
	
	[self updateMoviesHeaderLabel];
	[self.moviesArrayController setSortDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"score" ascending:FALSE], [NSSortDescriptor sortDescriptorWithKey:@"sortTitle" ascending:TRUE]]];
	
	if (mMovieSelection)
		[self.movieTable scrollRowToVisible:self.movieTable.selectedRow];
	else {
		((NSScrollView *)self.movieTable.superview.superview).verticalScroller.floatValue = 0;
		[((NSScrollView *)self.movieTable.superview.superview).contentView scrollToPoint:NSMakePoint(0,0)];
	}
}

/**
 *
 *
 */
- (void)doActionMoviesSortByRuntime:(id)sender
{
	mMovieHeaderMenuSortByTitleItem.state = NSOffState;
	mMovieHeaderMenuSortByYearItem.state = NSOffState;
	mMovieHeaderMenuSortByScoreItem.state = NSOffState;
	mMovieHeaderMenuSortByRuntimeItem.state = NSOnState;
	
	[[NSUserDefaults standardUserDefaults] setObject:@"Runtime" forKey:MBDefaultsKeyMoviesSort];
	
	[self updateMoviesHeaderLabel];
	[self.moviesArrayController setSortDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"duration" ascending:FALSE], [NSSortDescriptor sortDescriptorWithKey:@"sortTitle" ascending:TRUE]]];
	
	if (mMovieSelection)
		[self.movieTable scrollRowToVisible:self.movieTable.selectedRow];
	else {
		((NSScrollView *)self.movieTable.superview.superview).verticalScroller.floatValue = 0;
		[((NSScrollView *)self.movieTable.superview.superview).contentView scrollToPoint:NSMakePoint(0,0)];
	}
}

/**
 *
 *
 */
- (void)doActionMoviesShowHidden:(id)sender
{
	NSMenuItem *showHidden = (NSMenuItem *)sender;
	NSInteger state = showHidden.state;
	
	if (state == NSOnState) {
		showHidden.state = NSOffState;
		mShowHiddenMovies = FALSE;
	}
	else {
		showHidden.state = NSOnState;
		mShowHiddenMovies = TRUE;
	}
	
	[[NSUserDefaults standardUserDefaults] setBool:mShowHiddenMovies forKey:MBDefaultsKeyMoviesShowHidden];
	
	[self.movieTable reloadData];
}





#pragma mark - Genres Header Menu

/**
 *
 *
 */
- (void)doActionGenresMultiOr:(id)sender
{
	mGenreHeaderMenuMultiOrItem.state = NSOnState;
	mGenreHeaderMenuMultiAndItem.state = NSOffState;
	mGenreHeaderMenuMultiNotOrItem.state = NSOffState;
	mGenreHeaderMenuMultiNotAndItem.state = NSOffState;
	[self.genreTable.headerView setNeedsDisplay:TRUE];
	
	[[NSUserDefaults standardUserDefaults] setObject:@"Or" forKey:MBDefaultsKeyGenreMulti];
	
	[self doNotificationGenreSelectionChanged:nil];
}

/**
 *
 *
 */
- (void)doActionGenresMultiAnd:(id)sender
{
	mGenreHeaderMenuMultiOrItem.state = NSOffState;
	mGenreHeaderMenuMultiAndItem.state = NSOnState;
	mGenreHeaderMenuMultiNotOrItem.state = NSOffState;
	mGenreHeaderMenuMultiNotAndItem.state = NSOffState;
	[self.genreTable.headerView setNeedsDisplay:TRUE];
	
	[[NSUserDefaults standardUserDefaults] setObject:@"And" forKey:MBDefaultsKeyGenreMulti];
	
	[self doNotificationGenreSelectionChanged:nil];
}

/**
 *
 *
 */
- (void)doActionGenresMultiNotOr:(id)sender
{
	mGenreHeaderMenuMultiOrItem.state = NSOffState;
	mGenreHeaderMenuMultiAndItem.state = NSOffState;
	mGenreHeaderMenuMultiNotOrItem.state = NSOnState;
	mGenreHeaderMenuMultiNotAndItem.state = NSOffState;
	[self.genreTable.headerView setNeedsDisplay:TRUE];
	
	[[NSUserDefaults standardUserDefaults] setObject:@"NotOr" forKey:MBDefaultsKeyGenreMulti];
	
	[self doNotificationGenreSelectionChanged:nil];
}

/**
 *
 *
 */
- (void)doActionGenresMultiNotAnd:(id)sender
{
	mGenreHeaderMenuMultiOrItem.state = NSOffState;
	mGenreHeaderMenuMultiAndItem.state = NSOffState;
	mGenreHeaderMenuMultiNotOrItem.state = NSOffState;
	mGenreHeaderMenuMultiNotAndItem.state = NSOnState;
	[self.genreTable.headerView setNeedsDisplay:TRUE];
	
	[[NSUserDefaults standardUserDefaults] setObject:@"NotAnd" forKey:MBDefaultsKeyGenreMulti];
	
	[self doNotificationGenreSelectionChanged:nil];
}





#pragma mark - Actors Header Menu

/**
 *
 *
 */
- (void)updateActorsHeaderLabel
{
	NSString *prefix = nil;
	
	if (mActorHeaderMenuSortByName.state == NSOnState)
		prefix = @"Actor by Name";
	else if (mActorHeaderMenuSortByAge.state == NSOnState)
		prefix = @"Actor by Age";
	else if (mActorHeaderMenuSortByMovies.state == NSOnState)
		prefix = @"Actor by Movies";
	else
		prefix = @"Actor";
	
	if (mActorSelection)
		mActorHeaderCell.label = [NSString stringWithFormat:@"%@ (%@)", prefix, mActorSelection.name];
	else
		mActorHeaderCell.label = prefix;
	
	[self.actorTable.headerView setNeedsDisplay:TRUE];
}

/**
 *
 *
 */
- (void)doActionActorsShowAll:(id)sender
{
	mActorHeaderMenuShowAllItem.state = NSOnState;
	mActorHeaderMenuShowPopularItem.state = NSOffState;
	[self.actorTable.headerView setNeedsDisplay:TRUE];
	
	[[NSUserDefaults standardUserDefaults] setObject:@"All" forKey:MBDefaultsKeyActorShow];
	
	[self updateActorFilter];
}

/**
 *
 *
 */
- (void)doActionActorsShowPopular:(id)sender
{
	mActorHeaderMenuShowAllItem.state = NSOffState;
	mActorHeaderMenuShowPopularItem.state = NSOnState;
	[self.actorTable.headerView setNeedsDisplay:TRUE];
	
	[[NSUserDefaults standardUserDefaults] setObject:@"Popular" forKey:MBDefaultsKeyActorShow];
	
	[self updateActorFilter];
}

/**
 *
 *
 */
- (void)doActionActorsSortByName:(id)sender
{
	mActorHeaderMenuSortByName.state = NSOnState;
	mActorHeaderMenuSortByAge.state = NSOffState;
	mActorHeaderMenuSortByMovies.state = NSOffState;
	
	[self updateActorsHeaderLabel];
	[[NSUserDefaults standardUserDefaults] setObject:@"Name" forKey:MBDefaultsKeyActorSort];
	[self.actorsArrayController setSortDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"name" ascending:TRUE]]];
	
	if (mActorSelection)
		[self.actorTable scrollRowToVisible:self.actorTable.selectedRow];
	else {
		((NSScrollView *)self.actorTable.superview.superview).verticalScroller.floatValue = 0;
		[((NSScrollView *)self.actorTable.superview.superview).contentView scrollToPoint:NSMakePoint(0,0)];
	}
}

/**
 *
 *
 */
- (void)doActionActorsSortByAge:(id)sender
{
	mActorHeaderMenuSortByName.state = NSOffState;
	mActorHeaderMenuSortByAge.state = NSOnState;
	mActorHeaderMenuSortByMovies.state = NSOffState;
	
	[self updateActorsHeaderLabel];
	[[NSUserDefaults standardUserDefaults] setObject:@"Age" forKey:MBDefaultsKeyActorSort];
	[self.actorsArrayController setSortDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"dob" ascending:FALSE]]];
	
	if (mActorSelection)
		[self.actorTable scrollRowToVisible:self.actorTable.selectedRow];
	else {
		((NSScrollView *)self.actorTable.superview.superview).verticalScroller.floatValue = 0;
		[((NSScrollView *)self.actorTable.superview.superview).contentView scrollToPoint:NSMakePoint(0,0)];
	}
}

/**
 *
 *
 */
- (void)doActionActorsSortByMovies:(id)sender
{
	mActorHeaderMenuSortByName.state = NSOffState;
	mActorHeaderMenuSortByAge.state = NSOffState;
	mActorHeaderMenuSortByMovies.state = NSOnState;
	
	[self updateActorsHeaderLabel];
	[[NSUserDefaults standardUserDefaults] setObject:@"Movies" forKey:MBDefaultsKeyActorSort];
	[self.actorsArrayController setSortDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"movieCount" ascending:FALSE]]];
	
	if (mActorSelection)
		[self.actorTable scrollRowToVisible:self.actorTable.selectedRow];
	else {
		((NSScrollView *)self.actorTable.superview.superview).verticalScroller.floatValue = 0;
		[((NSScrollView *)self.actorTable.superview.superview).contentView scrollToPoint:NSMakePoint(0,0)];
	}
}





#pragma mark - Movies - Hide/Unhide

/**
 *
 *
 */
- (void)doActionMovieHide:(MBMovie *)mbmovie withView:(NSView *)view
{
	mbmovie.hidden = @(TRUE);
	[mDataManager saveMovie:mbmovie];
	
	NSLog(@"%@", view);
	
	if (view) {
		NSInteger index = [self.movieTable rowForView:view];
		
		NSLog(@"%ld", index);
		
		if (index >= 0) {
			[self.movieTable removeRowsAtIndexes:[NSIndexSet indexSetWithIndex:index] withAnimation:NSTableViewAnimationSlideRight];
			[self.movieTable reloadData];
		}
	}
}

/**
 *
 *
 */
- (void)doActionMovieUnhide:(MBMovie *)mbmovie withView:(NSView *)view
{
	mbmovie.hidden = @(FALSE);
	[mDataManager saveMovie:mbmovie];
	[self.movieTable reloadData];
}





#pragma mark - Link-To

/**
 *
 *
 */
- (void)doActionLinkToTMDb:(MBMovie *)mbmovie
{
	self.linkToTxt.stringValue = @"";
	[NSApp beginSheet:self.linkToWindow modalForWindow:self.window modalDelegate:self didEndSelector:@selector(tmdbSheetDidEnd:returnCode:contextInfo:) contextInfo:(void *)mbmovie];
}

- (void)tmdbSheetDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
	if (!returnCode)
		return;
}

- (IBAction)doActionLinkToCancel:(id)sender
{
	[NSApp endSheet:self.linkToWindow returnCode:0];
	[self.linkToWindow orderOut:sender];
}

- (IBAction)doActionLinkToLink:(id)sender
{
	[NSApp endSheet:self.linkToWindow returnCode:1];
	[self.linkToWindow orderOut:sender];
}






#pragma mark - Preferences

/**
 *
 *
 */
- (IBAction)doActionShowPrefs:(id)sender
{
	[NSApp beginSheet:self.prefsWin modalForWindow:self.window modalDelegate:nil didEndSelector:nil contextInfo:nil];
}

/**
 *
 *
 */
- (IBAction)doActionPrefsClose:(id)sender
{
	[NSApp endSheet:self.prefsWin];
	[self.prefsWin orderOut:sender];
}





#pragma mark - Search

/**
 *
 *
 */
- (void)doActionSearchShow:(id)sender
{
	if ([sender isKindOfClass:[MBMovie class]]) {
		MBMovie *mbmovie = (MBMovie *)sender;
		self.searchTxt.stringValue = mbmovie.title;
	}
	
	[NSApp beginSheet:self.searchWin modalForWindow:self.window modalDelegate:nil didEndSelector:nil contextInfo:nil];
}

/**
 *
 *
 */
- (IBAction)doActionSearchClose:(id)sender
{
	[NSApp endSheet:self.searchWin];
	[self.searchWin orderOut:sender];
}

/**
 *
 *
 */
- (IBAction)doActionSearch:(id)sender
{
	NSString *searchTxt = self.searchTxt.stringValue;
	
	if (!searchTxt)
		return;
	
	searchTxt = [searchTxt stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	
	if (!searchTxt.length)
		return;
	
	// clear out the search result table
	[self.searchArrayController removeObjects:self.searchArray];
	
	/*
	self.searchBtn.stringValue = @"Cancel";
	
	[NSThread performBlockInBackground:^{
		NSArray *results = [IDSearch tmdbSearchMovie:title andYear:year];
		[[NSThread mainThread] performBlock:^{
			self.searchBtn.stringValue = @"Search";
		}];
	}];
	*/
	
}





#pragma mark - Import / Export

/**
 *
 *
 */
- (IBAction)doActionImport:(id)sender
{
	[self.importController scanSource:@"/Volumes/bigger/Media/Movies/O"];
	[NSApp beginSheet:self.importWindow modalForWindow:self.window modalDelegate:self didEndSelector:nil contextInfo:nil];
}

/**
 *
 *
 */
- (IBAction)doActionExport:(id)sender
{
	NSArray *movies = self.moviesArrayController.arrangedObjects;
	NSMutableString *output = [[NSMutableString alloc] init];
	NSOutputStream *stream = [NSOutputStream outputStreamToFileAtPath:[@"~/Desktop/copy_movies.sh" stringByExpandingTildeInPath] append:TRUE];
	
	[movies enumerateObjectsUsingBlock:^ (id movie, NSUInteger movieNdx, BOOL *movieStop) {
		MBMovie *mbmovie = (MBMovie *)movie;
		NSString *dirpath = mbmovie.dirpath;
		NSString *dirname = dirpath.lastPathComponent;
		NSLog(@"%@", dirpath);
		[output appendFormat:@"if [ ! -e \"$MOVIE_DST/%@\" ]; then echo \"%@\"; cp -R \"%@\" \"$MOVIE_DST/%@\"; fi\n", dirname, dirpath, dirpath, dirname];
	}];
	
	[stream open];
	[stream write:(const uint8_t *)output.UTF8String maxLength:output.UTF8Length];
	[stream close];
}





#pragma mark - Find

/**
 *
 *
 */
- (IBAction)doActionFindShow:(id)sender
{
	[NSApp beginSheet:self.findWindow modalForWindow:self.window modalDelegate:nil didEndSelector:nil contextInfo:nil];
}

/**
 *
 *
 */
- (IBAction)doActionFindHide:(id)sender
{
	[NSApp endSheet:self.findWindow];
	[self.findWindow orderOut:sender];
}

/**
 *
 *
 */
- (IBAction)doActionFind:(id)sender
{
	NSString *findType = _findTypeBtn.titleOfSelectedItem;
	NSString *queryTxt = self.findTxt.stringValue.lowercaseString;
	
	// close the find window if the search query is zero-length
	if (!queryTxt.length) {
		[self doActionFindHide:sender];
		return;
	}
	
	//
	// movie search
	//
	if ([findType isEqualToString:@"Movies"]) {
		NSArray *arrangedObjects = self.moviesArrayController.arrangedObjects;
		__block MBMovie *mbmovie = nil;
		__block NSUInteger index = NSNotFound;
		
		[arrangedObjects enumerateObjectsUsingBlock:^ (id movie, NSUInteger movieNdx, BOOL *movieStop) {
			if ([((MBMovie *)movie).title.lowercaseString hasPrefix:queryTxt]) {
				mbmovie = movie;
				index = movieNdx;
				*movieStop = TRUE;
			}
		}];
		
		if (!mbmovie) {
			[arrangedObjects enumerateObjectsUsingBlock:^ (id movie, NSUInteger movieNdx, BOOL *movieStop) {
				if (NSNotFound != [((MBMovie *)movie).title.lowercaseString rangeOfString:queryTxt].location) {
					mbmovie = movie;
					index = movieNdx;
					*movieStop = TRUE;
				}
			}];
		}
		
		if (!mbmovie) {
			NSBeep();
			return;
		}
		
		[self doActionFindHide:sender];
		[_movieTable scrollRowToVisible:index];
	}
	
	//
	// actor search
	//
	else if ([findType isEqualToString:@"Actors"]) {
		NSArray *arrangedObjects = self.actorsArrayController.arrangedObjects;
		__block MBPerson *mbperson = nil;
		__block NSUInteger index = NSNotFound;
		
		[arrangedObjects enumerateObjectsUsingBlock:^ (id actor, NSUInteger actorNdx, BOOL *actorStop) {
			if ([((MBPerson *)actor).name.lowercaseString hasPrefix:queryTxt]) {
				mbperson = actor;
				index = actorNdx;
				*actorStop = TRUE;
			}
		}];
		
		if (!mbperson) {
			[arrangedObjects enumerateObjectsUsingBlock:^ (id actor, NSUInteger actorNdx, BOOL *actorStop) {
				if (NSNotFound != [((MBPerson *)actor).name.lowercaseString rangeOfString:queryTxt].location) {
					mbperson = actor;
					index = actorNdx;
					*actorStop = TRUE;
				}
			}];
		}
		
		if (!mbperson) {
			NSBeep();
			return;
		}
		
		[self doActionFindHide:sender];
		[_actorTable scrollRowToVisible:index];
	}
}





#pragma mark - Filters

/**
 *
 *
 */
- (void)updateActorFilter
{
	if (!mIsDoneLoading)
		return;
	
	NSPredicate *predicate = nil;
	BOOL (^genreMatches)(id) = nil;
	NSUInteger genreSelectionCount = mGenreSelections.count;
	BOOL showAll = mActorHeaderMenuShowAllItem.state == NSOnState;
	
	if (genreSelectionCount == 1) {
		MBGenre *mbgenre = mGenreSelections.allValues[0];
		BOOL x = ((NSOnState == mGenreHeaderMenuMultiOrItem.state) | (NSOnState == mGenreHeaderMenuMultiAndItem.state));
		genreMatches = ^ BOOL (id person) {
			return x == [mDataManager doesGenre:mbgenre haveActor:person];
		};
	}
	else if (genreSelectionCount > 1) {
		//
		// OR / NOT OR
		//
		if (NSOnState == mGenreHeaderMenuMultiOrItem.state || NSOnState == mGenreHeaderMenuMultiNotOrItem.state) {
			BOOL x = (NSOnState == mGenreHeaderMenuMultiOrItem.state);
			
			genreMatches = ^ BOOL (id person) {
				NSArray *genres = mGenreSelections.allValues;
				__block BOOL match = FALSE;
				
				[((MBPerson *)person).movies.allKeys enumerateObjectsUsingBlock:^ (id movieKey, NSUInteger movieNdx, BOOL *movieStop) {
					__block BOOL match2 = FALSE;
					MBMovie *mbmovie = [mDataManager movieWithKey:movieKey];
					
					[genres enumerateObjectsUsingBlock:^ (id mbgenre, NSUInteger genreNdx, BOOL *genreStop) {
						if (TRUE == [mDataManager doesMovie:mbmovie haveGenre:mbgenre]) {
							match2 = TRUE;
							*genreStop = TRUE;
						}
					}];
					
					if (match2) {
						match = TRUE;
						*movieStop = TRUE;
					}
				}];
				
				return match == x;
			};
		}
		
		//
		// AND / NOT AND
		//
		else if (NSOnState == mGenreHeaderMenuMultiAndItem.state || NSOnState == mGenreHeaderMenuMultiNotAndItem.state) {
			BOOL x = (NSOnState == mGenreHeaderMenuMultiAndItem.state);
			
			genreMatches = ^ BOOL (id person) {
				NSArray *genres = mGenreSelections.allValues;
				__block BOOL match = FALSE;
				
				[((MBPerson *)person).movies.allKeys enumerateObjectsUsingBlock:^ (id movieKey, NSUInteger movieNdx, BOOL *movieStop) {
					__block BOOL match2 = TRUE;
					MBMovie *mbmovie = [mDataManager movieWithKey:movieKey];
					
					[genres enumerateObjectsUsingBlock:^ (id mbgenre, NSUInteger genreNdx, BOOL *genreStop) {
						if (FALSE == [mDataManager doesMovie:mbmovie haveGenre:mbgenre]) {
							match2 = FALSE;
							*genreStop = TRUE;
						}
					}];
					
					if (match2) {
						match = TRUE;
						*movieStop = TRUE;
					}
				}];
				
				return match == x;
			};
		}
	}
	
	if (genreMatches && mMovieSelection) {
		predicate = [NSPredicate predicateWithBlock:^ BOOL (id object, NSDictionary *bindings) {
			return [mDataManager doesMovie:mMovieSelection haveActor:(MBPerson *)object] && genreMatches(object);
		}];
	}
	else if (genreMatches) {
		predicate = [NSPredicate predicateWithBlock:^ BOOL (id mbperson, NSDictionary *bindings) {
			return (showAll || 5 <= ((MBPerson *)mbperson).movies.count) && genreMatches(mbperson);
		}];
	}
	else if (mMovieSelection) {
		predicate = [NSPredicate predicateWithBlock:^ BOOL (id object, NSDictionary *bindings) {
			return [mDataManager doesMovie:mMovieSelection haveActor:(MBPerson *)object];
		}];
	}
	else if (!showAll) {
		predicate = [NSPredicate predicateWithBlock:^ BOOL (id object, NSDictionary *bindings) {
			return 5 <= ((MBPerson *)object).movies.count;
		}];
	}
	
	self.actorsArrayController.filterPredicate = predicate;
	
	if (mActorSelection) {
		if (NSNotFound == self.actorsArrayController.selectionIndex)
			[self doNotificationActorSelectionChanged:nil];
		else
			[self.actorTable scrollRowToVisible:self.actorTable.selectedRow];
	}
	else {
		((NSScrollView *)self.actorTable.superview.superview).verticalScroller.floatValue = 0;
		[((NSScrollView *)self.actorTable.superview.superview).contentView scrollToPoint:NSMakePoint(0,0)];
	}
	
	[self updateWindowTitle];
}

/**
 *
 *
 */
- (void)updateGenreFilter
{
	if (!mIsDoneLoading)
		return;
	
	NSPredicate *predicate = nil;
	
	if (mActorSelection && mMovieSelection) {
		predicate = [NSPredicate predicateWithBlock:^ BOOL (id object, NSDictionary *bindings) {
			return [mDataManager doesGenre:(MBGenre *)object haveActor:mActorSelection] &&
						 [mDataManager doesMovie:mMovieSelection haveGenre:(MBGenre *)object];
		}];
	}
	else if (mActorSelection) {
		predicate = [NSPredicate predicateWithBlock:^ BOOL (id object, NSDictionary *bindings) {
			return [mDataManager doesGenre:(MBGenre *)object haveActor:mActorSelection];
		}];
	}
	else if (mMovieSelection) {
		predicate = [NSPredicate predicateWithBlock:^ BOOL (id object, NSDictionary *bindings) {
			return [mDataManager doesMovie:mMovieSelection haveGenre:(MBGenre *)object];
		}];
	}
	
	self.genresArrayController.filterPredicate = predicate;
	
	if (mGenreSelections.count)
		[self.genreTable scrollRowToVisible:self.genreTable.selectedRow];
	
	[self updateWindowTitle];
}

/**
 *
 *
 */
- (void)updateMovieFilter
{
	if (!mIsDoneLoading)
		return;
	
	NSPredicate *predicate = nil;
	BOOL (^genreMatches)(id) = nil;
	NSUInteger genreSelectionCount = mGenreSelections.count;
	
	if (genreSelectionCount == 1) {
		MBGenre *mbgenre = mGenreSelections.allValues[0];
		BOOL x = ((NSOnState == mGenreHeaderMenuMultiOrItem.state) | (NSOnState == mGenreHeaderMenuMultiAndItem.state));
		genreMatches = ^ BOOL (id movie) {
			return x == [mDataManager doesMovie:movie haveGenre:mbgenre];
		};
	}
	else if (genreSelectionCount > 1) {
		//
		// OR / NOT OR
		//
		if (NSOnState == mGenreHeaderMenuMultiOrItem.state || NSOnState == mGenreHeaderMenuMultiNotOrItem.state) {
			BOOL x = (NSOnState == mGenreHeaderMenuMultiOrItem.state);
			
			genreMatches = ^ BOOL (id movie) {
				__block BOOL match = FALSE;
				[mGenreSelections.allValues enumerateObjectsUsingBlock:^ (id mbgenre, NSUInteger ndx, BOOL *stop) {
					if (TRUE == [mDataManager doesMovie:movie haveGenre:mbgenre]) {
						match = TRUE;
						*stop = TRUE;
					}
				}];
				return match == x;
			};
		}
		//
		// AND / NOT AND
		//
		else if (NSOnState == mGenreHeaderMenuMultiAndItem.state || NSOnState == mGenreHeaderMenuMultiNotAndItem.state) {
			BOOL x = (NSOnState == mGenreHeaderMenuMultiAndItem.state);
			
			genreMatches = ^ BOOL (id movie) {
				__block BOOL match = TRUE;
				[mGenreSelections.allValues enumerateObjectsUsingBlock:^ (id mbgenre, NSUInteger ndx, BOOL *stop) {
					if (FALSE == [mDataManager doesMovie:movie haveGenre:mbgenre]) {
						match = FALSE;
						*stop = TRUE;
					}
				}];
				return match == x;
			};
		}
	}
	
	if (mActorSelection && genreMatches) {
		predicate = [NSPredicate predicateWithBlock:^ BOOL (id object, NSDictionary *bindings) {
			return [mDataManager doesMovie:(MBMovie *)object haveActor:mActorSelection] &&
			       (mShowHiddenMovies || !((MBMovie *)object).hidden.boolValue) && genreMatches(object);
		}];
	}
	else if (genreMatches) {
		predicate = [NSPredicate predicateWithBlock:^ BOOL (id object, NSDictionary *bindings) {
			return (mShowHiddenMovies || !((MBMovie *)object).hidden.boolValue) && genreMatches(object);
		}];
	}
	else if (mActorSelection) {
		predicate = [NSPredicate predicateWithBlock:^ BOOL (id object, NSDictionary *bindings) {
			return [mDataManager doesMovie:(MBMovie *)object haveActor:mActorSelection] &&
			       (mShowHiddenMovies || !((MBMovie *)object).hidden.boolValue);
		}];
	}
	else {
		predicate = [NSPredicate predicateWithBlock:^ BOOL (id object, NSDictionary *bindings) {
			return (mShowHiddenMovies || !((MBMovie *)object).hidden.boolValue);
		}];
	}
	
	self.moviesArrayController.filterPredicate = predicate;
	
	// movie set duration
	{
		NSArray *arrangedObjects = self.moviesArrayController.arrangedObjects;
		NSMutableString *infoTxt = [[NSMutableString alloc] init];
		__block NSUInteger duration = 0;
		__block NSUInteger filesize = 0;
		
		[arrangedObjects enumerateObjectsUsingBlock:^ (id movie, NSUInteger movieNdx, BOOL *movieStop) {
			duration += ((MBMovie *)movie).duration.integerValue;
			filesize += ((MBMovie *)movie).filesize.integerValue;
		}];
		
		[infoTxt appendString:@(arrangedObjects.count).stringValue];
		[infoTxt appendString:@" movies, "];
		[infoTxt appendString:[MBStuff humanReadableDuration:duration]];
		[infoTxt appendString:@", "];
		[infoTxt appendString:[MBStuff humanReadableFileSize:filesize]];
		
		self.movieInfoTxt.stringValue = infoTxt;
	}
	
	if (mMovieSelection)
		[self.movieTable scrollRowToVisible:self.movieTable.selectedRow];
	else {
		((NSScrollView *)self.movieTable.superview.superview).verticalScroller.floatValue = 0;
		[((NSScrollView *)self.movieTable.superview.superview).contentView scrollToPoint:NSMakePoint(0,0)];
	}
		
	[self updateWindowTitle];
}

@end
