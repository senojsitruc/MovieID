//
//  MBMovieEditWindowController.h
//  MovieBrowse
//
//  Created by Curtis Jones on 2012.12.28.
//  Copyright (c) 2012 Curtis Jones. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class MBMovie;

@interface MBMovieEditWindowController : NSWindowController <NSTableViewDelegate, NSTableViewDataSource>

@property (readwrite, assign, nonatomic) IBOutlet NSImageView *posterImg;
@property (readwrite, assign, nonatomic) IBOutlet NSProgressIndicator *posterPrg;
@property (readwrite, assign, nonatomic) IBOutlet NSTextField *titleTxt;
@property (readwrite, assign, nonatomic) IBOutlet NSTextField *pathTxt;
@property (readwrite, assign, nonatomic) IBOutlet NSTextField *yearTxt;
@property (readwrite, assign, nonatomic) IBOutlet NSTextField *ratingTxt;
@property (readwrite, assign, nonatomic) IBOutlet NSPopUpButton *durationHrBtn;
@property (readwrite, assign, nonatomic) IBOutlet NSPopUpButton *durationMinBtn;
@property (readwrite, assign, nonatomic) IBOutlet NSPopUpButton *durationSecBtn;
@property (readwrite, assign, nonatomic) IBOutlet NSPopUpButton *scoreBtn;
@property (readwrite, assign, nonatomic) IBOutlet NSTextField *descriptionTxt;

@property (readwrite, assign, nonatomic) IBOutlet NSTableView *genreTbl;
@property (readwrite, assign, nonatomic) IBOutlet NSButton *genreAddBtn;
@property (readwrite, assign, nonatomic) IBOutlet NSButton *genreDelBtn;
@property (readwrite, assign, nonatomic) IBOutlet NSArrayController *genreArrayController;

@property (readwrite, assign, nonatomic) IBOutlet NSTableView *languageTbl;
@property (readwrite, assign, nonatomic) IBOutlet NSButton *languageAddBtn;
@property (readwrite, assign, nonatomic) IBOutlet NSButton *languageDelBtn;
@property (readwrite, assign, nonatomic) IBOutlet NSArrayController *languageArrayController;

@property (readwrite, assign, nonatomic) IBOutlet NSTableView *actorTbl;
@property (readwrite, assign, nonatomic) IBOutlet NSButton *actorAddBtn;
@property (readwrite, assign, nonatomic) IBOutlet NSButton *actorDelBtn;
@property (readwrite, assign, nonatomic) IBOutlet NSArrayController *actorArrayController;

@property (readwrite, assign, nonatomic) IBOutlet NSScrollView *postersView;

/**
 *
 */
- (void)showInWindow:(NSWindow *)window forMovie:(MBMovie *)movie;

@end
