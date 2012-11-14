//
//  IDSearch.h
//  MovieIDFramework
//
//  Created by Curtis Jones on 2012.10.19.
//  Copyright (c) 2012 Curtis Jones. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface IDSearch : NSObject

+ (NSArray *)titlesForName:(NSString *)movieName;
+ (NSString *)titleForName:(NSString *)aName;
+ (NSNumber *)yearForName:(NSString *)name;

+ (NSArray *)tmdbSearchMovieWithTitle:(NSString *)title andYear:(NSNumber *)year andRuntime:(NSNumber *)runtime;
+ (NSArray *)imdbSearchMovieWithTitle:(NSString *)title andYear:(NSNumber *)year andRuntime:(NSNumber *)runtime;
+ (NSString *)imdbQueryUrlWithAction:(NSString *)action method:(NSString *)method query:(NSString *)query anonymous:(BOOL)anonymous;

+ (NSData *)doUrlQuery:(NSString *)query;

+ (void)setTmdbApiKey:(NSString *)apiKey;
+ (void)setImdbApiKey:(NSString *)apiKey;
+ (void)setRtApiKey:(NSString *)apiKey;

+ (NSString *)tmdbApiKey;
+ (NSString *)imdbApiKey;
+ (NSString *)rtApiKey;

@end
