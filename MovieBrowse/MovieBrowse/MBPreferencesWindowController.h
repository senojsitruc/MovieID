//
//  MBPreferencesWindowController.h
//  MovieBrowse
//
//  Created by Curtis Jones on 2012.12.20.
//  Copyright (c) 2012 Curtis Jones. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface MBPreferencesWindowController : NSWindowController

@property (readwrite, assign, nonatomic) IBOutlet NSButton *sourcesAddBtn;
@property (readwrite, assign, nonatomic) IBOutlet NSButton *sourcesDelBtn;

/**
 * If you have to ask....
 */
- (void)showInWindow:(NSWindow *)parentWindow;

@end
