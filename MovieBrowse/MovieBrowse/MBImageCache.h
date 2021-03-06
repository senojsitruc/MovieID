//
//  MBImageCache.h
//  MovieBrowse
//
//  Created by Curtis Jones on 2012.10.18.
//  Copyright (c) 2012 Curtis Jones. All rights reserved.
//

#import <Foundation/Foundation.h>

@class MBMovie;

@interface MBImageCache : NSObject

+ (id)sharedInstance;

/**
 * Screencaps
 */
- (void)screencapInfoForMovie:(MBMovie *)mbmovie duration:(NSUInteger *)duration width:(NSUInteger *)width height:(NSUInteger *)height;
- (NSImage *)screencapImageForMovie:(MBMovie *)mbmovie offset:(NSUInteger)offset width:(NSUInteger)width height:(NSUInteger)height;

/**
 * Posters
 */
- (NSImage *)actorImageWithId:(NSString *)imageId;
- (NSImage *)actorImageWithId:(NSString *)imageId width:(NSUInteger)width height:(NSUInteger)height;
- (NSImage *)movieImageWithId:(NSString *)imageId;
- (NSImage *)movieImageWithId:(NSString *)imageId width:(NSUInteger)width height:(NSUInteger)height;

- (NSImage *)cachedImageWithId:(NSString *)imageId andHeight:(CGFloat)height;
- (void)cacheImage:(NSImage *)image withId:(NSString *)imageId andHeight:(CGFloat)height;

/**
 * Clears cached data.
 */
- (void)clearAll;
- (void)clearActorCacheForId:(NSString *)imageId;
- (void)clearMovieCacheForId:(NSString *)imageId;

@end
