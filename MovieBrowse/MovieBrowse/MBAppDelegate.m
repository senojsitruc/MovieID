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
#import "MBTableHeaderView.h"
#import "MBPopUpButtonCell.h"
#import "MBTableHeaderCell.h"
#import "MBDownloadQueue.h"
#import "MBImportWindowController.h"
#import "MBActorProfileWindowController.h"
#import "MBMovieEditWindowController.h"
#import "MBPreferencesWindowController.h"
#import "MBRenameWindowController.h"
#import "MBScreencapsWindowController.h"
#import "NSArray+Additions.h"
#import "NSString+Additions.h"
#import "NSThread+Additions.h"
#import <MovieID/IDMediaInfo.h>
#import <MovieID/IDSearch.h>

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
NSString * const MBDefaultsKeyFindQuery = @"MBDefaultsKeyFindQuery";
NSString * const MBDefaultsKeyFindType = @"MBDefaultsKeyFindType";
NSString * const MBDefaultsKeyFindTitleEnabled = @"MBDefaultsKeyFindTitleEnabled";
NSString * const MBDefaultsKeyFindFileNameEnabled = @"MBDefaultsKeyFindFileNameEnabled";
NSString * const MBDefaultsKeyFindDescriptionEnabled = @"MBDefaultsKeyFindDescriptionEnabled";

static MBAppDelegate *gAppDelegate;

@interface MBAppDelegate ()
{
	MBDataManager *mDataManager;
	MBActorProfileWindowController *mActorProfileController;
	MBImportWindowController *mImportController;
	MBMovieEditWindowController *mMovieEditController;
	MBPreferencesWindowController *mPreferencesController;
	MBRenameWindowController *mRenameController;
	MBScreencapsWindowController *mScreencapsController;
	BOOL mIsDoneLoading;
	
	/**
	 * Handle async issues. When the actor window is opened a background thread starts loading the
	 * images. By the time the thread finishes, it's possible that we've moved on to another actor.
	 * Only show the loaded images when the time comes if we're still awiting on that same actor.
	 */
	NSUInteger mActorWindowTransId;
	
	/**
	 * Keyed on language name with NSNumber values denoting the number of movies shown that include
	 * the language.
	 */
	NSMutableDictionary *mLanguagesByName;
	NSMutableArray *mLanguagesSorted;
	BOOL mLanguagesDirty;
	
	/**
	 * Keyed on rating name with NSNumber values denoting the number of movies show that include the
	 * rating.
	 */
	NSMutableDictionary *mRatingsByName;
	NSMutableArray *mRatingsSorted;
	BOOL mRatingsDirty;
	
	/**
	 * Selections
	 */
	MBPerson *mActorSelection;
	NSMutableArray *mGenreSelections;
	MBMovie *mMovieSelection;
	NSString *mLanguageSelection;
	NSString *mRatingSelection;
	
	/**
	 * Caches
	 */
	BOOL mIsUpdatingData;
	NSMutableDictionary *mGenresByName;
	NSMutableArray *mGenresSorted;
	NSMutableDictionary *mActorsByName;
	NSMutableArray *mActorsSorted;
	
	/**
	 * Find
	 */
	NSString *mFindType;
	NSString *mFindQuery;
	NSUInteger mFindIndex;
	
	/**
	 * Movie Table
	 */
	MBPopUpButtonCell *mMovieHeaderCell;
	NSMenu *mMovieHeaderMenu;
	NSMenuItem *mMovieHeaderMenuSortByTitleItem;
	NSMenuItem *mMovieHeaderMenuSortByYearItem;
	NSMenuItem *mMovieHeaderMenuSortByScoreItem;
	NSMenuItem *mMovieHeaderMenuSortByAddedItem;
	NSMenuItem *mMovieHeaderMenuSortByRuntimeItem;
	NSMenuItem *mMovieHeaderMenuShowHidden;
	NSMenuItem *mMovieHeaderMenuLanguageSeparatorItem;
	NSMenuItem *mMovieHeaderMenuLanguageHeadingItem;
	NSMutableArray *mMovieHeaderMenuLanguageItems;
	NSMenuItem *mMovieHeaderMenuRatingSeparatorItem;
	NSMenuItem *mMovieHeaderMenuRatingHeadingItem;
	NSMutableArray *mMovieHeaderMenuRatingItems;
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
@synthesize renameController = mRenameController;

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
	mActorProfileController = [[MBActorProfileWindowController alloc] init];
	mImportController = [[MBImportWindowController alloc] init];
	mMovieEditController = [[MBMovieEditWindowController alloc] init];
	mPreferencesController = [[MBPreferencesWindowController alloc] init];
	mRenameController = [[MBRenameWindowController alloc] init];
	mScreencapsController = [[MBScreencapsWindowController alloc] init];
	
	mGenreSelections = [[NSMutableArray alloc] init];
	mLanguagesByName = [[NSMutableDictionary alloc] init];
	mLanguagesSorted = [[NSMutableArray alloc] init];
	mRatingsByName = [[NSMutableDictionary alloc] init];
	mRatingsSorted = [[NSMutableArray alloc] init];
	mGenresByName = [[NSMutableDictionary alloc] init];
	mGenresSorted = [[NSMutableArray alloc] init];
	mActorsByName = [[NSMutableDictionary alloc] init];
	mActorsSorted = [[NSMutableArray alloc] init];
	
	self.actorsArray = [[NSMutableArray alloc] init];
	self.genresArray = [[NSMutableArray alloc] init];
	self.moviesArray = [[NSMutableArray alloc] init];
	
