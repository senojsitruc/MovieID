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
		[[MBAppDelegate sharedInstance] movie:mbmovie UnhideWithView:self.superview];
	}
	else {
		((NSMenuItem *)sender).state = NSOnState;
		[[MBAppDelegate sharedInstance] movie:mbmovie hideWithView:self.superview];
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
	
}

/**
 *
 *
 */
- (IBAction)doActionScreencaps:(id)sender
{
	[((MBAppDelegate *)[NSApp delegate]) showScreencapsForMovie:self.movie];
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
