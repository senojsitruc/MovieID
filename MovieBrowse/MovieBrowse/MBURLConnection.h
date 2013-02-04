//
//  MBURLConnection.h
//  MovieBrowse
//
//  Created by Curtis Jones on 2013.02.03.
//  Copyright (c) 2013 Curtis Jones. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^MBURLConnectionDataHandler) (NSNumber*, NSDictionary*, NSData*);
typedef void (^MBURLConnectionProgressHandler) (long long, long long, NSString*, NSString*, NSString*, NSURL*);

@interface MBURLConnection : NSURLConnection <NSURLConnectionDelegate, NSURLConnectionDataDelegate>

@property (readonly) long long contentLength;
@property (readonly) NSString *fileName;
@property (readonly) NSString *mimeType;
@property (readonly) NSString *textEncoding;
@property (readonly) NSURL *url;

/**
 *
 */
- (id)initWithRequest:(NSURLRequest *)request progressHandler:(MBURLConnectionProgressHandler)progressHandler dataHandler:(MBURLConnectionDataHandler)dataHandler;

/**
 *
 */
- (void)runInBackground:(BOOL)background;

@end
