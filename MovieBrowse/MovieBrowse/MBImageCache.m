//
//  MBImageCache.m
//  MovieBrowse
//
//  Created by Curtis Jones on 2012.10.18.
//  Copyright (c) 2012 Curtis Jones. All rights reserved.
//

#import "MBImageCache.h"
#import "MBAppDelegate.h"

static MBImageCache *gSharedInstance;

@interface MBImageCache ()
{
	NSMutableDictionary *mCache;
	dispatch_queue_t mDataQueue;
}
@end

@implementation MBImageCache

/**
 *
 *
 */
+ (void)load
{
	gSharedInstance = [[MBImageCache alloc] init];
}

/**
 *
 *
 */
+ (id)sharedInstance
{
	return gSharedInstance;
}

/**
 *
 *
 */
- (id)init
{
	self = [super init];
	
	if (self) {
		mCache = [[NSMutableDictionary alloc] init];
		mDataQueue = dispatch_queue_create("image-cache-queue", DISPATCH_QUEUE_CONCURRENT);
	}
	
	return self;
}

/**
 *
 *
 */
- (NSImage *)actorImageWithId:(NSString *)imageId
{
	if (!imageId.length)
		return nil;
	
	NSImage *image = nil;
	NSURL *remoteUrl = [NSURL URLWithString:[[[[NSUserDefaults standardUserDefaults] stringForKey:MBDefaultsKeyImageHost] stringByAppendingPathComponent:@"Actors"] stringByAppendingPathComponent:imageId]];
	NSString *localPath = [[[[[NSUserDefaults standardUserDefaults] stringForKey:MBDefaultsKeyImageCache] stringByExpandingTildeInPath] stringByAppendingPathComponent:@"Actors"] stringByAppendingPathComponent:imageId];
	
	localPath = [localPath stringByExpandingTildeInPath];
	
	// get the image from the local on-disk cache
	{
		NSData *data = [NSData dataWithContentsOfFile:localPath];
		
		if (data)
			image = [[NSImage alloc] initWithData:data];
	}
	
	// get the image from the remote server
	if (!image) {
		NSData *data = [NSData dataWithContentsOfURL:remoteUrl];
		
		if (data && nil != (image = [[NSImage alloc] initWithData:data])) {
			NSFileManager *fileManager = [[NSFileManager alloc] init];
			NSString *parentDir = [localPath stringByDeletingLastPathComponent];
			NSError *nserror = nil;
			
			if (FALSE == [fileManager fileExistsAtPath:parentDir])
				if (FALSE == [fileManager createDirectoryAtPath:parentDir withIntermediateDirectories:TRUE attributes:nil error:&nserror])
					NSLog(@"%s.. failed to create directory because %@ [%@]", __PRETTY_FUNCTION__, nserror.localizedDescription, parentDir);
			
			[data writeToFile:localPath atomically:TRUE];
		}
	}
	
	return image;
}

/**
 *
 *
 */
- (NSImage *)movieImageWithId:(NSString *)imageId
{
	if (!imageId.length)
		return nil;
	
	NSImage *image = nil;
	NSURL *remoteUrl = [NSURL URLWithString:[[[[NSUserDefaults standardUserDefaults] stringForKey:MBDefaultsKeyImageHost] stringByAppendingPathComponent:@"Movies"] stringByAppendingPathComponent:imageId]];
	NSString *localPath = [[[[NSUserDefaults standardUserDefaults] stringForKey:MBDefaultsKeyImageCache] stringByAppendingPathComponent:@"Movies"] stringByAppendingPathComponent:imageId];
	
	localPath = [localPath stringByExpandingTildeInPath];
	
	// get the image from the local on-disk cache
	{
		NSData *data = [NSData dataWithContentsOfFile:localPath];
		
		if (data)
			image = [[NSImage alloc] initWithData:data];
	}
	
	// get the image from the remote server
	if (!image) {
		NSData *data = [NSData dataWithContentsOfURL:remoteUrl];
		
		if (data && nil != (image = [[NSImage alloc] initWithData:data])) {
			NSFileManager *fileManager = [[NSFileManager alloc] init];
			NSString *parentDir = [localPath stringByDeletingLastPathComponent];
			NSError *nserror = nil;
			
			if (FALSE == [fileManager fileExistsAtPath:parentDir])
				if (FALSE == [fileManager createDirectoryAtPath:parentDir withIntermediateDirectories:TRUE attributes:nil error:&nserror])
					NSLog(@"%s.. failed to create directory because %@ [%@]", __PRETTY_FUNCTION__, nserror.localizedDescription, parentDir);
			
			[data writeToFile:localPath atomically:TRUE];
		}
	}
	
	return image;
}

/**
 *
 *
 */
- (NSImage *)cachedImageWithId:(NSString *)imageId andHeight:(CGFloat)height
{
	__block NSImage *image = nil;
	
	if (!imageId.length)
		return nil;
	
	NSMutableString *key = [[NSMutableString alloc] init];
	[key appendString:imageId];
	[key appendString:@"--"];
	[key appendString:@((NSUInteger)height).stringValue];
	
	dispatch_sync(mDataQueue, ^{
		image = mCache[key];
	});
	
	return image;
}

/**
 *
 *
 */
- (void)cacheImage:(NSImage *)image withId:(NSString *)imageId andHeight:(CGFloat)height
{
	if (!imageId.length)
		return;
	
	NSMutableString *key = [[NSMutableString alloc] init];
	[key appendString:imageId];
	[key appendString:@"--"];
	[key appendString:@((NSUInteger)height).stringValue];
	
	dispatch_barrier_sync(mDataQueue, ^{
		mCache[key] = image;
	});
}

@end