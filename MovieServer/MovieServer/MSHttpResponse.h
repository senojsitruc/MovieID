//
//  MSHttpResponse.h
//  MovieServer
//
//  Created by Curtis Jones on 2012.12.16.
//  Copyright (c) 2012 Curtis Jones. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HTTPResponse.h"

@class HTTPConnection;

@interface MSHttpResponse : NSObject <HTTPResponse>
{
	BOOL mIsDone;
	NSUInteger mResultCount;
	NSUInteger mContentLength;
}

@property (nonatomic, strong) NSString *filePath;
@property (nonatomic, weak) HTTPConnection *connection;
@property (readwrite, assign) NSUInteger theOffset;
@property (nonatomic, strong) NSMutableData *dataBuffer;

- (NSDictionary *)parseCgiParams:(NSString *)filePath;

@end