	// user defaults
	{
		NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
		
		[defaults registerDefaults:@{
								MBDefaultsKeyImageHost: @"http://home.stygian.net:20080",
							 MBDefaultsKeyImageCache: @"~/Library/Application Support/MovieBrowse/Cache",
									MBDefaultsKeySources: @[],
									MBDefaultsKeyApiTmdb: @"",
									MBDefaultsKeyApiImdb: @"2wex6aeu6a8q9e49k7sfvufd6rhh0n",
										MBDefaultsKeyApiRt: @"",
							 MBDefaultsKeyMoviesSort: @"Title",
				 MBDefaultsKeyMoviesShowHidden: @(0),
							 MBDefaultsKeyGenreMulti: @"Or",
								MBDefaultsKeyActorShow: @"Popular",
								MBDefaultsKeyActorSort: @"Name",
					 MBDefaultsKeyActorSelection: @[],
					 MBDefaultsKeyGenreSelection: @[],
					 MBDefaultsKeyMovieSelection: @[],
								MBDefaultsKeyFindQuery: @"",
								 MBDefaultsKeyFindType: @"Movies",
         MBDefaultsKeyFindTitleEnabled: @(TRUE),
      MBDefaultsKeyFindFileNameEnabled: @(FALSE),
   MBDefaultsKeyFindDescriptionEnabled: @(FALSE)
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
		headerCell.willDisplayHandler = ^{
			[self updateMoviesHeaderLanguages:TRUE];
			[self updateMoviesHeaderRating:TRUE];
		};
		
		[menu addItemWithTitle:@"Sort" action:nil keyEquivalent:@""];
		NSMenuItem *sortByTitle = [menu addItemWithTitle:@"  Movie by Title" action:@selector(doActionMoviesSortByTitle:) keyEquivalent:@""];
		NSMenuItem *sortByYear = [menu addItemWithTitle:@"  Movie by Year" action:@selector(doActionMoviesSortByYear:) keyEquivalent:@""];
		NSMenuItem *sortByScore = [menu addItemWithTitle:@"  Movie by Score" action:@selector(doActionMoviesSortByScore:) keyEquivalent:@""];
		NSMenuItem *sortByRuntime = [menu addItemWithTitle:@"  Movie by Runtime" action:@selector(doActionMoviesSortByRuntime:) keyEquivalent:@""];
		NSMenuItem *sortByAdded = [menu addItemWithTitle:@"  Movie by Added" action:@selector(doActionMoviesSortByAdded:) keyEquivalent:@""];
		[menu addItem:[NSMenuItem separatorItem]];
		[menu addItemWithTitle:@"Options" action:nil keyEquivalent:@""];
		NSMenuItem *showHidden = [menu addItemWithTitle:@"  Show Hidden" action:@selector(doActionMoviesShowHidden:) keyEquivalent:@""];
		
		sortByTitle.target = self;
		sortByYear.target = self;
		sortByScore.target = self;
		sortByRuntime.target = self;
		sortByAdded.target = self;
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
		mMovieHeaderMenuSortByAddedItem = sortByAdded;
		mMovieHeaderMenuShowHidden = showHidden;
		mMovieHeaderMenuLanguageSeparatorItem = [NSMenuItem separatorItem];
		mMovieHeaderMenuLanguageHeadingItem = [[NSMenuItem alloc] initWithTitle:@"Languages" action:nil keyEquivalent:@""];
		mMovieHeaderMenuLanguageItems = [[NSMutableArray alloc] init];
		mMovieHeaderMenuRatingSeparatorItem = [NSMenuItem separatorItem];
		mMovieHeaderMenuRatingHeadingItem = [[NSMenuItem alloc] initWithTitle:@"Ratings" action:nil keyEquivalent:@""];
		mMovieHeaderMenuRatingItems = [[NSMutableArray alloc] init];
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
			else if ([sort isEqualToString:@"Added"])
				[self doActionMoviesSortByAdded:mMovieHeaderMenuSortByAddedItem];
		}
	}
	
	//
	// load data
	//
	{
		NSMutableArray *actorsArray = [[NSMutableArray alloc] init];
		NSMutableArray *genresArray = [[NSMutableArray alloc] init];
		NSMutableArray *moviesArray = [[NSMutableArray alloc] init];
		
		[mDataManager enumerateGenres:^ (MBGenre *mbgenre, BOOL *stop) { [genresArray addObject:mbgenre]; }];
		[mDataManager enumerateActors:^ (MBPerson *mbactor, NSUInteger count, BOOL *stop) { [actorsArray addObject:mbactor]; }];
		[mDataManager enumerateMovies:^ (MBMovie *mbmovie, BOOL *stop) { [moviesArray addObject:mbmovie]; }];
		
		[self.actorsArrayController addObjects:actorsArray];
		[self.genresArrayController addObjects:genresArray];
		[self.moviesArrayController addObjects:moviesArray];
		
		mIsDoneLoading = TRUE;
		mLanguagesDirty = TRUE;
		mRatingsDirty = TRUE;
		
		[self updateMovieFilter];
		[self updateMovieFilter_actorCache];
		[self updateActorFilter];
		[self updateMovieFilter_genreCache];
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
					[mGenreSelections addObject:mbgenre];
			}];
			
			if (mGenreSelections.count == 1)
				mGenreHeaderCell.label = [NSString stringWithFormat:@"Genre (%@)", ((MBGenre *)mGenreSelections[0]).name];
			else
				mGenreHeaderCell.label = [NSString stringWithFormat:@"Genre (%lu selected)", mGenreSelections.count];
			
			[self.genresArrayController setSelectedObjects:mGenreSelections];
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
		
		//[mDataManager moveGenresToMovies];
		//[mDataManager getMissingImages];
		//[mDataManager upgradeTmdbToImdb];
		//[mDataManager ratingsUpdate];
		//[mDataManager findDuplicateMovies];
		//[mDataManager updateFileStats];
		
