//
//  MBPreferencesWindowController.m
//  MovieBrowse
//
//  Created by Curtis Jones on 2012.12.20.
//  Copyright (c) 2012 Curtis Jones. All rights reserved.
//

#import "MBPreferencesWindowController.h"
#import "MBAppDelegate.h"
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
	[self hide];
}

/**
 * This function intentionally does nothing when running in debug mode, because I don't want to
 * accidentally delete the master image set.
 */
- (IBAction)doActionClearCache:(id)sender
{
	[[MBImageCache sharedInstance] clearAll];
}

/**
 *
 *
 */
- (IBAction)doActionSourcesAdd:(id)sender
{
	NSOpenPanel *panel = [NSOpenPanel openPanel];
	
	panel.canChooseFiles = FALSE;
	panel.canChooseDirectories = TRUE;
	panel.resolvesAliases = TRUE;
	panel.allowsMultipleSelection = TRUE;
	panel.canCreateDirectories = FALSE;
	panel.prompt = @"Choose";
	panel.message = @"Select a source folder.";
	panel.delegate = self;
	
	[panel beginSheetModalForWindow:self.window completionHandler:^ (NSInteger result) {
		if (NSFileHandlingPanelOKButton == result) {
			NSMutableArray *sources = [[NSUserDefaults standardUserDefaults] mutableArrayValueForKey:MBDefaultsKeySources];
			[panel.URLs enumerateObjectsUsingBlock:^ (id urlObj, NSUInteger urlNdx, BOOL *urlStop) {
				[sources addObject:@{MBDefaultsKeySourcesPath:((NSURL *)urlObj).path}];
			}];
			[_sourcesTbl reloadData];
		}
	}];
}

/**
 *
 *
 */
- (IBAction)doActionSourcesDel:(id)sender
{
	NSMutableArray *sources = [[NSUserDefaults standardUserDefaults] mutableArrayValueForKey:MBDefaultsKeySources];
	NSInteger row = _sourcesTbl.selectedRow;
	
	if (row < 0 || row >= sources.count) {
		NSBeep();
		return;
	}
	
	NSDictionary *source = sources[row];
	NSLog(@"%s.. deleting source [%@]", __PRETTY_FUNCTION__, source[MBDefaultsKeySourcesPath]);
	[sources removeObjectAtIndex:row];
	[_sourcesTbl reloadData];
	
	if (!sources.count)
		[_sourcesDelBtn setEnabled:FALSE];
	else {
		if (row >= sources.count)
			row = sources.count - 1;
		[_sourcesTbl selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:FALSE];
	}
}





#pragma mark - NSOpenSavePanelDelegate

/**
 * Disable directories that are already included in the sources list.
 *
 */
- (BOOL)panel:(id)sender shouldEnableURL:(NSURL *)url
{
	NSArray *sources = [[NSUserDefaults standardUserDefaults] arrayForKey:MBDefaultsKeySources];
	NSString *path = url.path;
	__block BOOL found = FALSE;
	
	[sources enumerateObjectsUsingBlock:^ (id sourceObj, NSUInteger sourceNdx, BOOL *sourceStop) {
		if ([((NSDictionary *)sourceObj)[MBDefaultsKeySourcesPath] isEqualToString:path]) {
			found = TRUE;
			*sourceStop = TRUE;
		}
	}];
	
	return !found;
}





#pragma mark - NSTableViewDelegate

/**
 * Enable/disale the delete button based on the row selection.
 *
 */
- (void)tableViewSelectionDidChange:(NSNotification *)notification
{
	NSTableView *tableView = notification.object;
	NSArray *sources = [[NSUserDefaults standardUserDefaults] arrayForKey:MBDefaultsKeySources];
	NSInteger row = tableView.selectedRow;
	
	[_sourcesDelBtn setEnabled:(row >= 0 && row < sources.count)];
}

@end
