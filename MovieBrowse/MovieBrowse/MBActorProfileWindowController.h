//
//  MBActorProfileWindowController.h
//  MovieBrowse
//
//  Created by Curtis Jones on 2012.12.20.
//  Copyright (c) 2012 Curtis Jones. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class MBPerson;
@class MBActorMovieView;

@interface MBActorProfileWindowController : NSWindowController

@property (assign) IBOutlet NSImageView *actorImg;
@property (assign) IBOutlet NSTextField *nameTxt;
@property (assign) IBOutlet NSTextField *infoTxt;
@property (assign) IBOutlet NSTextView *descTxt;
@property (assign) IBOutlet NSScrollView *descScroll;
@property (assign) IBOutlet MBActorMovieView *moviesView;
@property (assign) IBOutlet NSProgressIndicator *imagePrg;

/**
 *
 */
- (void)showInWindow:(NSWindow *)parentWindow forPerson:(MBPerson *)person;

@end
