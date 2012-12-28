//
//  MSHttpProfileImageResponse.m
//  MovieServer
//
//  Created by Curtis Jones on 2012.12.16.
//  Copyright (c) 2012 Curtis Jones. All rights reserved.
//

#import "MSHttpProfileImageResponse.h"
#import "HTTPConnection.h"
#import "MSHttpResponse.h"
#import "MSAppDelegate.h"
#import "GCDAsyncSocket.h"
#import "NSThread+Additions.h"

static NSString * const gBaseDir = @"/Volumes/Stuart Little/MovieBrowse/Actors";

@implementation MSHttpProfileImageResponse

+ (MSHttpResponse *)responseWithFilePath:(NSString *)filePath andActorId:(NSString *)actorId forConnection:(HTTPConnection *)connection
{
	MSHttpProfileImageResponse *response = [[MSHttpProfileImageResponse alloc] init];
//NSDictionary *args = [response parseCgiParams:filePath];
	
	// initialize the response
	response.filePath = filePath;
	response.connection = connection;
	response.theOffset = 0;
	response.dataBuffer = [[NSMutableData alloc] init];
	response->mIsDone = FALSE;
	
	if (!actorId.length || NSNotFound != [actorId rangeOfString:@"/"].location)
		return nil;
	
	[NSThread performBlockInBackground:^{
		NSString *path = nil;
		NSArray *parts = [actorId componentsSeparatedByString:@"--"];
		NSUInteger width=0, height=0;
		
		if (parts.count == 3) {
			if (3 > ((NSString *)parts[0]).length) {
				response->mIsDone = TRUE;
				[connection responseDidAbort:response];
				return;
			}
			
			path = [gBaseDir stringByAppendingPathComponent:[(NSString *)parts[0] substringToIndex:2].lowercaseString];
			path = [path stringByAppendingPathComponent:parts[0]];
			width = ((NSString *)parts[1]).integerValue;
			height = ((NSString *)parts[2]).integerValue;
		}
		else {
			if (3 > actorId.length) {
				response->mIsDone = TRUE;
				[connection responseDidAbort:response];
				return;
			}
			
			path = [gBaseDir stringByAppendingPathComponent:[actorId substringToIndex:2].lowercaseString];
			path = [path stringByAppendingPathComponent:actorId];
		}
		
		NSData *data = [NSData dataWithContentsOfFile:path];
		
		if (width || height) {
			NSImage *image = [[NSImage alloc] initWithData:data];
			CGImageRef cgimage = [image CGImageForProposedRect:NULL context:nil hints:nil];
			CGSize imageSize = image.size;
			
			if (!width)
				width = imageSize.width * (height / imageSize.height);
			else if (!height)
				height = imageSize.height * (width / imageSize.width);
			
			if (imageSize.width > imageSize.height)
				width = imageSize.width * (height / imageSize.height);
			else if (imageSize.height > imageSize.width)
				height = imageSize.height * (width / imageSize.width);
			
			cgimage = [MSAppDelegate resizeCGImage:cgimage width:width height:height];
			data = [MSAppDelegate pngDataFromCGImage:cgimage];
		}
		
		if (data)
			[response.dataBuffer appendData:data];
		else
			[connection responseDidAbort:response];
		
		response->mIsDone = TRUE;
		[connection responseHasAvailableData:response];
	}];
	
	return response;
}

@end
