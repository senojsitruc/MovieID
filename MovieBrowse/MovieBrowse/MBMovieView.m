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

@implementation MBMovieView

/**
 *
 *
 */
- (IBAction)doActionHide:(id)sender
{
	NSTableCellView *parent = (NSTableCellView *)self.superview;
	
	if (![parent isKindOfClass:[NSTableCellView class]])
		return;
	
	MBMovie *mbmovie = (MBMovie *)parent.objectValue;
	BOOL hidden = mbmovie.hidden.boolValue;
	
	if (hidden) {
		((NSMenuItem *)sender).state = NSOffState;
		[[MBAppDelegate sharedInstance] doActionMovieUnhide:mbmovie withView:parent];
	}
	else {
		((NSMenuItem *)sender).state = NSOnState;
		[[MBAppDelegate sharedInstance] doActionMovieHide:mbmovie withView:parent];
	}
}

/**
 *
 *
 */
- (IBAction)doActionRemove:(id)sender
{
	NSTableCellView *parent = (NSTableCellView *)self.superview;
	
	if (![parent isKindOfClass:[NSTableCellView class]])
		return;
	
	MBDataManager *dataManager = [MBAppDelegate sharedInstance].dataManager;
	MBMovie *mbmovie = (MBMovie *)parent.objectValue;
	
	[dataManager deleteMovie:mbmovie];
}

/**
 *
 *
 */
- (IBAction)doActionSearch:(id)sender
{
	NSTableCellView *parent = (NSTableCellView *)self.superview;
	
	if (![parent isKindOfClass:[NSTableCellView class]])
		return;
	
	[[MBAppDelegate sharedInstance] doActionSearchShow:parent.objectValue];
}

/**
 *
 *
 */
- (IBAction)doActionLinkToTMDb:(id)sender
{
	MBMovie *mbmovie = nil;
	
	// find the parent NSTableCellView and get the object value (MBMovie) from it
	{
		NSView *parent = self.superview;
		
		while (parent && ![parent isKindOfClass:[NSTableCellView class]])
			parent = parent.superview;
		
		if (parent)
			mbmovie = (MBMovie *)((NSTableCellView *)parent).objectValue;
		
		if (!mbmovie) {
			NSLog(@"%s.. could not find the associated MBMovie", __PRETTY_FUNCTION__);
			return;
		}
	}
	
	[[MBAppDelegate sharedInstance] doActionLinkToTMDb:mbmovie];
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

@end
