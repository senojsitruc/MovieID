//
//  MBRenameWindowController.m
//  MovieBrowse
//
//  Created by Curtis Jones on 2012.12.22.
//  Copyright (c) 2012 Curtis Jones. All rights reserved.
//

#import "MBRenameWindowController.h"

@interface MBRenameWindowController ()
{
	void (^mHandler)(NSString*);
}
@end

@implementation MBRenameWindowController

/**
 *
 *
 */
- (id)init
{
	self = [super initWithWindowNibName:@"MBRenameWindowController"];
	
	if (self) {
		(void)self.window;
	}
	
	return self;
}

/**
 *
 *
 */
- (void)windowDidLoad
{
	[super windowDidLoad];
}





#pragma mark - Accessors

/**
 *
 *
 */
- (void)showInWindow:(NSWindow *)parentWindow withName:(NSString *)name handler:(void (^)(NSString *))handler
{
	mHandler = [handler copy];
	_renameTxt.stringValue = name ? name : @"";
	[NSApp beginSheet:self.window modalForWindow:parentWindow modalDelegate:nil didEndSelector:nil contextInfo:nil];
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
	[self hide];
}

/**
 *
 *
 */
- (IBAction)doActionRename:(id)sender
{
	[self hide];
	if (mHandler)
		mHandler(_renameTxt.stringValue);
}

@end
