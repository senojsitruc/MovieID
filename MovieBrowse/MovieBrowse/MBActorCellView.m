//
//  MBActorCellView.m
//  MovieBrowse
//
//  Created by Curtis Jones on 2012.10.20.
//  Copyright (c) 2012 Curtis Jones. All rights reserved.
//

#import "MBActorCellView.h"
#import "MBPerson.h"
#import "MBImageCache.h"
#import "MBAppDelegate.h"
#import "NSThread+Additions.h"
#import "MBDownloadQueue.h"

static NSImage *gMissingImg;

@interface MBActorCellView ()
{
	MBPerson *mPerson;
	NSUInteger mTransId;
}
@end

@implementation MBActorCellView

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
	
	if (objVal != mPerson) {
		NSUInteger transId = ++mTransId;
		
		mPerson = objVal;
		
		// actor image
		{
			NSString *imageId = mPerson.imageId;
			CGFloat width = self.actorImg.frame.size.width;
			CGFloat height = self.actorImg.frame.size.height;
			NSImage *image = [[MBImageCache sharedInstance] cachedImageWithId:imageId andHeight:height];
			
			if (!image && !imageId.length) {
				if (nil == (image = [[MBImageCache sharedInstance] cachedImageWithId:@"missing-actor" andHeight:height])) {
					image = [gMissingImg copy];
					image.size = NSMakeSize((NSUInteger)(image.size.width * (height / image.size.height)), height);
					[[MBImageCache sharedInstance] cacheImage:image withId:@"missing-actor" andHeight:height];
				}
			}
			
			if (!image) {
				self.actorImg.image = nil;
				
				[[MBDownloadQueue sharedInstance] dispatchBeg:^{
					NSImage *image = [[MBImageCache sharedInstance] actorImageWithId:imageId width:width height:height];
					
					if (!image)
						return;
					
					image.size = NSMakeSize((NSUInteger)(image.size.width * (height / image.size.height)), height);
					[[MBImageCache sharedInstance] cacheImage:image withId:imageId andHeight:height];
					
					if (transId != mTransId)
						return;
					
					[[NSThread mainThread] performBlock:^{
						if (transId == mTransId)
							self.actorImg.image = image;
					}];
				}];
			}
			else
				self.actorImg.image = image;
		}
	}
	
	return objVal;
}

@end
