//
//  IDRTMovie.m
//  MovieIDFramework
//
//  Created by Curtis Jones on 2012.10.21.
//  Copyright (c) 2012 Curtis Jones. All rights reserved.
//

#import "IDRTMovie.h"
#import "IDRTPerson.h"
#import "IDSearch.h"
#import "SBJson.h"

@interface IDRTMovie ()
{
	NSMutableDictionary *mInfo;
	NSMutableArray *mCast;
	
	BOOL mGotCast;
}
@end

@implementation IDRTMovie

/**
 * http://api.rottentomatoes.com/api/public/v1.0/movies.json?q=Toy+Story+3&page_limit=50
 *
 * {
 *   "total": 2,
 *   "movies": [
 *     {
 *       "id": "770672122",
 *       "title": "Toy Story 3",
 *       "year": 2010,
 *       "mpaa_rating": "G",
 *       "runtime": 103,
 *       "critics_consensus": "Deftly blending comedy, adventure, and honest emotion, Toy Story 3 is a rare second sequel that really works.",
 *       "release_dates": {
 *         "theater": "2010-06-18",
 *         "dvd": "2010-11-02"
 *       },
 *       "ratings": {
 *         "critics_rating": "Certified Fresh",
 *         "critics_score": 99,
 *         "audience_rating": "Upright",
 *         "audience_score": 91
 *       },
 *       "synopsis": "Pixar returns to their first success with Toy Story 3. The movie begins with Andy leaving for college and donating his beloved toys -- including Woody (Tom Hanks) and Buzz (Tim Allen) -- to a daycare. While the crew meets new friends, including Ken (Michael Keaton), they soon grow to hate their new surroundings and plan an escape. The film was directed by Lee Unkrich from a script co-authored by Little Miss Sunshine scribe Michael Arndt. ~ Perry Seibert, Rovi",
 *       "posters": {
 *         "thumbnail": "http://content6.flixster.com/movie/11/13/43/11134356_mob.jpg",
 *         "profile": "http://content6.flixster.com/movie/11/13/43/11134356_pro.jpg",
 *         "detailed": "http://content6.flixster.com/movie/11/13/43/11134356_det.jpg",
 *         "original": "http://content6.flixster.com/movie/11/13/43/11134356_ori.jpg"
 *       },
 *       "abridged_cast": [
 *         {"name": "Tom Hanks", "characters": ["Woody"]},
 *         {"name": "Tim Allen", "characters": ["Buzz Lightyear"]},
 *         {"name": "Joan Cusack", "characters": ["Jessie the Cowgirl"]},
 *         {"name": "Don Rickles", "characters": ["Mr. Potato Head"]},
 *         {"name": "Wallace Shawn", "characters": ["Rex"]}
 *       ],
 *       "alternate_ids": {"imdb": "0435761"},
 *       "links": {
 *         "self": "http://api.rottentomatoes.com/api/public/v1.0/movies/770672122.json",
 *         "alternate": "http://www.rottentomatoes.com/m/toy_story_3/",
 *         "cast": "http://api.rottentomatoes.com/api/public/v1.0/movies/770672122/cast.json",
 *         "clips": "http://api.rottentomatoes.com/api/public/v1.0/movies/770672122/clips.json",
 *         "reviews": "http://api.rottentomatoes.com/api/public/v1.0/movies/770672122/reviews.json",
 *         "similar": "http://api.rottentomatoes.com/api/public/v1.0/movies/770672122/similar.json"
 *       }
 *     },
 *     ...
 *   ],
 *   "links": {
 *     "self": "http://api.rottentomatoes.com/api/public/v1.0/movies.json?q=Toy+Story+3&page_limit=1&page=1",
 *     "next": "http://api.rottentomatoes.com/api/public/v1.0/movies.json?q=Toy+Story+3&page_limit=1&page=2"
 *   },
 *   "link_template": "http://api.rottentomatoes.com/api/public/v1.0/movies.json?q={search-term}&page_limit={results-per-page}&page={page-number}"
 * }
 */
- (id)initWithDictionary:(NSDictionary *)info
{
	self = [super init];
	
	if (self) {
		mInfo = [[NSMutableDictionary alloc] init];
		mCast = [[NSMutableArray alloc] init];
		
		[info enumerateKeysAndObjectsUsingBlock:^ (id key, id obj, BOOL *stop) {
			mInfo[key] = obj;
		}];
	}
	
	return self;
}





#pragma mark - Other

- (void)getCastDetails
{
	if (![IDSearch rtApiKey].length) {
		NSLog(@"%s.. can't use RT without an api key!", __PRETTY_FUNCTION__);
		return;
	}
	
	mGotCast = TRUE;
	
	NSMutableString *castQuery = [[NSMutableString alloc] init];
	[castQuery appendString:@"http://api.rottentomatoes.com/api/public/v1.0/movies/"];
	[castQuery appendString:self.rtId];
	[castQuery appendString:@"/cast.json?apikey="];
	[castQuery appendString:[IDSearch rtApiKey]];
	
	NSData *castData = [IDSearch doUrlQuery:castQuery];
	
	if (castData) {
		NSDictionary *castInfo = [[[SBJsonParser alloc] init] objectWithData:castData];
		NSArray *casts = (NSArray *)castInfo[@"cast"];
		
		[casts enumerateObjectsUsingBlock:^ (id obj, NSUInteger ndx, BOOL *stop) {
			[mCast addObject:[[IDRTPerson alloc] initWithDictionary:obj]];
		}];
	}
}





#pragma mark - IDMovie

- (NSString *)imdbId
{
	if (mInfo[@"alternate_ids"] && ![mInfo[@"alternate_ids"] isKindOfClass:[NSNull class]]) {
		NSString *imdb = mInfo[@"alternate_ids"][@"imdb"];
		
		if (imdb && ![imdb isKindOfClass:[NSNull class]])
			return imdb;
		else
			return nil;
	}
	else
		return nil;
}

- (NSString *)rtId
{
	if (mInfo[@"id"] && ![mInfo[@"id"] isKindOfClass:[NSNull class]])
		return ((NSNumber *)mInfo[@"id"]).stringValue;
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
	if (mInfo[@"year"] && ![mInfo[@"year"] isKindOfClass:[NSNull class]])
		return mInfo[@"year"];
	else
		return nil;
}

- (NSString *)rating
{
	if (mInfo[@"mpaa_rating"] && ![mInfo[@"mpaa_rating"] isKindOfClass:[NSNull class]])
		return mInfo[@"mpaa_rating"];
	else
		return nil;
}

- (NSNumber *)score
{
	if (mInfo[@"audience_score"] && ![mInfo[@"audience_score"] isKindOfClass:[NSNull class]])
		return mInfo[@"audience_score"];
	else
		return nil;
}

- (NSString *)synopsis
{
	if (mInfo[@"synopsis"] && ![mInfo[@"synopsis"] isKindOfClass:[NSNull class]])
		return mInfo[@"synopsis"];
	else
		return nil;
}

- (NSNumber *)runtime
{
	if (mInfo[@"runtime"] && ![mInfo[@"runtime"] isKindOfClass:[NSNull class]])
		return mInfo[@"runtime"];
	else
		return nil;
}

- (NSURL *)imageUrl
{
	NSDictionary *posters = mInfo[@"posters"];
	NSString *poster = nil;
	
	if (nil == (poster = posters[@"original"]))
		if (nil == (poster = posters[@"detailed"]))
			if (nil == (poster = posters[@"profile"]))
				poster = posters[@"thumbnail"];
	
	if (poster)
		return [NSURL URLWithString:poster];
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
	return mInfo[@"genres"];
}

@end
