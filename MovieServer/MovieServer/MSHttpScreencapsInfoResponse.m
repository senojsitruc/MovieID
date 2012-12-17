//
//  MSHttpScreencapsInfoResponse.m
//  MovieServer
//
//  Created by Curtis Jones on 2012.12.16.
//  Copyright (c) 2012 Curtis Jones. All rights reserved.
//

#import "MSHttpScreencapsInfoResponse.h"
#import "HTTPConnection.h"
#import "MSHttpResponse.h"
#import "GCDAsyncSocket.h"
#import "NSThread+Additions.h"
#import <MovieID/IDMediaInfo.h>

@implementation MSHttpScreencapsInfoResponse

+ (MSHttpResponse *)responseWithPath:(NSString *)filePath andFiles:(NSArray *)files forConnection:(HTTPConnection *)connection
{
	if (!files.count)
		return nil;
	
	MSHttpScreencapsInfoResponse *response = [[MSHttpScreencapsInfoResponse alloc] init];
//NSDictionary *args = [response parseCgiParams:filePath];
	
	// initialize the response
	response.filePath = filePath;
	response.connection = connection;
	response.theOffset = 0;
	response.dataBuffer = [[NSMutableData alloc] init];
	response->mIsDone = FALSE;
	
	NSLog(@"%s.. request='%@'", __PRETTY_FUNCTION__, filePath);
	
	[NSThread performBlockInBackground:^{
		IDMediaInfo *mediaInfo = [[IDMediaInfo alloc] initWithFilePath:files[0]];
		NSMutableDictionary *info = [[NSMutableDictionary alloc] init];
		NSNumber *duration = mediaInfo.duration;
		NSNumber *width = mediaInfo.width;
		NSNumber *height = mediaInfo.height;
		
		if (duration)
			info[@"duration"] = duration;
		
		if (width)
			info[@"width"] = width;
		
		if (height)
			info[@"height"] = height;
		
		[response.dataBuffer appendData:[NSJSONSerialization dataWithJSONObject:info options:0 error:nil]];
		response->mIsDone = TRUE;
		[connection responseHasAvailableData:response];
	}];
	
	return response;
}

@end
