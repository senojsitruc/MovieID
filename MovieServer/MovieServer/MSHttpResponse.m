//
//  MSHttpResponse.m
//  MovieServer
//
//  Created by Curtis Jones on 2012.12.16.
//  Copyright (c) 2012 Curtis Jones. All rights reserved.
//

#import "MSHttpResponse.h"
#import "HTTPResponse.h"
#import "HTTPConnection.h"
#import "MSAppDelegate.h"
#import "NSString+Additions.h"
#import "GCDAsyncSocket.h"

@implementation MSHttpResponse

#pragma mark - Helpers

/**
 *
 *
 */
- (NSDictionary *)parseCgiParams:(NSString *)filePath
{
	NSMutableDictionary *args = [[NSMutableDictionary alloc] init];
	NSInteger questionMark = [filePath rangeOfString:@"?"].location;
	
	if (NSNotFound == questionMark || filePath.length == 1 || filePath.length - 1 == questionMark)
		return args;
	
	NSArray *pairs = [[filePath substringFromIndex:questionMark+1] componentsSeparatedByString:@"&"];
	
	for (NSString *pair in pairs) {
		NSArray *parts = [pair componentsSeparatedByString:@"="];
		if (parts.count == 2)
			args[[[parts objectAtIndex:0] lowercaseString]] = [[parts objectAtIndex:1] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
	}
	
	return args;
}





#pragma mark - HTTPResponse - Required

/**
 *
 *
 */
- (UInt64)contentLength
{
	return 0;
}

/**
 *
 *
 */
- (UInt64)offset
{
	return self.theOffset;
}

/**
 *
 *
 */
- (void)setOffset:(UInt64)offset
{
	self.theOffset = offset;
}

/**
 *
 *
 */
- (NSData *)readDataOfLength:(NSUInteger)length
{
	if (self.theOffset >= self.dataBuffer.length)
		return nil;
	
	length = MIN(length, self.dataBuffer.length - self.theOffset);
	NSData *data = [NSData dataWithBytes:self.dataBuffer.bytes+self.theOffset length:length];
	self.theOffset += length;
	
	return data;
}

/**
 *
 *
 */
- (BOOL)isDone
{
	return mIsDone && self.theOffset >= self.dataBuffer.length;
}





#pragma mark - HTTPResponse - Optional

/**
 *
 *
 */
- (BOOL)isChunked
{
	return TRUE;
}

/**
 *
 *
 */
- (BOOL)isAsynchronous
{
	return TRUE;
}

/**
 *
 *
 */
- (void)connectionDidClose
{
	self.connection = nil;
}

@end
