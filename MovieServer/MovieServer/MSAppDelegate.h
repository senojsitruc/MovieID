//
//  MSAppDelegate.h
//  MovieServer
//
//  Created by Curtis Jones on 2012.10.17.
//  Copyright (c) 2012 Curtis Jones. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@protocol HTTPResponse;
@class HTTPConnection;

@interface MSAppDelegate : NSObject <NSApplicationDelegate>

@property (assign) IBOutlet NSWindow *window;

+ (NSObject<HTTPResponse> *)responseWithPath:(NSString *)filePath forConnection:(HTTPConnection *)connection;
+ (NSArray *)getMovieFilesInDir:(NSString *)dirPath;

@end
