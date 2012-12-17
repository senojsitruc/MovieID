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
- (NSImage *)actorImageWithId:(NSString *)imageId width:(NSUInteger)width height:(NSUInteger)height;
- (NSImage *)movieImageWithId:(NSString *)imageId;
- (NSImage *)movieImageWithId:(NSString *)imageId width:(NSUInteger)width height:(NSUInteger)height;

- (NSImage *)cachedImageWithId:(NSString *)imageId andHeight:(CGFloat)height;
- (void)cacheImage:(NSImage *)image withId:(NSString *)imageId andHeight:(CGFloat)height;

/**
 * Clears all of the on-disk and in-memory cache
 */
- (void)clearAll;

@end
