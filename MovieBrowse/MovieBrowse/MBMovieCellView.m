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
	NSString *path = [[NSBundle mainBundle] pathForResource:@"MissingMovie" ofType:@"png"];
	
	if (path) {
		NSData *data = [NSData dataWithContentsOfFile:path];
		
		if (data)
			gMissingImg = [[NSImage alloc] initWithData:data];
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
			NSImage *image = [[MBImageCache sharedInstance] cachedImageWithId:imageId andHeight:height];
			
			if (!image && !imageId.length) {
				image = [[MBImageCache sharedInstance] cachedImageWithId:@"missing-movie" andHeight:height];
				
				if (!image) {
					image = [gMissingImg copy];
					image.size = NSMakeSize((NSUInteger)(image.size.width * (height / image.size.height)), height);
					[[MBImageCache sharedInstance] cacheImage:image withId:@"missing-movie" andHeight:height];
				}
			}
			
			if (!image) {
				self.movieImg.image = nil;
				
				[[MBDownloadQueue sharedInstance] dispatchBeg:^{
					NSImage *image = [[MBImageCache sharedInstance] movieImageWithId:imageId];
					
					if (!image)
						return;
					
					image.size = NSMakeSize((NSUInteger)(image.size.width * (height / image.size.height)), height);
					[[MBImageCache sharedInstance] cacheImage:image withId:imageId andHeight:height];
					
					if (transId != mTransId)
						return;
					
					[[NSThread mainThread] performBlock:^{
						if (transId == mTransId)
							self.movieImg.image = image;
					}];
				}];
			}
			else
				self.movieImg.image = image;
		}
	}
	
	return objVal;
}

@end
