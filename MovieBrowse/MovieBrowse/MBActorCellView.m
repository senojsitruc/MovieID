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
	@autoreleasepool {
		NSString *path = [[NSBundle mainBundle] pathForResource:@"MissingMovie" ofType:@"png"];
		
		if (path) {
			NSData *data = [NSData dataWithContentsOfFile:path];
			
			if (data)
				gMissingImg = [[NSImage alloc] initWithData:data];
		}
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
			
			if (!imageId.length) {
				NSImage *image = [[MBImageCache sharedInstance] cachedImageWithId:@"missing-actor" andHeight:height];
				
				if (!image) {
					image = [gMissingImg copy];
					image.size = NSMakeSize((NSUInteger)(image.size.width * (height / image.size.height)), height);
					[[MBImageCache sharedInstance] cacheImage:image withId:@"missing-actor" andHeight:height];
				}
				
				self.actorImg.image = image;
			}
			else {
				self.actorImg.image = nil;
				
				[[MBDownloadQueue sharedInstance] dispatchBeg:^{
					NSImage *_image = [[MBImageCache sharedInstance] actorImageWithId:imageId width:width height:height];
					
					if (!_image)
						return;
					
					CGSize imageSize = _image.size;
					
					if (INFINITY == imageSize.width || INFINITY == imageSize.height) {
						NSLog(@"%s.. skipping person image name=%@, id=%@ because size = %@", __PRETTY_FUNCTION__, mPerson.name, mPerson.imageId, NSStringFromSize(imageSize));
						return;
					}
					
					_image.size = NSMakeSize((NSUInteger)(imageSize.width * (height / imageSize.height)), height);
					
					if (transId != mTransId)
						return;
					
					[[NSThread mainThread] performBlock:^{
						if (transId == mTransId)
							self.actorImg.image = _image;
					}];
				}];
			}
		}
	}
	
	return objVal;
}

@end
