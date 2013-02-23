//
//  MBAppDelegate.m
//  MovieBrowse
//
//  Created by Curtis Jones on 2012.09.05.
//  Copyright (c) 2012 Curtis Jones. All rights reserved.
//

#import <MovieID/Subscript.h>
#import "MBAppDelegate.h"
#import "MBGenre.h"
#import "MBMovie.h"
#import "MBPerson.h"
#import "MBStuff.h"
#import "MBDataManager.h"
#import "MBActorMovieView.h"
#import "MBImageCache.h"
#import "MBPopUpMenu.h"
#import "MBDownloadQueue.h"
#import "MBImportWindowController.h"
#import "MBActorEditWindowController.h"
#import "MBActorProfileWindowController.h"
#import "MBMovieEditWindowController.h"
#import "MBPreferencesWindowController.h"
#import "MBRenameWindowController.h"
#import "MBScreencapsWindowController.h"
#import "MMScroller.h"
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
	MBActorEditWindowController *mActorEditController;
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
	 * Table Menu Handlers
	 */
	MBPopUpMenuItemHandler mMovieMenuSortHandler;
	MBPopUpMenuItemHandler mGenreMenuMultiHandler;
	MBPopUpMenuItemHandler mActorMenuShowHandler;
	MBPopUpMenuItemHandler mActorMenuSortHandler;
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
	_splashTxt.stringValue = @"Loading...";
	[_splashWin makeKeyAndOrderFront:nil];
	
	gAppDelegate = self;
	mIsDoneLoading = FALSE;
	
	mDataManager = [[MBDataManager alloc] init];
	mActorEditController = [[MBActorEditWindowController alloc] init];
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
	
	// user defaults - we have two sets of user defaults data: the stuff that I'm willing to hard-code
	//                 and commit to GitHub, and the stuff just for me (like my personal api keys).
	//                 and that's where MovieBrowseConfig.plist comes in.
	{
		NSData *settingsData = [NSData dataWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"MovieBrowseConfig" ofType:@"plist"]];
		NSDictionary *settings = nil;
		
		if (settingsData)
			settings = [NSPropertyListSerialization propertyListWithData:settingsData options:NSPropertyListImmutable format:nil error:nil];
		
		NSMutableDictionary *defaults = [[NSMutableDictionary alloc] init];
		
		defaults[MBDefaultsKeyImageHost]              = @"";
		defaults[MBDefaultsKeyImageCache]             = @"~/Library/Application Support/MovieBrowse/Cache";
		defaults[MBDefaultsKeySources]                = @[];
		defaults[MBDefaultsKeyApiTmdb]                = @"";
		defaults[MBDefaultsKeyApiImdb]                = @"2wex6aeu6a8q9e49k7sfvufd6rhh0n";
		defaults[MBDefaultsKeyApiRt]                  = @"";
		defaults[MBDefaultsKeyMoviesSort]             = @"Title";
		defaults[MBDefaultsKeyMoviesShowHidden]       = @(0);
		defaults[MBDefaultsKeyGenreMulti]             = @"Or";
		defaults[MBDefaultsKeyActorShow]              = @"Popular";
		defaults[MBDefaultsKeyActorSort]              = @"Name";
		defaults[MBDefaultsKeyActorSelection]         = @[];
		defaults[MBDefaultsKeyGenreSelection]         = @[];
		defaults[MBDefaultsKeyMovieSelection]         = @[];
		defaults[MBDefaultsKeyFindQuery]              = @"";
		defaults[MBDefaultsKeyFindType]               = @"Movies";
		defaults[MBDefaultsKeyFindTitleEnabled]       = @(TRUE);
		defaults[MBDefaultsKeyFindFileNameEnabled]    = @(FALSE);
		defaults[MBDefaultsKeyFindDescriptionEnabled] = @(FALSE);
		
		[settings enumerateKeysAndObjectsUsingBlock:^ (id key, id obj, BOOL *stop) {
			defaults[key] = obj;
		}];
		
		[[NSUserDefaults standardUserDefaults] registerDefaults:defaults];
	}
	
	//
	// movie table menu
	//
	{
		_movieTableMenu.willDisplayHandler = ^{
			[gAppDelegate updateMoviesHeaderLanguages:TRUE];
			[gAppDelegate updateMoviesHeaderRating:TRUE];
		};
		
		mMovieMenuSortHandler = ^ (NSString *itemTitle, NSInteger itemTag, NSInteger state) {
			if ([itemTitle isEqualToString:@"  Movie by Title"] || [itemTitle isEqualToString:@"Title"]) {
				[[NSUserDefaults standardUserDefaults] setObject:@"Title" forKey:MBDefaultsKeyMoviesSort];
				[gAppDelegate updateMoviesHeaderLabel];
				[gAppDelegate.moviesArrayController setSortDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"sortTitle" ascending:TRUE]]];
				[gAppDelegate updateMoviesPostSort];
				[gAppDelegate->_movieTableMenu setState:NSOnState forItem:@"  Movie by Title" inSection:@"Sort"];
			}
			else if ([itemTitle isEqualToString:@"  Movie by Year"] || [itemTitle isEqualToString:@"Year"]) {
				[[NSUserDefaults standardUserDefaults] setObject:@"Year" forKey:MBDefaultsKeyMoviesSort];
				[gAppDelegate updateMoviesHeaderLabel];
				[gAppDelegate.moviesArrayController setSortDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"year" ascending:FALSE], [NSSortDescriptor sortDescriptorWithKey:@"sortTitle" ascending:TRUE]]];
				[gAppDelegate updateMoviesPostSort];
				[gAppDelegate->_movieTableMenu setState:NSOnState forItem:@"  Movie by Year" inSection:@"Sort"];
			}
			else if ([itemTitle isEqualToString:@"  Movie by Score"] || [itemTitle isEqualToString:@"Score"]) {
				[[NSUserDefaults standardUserDefaults] setObject:@"Score" forKey:MBDefaultsKeyMoviesSort];
				[gAppDelegate updateMoviesHeaderLabel];
				[gAppDelegate.moviesArrayController setSortDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"score" ascending:FALSE], [NSSortDescriptor sortDescriptorWithKey:@"sortTitle" ascending:TRUE]]];
				[gAppDelegate updateMoviesPostSort];
				[gAppDelegate->_movieTableMenu setState:NSOnState forItem:@"  Movie by Score" inSection:@"Sort"];
			}
			else if ([itemTitle isEqualToString:@"  Movie by Runtime"] || [itemTitle isEqualToString:@"Runtime"]) {
				[[NSUserDefaults standardUserDefaults] setObject:@"Runtime" forKey:MBDefaultsKeyMoviesSort];
				[gAppDelegate updateMoviesHeaderLabel];
				[gAppDelegate.moviesArrayController setSortDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"duration" ascending:FALSE], [NSSortDescriptor sortDescriptorWithKey:@"sortTitle" ascending:TRUE]]];
				[gAppDelegate updateMoviesPostSort];
				[gAppDelegate->_movieTableMenu setState:NSOnState forItem:@"  Movie by Runtime" inSection:@"Sort"];
			}
			else if ([itemTitle isEqualToString:@"  Movie by Added"] || [itemTitle isEqualToString:@"Added"]) {
				[[NSUserDefaults standardUserDefaults] setObject:@"Added" forKey:MBDefaultsKeyMoviesSort];
				[gAppDelegate updateMoviesHeaderLabel];
				[gAppDelegate.moviesArrayController setSortDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"mtime" ascending:FALSE], [NSSortDescriptor sortDescriptorWithKey:@"sortTitle" ascending:FALSE]]];
				[gAppDelegate updateMoviesPostSort];
				[gAppDelegate->_movieTableMenu setState:NSOnState forItem:@"  Movie by Added" inSection:@"Sort"];
			}
		};
		
		[_movieTableMenu addSectionWithTitle:@"Sort" mode:MBPopUpMenuSectionModeOne];
		[_movieTableMenu addItemWithTitle:@"  Movie by Title" toSection:@"Sort" withHandler:mMovieMenuSortHandler];
		[_movieTableMenu addItemWithTitle:@"  Movie by Year" toSection:@"Sort" withHandler:mMovieMenuSortHandler];
		[_movieTableMenu addItemWithTitle:@"  Movie by Score" toSection:@"Sort" withHandler:mMovieMenuSortHandler];
		[_movieTableMenu addItemWithTitle:@"  Movie by Runtime" toSection:@"Sort" withHandler:mMovieMenuSortHandler];
		[_movieTableMenu addItemWithTitle:@"  Movie by Added" toSection:@"Sort" withHandler:mMovieMenuSortHandler];
		
		((MMScroller *)_movieTableScrollView.verticalScroller).drawsRightRule = FALSE;
	}
	
	//
	// genre table menu
	//
	{
		mGenreMenuMultiHandler = ^ (NSString *itemTitle, NSInteger itemTag, NSInteger state) {
			if ([itemTitle isEqualToString:@"  Movies in Any"] || [itemTitle isEqualToString:@"Or"]) {
				[[NSUserDefaults standardUserDefaults] setObject:@"Or" forKey:MBDefaultsKeyGenreMulti];
				[gAppDelegate->_genreTableMenu setState:NSOnState forItem:@"  Movies in Any" inSection:@"Multi Select"];
			}
			else if ([itemTitle isEqualToString:@"  Movies in All"] || [itemTitle isEqualToString:@"And"]) {
				[[NSUserDefaults standardUserDefaults] setObject:@"And" forKey:MBDefaultsKeyGenreMulti];
				[gAppDelegate->_genreTableMenu setState:NSOnState forItem:@"  Movies in All" inSection:@"Multi Select"];
			}
			else if ([itemTitle isEqualToString:@"  Movies not in Any"] || [itemTitle isEqualToString:@"NotOr"]) {
				[[NSUserDefaults standardUserDefaults] setObject:@"NotOr" forKey:MBDefaultsKeyGenreMulti];
				[gAppDelegate->_genreTableMenu setState:NSOnState forItem:@"  Movies not in Any" inSection:@"Multi Select"];
			}
			else if ([itemTitle isEqualToString:@"  Movies not in All"] || [itemTitle isEqualToString:@"NotAnd"]) {
				[[NSUserDefaults standardUserDefaults] setObject:@"NotAnd" forKey:MBDefaultsKeyGenreMulti];
				[gAppDelegate->_genreTableMenu setState:NSOnState forItem:@"  Movies not in All" inSection:@"Multi Select"];
			}
			
			[gAppDelegate doNotificationGenreSelectionChanged:nil];
		};
		
		[_genreTableMenu addSectionWithTitle:@"Multi Select" mode:MBPopUpMenuSectionModeOne];
		[_genreTableMenu addItemWithTitle:@"  Movies in Any" toSection:@"Multi Select" withHandler:mGenreMenuMultiHandler];
		[_genreTableMenu addItemWithTitle:@"  Movies in All" toSection:@"Multi Select" withHandler:mGenreMenuMultiHandler];
		[_genreTableMenu addItemWithTitle:@"  Movies not in Any" toSection:@"Multi Select" withHandler:mGenreMenuMultiHandler];
		[_genreTableMenu addItemWithTitle:@"  Movies not in All" toSection:@"Multi Select" withHandler:mGenreMenuMultiHandler];
		
		((MMScroller *)_genreTableScrollView.verticalScroller).drawsRightRule = TRUE;
	}
	
	//
	// actor table menu
	//
	{
		mActorMenuShowHandler = ^ (NSString *itemTitle, NSInteger itemTag, NSInteger itemState) {
			if ([itemTitle isEqualToString:@"  All"] || [itemTitle isEqualToString:@"All"]) {
				[[NSUserDefaults standardUserDefaults] setObject:@"All" forKey:MBDefaultsKeyActorShow];
				[gAppDelegate->_actorTableMenu setState:NSOnState forItem:@"  All" inSection:@"Show"];
				[gAppDelegate updateActorsHeaderLabel];
				[gAppDelegate.actorsArrayController setSortDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"name" ascending:TRUE]]];
				[gAppDelegate updateActorPostSort];
				[gAppDelegate updateActorFilter];
			}
			else if ([itemTitle isEqualToString:@"  Popular"] || [itemTitle isEqualToString:@"Popular"]) {
				[[NSUserDefaults standardUserDefaults] setObject:@"Popular" forKey:MBDefaultsKeyActorShow];
				[gAppDelegate->_actorTableMenu setState:NSOnState forItem:@"  Popular" inSection:@"Show"];
				[gAppDelegate updateActorsHeaderLabel];
				[gAppDelegate.actorsArrayController setSortDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"name" ascending:TRUE]]];
				[gAppDelegate updateActorPostSort];
				[gAppDelegate updateActorFilter];
			}
		};
		
		mActorMenuSortHandler = ^ (NSString *itemTitle, NSInteger itemTag, NSInteger itemState) {
			if ([itemTitle isEqualToString:@"  Actor by Name"] || [itemTitle isEqualToString:@"Name"]) {
				[[NSUserDefaults standardUserDefaults] setObject:@"Name" forKey:MBDefaultsKeyActorSort];
				[gAppDelegate->_actorTableMenu setState:NSOnState forItem:@"  Actor by Name" inSection:@"Sort"];
				[gAppDelegate updateActorsHeaderLabel];
				[gAppDelegate.actorsArrayController setSortDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"name" ascending:TRUE]]];
				[gAppDelegate updateActorPostSort];
			}
			else if ([itemTitle isEqualToString:@"  Actor by Age"] || [itemTitle isEqualToString:@"Age"]) {
				[[NSUserDefaults standardUserDefaults] setObject:@"Age" forKey:MBDefaultsKeyActorSort];
				[gAppDelegate->_actorTableMenu setState:NSOnState forItem:@"  Actor by Age" inSection:@"Sort"];
				[gAppDelegate updateActorsHeaderLabel];
				[gAppDelegate.actorsArrayController setSortDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"dob" ascending:FALSE]]];
				[gAppDelegate updateActorPostSort];
			}
			else if ([itemTitle isEqualToString:@"  Actor by Movies"] || [itemTitle isEqualToString:@"Movies"]) {
				[[NSUserDefaults standardUserDefaults] setObject:@"Movies" forKey:MBDefaultsKeyActorSort];
				[gAppDelegate->_actorTableMenu setState:NSOnState forItem:@"  Actor by Movies" inSection:@"Sort"];
				[gAppDelegate updateActorsHeaderLabel];
				[gAppDelegate.actorsArrayController setSortDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"movieCount" ascending:FALSE]]];
				[gAppDelegate updateActorPostSort];
			}
		};
		
		[_actorTableMenu addSectionWithTitle:@"Show" mode:MBPopUpMenuSectionModeOne];
		[_actorTableMenu addItemWithTitle:@"  All" toSection:@"Show" withHandler:mActorMenuShowHandler];
		[_actorTableMenu addItemWithTitle:@"  Popular" toSection:@"Show" withHandler:mActorMenuShowHandler];
		
		[_actorTableMenu addSectionWithTitle:@"Sort" mode:MBPopUpMenuSectionModeOne];
		[_actorTableMenu addItemWithTitle:@"  Actor by Name" toSection:@"Sort" withHandler:mActorMenuSortHandler];
		[_actorTableMenu addItemWithTitle:@"  Actor by Age" toSection:@"Sort" withHandler:mActorMenuSortHandler];
		[_actorTableMenu addItemWithTitle:@"  Actor by Movies" toSection:@"Sort" withHandler:mActorMenuSortHandler];
		
		((MMScroller *)_actorTableScrollView.verticalScroller).drawsRightRule = TRUE;
	}
	
	// call this to restore the appropriate interface for the current find type (actor or movie)
	[self doActionFindType:nil];
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
	
	// observers - table selection changed notifications
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(doNotificationActorSelectionChanged:) name:NSTableViewSelectionDidChangeNotification object:self.actorTable];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(doNotificationGenreSelectionChanged:) name:NSTableViewSelectionDidChangeNotification object:self.genreTable];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(doNotificationMovieSelectionChanged:) name:NSTableViewSelectionDidChangeNotification object:self.movieTable];
	
	// actor - double click action
	self.actorTable.target = self;
	self.actorTable.doubleAction = @selector(doActionActorDoubleClick:);
	
	//
	// reinstate genre multi-select behavior
	//
	{
		NSString *multi = [[NSUserDefaults standardUserDefaults] stringForKey:MBDefaultsKeyGenreMulti];
		mGenreMenuMultiHandler(multi, 0, NSOnState);
	}
	
	//
	// reinstate actor "show" behavior
	{
		NSString *show = [[NSUserDefaults standardUserDefaults] stringForKey:MBDefaultsKeyActorShow];
		mActorMenuShowHandler(show, 0, NSOnState);
	}
	
	//
	// reinstate saved sort orders
	//
	{
		// actors
		{
			NSString *sort = [[NSUserDefaults standardUserDefaults] stringForKey:MBDefaultsKeyActorSort];
			mActorMenuSortHandler(sort, 0, NSOnState);
		}
		
		// genres
		[self.genresArrayController setSortDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"name" ascending:TRUE]]];
		
		// movies
		{
			NSString *sort = [[NSUserDefaults standardUserDefaults] stringForKey:MBDefaultsKeyMoviesSort];
			mMovieMenuSortHandler(sort, 0, NSOnState);
		}
	}
	
	[NSThread performBlockInBackground:^{
		NSMutableArray *actorsArray = [[NSMutableArray alloc] init];
		NSMutableArray *genresArray = [[NSMutableArray alloc] init];
		NSMutableArray *moviesArray = [[NSMutableArray alloc] init];
		
		void (^updateStatus) (NSString*) = ^ (NSString *status) {
			[[NSThread mainThread] performBlock:^{
				_splashTxt.stringValue = status;
			} waitUntilDone:TRUE];
		};
		
		//
		// read data
		//
		{
			[mDataManager loadActors:^ (NSUInteger count, NSString *name) {
				updateStatus([NSString stringWithFormat:@"Reading actors... %lu (%@)", count, name]);
			}];
			
			[mDataManager loadMovies:^ (NSUInteger count, NSString *name) {
				updateStatus([NSString stringWithFormat:@"Reading movies... %lu (%@)", count, name]);
			}];
		}
		
		//
		// load data
		//
		{
			updateStatus(@"Almost done...");
			[mDataManager enumerateGenres:^ (MBGenre *mbgenre, BOOL *stop) { [genresArray addObject:mbgenre]; }];
			[mDataManager enumerateActors:^ (MBPerson *mbactor, NSUInteger count, BOOL *stop) { [actorsArray addObject:mbactor]; }];
			[mDataManager enumerateMovies:^ (MBMovie *mbmovie, NSUInteger count, BOOL *stop) { [moviesArray addObject:mbmovie]; }];
		}
		
		[[NSThread mainThread] performBlock:^{
			{
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
					NSMutableArray *genres = [[NSMutableArray alloc] init];
					
					[selection enumerateObjectsUsingBlock:^ (id genreKey, NSUInteger genreNdx, BOOL *genreStop) {
						MBGenre *mbgenre = [mDataManager genreWithKey:genreKey];
						
						if (mbgenre)
							[genres addObject:mbgenre];
					}];
					
					[self.genresArrayController setSelectedObjects:genres];
					[self doNotificationGenreSelectionChanged:nil];
					[self.genreTable scrollColumnToVisible:self.genreTable.selectedRow];
				}
				else
					_genreTableMenu.label = @"Genre";
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
			
			[_splashWin orderOut:nil];
			[_window makeKeyAndOrderFront:nil];
		}];
	}];
	
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
//			[mDataManager deleteMovie:mbmovie];
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
- (void)editActor:(MBPerson *)mbperson
{
	if (mbperson)
		[mActorEditController showInWindow:self.window forPerson:mbperson];
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
- (void)movie:(MBMovie *)mbmovie unhideWithView:(NSView *)view
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
		_genreTableMenu.label = @"Genre";
		[defaults setObject:@[] forKey:MBDefaultsKeyGenreSelection];
	}
	else {
		[selectedObjects enumerateObjectsUsingBlock:^ (id obj, NSUInteger ndx, BOOL *stop) {
			[mGenreSelections addObject:obj];
		}];
		if (selectedObjects.count == 1)
			_genreTableMenu.label = [NSString stringWithFormat:@"Genre (%@)", ((MBGenre *)mGenreSelections[0]).name];
		else
			_genreTableMenu.label = [NSString stringWithFormat:@"Genre (%lu selected)", selectedObjects.count];
		NSMutableArray *genres = [[NSMutableArray alloc] init];
		[mGenreSelections enumerateObjectsUsingBlock:^ (id genreObj, NSUInteger genreNdx, BOOL *genreStop) {
			[genres addObject:((MBGenre *)genreObj).name];
		}];
		[defaults setObject:genres forKey:MBDefaultsKeyGenreSelection];
	}
	
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
	NSString *prefix=@"", *label=@"";
	NSString *sort = [[NSUserDefaults standardUserDefaults] stringForKey:MBDefaultsKeyMoviesSort];
	
	if (sort)
		prefix = [@"Movie by " stringByAppendingString:sort];
	else
		prefix = @"Movie by Title";
	
	if (mMovieSelection && mLanguageSelection && mRatingSelection)
		label = [NSString stringWithFormat:@"%@ (%@, %@) - %@", prefix, mLanguageSelection, mRatingSelection, mMovieSelection.title];
	
	else if (mMovieSelection && mLanguageSelection)
		label = [NSString stringWithFormat:@"%@ (%@) - %@", prefix, mLanguageSelection, mMovieSelection.title];
	else if (mMovieSelection && mRatingSelection)
		label = [NSString stringWithFormat:@"%@ (%@) - %@", prefix, mRatingSelection, mMovieSelection.title];
	else if (mLanguageSelection && mRatingSelection)
		label = [NSString stringWithFormat:@"%@ (%@, %@)", prefix, mLanguageSelection, mRatingSelection];
	
	else if (mMovieSelection)
		label = [NSString stringWithFormat:@"%@ - %@", prefix, mMovieSelection.title];
	else if (mLanguageSelection)
		label = [NSString stringWithFormat:@"%@ (%@)", prefix, mLanguageSelection];
	else if (mRatingSelection)
		label = [NSString stringWithFormat:@"%@ (%@)", prefix, mRatingSelection];
	else
		label = prefix;
	
	_movieTableMenu.label = label;
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
	[_movieTableMenu removeSectionWithTitle:@"Languages"];
	
	// tally the count for each language
	{
		NSArray *objects = _moviesArrayController.arrangedObjects;
		
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
		[_movieTableMenu addSectionWithTitle:@"Languages" mode:MBPopUpMenuSectionModeOne];
		
		MBPopUpMenuItemHandler handler = ^ (NSString *_title, NSInteger _tag, NSInteger _state) {
			mLanguageSelection = _state ? mLanguagesSorted[_tag] : nil;
			[self updateMovieFilter];
			[self updateActorFilter];
			[self updateMoviesHeaderLabel];
		};
		
		[mLanguagesSorted enumerateObjectsUsingBlock:^ (id languageObj, NSUInteger languageNdx, BOOL *languageStop) {
			NSString *title = [NSString stringWithFormat:@"  %@ (%@)", languageObj, mLanguagesByName[languageObj]];
			[_movieTableMenu addItemWithTitle:title andTag:languageNdx toSection:@"Languages" withHandler:handler];
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
			[_movieTableMenu setState:NSOnState forItem:mLanguageSelection inSection:@"Languages"];
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
	[_movieTableMenu removeSectionWithTitle:@"Ratings"];
	
	// tally the count for each rating
	{
		NSArray *objects = _moviesArrayController.arrangedObjects;
		
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
		[_movieTableMenu addSectionWithTitle:@"Ratings" mode:MBPopUpMenuSectionModeOne];
		
		MBPopUpMenuItemHandler handler = ^ (NSString *_title, NSInteger _tag, NSInteger _state) {
			mRatingSelection = _state ? mRatingsSorted[_tag] : nil;
			[self updateMovieFilter];
			[self updateActorFilter];
			[self updateMoviesHeaderLabel];
		};
		
		[mRatingsSorted enumerateObjectsUsingBlock:^ (id ratingObj, NSUInteger ratingNdx, BOOL *ratingStop) {
			NSString *title = [NSString stringWithFormat:@"  %@ (%@)", ratingObj, mRatingsByName[ratingObj]];
			[_movieTableMenu addItemWithTitle:title andTag:ratingNdx toSection:@"Ratings" withHandler:handler];
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
			[_movieTableMenu setState:NSOnState forItem:mRatingSelection inSection:@"Ratings"];
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





#pragma mark - Actors Header Menu

/**
 *
 *
 */
- (void)updateActorsHeaderLabel
{
	NSString *prefix=nil, *label=nil;
	NSString *sort = [[NSUserDefaults standardUserDefaults] stringForKey:MBDefaultsKeyActorSort];
	NSString *show = [[NSUserDefaults standardUserDefaults] stringForKey:MBDefaultsKeyActorShow];
	
	if (sort)
		prefix = [@"Actor by " stringByAppendingString:sort];
	else
		prefix = @"Actor";
	
	if (mActorSelection)
		label = [NSString stringWithFormat:@"%@ (%@)", prefix, mActorSelection.name];
	else if ([show isEqualToString:@"Popular"])
		label = [NSString stringWithFormat:@"%@ (%@)", prefix, @"Popular"];
	else
		label = prefix;
	
	_actorTableMenu.label = label;
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
				return (_mbmovie.title && NSNotFound != [_mbmovie.title.lowercaseString rangeOfString:mFindQuery].location) ||
							 (_mbmovie.description && NSNotFound != [_mbmovie.description.lowercaseString rangeOfString:mFindQuery].location) ||
							 (_mbmovie.dirpath && NSNotFound != [_mbmovie.dirpath.lowercaseString rangeOfString:mFindQuery].location);
			};
		}
		else if (findTitle && findDesc) {
			compare = ^ BOOL (MBMovie *_mbmovie) {
				return (_mbmovie.title && NSNotFound != [_mbmovie.title.lowercaseString rangeOfString:mFindQuery].location) ||
							 (_mbmovie.description && NSNotFound != [_mbmovie.description.lowercaseString rangeOfString:mFindQuery].location);
			};
		}
		else if (findTitle && findName) {
			compare = ^ BOOL (MBMovie *_mbmovie) {
				return (_mbmovie.title && NSNotFound != [_mbmovie.title.lowercaseString rangeOfString:mFindQuery].location) ||
							 (_mbmovie.dirpath && NSNotFound != [_mbmovie.dirpath.lowercaseString rangeOfString:mFindQuery].location);
			};
		}
		else if (findDesc && findName) {
			compare = ^ BOOL (MBMovie *_mbmovie) {
				return (_mbmovie.description && NSNotFound != [_mbmovie.description.lowercaseString rangeOfString:mFindQuery].location) ||
							 (_mbmovie.dirpath && NSNotFound != [_mbmovie.dirpath.lowercaseString rangeOfString:mFindQuery].location);
			};
		}
		else if (findTitle) {
			compare = ^ BOOL (MBMovie *_mbmovie) {
				return _mbmovie.title && NSNotFound != [_mbmovie.title.lowercaseString rangeOfString:mFindQuery].location;
			};
		}
		else if (findDesc) {
			compare = ^ BOOL (MBMovie *_mbmovie) {
				return _mbmovie.description && NSNotFound != [_mbmovie.description.lowercaseString rangeOfString:mFindQuery].location;
			};
		}
		else if (findName) {
			compare = ^ BOOL (MBMovie *_mbmovie) {
				return _mbmovie.dirpath && NSNotFound != [_mbmovie.dirpath.lowercaseString rangeOfString:mFindQuery].location;
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
				return (_mbperson.name && NSNotFound != [_mbperson.name.lowercaseString rangeOfString:mFindQuery].location) ||
							 (_mbperson.bio && NSNotFound != [_mbperson.bio.lowercaseString rangeOfString:mFindQuery].location);
			};
		}
		else if (findTitle) {
			compare = ^ BOOL (MBPerson *_mbperson) {
				return _mbperson.name && NSNotFound != [_mbperson.name.lowercaseString rangeOfString:mFindQuery].location;
			};
		}
		else if (findDesc) {
			compare = ^ BOOL (MBPerson *_mbperson) {
				return _mbperson.bio && NSNotFound != [_mbperson.bio.lowercaseString rangeOfString:mFindQuery].location;
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
	
	// run a search for the given query (if any), otherwise close the find sheet
	if (mFindQuery.length)
		[self doActionFindNext:sender];
	else
		[self doActionFindHide:sender];
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
	NSString *show = [[NSUserDefaults standardUserDefaults] stringForKey:MBDefaultsKeyActorShow];
	BOOL showAll = [show isEqualToString:@"All"];
	
	if (mMovieSelection) {
		predicate = [NSPredicate predicateWithBlock:^ BOOL (id object, NSDictionary *bindings) {
			return [mDataManager doesMovie:mMovieSelection haveActor:(MBPerson *)object];
		}];
	}
	else {
		predicate = [NSPredicate predicateWithBlock:^ BOOL (id personObj, NSDictionary *bindings) {
			return nil != mActorsByName[((MBPerson *)personObj).name] && (showAll || (5 <= ((MBPerson *)personObj).movies.count && ((MBPerson *)personObj).imageId));
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
	NSString *genreMode = [[NSUserDefaults standardUserDefaults] stringForKey:MBDefaultsKeyGenreMulti];
	
	if (genreSelectionCount == 1) {
		MBGenre *mbgenre = mGenreSelections[0];
		BOOL x = [genreMode isEqualToString:@"Or"] || [genreMode isEqualToString:@"And"];
		genreMatches = ^ BOOL (id movie) {
			return x == [mDataManager doesMovie:movie haveGenre:mbgenre];
		};
	}
	else if (genreSelectionCount > 1) {
		//
		// OR / NOT OR
		//
		if ([genreMode isEqualToString:@"Or"] || [genreMode isEqualToString:@"NotOr"]) {
			BOOL x = [genreMode isEqualToString:@"Or"];
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
		else if ([genreMode isEqualToString:@"And"] || [genreMode isEqualToString:@"NotAnd"]) {
			BOOL x = [genreMode isEqualToString:@"And"];
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
						 [mRatingSelection isEqualToString:((MBMovie *)object).rating] && genreMatches(object);
		}];
	}
	
	
	
	
	
	//
	// actor & language & rating
	//
	if (mActorSelection && mLanguageSelection && mRatingSelection) {
		predicate = [NSPredicate predicateWithBlock:^ BOOL (id object, NSDictionary *bindings) {
			return [mDataManager doesMovie:(MBMovie *)object haveActor:mActorSelection] &&
			       [mDataManager doesMovie:(MBMovie *)object haveLanguage:mLanguageSelection] &&
			       [mRatingSelection isEqualToString:((MBMovie *)object).rating];
		}];
	}
	
	//
	// actor & language & genre
	//
	if (mActorSelection && mLanguageSelection && genreMatches) {
		predicate = [NSPredicate predicateWithBlock:^ BOOL (id object, NSDictionary *bindings) {
			return [mDataManager doesMovie:(MBMovie *)object haveActor:mActorSelection] &&
			       [mDataManager doesMovie:(MBMovie *)object haveLanguage:mLanguageSelection] && genreMatches(object);
		}];
	}
	
	//
	// actor & rating & genre
	//
	if (mActorSelection && mRatingSelection && genreMatches) {
		predicate = [NSPredicate predicateWithBlock:^ BOOL (id object, NSDictionary *bindings) {
			return [mDataManager doesMovie:(MBMovie *)object haveActor:mActorSelection] &&
			       [mRatingSelection isEqualToString:((MBMovie *)object).rating] && genreMatches(object);
		}];
	}
	
	//
	// language & rating & genre
	//
	if (mLanguageSelection && mRatingSelection && genreMatches) {
		predicate = [NSPredicate predicateWithBlock:^ BOOL (id object, NSDictionary *bindings) {
			return [mDataManager doesMovie:(MBMovie *)object haveLanguage:mLanguageSelection] &&
			       [mRatingSelection isEqualToString:((MBMovie *)object).rating] && genreMatches(object);
		}];
	}
	
	
	
	
	
	//
	// actor & language
	//
	else if (mActorSelection && mLanguageSelection) {
		predicate = [NSPredicate predicateWithBlock:^ BOOL (id object, NSDictionary *bindings) {
			return [mDataManager doesMovie:(MBMovie *)object haveActor:mActorSelection] &&
			       [mDataManager doesMovie:(MBMovie *)object haveLanguage:mLanguageSelection];
		}];
	}
	
	//
	// actor & rating
	//
	else if (mActorSelection && mRatingSelection) {
		predicate = [NSPredicate predicateWithBlock:^ BOOL (id object, NSDictionary *bindings) {
			return [mDataManager doesMovie:(MBMovie *)object haveActor:mActorSelection] &&
			       [mRatingSelection isEqualToString:((MBMovie *)object).rating];
		}];
	}
	
	//
	// actor & genre
	//
	else if (mActorSelection && genreMatches) {
		predicate = [NSPredicate predicateWithBlock:^ BOOL (id object, NSDictionary *bindings) {
			return [mDataManager doesMovie:(MBMovie *)object haveActor:mActorSelection] && genreMatches(object);
		}];
	}
	
	//
	// language & rating
	//
	else if (mLanguageSelection && mRatingSelection) {
		predicate = [NSPredicate predicateWithBlock:^ BOOL (id object, NSDictionary *bindings) {
			return [mDataManager doesMovie:(MBMovie *)object haveLanguage:mLanguageSelection] &&
			       [mRatingSelection isEqualToString:((MBMovie *)object).rating];
		}];
	}
	
	//
	// language & genre
	//
	else if (mLanguageSelection && genreMatches) {
		predicate = [NSPredicate predicateWithBlock:^ BOOL (id object, NSDictionary *bindings) {
			return [mDataManager doesMovie:(MBMovie *)object haveLanguage:mLanguageSelection] && genreMatches(object);
		}];
	}
	
	//
	// rating & genre
	//
	else if (mRatingSelection && genreMatches) {
		predicate = [NSPredicate predicateWithBlock:^ BOOL (id object, NSDictionary *bindings) {
			return [mRatingSelection isEqualToString:((MBMovie *)object).rating] && genreMatches(object);
		}];
	}
	
	
	
	
	
	//
	// genre
	//
	else if (genreMatches) {
		predicate = [NSPredicate predicateWithBlock:^ BOOL (id object, NSDictionary *bindings) {
			return genreMatches(object);
		}];
	}
	
	//
	// actor
	//
	else if (mActorSelection) {
		predicate = [NSPredicate predicateWithBlock:^ BOOL (id object, NSDictionary *bindings) {
			return [mDataManager doesMovie:(MBMovie *)object haveActor:mActorSelection];
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
	else
		predicate = nil;
	
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
		[_moviesArrayController.arrangedObjects enumerateObjectsUsingBlock:^ (id movieObj, NSUInteger movieNdx, BOOL *movieStop) {
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
