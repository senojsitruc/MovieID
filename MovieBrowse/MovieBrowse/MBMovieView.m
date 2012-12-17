//
//  MBMovieView.m
//  MovieBrowse
//
//  Created by Curtis Jones on 2012.09.09.
//  Copyright (c) 2012 Curtis Jones. All rights reserved.
//

#import "MBMovieView.h"
#import "MBAppDelegate.h"
#import "MBDataManager.h"
#import "MBMovie.h"
#import "MBScreencapsWindowController.h"

@implementation MBMovieView

/**
 *
 *
 */
- (IBAction)doActionHide:(id)sender
{
	MBMovie *mbmovie = self.movie;
	BOOL hidden = mbmovie.hidden.boolValue;
	
	if (hidden) {
		((NSMenuItem *)sender).state = NSOffState;
		[[MBAppDelegate sharedInstance] doActionMovieUnhide:mbmovie withView:self.superview];
	}
	else {
		((NSMenuItem *)sender).state = NSOnState;
		[[MBAppDelegate sharedInstance] doActionMovieHide:mbmovie withView:self.superview];
	}
}

/**
 *
 *
 */
- (IBAction)doActionRemove:(id)sender
{
	MBMovie *mbmovie = self.movie;
	MBDataManager *dataManager = [MBAppDelegate sharedInstance].dataManager;
	[dataManager deleteMovie:mbmovie];
}

/**
 *
 *
 */
- (IBAction)doActionSearch:(id)sender
{
	[[MBAppDelegate sharedInstance] doActionSearchShow:self.movie];
}

/**
 *
 *
 */
- (IBAction)doActionScreencaps:(id)sender
{
	MBAppDelegate *appDelegate = (MBAppDelegate *)[NSApp delegate];
	[appDelegate.screencapsController showInWindow:appDelegate.window forMovie:self.movie];
}

/**
 *
 *
 */
- (IBAction)doActionLinkToTMDb:(id)sender
{
	[[MBAppDelegate sharedInstance] doActionLinkToTMDb:self.movie];
}

/**
 *
 *
 */
- (IBAction)doActionLinkToRT:(id)sender
{
	
}

/**
 *
 *
 */
- (IBAction)doActionLinkToIMDb:(id)sender
{
	
}

/**
 *
 *
 */
- (IBAction)doActionRename:(id)sender
{
	
}

/*
- (void)mouseDown:(NSEvent *)theEvent
{
	MBAppDelegate *appDelegate = [MBAppDelegate sharedInstance];
	NSCollectionView *collectionView = appDelegate.moviesCollectionView;
	
	if (mSelected && (theEvent.modifierFlags & NSCommandKeyMask))
		collectionView.selectionIndexes = nil;
	else
		[super mouseDown:theEvent];
}
*/




#pragma mark - Private

/**
 *
 *
 */
- (MBMovie *)movie
{
	NSTableCellView *parent = (NSTableCellView *)self.superview;
	
	if (![parent isKindOfClass:NSTableCellView.class])
		return nil;
	
	MBMovie *mbmovie = (MBMovie *)parent.objectValue;
	
	if (![mbmovie isKindOfClass:MBMovie.class])
		return nil;
	
	return mbmovie;
}

@end
