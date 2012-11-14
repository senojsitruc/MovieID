//
//  IDTmdbMovie.m
//  MovieIDFramework
//
//  Created by Curtis Jones on 2012.10.19.
//  Copyright (c) 2012 Curtis Jones. All rights reserved.
//

#import "IDTmdbMovie.h"
#import "IDTmdbPerson.h"
#import "IDSearch.h"
#import "SBJson.h"

@interface IDTmdbMovie ()
{
	NSMutableDictionary *mInfo;
	NSMutableArray *mCast;
	NSMutableArray *mGenres;
	
	BOOL mGotMovie;
	BOOL mGotCast;
	BOOL mGotGenres;
}
@end

@implementation IDTmdbMovie

/**
 * API Documentation:
 *
 *   http://docs.themoviedb.apiary.io/#movies
 *
 * http://api.themoviedb.org/3/search/movie?api_key=d257f5f93714b665cefa48800a6332e2&query=Fair+Game+1995
 *
 * {
 *   "page":1,
 *   "results":[
 *     {
 *       "adult":false,
 *       "backdrop_path":"/qev1bI9ppIhgFdW6F72VmTBBtK1.jpg",
 *       "id":11859,
 *       "original_title":"Fair Game",
 *       "release_date":"1995-11-03",
 *       "poster_path":"/g3X5Gk4N0Sll1j3WC24zl1PCvq5.jpg",
 *       "popularity":0.107,
 *       "title":"Fair Game",
 *       "vote_average":7.0,
 *       "vote_count":0
 *     }
 *   ],
 *   "total_pages":1,
 *   "total_results":1
 * }
 *
 *
 *
 * http://api.themoviedb.org/3/movie/11859?api_key=d257f5f93714b665cefa48800a6332e2
 *
 * {
 *   "adult":false,
 *   "backdrop_path":"/qev1bI9ppIhgFdW6F72VmTBBtK1.jpg",
 *   "belongs_to_collection":null,
 *   "budget":30000000,
 *   "genres":[
 *     {"id":28,"name":"Action"},
 *     {"id":53,"name":"Thriller"},
 *     {"id":10749,"name":"Romance"}
 *   ],
 *   "homepage":"",
 *   "id":11859,
 *   "imdb_id":"tt0113010",
 *   "original_title":"Fair Game",
 *   "overview":"Max Kirkpatrick is a cop who protects Kate McQuean, a civil law attorney, from a renegade KGB team out to terminate her",
 *   "popularity":0.179,
 *   "poster_path":"/g3X5Gk4N0Sll1j3WC24zl1PCvq5.jpg",
 *   "production_companies":[],
 *   "production_countries":[{"iso_3166_1":"US","name":"United States of America"}],
 *   "release_date":"1995-11-03",
 *   "revenue":11534477,
 *   "runtime":91,
 *   "spoken_languages":[{"iso_639_1":"en","name":"English"}],
 *   "tagline":"He's a cop on the edge. She's a woman with a dangerous secret. And now they're both...",
 *   "title":"Fair Game",
 *   "vote_average":7.0,
 *   "vote_count":0
 * }
 *
 * http://cf2.imgobject.com/t/p/original/g3X5Gk4N0Sll1j3WC24zl1PCvq5.jpg
 *
 */
- (id)initWithDictionary:(NSDictionary *)info
{
	self = [super init];
	
	if (self) {
		mInfo = [[NSMutableDictionary alloc] init];
		mCast = [[NSMutableArray alloc] init];
		mGenres = [[NSMutableArray alloc] init];
		
		[info enumerateKeysAndObjectsUsingBlock:^ (id key, id obj, BOOL *stop) {
			mInfo[key] = obj;
		}];
	}
	
	return self;
}





#pragma mark - Other

- (void)getMovieDetails
{
	if (![IDSearch tmdbApiKey].length) {
		NSLog(@"%s.. can't use TMDb without an api key!", __PRETTY_FUNCTION__);
		return;
	}
	
	mGotMovie = TRUE;
	
	NSMutableString *movieQuery = [[NSMutableString alloc] init];
	[movieQuery appendString:@"http://api.themoviedb.org/3/movie/"];
	[movieQuery appendString:[mInfo[@"id"] stringValue]];
	[movieQuery appendString:@"?api_key="];
	[movieQuery appendString:[IDSearch tmdbApiKey]];
	
	NSData *movieData = [IDSearch doUrlQuery:movieQuery];
	
	if (movieData) {
		NSDictionary *info = [[[SBJsonParser alloc] init] objectWithData:movieData];
		
		[info enumerateKeysAndObjectsUsingBlock:^ (id key, id obj, BOOL *stop) {
			mInfo[key] = obj;
		}];
	}
}

