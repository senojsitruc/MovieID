//
//  MBImageCache.m
//  MovieBrowse
//
//  Created by Curtis Jones on 2012.10.18.
//  Copyright (c) 2012 Curtis Jones. All rights reserved.
//

#import "MBImageCache.h"
#import "MBAppDelegate.h"
#import "NSImage+Additions.h"

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





#pragma mark - Clear

/**
 *
 *
 */
- (void)clearAll
{
	NSFileManager *fileManager = [[NSFileManager alloc] init];
	NSString *baseDir = [[[NSUserDefaults standardUserDefaults] stringForKey:MBDefaultsKeyImageCache] stringByExpandingTildeInPath];
	NSString *actors = [baseDir stringByAppendingPathComponent:@"Actors"];
	NSString *movies = [baseDir stringByAppendingPathComponent:@"Movies"];
	void (^deleteItems)(NSString*);
	
	deleteItems = ^ (NSString *baseDir) {
		NSArray *dirs = [fileManager contentsOfDirectoryAtPath:baseDir error:nil];
		
		[dirs enumerateObjectsUsingBlock:^ (id dirName, NSUInteger dirNdx, BOOL *dirStop) {
			NSString *dirPath = [baseDir stringByAppendingPathComponent:dirName];
			BOOL isDir = FALSE;
			
			if (![fileManager fileExistsAtPath:dirPath isDirectory:&isDir] || !isDir)
				return;
			
			NSArray *items = [fileManager contentsOfDirectoryAtPath:dirPath error:nil];
			
			[items enumerateObjectsUsingBlock:^ (id fileName, NSUInteger fileNdx, BOOL *fileStop) {
				if (NSNotFound == [(NSString *)fileName rangeOfString:@"--"].location)
					return;
				
				[fileManager removeItemAtPath:[dirPath stringByAppendingPathComponent:fileName] error:nil];
			}];
		}];
	};
	
	deleteItems(actors);
	deleteItems(movies);
	
	dispatch_barrier_sync(mDataQueue, ^{
		[mCache removeAllObjects];
	});
}

/**
 *
 *
 */
- (void)clearActorCacheForId:(NSString *)imageId
{
	NSString *actors = [[[[NSUserDefaults standardUserDefaults] stringForKey:MBDefaultsKeyImageCache] stringByExpandingTildeInPath] stringByAppendingPathComponent:@"Actors"];
	[self clearCacheForId:imageId inDir:actors];
}

/**
 *
 *
 */
- (void)clearMovieCacheForId:(NSString *)imageId
{
	NSString *movies = [[[[NSUserDefaults standardUserDefaults] stringForKey:MBDefaultsKeyImageCache] stringByExpandingTildeInPath] stringByAppendingPathComponent:@"Movies"];
	[self clearCacheForId:imageId inDir:movies];
}

/**
 *
 *
 */
- (void)clearCacheForId:(NSString *)imageId inDir:(NSString *)basedir
{
	NSFileManager *fileManager = [[NSFileManager alloc] init];
	void (^deleteItems)(NSString*);
	
	deleteItems = ^ (NSString *dirPath) {
		BOOL isDir = FALSE;
		
		if (![fileManager fileExistsAtPath:dirPath isDirectory:&isDir] || !isDir)
			return;
		
		NSArray *items = [fileManager contentsOfDirectoryAtPath:dirPath error:nil];
		
		[items enumerateObjectsUsingBlock:^ (id fileName, NSUInteger fileNdx, BOOL *fileStop) {
			if (NSNotFound == [(NSString *)fileName rangeOfString:@"--"].location)
				return;
			
			if (![(NSString *)fileName hasPrefix:imageId])
				return;
			
			[fileManager removeItemAtPath:[dirPath stringByAppendingPathComponent:fileName] error:nil];
		}];
	};
	
	deleteItems([basedir stringByAppendingString:[imageId substringToIndex:2].lowercaseString]);
	
	dispatch_barrier_sync(mDataQueue, ^{
		NSMutableArray *keys = [[NSMutableArray alloc] init];
		
		[mCache enumerateKeysAndObjectsUsingBlock:^ (id key, id val, BOOL *stop) {
			if ([(NSString *)key hasPrefix:imageId])
				[keys addObject:key];
		}];
		
		[mCache removeObjectsForKeys:keys];
	});
}





#pragma mark - Disk / Server Cache

/**
 *
 *
 */
- (NSImage *)actorImageWithId:(NSString *)imageId
{
	return [self actorImageWithId:imageId width:0 height:0];
}

/**
 *
 *
 */
- (NSImage *)actorImageWithId:(NSString *)imageId width:(NSUInteger)width height:(NSUInteger)height
{
	return [self imageWithId:imageId width:width height:height inDir:@"Actors"];
}

/**
 *
 *
 */
- (NSImage *)movieImageWithId:(NSString *)imageId
{
	return [self movieImageWithId:imageId width:0 height:0];
}

/**
 *
 *
 */
- (NSImage *)movieImageWithId:(NSString *)imageId width:(NSUInteger)width height:(NSUInteger)height
{
	return [self imageWithId:imageId width:width height:height inDir:@"Movies"];
}

/**
 *
 *
 */