		/*
		[[mDataManager findMissingFiles] enumerateObjectsUsingBlock:^ (id movie, NSUInteger movieNdx, BOOL *movieStop) {
			MBMovie *mbmovie = (MBMovie *)movie;
			
			if ([mbmovie.dirpath rangeOfString:@"Varg "].location == NSNotFound) {
				NSLog(@"%@", mbmovie.dirpath);
			[mDataManager deleteMovie:mbmovie];
			}
		}];
		*/
		
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
			[title appendString:((MBGenre *)mGenreSelections[0]).name];
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





#pragma mark - Accessors

/**
 * Used to populate the "count" badge for each genre in the genre table.
 *
 */
- (NSUInteger)movieCountForGenre:(MBGenre *)mbgenre
{
	return ((NSNumber *)mGenresByName[mbgenre.name]).integerValue;
}

/**
 *
 *
 */
- (void)showActor:(MBPerson *)mbperson
{
	if (mbperson)
		[mActorProfileController showInWindow:self.window forPerson:mbperson];
}

/**
 *
 *
 */
- (void)showScreencapsForMovie:(MBMovie *)mbmovie
{
	[mScreencapsController showInWindow:self.window forMovie:mbmovie];
}

/**
 *
 *
 */
- (void)editMovie:(MBMovie *)mbmovie
{
	[mMovieEditController showInWindow:self.window forMovie:mbmovie];
}

/**
 *
 *
 */
- (void)movie:(MBMovie *)mbmovie hideWithView:(NSView *)view
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
- (void)movie:(MBMovie *)mbmovie UnhideWithView:(NSView *)view
{
	mbmovie.hidden = @(FALSE);
	[mDataManager saveMovie:mbmovie];
	[self.movieTable reloadData];
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
	
	mLanguagesDirty = TRUE;
	mRatingsDirty = TRUE;
	
	[self updateActorsHeaderLabel];
	
	[self updateMovieFilter];
	[self updateMovieFilter_genreCache];
	
	if (!mActorSelection) {
		[self updateMovieFilter_actorCache];
		[self updateActorFilter];
	}
	
	if (mLanguageSelection)
		[self updateMoviesHeaderLanguages:TRUE];
	
	if (!mIsUpdatingData) {
		mIsUpdatingData = TRUE;
		[_genresArrayController rearrangeObjects];
		mIsUpdatingData = FALSE;
	}
	
	// our find state is now invalid for doing "find next"
	mFindIndex = NSNotFound;
}

/**
 *
 *
 */
- (void)doNotificationGenreSelectionChanged:(NSNotification *)notification
{
	if (mIsUpdatingData)
		return;
	
	NSArray *selectedObjects = self.genresArrayController.selectedObjects;
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	
	[mGenreSelections removeAllObjects];
	
	if (selectedObjects.count == 0) {
		mGenreHeaderCell.label = @"Genre";
		[defaults setObject:@[] forKey:MBDefaultsKeyGenreSelection];
	}
	else {
		[selectedObjects enumerateObjectsUsingBlock:^ (id obj, NSUInteger ndx, BOOL *stop) {
			[mGenreSelections addObject:obj];
		}];
		if (selectedObjects.count == 1)
			mGenreHeaderCell.label = [NSString stringWithFormat:@"Genre (%@)", ((MBGenre *)mGenreSelections[0]).name];
		else
			mGenreHeaderCell.label = [NSString stringWithFormat:@"Genre (%lu selected)", selectedObjects.count];
		NSMutableArray *genres = [[NSMutableArray alloc] init];
		[mGenreSelections enumerateObjectsUsingBlock:^ (id genreObj, NSUInteger genreNdx, BOOL *genreStop) {
			[genres addObject:((MBGenre *)genreObj).name];
		}];
		[defaults setObject:genres forKey:MBDefaultsKeyGenreSelection];
	}
	
	[self.genreTable.headerView setNeedsDisplay:TRUE];
	
	mLanguagesDirty = TRUE;
	mRatingsDirty = TRUE;
	
	[self updateMovieFilter];
	
	if (!mActorSelection) {
		[self updateMovieFilter_actorCache];
		[self updateActorFilter];
	}
	
	if (mLanguageSelection)
		[self updateMoviesHeaderLanguages:TRUE];
	
	// our find state is now invalid for doing "find next"
	mFindIndex = NSNotFound;
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
	
	mLanguagesDirty = TRUE;
	mRatingsDirty = TRUE;
	
	[self updateMoviesHeaderLabel];
	[self updateMovieFilter_actorCache];
	[self updateActorFilter];
	
	// our find state is now invalid for doing "find next"
	mFindIndex = NSNotFound;
}





#pragma mark - Actors

/**
 *
 *
 */
- (void)doActionActorDoubleClick:(NSTableView *)tableView
{
	if (tableView.selectedRow >= 0)
		[self showActor:[[self.actorsArrayController arrangedObjects] objectAtIndex:tableView.selectedRow]];
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
	else if (mMovieHeaderMenuSortByAddedItem.state == NSOnState)
		prefix = @"Movie by Added";
	
	if (mMovieSelection && mLanguageSelection && mRatingSelection)
		mMovieHeaderCell.label = [NSString stringWithFormat:@"%@ (%@, %@) - %@", prefix, mLanguageSelection, mRatingSelection, mMovieSelection.title];
	
	else if (mMovieSelection && mLanguageSelection)
		mMovieHeaderCell.label = [NSString stringWithFormat:@"%@ (%@) - %@", prefix, mLanguageSelection, mMovieSelection.title];
	else if (mMovieSelection && mRatingSelection)
		mMovieHeaderCell.label = [NSString stringWithFormat:@"%@ (%@) - %@", prefix, mRatingSelection, mMovieSelection.title];
	else if (mLanguageSelection && mRatingSelection)
		mMovieHeaderCell.label = [NSString stringWithFormat:@"%@ (%@, %@)", prefix, mLanguageSelection, mRatingSelection];
	
	else if (mMovieSelection)
		mMovieHeaderCell.label = [NSString stringWithFormat:@"%@ - %@", prefix, mMovieSelection.title];
	else if (mLanguageSelection)
		mMovieHeaderCell.label = [NSString stringWithFormat:@"%@ (%@)", prefix, mLanguageSelection];
	else if (mRatingSelection)
		mMovieHeaderCell.label = [NSString stringWithFormat:@"%@ (%@)", prefix, mRatingSelection];
	else
		mMovieHeaderCell.label = prefix;
	
	[self.movieTable.headerView setNeedsDisplay:TRUE];
}

/**
 *
 *
 */
- (void)updateMoviesHeaderLanguages:(BOOL)visibleOnly
{
	if (!mLanguagesDirty)
		return;
	
	// we ain't dirty no more; or we won't be, shortly
	mLanguagesDirty = FALSE;
	
	// remove any language-related menu items
	if (mLanguagesSorted.count) {
		[mMovieHeaderMenu removeItem:mMovieHeaderMenuLanguageSeparatorItem];
		[mMovieHeaderMenu removeItem:mMovieHeaderMenuLanguageHeadingItem];
		
		[mMovieHeaderMenuLanguageItems enumerateObjectsUsingBlock:^ (id menuObj, NSUInteger menuNdx, BOOL *menuStop) {
			[mMovieHeaderMenu removeItem:menuObj];
		}];
		
		[mLanguagesByName removeAllObjects];
		[mLanguagesSorted removeAllObjects];
		[mMovieHeaderMenuLanguageItems removeAllObjects];
	}
	
	// tally the count for each language
	{
		NSArray *objects = visibleOnly ? _moviesArrayController.arrangedObjects : _moviesArray;
		
		[objects enumerateObjectsUsingBlock:^ (id movieObj, NSUInteger movieNdx, BOOL *movieStop) {
			NSArray *languages = ((MBMovie *)movieObj).languages;
			
			if (languages.count) {
				[languages enumerateObjectsUsingBlock:^ (id languageObj, NSUInteger languageNdx, BOOL *languageStop) {
					mLanguagesByName[languageObj] = @(1 + ((NSNumber *)mLanguagesByName[languageObj]).integerValue);
				}];
			}
			else
				mLanguagesByName[@"Unknown"] = @(1 + ((NSNumber *)mLanguagesByName[@"Unknown"]).integerValue);
		}];
		
		[mLanguagesSorted setArray:[mLanguagesByName.allKeys sortedArrayUsingComparator:^ NSComparisonResult (id language1, id language2) {
			return [mLanguagesByName[language2] compare:mLanguagesByName[language1]];
		}]];
	}
	
	// insert the language-related menu items (if any)
	if (mLanguagesSorted.count) {
		[mMovieHeaderMenu addItem:mMovieHeaderMenuLanguageSeparatorItem];
		[mMovieHeaderMenu addItem:mMovieHeaderMenuLanguageHeadingItem];
		
		[mLanguagesSorted enumerateObjectsUsingBlock:^ (id languageObj, NSUInteger languageNdx, BOOL *languageStop) {
			NSString *title = [NSString stringWithFormat:@"  %@ (%@)", languageObj, mLanguagesByName[languageObj]];
			NSMenuItem *item = [mMovieHeaderMenu addItemWithTitle:title action:@selector(doActionMoviesFilterByLanguage:) keyEquivalent:@""];
			item.target = self;
			item.tag = languageNdx;
			[mMovieHeaderMenuLanguageItems addObject:item];
		}];
	}
	
	// maintain the language selection if possible
	if (mLanguageSelection) {
		NSInteger index = [mLanguagesSorted indexOfObject:mLanguageSelection];
		
		if (NSNotFound == index) {
			mLanguageSelection = nil;
			[self updateMoviesHeaderLabel];
		}
		else
			((NSMenuItem *)mMovieHeaderMenuLanguageItems[index]).state = NSOnState;
	}
}

/**
 *
 *
 */
- (void)updateMoviesHeaderRating:(BOOL)visibleOnly
{
	if (!mRatingsDirty)
		return;
	
	// we ain't dirty no more; or we won't be, shortly
	mRatingsDirty = FALSE;
	
	// remove any rating-related menu items
	if (mRatingsSorted.count) {
		[mMovieHeaderMenu removeItem:mMovieHeaderMenuRatingSeparatorItem];
		[mMovieHeaderMenu removeItem:mMovieHeaderMenuRatingHeadingItem];
		
		[mMovieHeaderMenuRatingItems enumerateObjectsUsingBlock:^ (id menuObj, NSUInteger menuNdx, BOOL *menuStop) {
			[mMovieHeaderMenu removeItem:menuObj];
		}];
		
		[mRatingsByName removeAllObjects];
		[mRatingsSorted removeAllObjects];
		[mMovieHeaderMenuRatingItems removeAllObjects];
	}
	
	// tally the count for each rating
	{
		NSArray *objects = visibleOnly ? _moviesArrayController.arrangedObjects : _moviesArray;
		
		[objects enumerateObjectsUsingBlock:^ (id movieObj, NSUInteger movieNdx, BOOL *movieStop) {
			NSString *rating = ((MBMovie *)movieObj).rating;
			
			if (rating.length)
				mRatingsByName[rating] = @(1 + ((NSNumber *)mRatingsByName[rating]).integerValue);
			else
				mRatingsByName[@"Unknown"] = @(1 + ((NSNumber *)mRatingsByName[@"Unknown"]).integerValue);
		}];
		
		[mRatingsSorted setArray:[mRatingsByName.allKeys sortedArrayUsingComparator:^ NSComparisonResult (id rating1, id rating2) {
			return [rating1 compare:rating2];
		}]];
		
#if !defined DEBUG
		[mRatingsByName removeObjectForKey:@"NC-17"];
#endif
	}
	
	// insert the rating-related menu items (if any)
	if (mRatingsSorted.count) {
		[mMovieHeaderMenu addItem:mMovieHeaderMenuRatingSeparatorItem];
		[mMovieHeaderMenu addItem:mMovieHeaderMenuRatingHeadingItem];
		
		[mRatingsSorted enumerateObjectsUsingBlock:^ (id ratingObj, NSUInteger ratingNdx, BOOL *ratingStop) {
			NSString *title = [NSString stringWithFormat:@"  %@ (%@)", ratingObj, mRatingsByName[ratingObj]];
			NSMenuItem *item = [mMovieHeaderMenu addItemWithTitle:title action:@selector(doActionMoviesFilterByRating:) keyEquivalent:@""];
			item.target = self;
			item.tag = ratingNdx;
			[mMovieHeaderMenuRatingItems addObject:item];
		}];
	}
	
	// maintain the rating selection if possible
	if (mRatingSelection) {
		NSInteger index = [mRatingsSorted indexOfObject:mRatingSelection];
		
		if (NSNotFound == index) {
			mRatingSelection = nil;
			[self updateMoviesHeaderLabel];
		}
		else
			((NSMenuItem *)mMovieHeaderMenuRatingItems[index]).state = NSOnState;
	}
}

/**
 * Various things to do after we change the sort order for the movies table.
 *
 */
- (void)updateMoviesPostSort
{
	if (mMovieSelection)
		[self.movieTable scrollRowToVisible:self.movieTable.selectedRow];
	else {
		((NSScrollView *)self.movieTable.superview.superview).verticalScroller.floatValue = 0;
		[((NSScrollView *)self.movieTable.superview.superview).contentView scrollToPoint:NSMakePoint(0,0)];
	}
	
	// our find state is now invalid for doing "find next"
	if ([mFindType isEqualToString:@"Movies"])
		mFindIndex = NSNotFound;
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
	mMovieHeaderMenuSortByAddedItem.state = NSOffState;
	
	[[NSUserDefaults standardUserDefaults] setObject:@"Title" forKey:MBDefaultsKeyMoviesSort];
	
	[self updateMoviesHeaderLabel];
	[self.moviesArrayController setSortDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"sortTitle" ascending:TRUE]]];
	[self updateMoviesPostSort];
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
	mMovieHeaderMenuSortByAddedItem.state = NSOffState;
	
	[[NSUserDefaults standardUserDefaults] setObject:@"Year" forKey:MBDefaultsKeyMoviesSort];
	
	[self updateMoviesHeaderLabel];
	[self.moviesArrayController setSortDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"year" ascending:FALSE], [NSSortDescriptor sortDescriptorWithKey:@"sortTitle" ascending:TRUE]]];
	[self updateMoviesPostSort];
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
	mMovieHeaderMenuSortByAddedItem.state = NSOffState;
	
	[[NSUserDefaults standardUserDefaults] setObject:@"Score" forKey:MBDefaultsKeyMoviesSort];
	
	[self updateMoviesHeaderLabel];
	[self.moviesArrayController setSortDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"score" ascending:FALSE], [NSSortDescriptor sortDescriptorWithKey:@"sortTitle" ascending:TRUE]]];
	[self updateMoviesPostSort];
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
	mMovieHeaderMenuSortByAddedItem.state = NSOffState;
	
	[[NSUserDefaults standardUserDefaults] setObject:@"Runtime" forKey:MBDefaultsKeyMoviesSort];
	
	[self updateMoviesHeaderLabel];
	[self.moviesArrayController setSortDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"duration" ascending:FALSE], [NSSortDescriptor sortDescriptorWithKey:@"sortTitle" ascending:TRUE]]];
	[self updateMoviesPostSort];
}

