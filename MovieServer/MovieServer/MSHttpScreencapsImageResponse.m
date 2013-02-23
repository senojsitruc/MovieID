//
//  MSHttpScreencapsImageResponse.m
//  MovieServer
//
//  Created by Curtis Jones on 2012.12.16.
//  Copyright (c) 2012 Curtis Jones. All rights reserved.
//

#import "MSHttpScreencapsImageResponse.h"
#import "HTTPDataResponse.h"
#import "HTTPConnection.h"
#import "MSHttpResponse.h"
#import "MSAppDelegate.h"
#import "GCDAsyncSocket.h"
#import "NSThread+Additions.h"
#import <MovieID/IDMediaInfo.h>
#import <AVFoundation/AVFoundation.h>

@implementation MSHttpScreencapsImageResponse

+ (NSObject<HTTPResponse> *)responseWithPath:(NSString *)filePath andFiles:(NSArray *)files andParams:(NSString *)params forConnection:(HTTPConnection *)connection
{
	if (!files.count)
		return nil;
	
	NSArray *paramParts = [params componentsSeparatedByString:@"--"];
	
	if (paramParts.count < 5) {
		NSLog(@"%s.. invalid params, '%@'", __PRETTY_FUNCTION__, params);
		return nil;
	}
	
	NSUInteger offset = ((NSString *)paramParts[1]).integerValue;
	CGSize size = CGSizeMake(((NSString *)paramParts[3]).integerValue, ((NSString *)paramParts[4]).integerValue);
	NSData *imageData = [MSAppDelegate pngDataForTime:offset inMovie:files[0] maxSize:size];
	
	return [[HTTPDataResponse alloc] initWithData:imageData];
}

@end
