//
//  MSHttpScreencapsImageResponse.h
//  MovieServer
//
//  Created by Curtis Jones on 2012.12.16.
//  Copyright (c) 2012 Curtis Jones. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MSHttpResponse.h"

@interface MSHttpScreencapsImageResponse : MSHttpResponse

+ (id<HTTPResponse>)responseWithPath:(NSString *)filePath andFiles:(NSArray *)files andParams:(NSString *)params forConnection:(HTTPConnection *)connection;

@end
