//
//  MBMovieCastView.m
//  MovieBrowse
//
//  Created by Curtis Jones on 2012.10.17.
//  Copyright (c) 2012 Curtis Jones. All rights reserved.
//

#import "MBMovieCastView.h"
#import "MBMovie.h"
#import "MBPerson.h"
#import "MBAppDelegate.h"
#import "MBDataManager.h"
#import "MBImageCache.h"
#import "MBImageView.h"
#import "NSThread+Additions.h"
#import "MBDownloadQueue.h"
#import <objc/runtime.h>

static NSMutableDictionary *gActorViews;

@interface MBMovieCastView ()
{
	MBMovie *mMovie;
	NSUInteger mTransId;
}
@end

@implementation MBMovieCastView

+ (void)load
{
	gActorViews = [[NSMutableDictionary alloc] init];
}

- (void)setMovie:(MBMovie *)mbmovie
{
	NSUInteger transId = ++mTransId;
	
	if (mMovie == mbmovie)
		return;
	
	if (nil == (mMovie = mbmovie))
		return;
	
	// remove any existing subviews
	[[self subviews] enumerateObjectsUsingBlock:^ (id obj, NSUInteger ndx, BOOL *stop) {
		[(NSView *)obj removeFromSuperview];
	}];
	
	CGRect myFrame = self.frame;
	NSView *actorsView = gActorViews[mbmovie.dbkey];
	
	if (actorsView) {
		[self addSubview:actorsView];
		return;
	}
	else
		gActorViews[mbmovie.dbkey] = (actorsView = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, 0, 0)]);
	
	[[MBDownloadQueue sharedInstance] dispatchBeg:^{
		__block CGFloat hoffset = 0;
		NSMutableArray *actors = [[NSMutableArray alloc] init];
		
		[[MBAppDelegate sharedInstance].dataManager enumerateActorsForMovie:mMovie handler:^ (MBPerson *mbperson, BOOL *stop) {
			if (!mbperson.imageId)
				return;
			else
				[actors addObject:mbperson];
		}];
		
		// sort actors by number of associated movies (descending)
		[actors setArray:[actors sortedArrayUsingComparator:^ NSComparisonResult (id obj1, id obj2) {
			return [((MBPerson *)obj2).movieCount compare:((MBPerson *)obj1).movieCount];
		}]];
		
		[actors enumerateObjectsUsingBlock:^ (id person, NSUInteger personNdx, BOOL *personStop) {
			MBPerson *mbperson = (MBPerson *)person;
			
			if (transId != mTransId) {
				*personStop = TRUE;
				return;
			}
			
			NSImage *image = [[MBImageCache sharedInstance] actorImageWithId:mbperson.imageId width:0 height:myFrame.size.height];
			
			if (!image)
				return;
			
			CGFloat width = (NSUInteger)(image.size.width * (myFrame.size.height / image.size.height));
			image.size = NSMakeSize(width, myFrame.size.height);
			
			NSButton *imageBtn = [[NSButton alloc] initWithFrame:NSMakeRect(hoffset, 0, image.size.width, image.size.height)];
			[imageBtn setButtonType:NSMomentaryPushInButton];
			[imageBtn setBordered:FALSE];
			[imageBtn setImage:image];
			[imageBtn setToolTip:mbperson.name];
			[imageBtn setTarget:self];
			[imageBtn setAction:@selector(doActionShowActor:)];
			objc_setAssociatedObject(imageBtn, "mbperson", mbperson, OBJC_ASSOCIATION_ASSIGN);
			
			[actorsView addSubview:imageBtn];
			hoffset += image.size.width;
		}];
		
		actorsView.frame = NSMakeRect(0, 0, hoffset, myFrame.size.height);
		
		if (transId != mTransId)
			return;
		
		[[NSThread mainThread] performBlock:^{
			if (transId == mTransId)
				[self addSubview:actorsView];
		}];
	}];
}

/**
 *
 *
 */
- (void)doActionShowActor:(NSButton *)actorBtn
{
	MBPerson *mbperson = objc_getAssociatedObject(actorBtn, "mbperson");
	
	if (mbperson)
		[[MBAppDelegate sharedInstance] showActor:mbperson];
}

@end
