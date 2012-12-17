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
#import "MSHttpResponse.h"
#import "MSHttpScreencapsInfoResponse.h"
#import "MShttpScreencapsImageResponse.h"
#import "MSHttpProfileImageResponse.h"
#import "MSHttpPosterImageResponse.h"

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
	[mHttpServer setPort:10080];
	[mHttpServer start:nil];
}

/**
 *
 *
 */
+ (NSObject<HTTPResponse> *)responseWithPath:(NSString *)filePath forConnection:(HTTPConnection *)connection
{
	NSLog(@"%s.. filePath='%@'", __PRETTY_FUNCTION__, filePath);
	
	@try {
		NSArray *pathParts = [filePath componentsSeparatedByString:@"/"];
		NSLog(@"%s.. %@", __PRETTY_FUNCTION__, pathParts);
		
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
			if (pathParts.count < 3)
				return nil;
			else
				return [MSHttpProfileImageResponse responseWithFilePath:filePath andActorId:pathParts[2] forConnection:connection];
		}
		
		//
		// Poster
		//
		else if ([action isEqualToString:@"Movies"]) {
			if (pathParts.count < 3)
				return nil;
			else
				return [MSHttpPosterImageResponse responseWithFilePath:filePath andMovieId:pathParts[2] forConnection:connection];
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

@end
