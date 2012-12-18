//
//  MSAppDelegate.m
//  MovieServer
//
//  Created by Curtis Jones on 2012.10.17.
//  Copyright (c) 2012 Curtis Jones. All rights reserved.
//

#import "MSAppDelegate.h"
#import "HTTPConnection.h"
#import "HTTPResponse.h"
#import "HTTPServer.h"
#import "NSThread+Additions.h"
#import "MSHttpResponse.h"
#import "MSHttpScreencapsInfoResponse.h"
#import "MShttpScreencapsImageResponse.h"
#import "MSHttpProfileImageResponse.h"
#import "MSHttpPosterImageResponse.h"
#import <AVFoundation/AVFoundation.h>
#import <QTKit/QTKit.h>

NSString * const gBaseDir = @"/Volumes/bigger/Media/Movies";

@interface MSAppDelegate ()
{
	HTTPServer *mHttpServer;
}
@end

@implementation MSAppDelegate

/**
 *
 *
 */
- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	[self startHttp];
}

/**
 *
 *
 */
- (void)startHttp
{
	mHttpServer = [[HTTPServer alloc] init];
	[mHttpServer setPort:20080];
	[mHttpServer start:nil];
}

/**
 *
 *
 */
+ (NSObject<HTTPResponse> *)responseWithPath:(NSString *)filePath forConnection:(HTTPConnection *)connection
{
	NSLog(@"%@", filePath);
	
	@try {
		NSArray *pathParts = [filePath componentsSeparatedByString:@"/"];
		
		if (pathParts.count < 2)
			return nil;
		
		NSString *action = pathParts[1];
		
		//
		// screencaps
		//
		if ([action isEqualToString:@"Screencaps"]) {
			NSString *movieDir = [pathParts[2] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
			NSString *fileName = pathParts[3];
			
			if (NSNotFound != [movieDir rangeOfString:@"/"].location)
				return nil;
			
			if (!movieDir.length)
				return nil;
			
			NSString *section = [movieDir substringToIndex:1];
			NSString *moviePath = gBaseDir;
			
			moviePath = [moviePath stringByAppendingPathComponent:section];
			moviePath = [moviePath stringByAppendingPathComponent:movieDir];
			
			NSArray *movieFiles = [self getMovieFilesInDir:moviePath];
			
			if ([fileName isEqualToString:@"info"])
				return [MSHttpScreencapsInfoResponse responseWithPath:filePath andFiles:movieFiles forConnection:connection];
			else if ([fileName hasPrefix:@"image--"])
				return [MSHttpScreencapsImageResponse responseWithPath:filePath andFiles:movieFiles andParams:fileName forConnection:connection];
			else
				return nil;
		}
		
		//
		// Profile
		//
		else if ([action isEqualToString:@"Actors"]) {
			if (pathParts.count == 3)
				return [MSHttpProfileImageResponse responseWithFilePath:filePath andActorId:pathParts[2] forConnection:connection];
			else
				return nil;
		}
		
		//
		// Poster
		//
		else if ([action isEqualToString:@"Movies"]) {
			if (pathParts.count == 3)
				return [MSHttpPosterImageResponse responseWithFilePath:filePath andMovieId:pathParts[2] forConnection:connection];
			else
				return nil;
		}
	}
	@catch (NSException *e) {
		NSLog(@"%s.. name = %@", __PRETTY_FUNCTION__, [e name]);
		NSLog(@"%s.. reason = %@", __PRETTY_FUNCTION__, [e reason]);
		NSLog(@"%s.. userInfo = %@", __PRETTY_FUNCTION__, [e userInfo]);
		NSLog(@"%s.. %@", __PRETTY_FUNCTION__, [e callStackSymbols]);
	}
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
+ (CGImageRef)resizeCGImage:(CGImageRef)cgimage width:(NSUInteger)width height:(NSUInteger)height
{
	if (!cgimage || !width || !height)
		return nil;
	
	CGColorSpaceRef cs = CGImageGetColorSpace(cgimage);
	CGContextRef context = CGBitmapContextCreate(NULL, width, height, CGImageGetBitsPerComponent(cgimage), CGImageGetBytesPerRow(cgimage), cs, CGImageGetAlphaInfo(cgimage));
	CGColorSpaceRelease(cs);
	
	if (!context)
		return nil;
	
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
+ (NSData *)pngDataForTime:(NSTimeInterval)timeInSeconds inMovie:(NSString *)moviePath maxSize:(CGSize)size
{
	CGImageRef cgimage = NULL;
	NSData *imageData = nil;
	
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
		NSLog(@"%s.. failed to attachToCurrentThread() [%@]", __PRETTY_FUNCTION__, moviePath);
		[QTMovie exitQTKitOnThread];
		return nil;
	}
	
	[qtmovie setIdling:FALSE];
	
	NSDictionary *attrs = @{QTMovieFrameImageType: QTMovieFrameImageTypeCGImageRef,
												 QTMovieFrameImageSize: [NSValue valueWithSize:NSSizeFromCGSize(size)] };
	CGImageRef cgimage = [qtmovie frameImageAtTime:QTMakeTime(timeInSeconds,1) withAttributes:attrs error:&error];
	
	if (!cgimage)
		NSLog(@"%s.. failed to frameAtImageTime(), because %@ [%@]", __PRETTY_FUNCTION__, error.localizedDescription, moviePath);
	else
		CFRetain(cgimage);
	
	[qtmovie detachFromCurrentThread];
	[QTMovie exitQTKitOnThread];
	
	return cgimage;
}

@end
