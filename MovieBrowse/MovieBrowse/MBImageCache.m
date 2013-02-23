//
//  MBImageCache.m
//  MovieBrowse
//
//  Created by Curtis Jones on 2012.10.18.
//  Copyright (c) 2012 Curtis Jones. All rights reserved.
//

#import "MBImageCache.h"
#import "MBAppDelegate.h"
#import "MBMovie.h"
#import "NSImage+Additions.h"
#import "NSThread+Additions.h"
#import <MovieID/IDMediaInfo.h>
#import <AVFoundation/AVFoundation.h>
#import <QTKit/QTKit.h>

static NSString * const MBScreencapsKeyDuration = @"duration";
static NSString * const MBScreencapsKeyWidth = @"width";
static NSString * const MBScreencapsKeyHeight = @"height";

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
	@autoreleasepool {
		gSharedInstance = [[MBImageCache alloc] init];
	}
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





#pragma mark - Clear On-Disk Cache

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





#pragma mark - Disk / Server Screencap Image Cache

/**
 * Get one or more parameters about a movie. A movie might be chopped into multiple files.
 *
 */
- (void)screencapInfoForMovie:(MBMovie *)mbmovie duration:(NSUInteger *)_duration width:(NSUInteger *)_width height:(NSUInteger *)_height
{
	NSFileManager *fileManager = [[NSFileManager alloc] init];
	
	if ([fileManager fileExistsAtPath:mbmovie.dirpath])
		[self local_screencapInfoForMovie:mbmovie duration:_duration width:_width height:_height];
	else
		[self remote_screencapInfoForMovie:mbmovie duration:_duration width:_width height:_height];
}

/**
 * Local.
 *
 */
- (void)local_screencapInfoForMovie:(MBMovie *)mbmovie duration:(NSUInteger *)_duration width:(NSUInteger *)_width height:(NSUInteger *)_height
{
	NSArray *movieFiles = [self.class getMovieFilesInDir:mbmovie.dirpath];
	__block NSUInteger duration=0, width=0, height=0;
	
	[movieFiles enumerateObjectsUsingBlock:^ (NSString *fileObj, NSUInteger fileNdx, BOOL *fileStop) {
		IDMediaInfo *mediaInfo = [[IDMediaInfo alloc] initWithFilePath:fileObj];
		duration += mediaInfo.duration.integerValue;
		width = mediaInfo.width.integerValue;
		height = mediaInfo.height.integerValue;
	}];
	
	if (_duration)
		*_duration = duration;
	
	if (_width)
		*_width = width;
	
	if (_height)
		*_height = height;
}

/**
 * Remote.
 *
 */
