//
//  MBPreferencesWindowController.m
//  MovieBrowse
//
//  Created by Curtis Jones on 2012.12.20.
//  Copyright (c) 2012 Curtis Jones. All rights reserved.
//

#import "MBPreferencesWindowController.h"
#import "MBImageCache.h"

@interface MBPreferencesWindowController ()
@end

@implementation MBPreferencesWindowController

- (id)init
{
	self = [super initWithWindowNibName:@"MBPreferencesWindowController"];
	
	if (self) {
		(void)self.window;
	}
	
	return self;
}

- (void)windowDidLoad
{
	[super windowDidLoad];
}





#pragma mark - Accessors

/**
 *
 *
 */
- (void)showInWindow:(NSWindow *)parentWindow
{
	[NSApp beginSheet:self.window modalForWindow:parentWindow modalDelegate:self didEndSelector:nil contextInfo:nil];
}

/**
 *
 *
 */
- (void)hide
{
	[NSApp endSheet:self.window];
	[self.window orderOut:nil];
}





#pragma mark - Actions

/**
 *
 *
 */
- (IBAction)doActionClose:(id)sender
{
	[NSApp endSheet:self.window];
	[self.window orderOut:sender];
}

/**
 * This function intentionally does nothing when running in debug mode, because I don't want to
 * accidentally delete the master image set.
 */
- (IBAction)doActionClearCache:(id)sender
{
	[[MBImageCache sharedInstance] clearAll];
}

@end
