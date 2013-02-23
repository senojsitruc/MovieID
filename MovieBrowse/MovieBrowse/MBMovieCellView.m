//
//  MBMovieCellView.m
//  MovieBrowse
//
//  Created by Curtis Jones on 2012.10.17.
//  Copyright (c) 2012 Curtis Jones. All rights reserved.
//

#import "MBMovieCellView.h"
#import "MBMovieCastView.h"
#import "MBImageCache.h"
#import "MBMovie.h"
#import "MBAppDelegate.h"
#import "NSThread+Additions.h"
#import "MBDownloadQueue.h"

static NSImage *gMissingImg;

@interface MBMovieCellView ()
{
	MBMovie *mMovie;
	NSUInteger mTransId;
}
@end

@implementation MBMovieCellView

+ (void)load
{
	@autoreleasepool {
		NSString *path = [[NSBundle mainBundle] pathForResource:@"MissingMovie" ofType:@"png"];
		if (path) gMissingImg = [[NSImage alloc] initWithContentsOfFile:path];
	}
}

- (id)objectValue
{
	id objVal = [super objectValue];
	
	if (objVal != mMovie) {
		NSUInteger transId = ++mTransId;
		
		mMovie = objVal;
		self.castView.movie = mMovie;
		
		// restore the state of the "hide" menu item
		self.hideMenuItem.state = mMovie.hidden.boolValue ? NSOnState : NSOffState;
		
		// movie image
		{
			NSString *imageId = mMovie.posterId;
			CGFloat height = self.movieImg.frame.size.height;
			
			// if there is no image id for this movie, use the "missing" image
			if (!imageId.length) {
				NSImage *image = [[MBImageCache sharedInstance] cachedImageWithId:@"missing-movie" andHeight:height];
				
				if (!image) {
					image = [gMissingImg copy];
					image.size = NSMakeSize((NSUInteger)(image.size.width * (height / image.size.height)), height);
					[[MBImageCache sharedInstance] cacheImage:image withId:@"missing-movie" andHeight:height];
				}
				self.movieImg.image = image;
			}
			
			// there is an image id for this movie, so try to load it
			else {
				self.movieImg.image = nil;
				
				[[MBDownloadQueue sharedInstance] dispatchBeg:^{
					NSImage *_image = [[MBImageCache sharedInstance] movieImageWithId:imageId width:0 height:height];
					
					if (!_image)
						return;
					
					_image.size = NSMakeSize((NSUInteger)(_image.size.width * (height / _image.size.height)), height);
					
					if (transId != mTransId)
						return;
					
					[[NSThread mainThread] performBlock:^{
						if (transId == mTransId)
							self.movieImg.image = _image;
					}];
				}];
			}
		}
	}
	
	return objVal;
}

@end
