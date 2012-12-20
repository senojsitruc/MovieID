//
//  MBImportWindowController.h
//  MovieBrowse
//
//  Created by Curtis Jones on 2012.10.24.
//  Copyright (c) 2012 Curtis Jones. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface MBImportWindowController : NSWindowController

@property (assign) IBOutlet NSView *mainView;
@property (assign) IBOutlet NSTextField *sourcePathTxt;
@property (assign) IBOutlet NSTextField *sourceInfo1Txt;
@property (assign) IBOutlet NSTextField *sourceInfo2Txt;
@property (assign) IBOutlet NSTextField *searchQueryTxt;
@property (assign) IBOutlet NSPopUpButton *searchMethodBtn;
@property (assign) IBOutlet NSButton *searchBtn;
@property (assign) IBOutlet NSTableView *searchResultTbl;
@property (assign) IBOutlet NSButton *prevBtn;
@property (assign) IBOutlet NSButton *nextBtn;
@property (assign) IBOutlet NSButton *applyBtn;
@property (assign) IBOutlet NSButton *closeBtn;

@property (assign) IBOutlet NSArrayController *resultsController;
@property (readwrite, strong) NSMutableArray *resultsArray;
@property (readwrite, strong) NSIndexSet *resultsSelection;

/**
 *
 */
- (void)showInWindow:(NSWindow *)window;

/**
 *
 */
- (void)scanSources;

@end
