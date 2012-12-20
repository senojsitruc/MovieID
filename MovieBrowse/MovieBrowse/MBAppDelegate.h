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

@class MBGenre;
@class MBMovie;
@class MBPerson;
@class MBDataManager;
@class MBActorMovieView;
@class MBImportWindowController;
@class MBActorProfileWindowController;
@class MBPreferencesWindowController;
@class MBScreencapsWindowController;

@interface MBAppDelegate : NSObject <NSApplicationDelegate, NSTableViewDelegate>

/**
 * Other
 */
@property (readonly) MBDataManager *dataManager;
@property (readonly) MBActorProfileWindowController *actorProfileController;
@property (readonly) MBImportWindowController *importController;
@property (readonly) MBPreferencesWindowController *preferencesController;
@property (readonly) MBScreencapsWindowController *screencapsController;

/**
 * Main Window
 */
@property (assign) IBOutlet NSWindow *window;
@property (assign) IBOutlet NSTextField *movieInfoTxt;

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
 * Find
 */
@property (assign) IBOutlet NSWindow *findWindow;
@property (assign) IBOutlet NSPopUpButton *findTypeBtn;
@property (assign) IBOutlet NSTextField *findTxt;
@property (assign) IBOutlet NSButton *findBtn;
@property (assign) IBOutlet NSButton *findTitleBtn;
@property (assign) IBOutlet NSButton *findFileNameBtn;
@property (assign) IBOutlet NSButton *findDescBtn;

+ (MBAppDelegate *)sharedInstance;

/**
 * Used by the MBMovieView to toggle whether a movie is hidden.
 */
- (void)doActionMovieHide:(MBMovie *)mbmovie withView:(NSView *)view;
- (void)doActionMovieUnhide:(MBMovie *)mbmovie withView:(NSView *)view;

/**
 * Display a modal sheet with the actor profile.
 */
- (void)showActor:(MBPerson *)person;

/**
 * Used to populate the "count" badge for each genre in the genre table.
 */
- (NSUInteger)movieCountForGenre:(MBGenre *)genre;

@end