/**
 *
 *
 */
- (void)doActionMoviesSortByAdded:(id)sender
{
	mMovieHeaderMenuSortByTitleItem.state = NSOffState;
	mMovieHeaderMenuSortByYearItem.state = NSOffState;
	mMovieHeaderMenuSortByScoreItem.state = NSOffState;
	mMovieHeaderMenuSortByRuntimeItem.state = NSOffState;
	mMovieHeaderMenuSortByAddedItem.state = NSOnState;
	
	[[NSUserDefaults standardUserDefaults] setObject:@"Added" forKey:MBDefaultsKeyMoviesSort];
	
	[self updateMoviesHeaderLabel];
	[self.moviesArrayController setSortDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"mtime" ascending:FALSE], [NSSortDescriptor sortDescriptorWithKey:@"sortTitle" ascending:FALSE]]];
	[self updateMoviesPostSort];
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

/**
 *
 *
 */
- (void)doActionMoviesFilterByLanguage:(id)sender
{
	NSMenuItem *item = sender;
	
	if (item.state) {
		item.state = NSOffState;
		mLanguageSelection = nil;
	}
	else {
		[mMovieHeaderMenuLanguageItems enumerateObjectsUsingBlock:^ (id itemObj, NSUInteger itemNdx, BOOL *itemStop) {
			((NSMenuItem *)itemObj).state = NSOffState;
		}];
		
		item.state = NSOnState;
		mLanguageSelection = mLanguagesSorted[item.tag];
	}
	
	[self updateMovieFilter];
	[self updateActorFilter];
	[self updateMoviesHeaderLabel];
}