- (void)remote_screencapInfoForMovie:(MBMovie *)mbmovie duration:(NSUInteger *)_duration width:(NSUInteger *)_width height:(NSUInteger *)_height
{
	NSString *imageHost = [[NSUserDefaults standardUserDefaults] stringForKey:MBDefaultsKeyImageHost];
	
	if (imageHost.length) {
		NSMutableString *urlString = [[NSMutableString alloc] initWithString:imageHost];
		
		[urlString appendString:@"/Screencaps/"];
		[urlString appendString:[mbmovie.dirpath.lastPathComponent stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
		[urlString appendString:@"/info"];
		
		NSURL *url = [NSURL URLWithString:urlString];
		NSData *data = [NSData dataWithContentsOfURL:url];
		NSDictionary *info = nil;
		
		@try {
			info = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
		}
		@catch (NSException *e) {
			NSLog(@"%s.. failed to JSONObjectWithData(), %@", __PRETTY_FUNCTION__, e.reason);
			NSLog(@"%@", e.callStackSymbols);
			NSLog(@"%@", url);
			return;
		}
		
		if (_duration)
			*_duration = ((NSNumber *)info[MBScreencapsKeyDuration]).integerValue;
		
		if (_width)
			*_width = ((NSNumber *)info[MBScreencapsKeyWidth]).integerValue;
		
		if (_height)
			*_height = ((NSNumber *)info[MBScreencapsKeyHeight]).integerValue;
	}
}

/**
 * The offset is given in seconds.
 *
 */
- (NSImage *)screencapImageForMovie:(MBMovie *)mbmovie offset:(NSUInteger)offset width:(NSUInteger)width height:(NSUInteger)height
{
	NSFileManager *fileManager = [[NSFileManager alloc] init];
	
	if ([fileManager fileExistsAtPath:mbmovie.dirpath])
		return [self local_screencapImageForMovie:mbmovie offset:offset width:width height:height];
	else
		return [self remote_screencapImageForMovie:mbmovie offset:offset width:width height:height];
}

/**
 *
 *
 */
- (NSImage *)local_screencapImageForMovie:(MBMovie *)mbmovie offset:(NSUInteger)offset width:(NSUInteger)width height:(NSUInteger)height
{
	__block NSString *movieFile = nil;
	
	// a movie can be chopped up into multiple files. we assume that the movie progresses through the
	// files alphabetically. find which file applies to the given offset and adjust the offset to the
	// appropriate point within its target file. from an outsider's perspective, a movie is just one
	// big file - the way it should be.
	{
		NSArray *movieFiles = [self.class getMovieFilesInDir:mbmovie.dirpath];
		__block NSUInteger tmpOffset = 0;
		
		if (!movieFiles.count) {
			NSLog(@"%s.. no movie files found for movie [%@]", __PRETTY_FUNCTION__, mbmovie.dirpath);
			return nil;
		}
		
		[movieFiles enumerateObjectsUsingBlock:^ (NSString *fileObj, NSUInteger fileNdx, BOOL *fileStop) {
			IDMediaInfo *mediaInfo = [[IDMediaInfo alloc] initWithFilePath:fileObj];
			NSUInteger duration = mediaInfo.duration.integerValue;
			
			if (tmpOffset + duration >= offset)
				*fileStop = TRUE;
			else
				tmpOffset += duration;
		 
		 movieFile = fileObj;
		}];
		
		offset -= tmpOffset;
	}
	
	return [self.class imageFromMovie:movieFile atTime:offset maxSize:CGSizeMake(width,height)];
}

/**
 *
 *
 */
- (NSImage *)remote_screencapImageForMovie:(MBMovie *)mbmovie offset:(NSUInteger)offset width:(NSUInteger)width height:(NSUInteger)height
{
	NSString *key = [NSString stringWithFormat:@"%lu--png--%d--%d", offset, (int)width, (int)height];
	NSString *imageHost = [[NSUserDefaults standardUserDefaults] stringForKey:MBDefaultsKeyImageHost];
	
	if (imageHost.length) {
		NSMutableString *urlString = [[NSMutableString alloc] initWithString:imageHost];
		
		[urlString appendString:@"/Screencaps/"];
		[urlString appendString:[mbmovie.dirpath.lastPathComponent stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
		[urlString appendString:@"/image--"];
		[urlString appendString:key];
		
		return [[NSImage alloc] initWithContentsOfURL:[NSURL URLWithString:urlString]];
	}
	
	return nil;
}





#pragma mark - Disk / Server Poster Image Cache

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
			
			if (originalImage) CGImageRelease(originalImage);
			if (resizedImage) CGImageRelease(resizedImage);
			
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

/**
 *
 *
 */
+ (NSArray *)getMovieFilesInDir:(NSString *)dirPath
{
	NSFileManager *fileManager = [[NSFileManager alloc] init];
	NSArray *files = [fileManager contentsOfDirectoryAtPath:dirPath error:nil];
	NSMutableArray *movieFiles = [[NSMutableArray alloc] init];
	
	[files enumerateObjectsUsingBlock:^ (id obj2, NSUInteger ndx2, BOOL *stop2) {
		NSString *file = [(NSString *)obj2 lowercaseString];
		
		if ([file hasSuffix:@".mp4"] ||
				[file hasSuffix:@".m4v"] ||
				[file hasSuffix:@".mpg"] ||
				[file hasSuffix:@".mov"] ||
				[file hasSuffix:@".wmv"] ||
				[file hasSuffix:@".avi"] ||
				[file hasSuffix:@".mkv"])
			[movieFiles addObject:[dirPath stringByAppendingPathComponent:obj2]];
	}];
	
	return movieFiles;
}

/**
 *
 *
 */
+ (NSImage *)imageFromMovie:(NSString *)moviePath atTime:(NSTimeInterval)timeInSeconds maxSize:(CGSize)size
{
	CGImageRef cgimage = NULL;
	NSImage *image = nil;
	
	if ([moviePath hasSuffix:@".mkv"])
		return nil;
	
	if ([moviePath hasSuffix:@".m4v"] ||
			[moviePath hasSuffix:@".mp4"] ||
			[moviePath hasSuffix:@".mov"])
		cgimage = [self avf_CGImageForTime:timeInSeconds inMovie:moviePath maxSize:size];
	
	if (!cgimage)
		cgimage = [self qtkit_CGImageForTime:timeInSeconds inMovie:moviePath maxSize:size];
	
	if (cgimage) {
		image = [[NSImage alloc] initWithCGImage:cgimage size:size];
		CFRelease(cgimage);
	}
	
	return image;
}

/**
 *
 *
 */
+ (NSData *)pngDataFromMovie:(NSString *)moviePath atTime:(NSTimeInterval)timeInSeconds maxSize:(CGSize)size
{
	CGImageRef cgimage = NULL;
	NSData *imageData = nil;
	
	if ([moviePath hasSuffix:@".mkv"])
		return nil;
	
	if ([moviePath hasSuffix:@".m4v"] ||
			[moviePath hasSuffix:@".mp4"] ||
			[moviePath hasSuffix:@".mov"])
		cgimage = [self avf_CGImageForTime:timeInSeconds inMovie:moviePath maxSize:size];
	
	if (!cgimage)
		cgimage = [self qtkit_CGImageForTime:timeInSeconds inMovie:moviePath maxSize:size];
	
	if (cgimage) {
		imageData = [self pngDataFromCGImage:cgimage];
		CFRelease(cgimage);
	}
	
	return imageData;
}

/**
 *
 *
 */
+ (CGImageRef)avf_CGImageForTime:(NSTimeInterval)timeInSeconds inMovie:(NSString *)moviePath maxSize:(CGSize)size
{
	AVAsset *avasset = [AVAsset assetWithURL:[NSURL fileURLWithPath:moviePath]];
	
	if (!avasset || !avasset.tracks.count) {
		NSLog(@"%s.. failed to create AVAsset [%@]", __PRETTY_FUNCTION__, moviePath.lastPathComponent);
		return nil;
	}
	
	AVAssetImageGenerator *generator = [AVAssetImageGenerator assetImageGeneratorWithAsset:avasset];
	
	if (!generator) {
		NSLog(@"%s.. failed to create AVAssetImageGenerator() [%@]", __PRETTY_FUNCTION__, moviePath.lastPathComponent);
		return nil;
	}
	
	generator.maximumSize = size;
	
	return [generator copyCGImageAtTime:CMTimeMake(timeInSeconds,1) actualTime:NULL error:nil];
}

/**
 *
 *
 */
+ (CGImageRef)qtkit_CGImageForTime:(NSTimeInterval)timeInSeconds inMovie:(NSString *)moviePath maxSize:(CGSize)size
{
	__block NSError *error = nil;
	__block QTMovie *qtmovie = nil;
	
	if (!moviePath.length)
		return nil;
	
	[[NSThread mainThread] performBlock:^{
		qtmovie = [[QTMovie alloc] initWithURL:[NSURL fileURLWithPath:moviePath] error:&error];
		[qtmovie detachFromCurrentThread];
	} waitUntilDone:TRUE];
	
	if (!qtmovie) {
		NSLog(@"%s.. failed to QTMovie::initWithURL(%@), %@", __PRETTY_FUNCTION__, moviePath, error.localizedDescription);
		return nil;
	}
	
	[QTMovie enterQTKitOnThread];
	
	if (![qtmovie attachToCurrentThread]) {
		NSLog(@"%s.. failed to QTMovie::attachToCurrentThread() [%@]", __PRETTY_FUNCTION__, moviePath);
		[QTMovie exitQTKitOnThread];
		return nil;
	}
	
	[qtmovie setIdling:FALSE];
	
	NSDictionary *attrs = @{QTMovieFrameImageType: QTMovieFrameImageTypeCGImageRef,
												 QTMovieFrameImageSize: [NSValue valueWithSize:NSSizeFromCGSize(size)] };
	CGImageRef cgimage = [qtmovie frameImageAtTime:QTMakeTime(timeInSeconds,1) withAttributes:attrs error:&error];
	
	if (!cgimage)
		NSLog(@"%s.. failed to QTMovie::frameAtImageTime(), because %@ [%@]", __PRETTY_FUNCTION__, error.localizedDescription, moviePath);
	else
		CFRetain(cgimage);
	
	[qtmovie detachFromCurrentThread];
	[QTMovie exitQTKitOnThread];
	
	return cgimage;
}

@end
