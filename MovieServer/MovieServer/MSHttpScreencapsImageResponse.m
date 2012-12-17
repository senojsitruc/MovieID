//
//  MSHttpScreencapsImageResponse.m
//  MovieServer
//
//  Created by Curtis Jones on 2012.12.16.
//  Copyright (c) 2012 Curtis Jones. All rights reserved.
//

#import "MSHttpScreencapsImageResponse.h"
#import "HTTPConnection.h"
#import "MSHttpResponse.h"
#import "GCDAsyncSocket.h"
#import "NSThread+Additions.h"
#import <MovieID/IDMediaInfo.h>
#import <AVFoundation/AVFoundation.h>

@implementation MSHttpScreencapsImageResponse

+ (MSHttpResponse *)responseWithPath:(NSString *)filePath andFiles:(NSArray *)files andParams:(NSString *)params forConnection:(HTTPConnection *)connection;
{
	if (!files.count)
		return nil;
	
	MSHttpScreencapsImageResponse *response = [[MSHttpScreencapsImageResponse alloc] init];
//NSDictionary *args = [response parseCgiParams:filePath];
	
	// initialize the response
	response.filePath = filePath;
	response.connection = connection;
	response.theOffset = 0;
	response.dataBuffer = [[NSMutableData alloc] init];
	response->mIsDone = FALSE;
	
	NSLog(@"%s.. request='%@'", __PRETTY_FUNCTION__, filePath);
	
	[NSThread performBlockInBackground:^{
		AVAsset *avasset = [AVAsset assetWithURL:[NSURL fileURLWithPath:files[0]]];
		
		if (!avasset || !avasset.tracks.count) {
			NSLog(@"%s.. failed to create AVAsset with '%@'", __PRETTY_FUNCTION__, files[0]);
			response->mIsDone = TRUE;
			[connection responseHasAvailableData:response];
			return;
		}
		
		NSArray *paramParts = [params componentsSeparatedByString:@"--"];
		
		if (paramParts.count < 5) {
			NSLog(@"%s.. invalid params, '%@'", __PRETTY_FUNCTION__, params);
			response->mIsDone = TRUE;
			[connection responseHasAvailableData:response];
			return;
		}
		
		NSError *error = nil;
		NSUInteger offset = ((NSString *)paramParts[1]).integerValue;
		NSMutableData *imageData = [[NSMutableData alloc] init];
		AVAssetImageGenerator *generator = [AVAssetImageGenerator assetImageGeneratorWithAsset:avasset];
		
		if (!generator) {
			NSLog(@"%s.. failed to create AVAssetImageGenerator", __PRETTY_FUNCTION__);
			response->mIsDone = TRUE;
			[connection responseHasAvailableData:response];
			return;
		}
		
		generator.maximumSize = CGSizeMake(((NSString *)paramParts[3]).integerValue, ((NSString *)paramParts[4]).integerValue);
		
		CGImageRef imageRef = [generator copyCGImageAtTime:CMTimeMake(offset,1) actualTime:NULL error:&error];
		
		if (!imageRef) {
			NSLog(@"%s.. failed to create CGImage from generator, %@", __PRETTY_FUNCTION__, error.localizedDescription);
			response->mIsDone = TRUE;
			[connection responseHasAvailableData:response];
			return;
		}
		
		CGImageDestinationRef imageDestRef = CGImageDestinationCreateWithData((__bridge CFMutableDataRef)imageData, kUTTypePNG, 1, NULL);
		CGImageDestinationSetProperties(imageDestRef, (__bridge CFDictionaryRef)@{(NSString *)kCGImageDestinationLossyCompressionQuality: @(0.5)});
		CGImageDestinationAddImage(imageDestRef, imageRef, NULL);
		
		if (!CGImageDestinationFinalize(imageDestRef)) {
			NSLog(@"%s.. failed to finalize image", __PRETTY_FUNCTION__);
			response->mIsDone = TRUE;
			[connection responseHasAvailableData:response];
			CFRelease(imageDestRef);
			return;
		}
		
		CFRelease(imageDestRef);
		
		[response.dataBuffer appendData:imageData];
		response->mIsDone = TRUE;
		[connection responseHasAvailableData:response];
	}];
	
	return response;
}

@end
