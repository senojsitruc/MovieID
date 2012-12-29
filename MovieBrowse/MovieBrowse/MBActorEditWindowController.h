//
//  MBActorEditWindowController.h
//  MovieBrowse
//
//  Created by Curtis Jones on 2012.12.29.
//  Copyright (c) 2012 Curtis Jones. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class MBPerson;

@interface MBActorEditWindowController : NSWindowController

@property (readwrite, assign, nonatomic) IBOutlet NSImageView *posterImg;
@property (readwrite, assign, nonatomic) IBOutlet NSProgressIndicator *posterPrg;
@property (readwrite, assign, nonatomic) IBOutlet NSScrollView *postersView;

@property (readwrite, assign, nonatomic) IBOutlet NSTextField *nameTxt;
@property (readwrite, assign, nonatomic) IBOutlet NSTextField *webTxt;
@property (readwrite, assign, nonatomic) IBOutlet NSTextField *imdbTxt;
@property (readwrite, assign, nonatomic) IBOutlet NSTextField *tmdbTxt;
@property (readwrite, assign, nonatomic) IBOutlet NSTextField *rtidTxt;

@property (readwrite, assign, nonatomic) IBOutlet NSPopUpButton *dobYearBtn;
@property (readwrite, assign, nonatomic) IBOutlet NSPopUpButton *dobMonthBtn;
@property (readwrite, assign, nonatomic) IBOutlet NSPopUpButton *dobDayBtn;

@property (readwrite, assign, nonatomic) IBOutlet NSPopUpButton *dodYearBtn;
@property (readwrite, assign, nonatomic) IBOutlet NSPopUpButton *dodMonthBtn;
@property (readwrite, assign, nonatomic) IBOutlet NSPopUpButton *dodDayBtn;

@property (readwrite, assign, nonatomic) IBOutlet NSTextField *bioTxt;

/**
 *
 */
- (void)showInWindow:(NSWindow *)parentWindow forPerson:(MBPerson *)person;

@end
