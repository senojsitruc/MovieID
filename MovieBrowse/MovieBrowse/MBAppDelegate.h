//
//  MBAppDelegate.h
//  MovieBrowse
//
//  Created by Curtis Jones on 2012.09.05.
//  Copyright (c) 2012 Curtis Jones. All rights reserved.
//

#import <Cocoa/Cocoa.h>

extern NSString * const MBDefaultsKeyImageHost;
extern NSString * const MBDefaultsKeyImageCache;
extern NSString * const MBDefaultsKeySources;
extern NSString * const MBDefaultsKeySourcesPath;
extern NSString * const MBDefaultsKeyApiTmdb;
extern NSString * const MBDefaultsKeyApiImdb;
extern NSString * const MBDefaultsKeyApiRt;

@class MBMovie;
@class MBPerson;
@class MBDataManager;
@class MBActorMovieView;
@class MBImportViewController;

@interface MBAppDelegate : NSObject <NSApplicationDelegate, NSTableViewDelegate>

/**
 * Other
 */
@property (readonly) MBDataManager *dataManager;
@property (readonly) dispatch_queue_t imageQueue;

/**
 * Main Window
 */
@property (assign) IBOutlet NSWindow *window;
@property (assign) IBOutlet NSTextField *movieInfoTxt;

/**
 * Actor Sheet
 */
@property (assign) IBOutlet NSWindow *actorWindow;
@property (assign) IBOutlet NSImageView *actorWindowImage;
@property (assign) IBOutlet NSTextField *actorWindowName;
@property (assign) IBOutlet NSTextField *actorWindowInfo;
@property (assign) IBOutlet NSTextView *actorDescTxt;
@property (assign) IBOutlet NSScrollView *actorDescScroll;
@property (assign) IBOutlet MBActorMovieView *actorMovies;
@property (assign) IBOutlet NSProgressIndicator *actorImagePrg;

/**
 * Link-To Sheet
 */
@property (assign) IBOutlet NSWindow *linkToWindow;
@property (assign) IBOutlet NSTextField *linkToTxt;

/**
 * Tables
 */
@property (assign) IBOutlet NSTableView *actorTable;
@property (assign) IBOutlet NSTableView *genreTable;
@property (assign) IBOutlet NSTableView *movieTable;

/**
 * Arrays
 */
@property (readwrite, strong) NSMutableArray *actorsArray;
@property (readwrite, strong) NSMutableArray *genresArray;
@property (readwrite, strong) NSMutableArray *moviesArray;

/**
 * Selection
 */
@property (readwrite, strong) NSIndexSet *actorsArraySelection;
@property (readwrite, strong) NSIndexSet *genresArraySelection;
@property (readwrite, strong) NSIndexSet *moviesArraySelection;

/**
 * Array Controllers
 */
@property (readwrite, strong) IBOutlet NSArrayController *actorsArrayController;
@property (readwrite, strong) IBOutlet NSArrayController *genresArrayController;
@property (readwrite, strong) IBOutlet NSArrayController *moviesArrayController;

/**
 * Preferences
 */
@property (assign) IBOutlet NSWindow *prefsWin;
@property (assign) IBOutlet NSMenuItem *prefsMenu;
@property (assign) IBOutlet NSButton *prefsAddBtn;
@property (assign) IBOutlet NSButton *prefsDelBtn;

/**
 * Search
 */
@property (readwrite, strong) NSMutableArray *searchArray;
@property (assign) IBOutlet NSArrayController *searchArrayController;
@property (assign) IBOutlet NSWindow *searchWin;
@property (assign) IBOutlet NSTextField *searchTxt;
@property (assign) IBOutlet NSPopUpButton *searchType;
@property (assign) IBOutlet NSPopUpButton *searchSite;
@property (assign) IBOutlet NSButton *searchBtn;
@property (assign) IBOutlet NSTableView *searchTbl;

/**
 * Import
 */
@property (assign) IBOutlet NSWindow *importWindow;
@property (assign) IBOutlet MBImportViewController *importController;

/**
 * Find
 */
@property (assign) IBOutlet NSWindow *findWindow;
@property (assign) IBOutlet NSPopUpButton *findTypeBtn;
@property (assign) IBOutlet NSTextField *findTxt;
@property (assign) IBOutlet NSButton *findBtn;

+ (MBAppDelegate *)sharedInstance;

- (void)doActionMovieHide:(MBMovie *)mbmovie withView:(NSView *)view;
- (void)doActionMovieUnhide:(MBMovie *)mbmovie withView:(NSView *)view;

- (void)doActionLinkToTMDb:(MBMovie *)movie;
- (void)doActionSearchShow:(id)sender;

- (void)showActor:(MBPerson *)mbperson;

@end