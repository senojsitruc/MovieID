//
//  MBActorProfileWindowController.m
//  MovieBrowse
//
//  Created by Curtis Jones on 2012.12.20.
//  Copyright (c) 2012 Curtis Jones. All rights reserved.
//

#import "MBActorProfileWindowController.h"
#import "MBActorMovieView.h"
#import "MBDownloadQueue.h"
#import "MBImageCache.h"
#import "MBPerson.h"
#import "NSThread+Additions.h"

@interface MBActorProfileWindowController ()
{
	NSUInteger mTransactionId;
	MBPerson *mPerson;
}
@end

@implementation MBActorProfileWindowController

/**
 *
 *
 */
- (id)init
{
	self = [super initWithWindowNibName:@"MBActorProfileWindowController"];
	
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
	
	_descScroll.frame = NSMakeRect(423, 49, 425, 400);
	[self.window.contentView addSubview:_descScroll];
}




#pragma mark - Accessors

/**
 *
 *
 */
- (void)showInWindow:(NSWindow *)parentWindow forPerson:(MBPerson *)mbperson
{
	if (mbperson != mPerson) {
		NSUInteger transactionId = ++mTransactionId;
		
		mPerson = mbperson;
		_nameTxt.stringValue = mbperson.name ? mbperson.name : @"";
		_infoTxt.stringValue = mbperson.info ? mbperson.info : @"";
		_moviesView.person = mbperson;
		_actorImg.image = nil;
		
		[_descTxt setEditable:TRUE];
		[_descTxt insertText:(mbperson.bio ? [[NSAttributedString alloc] initWithString:mbperson.bio] : @"Nothing!")];
		[_descTxt setEditable:FALSE];
		
		// set the actor's bio text
		if (mbperson.bio)
			[_descTxt.textStorage replaceCharactersInRange:NSMakeRange(0, _descTxt.textStorage.length) withString:mbperson.bio];
		else
			[_descTxt.textStorage replaceCharactersInRange:NSMakeRange(0, _descTxt.textStorage.length) withString:@""];
		
		// scroll to the top
		_descScroll.verticalScroller.floatValue = 0;
		[_descScroll.contentView scrollToPoint:NSMakePoint(0,0)];
		
		// animate the indefinite progress indicator
		[_imagePrg startAnimation:self];
		
		NSSize imageSize = _actorImg.frame.size;
		
		// retrieve the actor's image and update the ui when we're done; but don't update the ui if the
		// user has moved on to another actor between the time that we initiated the download and when
		// the image actually became avaliable for use.
		[[MBDownloadQueue sharedInstance] dispatchBeg:^{
			NSImage *image = [[MBImageCache sharedInstance] actorImageWithId:mbperson.imageId width:imageSize.width height:imageSize.height];
			
			if (transactionId != mTransactionId)
				return;
			
			[[NSThread mainThread] performBlock:^{
				[_imagePrg stopAnimation:self];
				
				if (transactionId != mTransactionId)
					return;
				
				_actorImg.image = image;
			}];
		}];
	}
	
	[NSApp beginSheet:self.window modalForWindow:parentWindow modalDelegate:nil didEndSelector:nil contextInfo:nil];
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

@end