- (NSImage *)imageWithId:(NSString *)_imageId width:(NSUInteger)width height:(NSUInteger)height inDir:(NSString *)cacheDir
{
	NSString *imageId = _imageId;
	
	if (!imageId.length)
		return nil;
	
	if (width || height)
		imageId = [imageId stringByAppendingFormat:@"--%lu--%lu", width, height];
	
	NSImage *image = nil;
	NSString *imageHost = [[NSUserDefaults standardUserDefaults] stringForKey:MBDefaultsKeyImageHost];
	NSURL *remoteUrl = [NSURL URLWithString:[[imageHost stringByAppendingPathComponent:cacheDir] stringByAppendingPathComponent:imageId]];
	NSString *localPath = [[[[NSUserDefaults standardUserDefaults] stringForKey:MBDefaultsKeyImageCache] stringByExpandingTildeInPath] stringByAppendingPathComponent:cacheDir];
	
	localPath = [localPath stringByAppendingPathComponent:[imageId substringToIndex:2].lowercaseString];
	localPath = [localPath stringByAppendingPathComponent:imageId];
	localPath = [localPath stringByExpandingTildeInPath];
	
	// get the image from the local on-disk cache
	image = [[NSImage alloc] initWithContentsOfFile:localPath];
	
	// look for the original-size image in the on-disk cache; if we find it, resize it and save the
	// resized version back to the on-disk cache.
	if (!image) {
		NSString *_localPath = [[localPath stringByDeletingLastPathComponent] stringByAppendingPathComponent:_imageId];
		
		image = [[NSImage alloc] initWithContentsOfFile:_localPath];
		
		if (image) {
			CGSize imageSize = image.size;
			
			if (imageSize.width != INFINITY && imageSize.width != NAN && imageSize.height != INFINITY && imageSize.height != NAN) {
				if (!width)
					width = imageSize.width * (height / imageSize.height);
				else if (!height)
					height = imageSize.height * (width / imageSize.width);
				
				if (imageSize.width > imageSize.height)
					width = imageSize.width * (height / imageSize.height);
				else if (imageSize.height > imageSize.width)
					height = imageSize.height * (width / imageSize.width);
			}
			
			CGImageRef originalImage = image.CGImage;
			CGImageRef resizedImage = [[self class] resizeCGImage:originalImage width:width height:height];
			NSData *imageData = [[self class] pngDataFromCGImage:resizedImage];
			
			CGImageRelease(originalImage);
			CGImageRelease(resizedImage);
			
			if (imageData.length) {
				NSFileManager *fileManager = [[NSFileManager alloc] init];
				NSString *parentDir = [localPath stringByDeletingLastPathComponent];
				NSError *nserror = nil;
				
				if (FALSE == [fileManager fileExistsAtPath:parentDir])
					if (FALSE == [fileManager createDirectoryAtPath:parentDir withIntermediateDirectories:TRUE attributes:nil error:&nserror])
						NSLog(@"%s.. failed to create directory because %@ [%@]", __PRETTY_FUNCTION__, nserror.localizedDescription, parentDir);
				
				[imageData writeToFile:localPath atomically:TRUE];
			}
		}
	}
	
	// get the image from the remote server
	if (!image && imageHost.length) {
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





#pragma mark - Memory Cache

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





#pragma mark - Private

/**
 *
 *
 */
+ (CGImageRef)resizeCGImage:(CGImageRef)cgimage width:(NSUInteger)width height:(NSUInteger)height
{
	if (!cgimage || !width || !height)
		return nil;
	
	CGColorSpaceRef cs = CGColorSpaceCreateDeviceRGB();
	
	if (!cs) {
		NSLog(@"%s.. failed to CGImageGetColorSpace()", __PRETTY_FUNCTION__);
		return nil;
	}
	
	size_t bpp = CGImageGetBitsPerPixel(cgimage);
	size_t bpc = CGImageGetBitsPerComponent(cgimage);
	size_t bpr = CGImageGetBytesPerRow(cgimage);
	CGImageAlphaInfo ai = CGImageGetAlphaInfo(cgimage);
	CGContextRef context = CGBitmapContextCreate(NULL, width, height, 8, width*4, cs, kCGImageAlphaNoneSkipLast);
	CGColorSpaceRelease(cs);
	
	if (!context) {
		NSLog(@"%s.. failed to CGBitmapContextCreate() [bpc=%lu, bpr=%lu, bpp=%lu, ai=%d, width=%lu, height=%lu]", __PRETTY_FUNCTION__, bpc, bpr, bpp, (int)ai, width, height);
		return nil;
	}
	
	CGContextDrawImage(context, CGRectMake(0, 0, width, height), cgimage);
	CGImageRef newImage = CGBitmapContextCreateImage(context);
	CGContextRelease(context);
	
	return newImage;
}

/**
 *
 *
 */
+ (NSData *)pngDataFromCGImage:(CGImageRef)cgimage
{
	if (!cgimage)
		return nil;
	
	NSMutableData *imageData = [[NSMutableData alloc] init];
	CGImageDestinationRef idRef = CGImageDestinationCreateWithData((__bridge CFMutableDataRef)imageData, kUTTypePNG, 1, NULL);
	
	if (!idRef) {
		NSLog(@"%s.. failed to CGImageDestinationCreateWithData()", __PRETTY_FUNCTION__);
		return nil;
	}
	
	CGImageDestinationSetProperties(idRef, (__bridge CFDictionaryRef)@{(NSString *)kCGImageDestinationLossyCompressionQuality: @(0.5)});
	CGImageDestinationAddImage(idRef, cgimage, NULL);
	
	if (!CGImageDestinationFinalize(idRef)) {
		CFRelease(idRef);
		return nil;
	}
	
	CFRelease(idRef);
	
	return imageData;
}

@end
