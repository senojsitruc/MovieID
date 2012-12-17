//
//  MBActorMovieView.m
//  MovieBrowse
//
//  Created by Curtis Jones on 2012.10.20.
//  Copyright (c) 2012 Curtis Jones. All rights reserved.
//

#import "MBActorMovieView.h"
#import "MBMovie.h"
#import "MBPerson.h"
#import "MBAppDelegate.h"
#import "MBDataManager.h"
#import "MBImageCache.h"
#import "NSThread+Additions.h"
#import "MBDownloadQueue.h"

@interface MBActorMovieView ()
{
	MBPerson *mPerson;
	NSUInteger mTransId;
}
@end

@implementation MBActorMovieView

- (void)setPerson:(MBPerson *)mbperson
{
	NSUInteger transId = ++mTransId;
	
	if (mPerson == mbperson)
		return;
	
	if (nil == (mPerson = mbperson))
		return;
	
	self.documentView = nil;
	
	CGRect myFrame = self.frame;
	NSView *documentView = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, 0, 0)];
	
	[[MBDownloadQueue sharedInstance] dispatchBeg:^{
		__block CGFloat hoffset = 0;
		
		[[MBAppDelegate sharedInstance].dataManager enumerateMoviesForPerson:mPerson handler:^ (MBMovie *mbmovie, BOOL *stop) {
			if (!mbmovie.posterId)
				return;
			
			if (transId != mTransId) {
				*stop = TRUE;
				return;
			}
			
			NSImage *image = [[MBImageCache sharedInstance] cachedImageWithId:mbmovie.posterId andHeight:myFrame.size.height];
			
			if (!image) {
				if (nil == (image = [[MBImageCache sharedInstance] movieImageWithId:mbmovie.posterId width:0 height:myFrame.size.height]))
					return;
				
				CGFloat width = (NSUInteger)(image.size.width * (myFrame.size.height / image.size.height));
				image.size = NSMakeSize(width, myFrame.size.height);
				[[MBImageCache sharedInstance] cacheImage:image withId:mbmovie.posterId andHeight:myFrame.size.height];
			}
			
			NSImageView *imageView = [[NSImageView alloc] initWithFrame:NSMakeRect(hoffset, 0, image.size.width, image.size.height)];
			imageView.image = image;
			imageView.toolTip = [NSString stringWithFormat:@"%@ (%@)", mbmovie.title, mbmovie.year];
			
			[documentView addSubview:imageView];
			hoffset += image.size.width;
		}];
		
		documentView.frame = NSMakeRect(0, 0, hoffset, myFrame.size.height);
		
		if (transId != mTransId)
			return;
		
		[[NSThread mainThread] performBlock:^{
			if (transId == mTransId)
				self.documentView = documentView;
		}];
	}];
}

@end