/**
 *
 *
 */
- (void)doActionMoviesFilterByRating:(id)sender
{
	NSMenuItem *item = sender;
	
	if (item.state) {
		item.state = NSOffState;
		mRatingSelection = nil;
	}
	else {
		[mMovieHeaderMenuRatingItems enumerateObjectsUsingBlock:^ (id itemObj, NSUInteger itemNdx, BOOL *itemStop) {
			((NSMenuItem *)itemObj).state = NSOffState;
		}];
		
		item.state = NSOnState;
		mRatingSelection = mRatingsSorted[item.tag];
	}
	
	[self updateMovieFilter];
	[self updateActorFilter];
	[self updateMoviesHeaderLabel];
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
	else if (mActorHeaderMenuShowPopularItem.state)
		mActorHeaderCell.label = [NSString stringWithFormat:@"%@ (%@)", prefix, @"Popular"];
	else
		mActorHeaderCell.label = prefix;
	
	[self.actorTable.headerView setNeedsDisplay:TRUE];
}

/**
 *
 *
 */
- (void)updateActorPostSort
{
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
- (void)doActionActorsShowAll:(id)sender
{
	mActorHeaderMenuShowAllItem.state = NSOnState;
	mActorHeaderMenuShowPopularItem.state = NSOffState;
	
	[[NSUserDefaults standardUserDefaults] setObject:@"All" forKey:MBDefaultsKeyActorShow];
	
	[self updateActorFilter];
	[self updateActorsHeaderLabel];
}

/**
 *
 *
 */
- (void)doActionActorsShowPopular:(id)sender
{
	mActorHeaderMenuShowAllItem.state = NSOffState;
	mActorHeaderMenuShowPopularItem.state = NSOnState;
	
	[[NSUserDefaults standardUserDefaults] setObject:@"Popular" forKey:MBDefaultsKeyActorShow];
	
	[self updateActorFilter];
	[self updateActorsHeaderLabel];
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
	[self updateActorPostSort];
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
	[self updateActorPostSort];
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
	[self updateActorPostSort];
}





#pragma mark - Preferences

/**
 *
 *
 */
- (IBAction)doActionPreferencesShow:(id)sender
{
	[mPreferencesController showInWindow:self.window];
}





#pragma mark - Import / Export

/**
 *
 *
 */
- (IBAction)doActionImport:(id)sender
{
	[mImportController showInWindow:self.window];
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
- (IBAction)doActionFindType:(id)sender
{
	NSString *findType = [_findTypeBtn titleOfSelectedItem];
	
	if ([findType isEqualToString:@"Movies"]) {
		[_findTitleBtn setHidden:FALSE];
		[_findDescBtn setHidden:FALSE];
		[_findFileNameBtn setHidden:FALSE];
		[_findTitleBtn setTitle:@"Title"];
		[_findDescBtn setTitle:@"Description"];
	}
	else if ([findType isEqualToString:@"Actors"]) {
		[_findTitleBtn setHidden:FALSE];
		[_findDescBtn setHidden:FALSE];
		[_findFileNameBtn setHidden:TRUE];
		[_findTitleBtn setTitle:@"Name"];
		[_findDescBtn setTitle:@"Biography"];
	}
}

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
- (IBAction)doActionFindPrev:(id)sender
{
	
}

/**
 *
 *
 */
- (IBAction)doActionFindNext:(id)sender
{
	if (!mFindQuery.length)
		return;
	
	if (NSNotFound == mFindIndex)
		mFindIndex = 0;
	else
		mFindIndex += 1;
	
	BOOL findTitle = _findTitleBtn.state;
	BOOL findDesc = _findDescBtn.state;
	BOOL findName = _findFileNameBtn.state;
	
	BOOL (^findNext) (NSArray*, NSUInteger, NSObject**, NSUInteger*, BOOL (^)(id)) = ^ BOOL (NSArray *objects, NSUInteger startNdx, NSObject **matchObj, NSUInteger *matchNdx, BOOL (^comparator)(id)) {
		__block BOOL _found = FALSE;
		
		[objects enumerateObjectsFromIndex:startNdx usingBlock:^ (id obj, NSUInteger objNdx, BOOL *objStop) {
			if (comparator(obj)) {
				*matchObj = obj;
				*matchNdx = objNdx;
				_found = TRUE;
				*objStop = TRUE;
			}
		}];
		
		return _found;
	};
	
	//
	// movie search
	//
	if ([mFindType isEqualToString:@"Movies"]) {
		NSArray *objects = self.moviesArrayController.arrangedObjects;
		__block MBMovie *mbmovie = nil;
		__block NSUInteger index = NSNotFound;
		BOOL (^compare) (MBMovie*) = nil;
		
		if (findTitle && findDesc && findName) {
			compare = ^ BOOL (MBMovie *_mbmovie) {
				return NSNotFound != [_mbmovie.title.lowercaseString rangeOfString:mFindQuery].location ||
							 NSNotFound != [_mbmovie.description.lowercaseString rangeOfString:mFindQuery].location ||
							 NSNotFound != [_mbmovie.dirpath.lowercaseString rangeOfString:mFindQuery].location;
			};
		}
		else if (findTitle && findDesc) {
			compare = ^ BOOL (MBMovie *_mbmovie) {
				return NSNotFound != [_mbmovie.title.lowercaseString rangeOfString:mFindQuery].location ||
							 NSNotFound != [_mbmovie.description.lowercaseString rangeOfString:mFindQuery].location;
			};
		}
		else if (findTitle && findName) {
			compare = ^ BOOL (MBMovie *_mbmovie) {
				return NSNotFound != [_mbmovie.title.lowercaseString rangeOfString:mFindQuery].location ||
							 NSNotFound != [_mbmovie.dirpath.lowercaseString rangeOfString:mFindQuery].location;
			};
		}
		else if (findDesc && findName) {
			compare = ^ BOOL (MBMovie *_mbmovie) {
				return NSNotFound != [_mbmovie.description.lowercaseString rangeOfString:mFindQuery].location ||
							 NSNotFound != [_mbmovie.dirpath.lowercaseString rangeOfString:mFindQuery].location;
			};
		}
		else if (findTitle) {
			compare = ^ BOOL (MBMovie *_mbmovie) {
				return NSNotFound != [_mbmovie.title.lowercaseString rangeOfString:mFindQuery].location;
			};
		}
		else if (findDesc) {
			compare = ^ BOOL (MBMovie *_mbmovie) {
				return NSNotFound != [_mbmovie.description.lowercaseString rangeOfString:mFindQuery].location;
			};
		}
		else if (findName) {
			compare = ^ BOOL (MBMovie *_mbmovie) {
				return NSNotFound != [_mbmovie.dirpath.lowercaseString rangeOfString:mFindQuery].location;
			};
		}
		else {
			NSBeep();
			return;
		}
		
		if (!findNext(objects, mFindIndex, &mbmovie, &index, compare) && mFindIndex != 0)
			findNext(objects, 0, &mbmovie, &index, compare);
		
		if (!mbmovie) {
			NSBeep();
			return;
		}
		
		mFindIndex = index;
		
		[self doActionFindHide:sender];
		[_movieTable scrollRowToVisible:index];
	}
	
	//
	// actor search
	//
	else if ([mFindType isEqualToString:@"Actors"]) {
		NSArray *objects = self.actorsArrayController.arrangedObjects;
		__block MBPerson *mbperson = nil;
		__block NSUInteger index = NSNotFound;
		BOOL (^compare) (MBPerson*) = nil;
		
		if (findTitle && findDesc) {
			compare = ^ BOOL (MBPerson *_mbperson) {
				return NSNotFound != [_mbperson.name.lowercaseString rangeOfString:mFindQuery].location ||
							 NSNotFound != [_mbperson.bio.lowercaseString rangeOfString:mFindQuery].location;
			};
		}
		else if (findTitle) {
			compare = ^ BOOL (MBPerson *_mbperson) {
				return NSNotFound != [_mbperson.name.lowercaseString rangeOfString:mFindQuery].location;
			};
		}
		else if (findDesc) {
			compare = ^ BOOL (MBPerson *_mbperson) {
				return NSNotFound != [_mbperson.bio.lowercaseString rangeOfString:mFindQuery].location;
			};
		}
		else {
			NSBeep();
			return;
		}
		
		if (!findNext(objects, mFindIndex, &mbperson, &index, compare) && mFindIndex != 0)
			findNext(objects, 0, &mbperson, &index, compare);
		
		if (!mbperson) {
			NSBeep();
			return;
		}
		
		mFindIndex = index;
		
		[self doActionFindHide:sender];
		[_actorTable scrollRowToVisible:index];
	}
}

/**
 *
 *
 */
- (IBAction)doActionFind:(id)sender
{
	mFindQuery = self.findTxt.stringValue.lowercaseString;
	mFindType = _findTypeBtn.titleOfSelectedItem;
	mFindIndex = NSNotFound;
	
	// close the find window if the search query is zero-length
	if (!mFindQuery.length) {
		[self doActionFindHide:sender];
		return;
	}
	
	[self doActionFindNext:sender];
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
	BOOL showAll = mActorHeaderMenuShowAllItem.state == NSOnState;
	
	if (mMovieSelection) {
		predicate = [NSPredicate predicateWithBlock:^ BOOL (id object, NSDictionary *bindings) {
			return [mDataManager doesMovie:mMovieSelection haveActor:(MBPerson *)object];
		}];
	}
	else {
		predicate = [NSPredicate predicateWithBlock:^ BOOL (id personObj, NSDictionary *bindings) {
			return nil != mActorsByName[((MBPerson *)personObj).name] && (showAll || 5 <= ((MBPerson *)personObj).movies.count);
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
	NSLog(@"%s", __PRETTY_FUNCTION__);
	
	if (!mIsDoneLoading)
		return;
	
	NSPredicate *predicate = nil;
	
	if (mMovieSelection) {
		predicate = [NSPredicate predicateWithBlock:^ BOOL (id genreObj, NSDictionary *bindings) {
			return [mDataManager doesMovie:mMovieSelection haveGenre:genreObj];
		}];
	}
	else {
		predicate = [NSPredicate predicateWithBlock:^ BOOL (id genreObj, NSDictionary *bindings) {
			return nil != mGenresByName[genreObj];
		}];
	}
	
	self.genresArrayController.filterPredicate = predicate;
	
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
	
	NSLog(@"%s.. mActor=%@, mGenre=%@, mMovie=%@, mLanguage=%@, mRating=%@", __PRETTY_FUNCTION__, mActorSelection.name, [mGenreSelections componentsJoinedByString:@", "], mMovieSelection.title, mLanguageSelection, mRatingSelection);
	
	NSPredicate *predicate = nil;
	BOOL (^genreMatches)(id) = nil;
	NSUInteger genreSelectionCount = mGenreSelections.count;
	
	if (genreSelectionCount == 1) {
		MBGenre *mbgenre = mGenreSelections[0];
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
				[mGenreSelections enumerateObjectsUsingBlock:^ (id mbgenre, NSUInteger ndx, BOOL *stop) {
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
				[mGenreSelections enumerateObjectsUsingBlock:^ (id genre, NSUInteger ndx, BOOL *stop) {
					if (FALSE == [mDataManager doesMovie:movie haveGenre:genre]) {
						match = FALSE;
						*stop = TRUE;
					}
				}];
				return match == x;
			};
		}
	}
	
	//
	// actor & language & rating & genre
	//
	if (mActorSelection && mLanguageSelection && genreMatches) {
		predicate = [NSPredicate predicateWithBlock:^ BOOL (id object, NSDictionary *bindings) {
			return [mDataManager doesMovie:(MBMovie *)object haveActor:mActorSelection] &&
			       [mDataManager doesMovie:(MBMovie *)object haveLanguage:mLanguageSelection] &&
						 [mRatingSelection isEqualToString:((MBMovie *)object).rating] &&
			       (mShowHiddenMovies || !((MBMovie *)object).hidden.boolValue) && genreMatches(object);
		}];
	}
	
	
	
	
	
	//
	// actor & language & rating
	//
	if (mActorSelection && mLanguageSelection && mRatingSelection) {
		predicate = [NSPredicate predicateWithBlock:^ BOOL (id object, NSDictionary *bindings) {
			return [mDataManager doesMovie:(MBMovie *)object haveActor:mActorSelection] &&
			       [mDataManager doesMovie:(MBMovie *)object haveLanguage:mLanguageSelection] &&
			       [mRatingSelection isEqualToString:((MBMovie *)object).rating] &&
			       (mShowHiddenMovies || !((MBMovie *)object).hidden.boolValue);
		}];
	}
	
	//
	// actor & language & genre
	//
	if (mActorSelection && mLanguageSelection && genreMatches) {
		predicate = [NSPredicate predicateWithBlock:^ BOOL (id object, NSDictionary *bindings) {
			return [mDataManager doesMovie:(MBMovie *)object haveActor:mActorSelection] &&
			       [mDataManager doesMovie:(MBMovie *)object haveLanguage:mLanguageSelection] &&
			       (mShowHiddenMovies || !((MBMovie *)object).hidden.boolValue) && genreMatches(object);
		}];
	}
	
	//
	// actor & rating & genre
	//
	if (mActorSelection && mRatingSelection && genreMatches) {
		predicate = [NSPredicate predicateWithBlock:^ BOOL (id object, NSDictionary *bindings) {
			return [mDataManager doesMovie:(MBMovie *)object haveActor:mActorSelection] &&
			       [mRatingSelection isEqualToString:((MBMovie *)object).rating] &&
			       (mShowHiddenMovies || !((MBMovie *)object).hidden.boolValue) && genreMatches(object);
		}];
	}
	
	//
	// language & rating & genre
	//
	if (mLanguageSelection && mRatingSelection && genreMatches) {
		predicate = [NSPredicate predicateWithBlock:^ BOOL (id object, NSDictionary *bindings) {
			return [mDataManager doesMovie:(MBMovie *)object haveLanguage:mLanguageSelection] &&
			       [mRatingSelection isEqualToString:((MBMovie *)object).rating] &&
			       (mShowHiddenMovies || !((MBMovie *)object).hidden.boolValue) && genreMatches(object);
		}];
	}
	
	
	
	
	
	//
	// actor & language
	//
	else if (mActorSelection && mLanguageSelection) {
		predicate = [NSPredicate predicateWithBlock:^ BOOL (id object, NSDictionary *bindings) {
			return [mDataManager doesMovie:(MBMovie *)object haveActor:mActorSelection] &&
						 [mDataManager doesMovie:(MBMovie *)object haveLanguage:mLanguageSelection] &&
			       (mShowHiddenMovies || !((MBMovie *)object).hidden.boolValue);
		}];
	}
	
	//
	// actor & rating
	//
	else if (mActorSelection && mRatingSelection) {
		predicate = [NSPredicate predicateWithBlock:^ BOOL (id object, NSDictionary *bindings) {
			return [mDataManager doesMovie:(MBMovie *)object haveActor:mActorSelection] &&
			       [mRatingSelection isEqualToString:((MBMovie *)object).rating] &&
			       (mShowHiddenMovies || !((MBMovie *)object).hidden.boolValue);
		}];
	}
	
	//
	// actor & genre
	//
	else if (mActorSelection && genreMatches) {
		predicate = [NSPredicate predicateWithBlock:^ BOOL (id object, NSDictionary *bindings) {
			return [mDataManager doesMovie:(MBMovie *)object haveActor:mActorSelection] &&
			       (mShowHiddenMovies || !((MBMovie *)object).hidden.boolValue) && genreMatches(object);
		}];
	}
	
	//
	// language & rating
	//
	else if (mLanguageSelection && mRatingSelection) {
		predicate = [NSPredicate predicateWithBlock:^ BOOL (id object, NSDictionary *bindings) {
			return [mDataManager doesMovie:(MBMovie *)object haveLanguage:mLanguageSelection] &&
			       [mRatingSelection isEqualToString:((MBMovie *)object).rating] &&
			       (mShowHiddenMovies || !((MBMovie *)object).hidden.boolValue) && genreMatches(object);
		}];
	}
	
	//
	// language & genre
	//
	else if (mLanguageSelection && genreMatches) {
		predicate = [NSPredicate predicateWithBlock:^ BOOL (id object, NSDictionary *bindings) {
			return [mDataManager doesMovie:(MBMovie *)object haveLanguage:mLanguageSelection] &&
			       (mShowHiddenMovies || !((MBMovie *)object).hidden.boolValue) && genreMatches(object);
		}];
	}
	
	//
	// rating & genre
	//
	else if (mRatingSelection && genreMatches) {
		predicate = [NSPredicate predicateWithBlock:^ BOOL (id object, NSDictionary *bindings) {
			return [mRatingSelection isEqualToString:((MBMovie *)object).rating] &&
			       (mShowHiddenMovies || !((MBMovie *)object).hidden.boolValue) && genreMatches(object);
		}];
	}
	
	
	
	
	
	//
	// genre
	//
	else if (genreMatches) {
		predicate = [NSPredicate predicateWithBlock:^ BOOL (id object, NSDictionary *bindings) {
			return (mShowHiddenMovies || !((MBMovie *)object).hidden.boolValue) && genreMatches(object);
		}];
	}
	
	//
	// actor
	//
	else if (mActorSelection) {
		predicate = [NSPredicate predicateWithBlock:^ BOOL (id object, NSDictionary *bindings) {
			return [mDataManager doesMovie:(MBMovie *)object haveActor:mActorSelection] &&
			       (mShowHiddenMovies || !((MBMovie *)object).hidden.boolValue);
		}];
	}
	
	//
	// language
	//
	else if (mLanguageSelection) {
		predicate = [NSPredicate predicateWithBlock:^ BOOL (id object, NSDictionary *bindings) {
			return [mDataManager doesMovie:(MBMovie *)object haveLanguage:mLanguageSelection];
		}];
	}
	
	//
	// rating
	//
	else if (mRatingSelection) {
		predicate = [NSPredicate predicateWithBlock:^ BOOL (id object, NSDictionary *bindings) {
			return [mRatingSelection isEqualToString:((MBMovie *)object).rating];
		}];
	}
	
	//
	// nothing
	//
	else {
		predicate = [NSPredicate predicateWithBlock:^ BOOL (id object, NSDictionary *bindings) {
			return (mShowHiddenMovies || !((MBMovie *)object).hidden.boolValue);
		}];
	}
	
	_moviesArrayController.filterPredicate = predicate;
	
	// keep the movie selection (if any) visible, otherwise scroll to the top
	if (mMovieSelection) {
		if (NSNotFound == _moviesArrayController.selectionIndex) {
			mMovieSelection = nil;
			[self updateMovieFilter];
			[self doNotificationMovieSelectionChanged:nil];
		}
		else
			[_movieTable scrollRowToVisible:_movieTable.selectedRow];
	}
	else {
		((NSScrollView *)_movieTable.superview.superview).verticalScroller.floatValue = 0;
		[((NSScrollView *)_movieTable.superview.superview).contentView scrollToPoint:NSMakePoint(0,0)];
	}
	
	[self updateMovieFilter_infoText];
	[self updateWindowTitle];
}

/**
 * calculate the total duration and file size for all of the movie represented in the current set.
 * also, count the number of movies associated with each genre.
 */
- (void)updateMovieFilter_infoText
{
	NSArray *arrangedObjects = self.moviesArrayController.arrangedObjects;
	NSMutableString *infoTxt = [[NSMutableString alloc] init];
	__block NSUInteger duration = 0;
	__block NSUInteger filesize = 0;
	
	[arrangedObjects enumerateObjectsUsingBlock:^ (id movieObj, NSUInteger movieNdx, BOOL *movieStop) {
		duration += ((MBMovie *)movieObj).duration.integerValue;
		filesize += ((MBMovie *)movieObj).filesize.integerValue;
	}];
	
	[infoTxt appendString:@(arrangedObjects.count).stringValue];
	[infoTxt appendString:@" movies, "];
	[infoTxt appendString:[MBStuff humanReadableDuration:duration]];
	[infoTxt appendString:@", "];
	[infoTxt appendString:[MBStuff humanReadableFileSize:filesize]];
	
	self.movieInfoTxt.stringValue = infoTxt;
}

/**
 *
 *
 */
- (void)updateMovieFilter_genreCache
{
	[mGenresByName removeAllObjects];
	[mGenresSorted removeAllObjects];
	
	if (mActorSelection) {
		[mActorSelection.movies.allKeys enumerateObjectsUsingBlock:^ (id movieObj, NSUInteger movieNdx, BOOL *movieStop) {
			[[mDataManager movieWithKey:movieObj].genres.allKeys enumerateObjectsUsingBlock:^ (id genreObj, NSUInteger genreNdx, BOOL *genreStop) {
				mGenresByName[genreObj] = @(1 + ((NSNumber *)mGenresByName[genreObj]).integerValue);
			}];
		}];
	}
	else {
		[_moviesArray enumerateObjectsUsingBlock:^ (id movieObj, NSUInteger movieNdx, BOOL *movieStop) {
			[((MBMovie *)movieObj).genres.allKeys enumerateObjectsUsingBlock:^ (id genreObj, NSUInteger genreNdx, BOOL *genreStop) {
				mGenresByName[genreObj] = @(1 + ((NSNumber *)mGenresByName[genreObj]).integerValue);
			}];
		}];
	}
	
#if !defined DEBUG
	[mGenresByName removeObjectForKey:@"Adult"];
	[mGenresByName removeObjectForKey:@"Erotic"];
#endif
}

/**
 *
 *
 */
- (void)updateMovieFilter_actorCache
{
	[mActorsByName removeAllObjects];
	[mActorsSorted removeAllObjects];
	
	if (mMovieSelection) {
		[mMovieSelection.actors.allKeys enumerateObjectsUsingBlock:^ (id actorObj, NSUInteger actorNdx, BOOL *actorStop) {
			mActorsByName[actorObj] = @(1 + ((NSNumber *)mActorsByName[actorObj]).integerValue);
		}];
	}
	else
		[mActorsByName setDictionary:mDataManager.actorsByName];
}

@end
