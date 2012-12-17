//
//  MSHttpPosterImageResponse.m
//  MovieServer
//
//  Created by Curtis Jones on 2012.12.16.
//  Copyright (c) 2012 Curtis Jones. All rights reserved.
//

#import "MSHttpPosterImageResponse.h"
#import "HTTPConnection.h"
#import "MSHttpResponse.h"
#import "GCDAsyncSocket.h"
#import "NSThread+Additions.h"

static NSString * const gBaseDir = @"/Volumes/Stuart Little/MovieBrowse/Movies";

@implementation MSHttpPosterImageResponse

+ (MSHttpResponse *)responseWithMovieId:(NSString *)movieId forConnection:(HTTPConnection *)connection
{
	MSHttpProfileImageResponse *response = [[MSHttpProfileImageResponse alloc] init];
//NSDictionary *args = [response parseCgiParams:filePath];
	
	// initialize the response
	response.filePath = filePath;
	response.connection = connection;
	response.theOffset = 0;
	response.dataBuffer = [[NSMutableData alloc] init];
	response->mIsDone = FALSE;
	
	NSLog(@"%s.. request='%@'", __PRETTY_FUNCTION__, filePath);
	
	if (!movieId.length || NSNotFound != [movieId rangeOfString:@"/"].location)
		return nil;
	
	[NSThread performBlockInBackground:^{
		NSString *path = [gBaseDir stringByAppendingPathComponent:movieId];
		NSData *data = [NSData dataWithContentsOfFile:path];
		
		[response.dataBuffer appendData:data];
		response->mIsDone = TRUE;
		[connection responseHasAvailableData:response];
	}];
	
	return response;
}

@end
