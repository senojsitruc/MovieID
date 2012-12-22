//
//  MBGenreCellView.m
//  MovieBrowse
//
//  Created by Curtis Jones on 2012.12.15.
//  Copyright (c) 2012 Curtis Jones. All rights reserved.
//

#import "MBGenreCellView.h"
#import "MBGenreBadgeView.h"
#import "MBAppDelegate.h"
#import "MBDataManager.h"
#import "MBGenre.h"
#import "MBRenameWindowController.h"

@interface MBGenreCellView ()
{
	MBGenre *mGenre;
}
@end

@implementation MBGenreCellView

/**
 *
 *
 */
- (id)objectValue
{
	_badgeView.number = [(MBAppDelegate *)[NSApp delegate] movieCountForGenre:(mGenre = [super objectValue])];
	return mGenre;
}

/**
 *
 *
 */
- (void)rightMouseDown:(NSEvent *)theEvent
{
	NSLog(@"%s.. %@", __PRETTY_FUNCTION__, mGenre);
	[self showMenu];
}

/**
 *
 *
 */
- (void)showMenu
{
	NSMenu *menu = [[NSMenu alloc] initWithTitle:@"Genre Menu"];
	NSMenuItem *genreItem = [menu addItemWithTitle:mGenre.name action:nil keyEquivalent:@""];
	NSMenuItem *renameItem = [menu addItemWithTitle:@"  Rename" action:@selector(doActionRename:) keyEquivalent:@""];
	NSMenuItem *deleteItem = [menu addItemWithTitle:@"  Delete" action:@selector(doActionDelete:) keyEquivalent:@""];
	
	genreItem.target = nil;
	renameItem.target = self;
	deleteItem.target = self;
	
	NSEvent *event = [NSEvent mouseEventWithType:NSLeftMouseUp
																			location:[self.window.contentView convertPoint:self.frame.origin fromView:self.superview]
																 modifierFlags:0
																		 timestamp:NSTimeIntervalSince1970
																	windowNumber:self.window.windowNumber
																			 context:nil
																	 eventNumber:0
																		clickCount:0
																			pressure:0.1];
	
	[NSMenu popUpContextMenu:menu withEvent:event forView:self.window.contentView];
}

/**
 *
 *
 */
- (void)doActionRename:(id)sender
{
	MBAppDelegate *appDelegate = (MBAppDelegate *)[NSApp delegate];
	MBDataManager *dataManager = appDelegate.dataManager;
	
	[appDelegate.renameController showInWindow:self.window withName:mGenre.name handler:^ (NSString *newName) {
		if (newName.length)
			[dataManager genre:mGenre updateWithName:newName];
	}];
}

/**
 *
 *
 */
- (void)doActionDelete:(id)sender
{
	MBAppDelegate *appDelegate = (MBAppDelegate *)[NSApp delegate];
	MBDataManager *dataManager = appDelegate.dataManager;
	
	[dataManager genreDelete:mGenre];
}

@end
