//
//  MBGenreView.m
//  MovieBrowse
//
//  Created by Curtis Jones on 2012.09.07.
//  Copyright (c) 2012 Curtis Jones. All rights reserved.
//

#import "MBGenreView.h"
#import "MBAppDelegate.h"

@implementation MBGenreView

@synthesize selected = mSelected;

- (id)initWithFrame:(NSRect)frame
{
	self = [super initWithFrame:frame];
	
	if (self) {
		// Initialization code here.
	}
	
	return self;
}

- (void)drawRect:(NSRect)dirtyRect
{
	if (mSelected) {
		[[NSColor lightGrayColor] set];
		NSRectFill([self bounds]);
	}
}

- (NSMenu *)menuForEvent:(NSEvent *)theEvent
{
	NSLog(@"%s", __PRETTY_FUNCTION__);
	
	NSMenu *menu = [[NSMenu alloc] initWithTitle:@"Genre Menu"];
	[menu addItemWithTitle:@"Rename" action:@selector(doActionRename:) keyEquivalent:@""];
	
	return menu;
}

- (void)doActionRename:(id)sender
{
	
}

- (void)mouseDown:(NSEvent *)theEvent
{
	/*
	MBAppDelegate *appDelegate = [MBAppDelegate sharedInstance];
	NSCollectionView *collectionView = appDelegate.genresCollectionView;
	
	if (mSelected && (theEvent.modifierFlags & NSCommandKeyMask))
		collectionView.selectionIndexes = nil;
	else
		[super mouseDown:theEvent];
	*/
}

@end
