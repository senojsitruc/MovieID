//
//  MBImageCache.h
//  MovieBrowse
//
//  Created by Curtis Jones on 2012.10.18.
//  Copyright (c) 2012 Curtis Jones. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MBImageCache : NSObject

+ (id)sharedInstance;

- (NSImage *)actorImageWithId:(NSString *)imageId;
- (NSImage *)movieImageWithId:(NSString *)imageId;

- (NSImage *)cachedImageWithId:(NSString *)imageId andHeight:(CGFloat)height;
- (void)cacheImage:(NSImage *)image withId:(NSString *)imageId andHeight:(CGFloat)height;

@end