- (void)getCastDetails
{
	if (![IDSearch tmdbApiKey].length) {
		NSLog(@"%s.. can't use TMDb without an api key!", __PRETTY_FUNCTION__);
		return;
	}
	
	mGotCast = TRUE;
	
	NSMutableString *castQuery = [[NSMutableString alloc] init];
	[castQuery appendString:@"http://api.themoviedb.org/3/movie/"];
	[castQuery appendString:[mInfo[@"id"] stringValue]];
	[castQuery appendString:@"/casts"];
	[castQuery appendString:@"?api_key="];
	[castQuery appendString:[IDSearch tmdbApiKey]];
	[castQuery appendString:@"&include_adult=1&query="];
	
	NSData *castData = [IDSearch doUrlQuery:castQuery];
	
	if (castData) {
		NSDictionary *castInfo = [[[SBJsonParser alloc] init] objectWithData:castData];
		NSArray *casts = (NSArray *)castInfo[@"cast"];
		
		[casts enumerateObjectsUsingBlock:^ (id obj, NSUInteger ndx, BOOL *stop) {
			[mCast addObject:[[IDTmdbPerson alloc] initWithDictionary:obj]];
		}];
	}
}





#pragma mark - IDMovie

- (NSString *)tmdbId
{
	return ((NSNumber *)mInfo[@"id"]).stringValue;
}

- (NSString *)imdbId
{
	if (!mGotMovie)
		[self getMovieDetails];
	
	if (mInfo[@"imdb_id"] && ![mInfo[@"imdb_id"] isKindOfClass:[NSNull class]])
		return mInfo[@"imdb_id"];
	else
		return nil;
}

- (NSString *)title
{
	if (mInfo[@"title"] && ![mInfo[@"title"] isKindOfClass:[NSNull class]])
		return mInfo[@"title"];
	else
		return nil;
}

- (NSNumber *)year
{
	if (mInfo[@"release_date"] && ![mInfo[@"release_date"] isKindOfClass:[NSNull class]]) {
		NSString *year = mInfo[@"release_date"];
		
		if (year.length >= 4)
			return @([year substringToIndex:4].integerValue);
		else
			return nil;
	}
	else
		return nil;
}

- (NSNumber *)score
{
	if (!mGotMovie)
		[self getMovieDetails];
	
	if (mInfo[@"vote_average"] && ![mInfo[@"vote_average"] isKindOfClass:[NSNull class]]) {
		NSNumber *score = mInfo[@"vote_average"];
		return @((NSUInteger)(score.doubleValue * 10.));
	}
	else
		return nil;
}

- (NSString *)synopsis
{
	if (!mGotMovie)
		[self getMovieDetails];
	
	if (mInfo[@"overview"] && ![mInfo[@"overview"] isKindOfClass:[NSNull class]])
		return mInfo[@"overview"];
	else
		return nil;
}

- (NSNumber *)runtime
{
	if (!mGotMovie)
		[self getMovieDetails];
	
	if (mInfo[@"runtime"] && ![mInfo[@"runtime"] isKindOfClass:[NSNull class]])
		return mInfo[@"runtime"];
	else
		return nil;
}

- (NSURL *)imageUrl
{
	if (mInfo[@"poster_path"] && ![mInfo[@"poster_path"] isKindOfClass:[NSNull class]])
		return [NSURL URLWithString:[@"http://cf2.imgobject.com/t/p/original" stringByAppendingPathComponent:mInfo[@"poster_path"]]];
	else
		return nil;
}

- (NSArray *)cast
{
	if (!mGotCast)
		[self getCastDetails];
	
	return mCast;
}

- (NSArray *)genres
{
	if (!mGotMovie)
		[self getMovieDetails];
	
	if (!mGotGenres) {
		[(NSArray *)mInfo[@"genres"] enumerateObjectsUsingBlock:^ (id obj, NSUInteger ndx, BOOL *stop) {
			[mGenres addObject:((NSDictionary *)obj)[@"name"]];
		}];
		
		mGotGenres = TRUE;
	}
	
	return mGenres;
}

@end
