//
//  MBGoogleImageSearch.h
//  MovieBrowse
//
//  Created by Curtis Jones on 2012.12.28.
//  Copyright (c) 2012 Curtis Jones. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MBGoogleImageSearch : NSObject

typedef void (^MBGoogleImageSearchHandler) (NSURL*, NSInteger, NSInteger, BOOL*);

/**
 *
 */
- (void)imagesForQuery:(NSString *)query offset:(NSInteger)offset count:(NSInteger)count handler:(MBGoogleImageSearchHandler)handler;

@end
