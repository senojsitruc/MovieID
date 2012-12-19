//
//  IDSearch.m
//  MovieIDFramework
//
//  Created by Curtis Jones on 2012.10.19.
//  Copyright (c) 2012 Curtis Jones. All rights reserved.
//

#import "IDSearch.h"
#import "SBJson.h"
#import "RegexKitLite.h"
#import "IDImdbMovie.h"
#import "IDTmdbMovie.h"
#import "NSData+Base64.h"
#import <CommonCrypto/CommonCrypto.h>
#import <CommonCrypto/CommonDigest.h>

static NSString *gTmdbApiKey;
static NSString *gImdbApiKey;
static NSString *gRtApiKey;

@implementation IDSearch

#pragma mark - API Keys

+ (void)setTmdbApiKey:(NSString *)apiKey
{
	gTmdbApiKey = apiKey;
}

+ (void)setImdbApiKey:(NSString *)apiKey
{
	gImdbApiKey = apiKey;
}

+ (void)setRtApiKey:(NSString *)apiKey
{
	gRtApiKey = apiKey;
}

+ (NSString *)tmdbApiKey
{
	return gTmdbApiKey;
}

+ (NSString *)imdbApiKey
{
	return gImdbApiKey;
}

+ (NSString *)rtApiKey
{
	return gRtApiKey;
}





#pragma mark - Names

/**
 * Some Movie, The (1979) - The Final Chapter
 *
 */
+ (NSArray *)titlesForName:(NSString *)name
{
	NSMutableDictionary *names = [[NSMutableDictionary alloc] init];
	
	NSString *_name = [name lowercaseString];
	
	// remave the year
	_name = [_name stringByReplacingOccurrencesOfRegex:@"\\(\\d\\d\\d\\d\\)" withString:@""];
	_name = [_name stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
	_name = [_name stringByReplacingOccurrencesOfRegex:@"  " withString:@" "];
	_name = [_name stringByReplacingOccurrencesOfRegex:@" \\- " withString:@": "];
	
	// move articles from the end to the beginning of the title
	{
		NSArray *parts = [_name componentsSeparatedByString:@": "];
		NSMutableString *tmp = [[NSMutableString alloc] init];
		
		[parts enumerateObjectsUsingBlock:^ (id obj, NSUInteger ndx, BOOL *stop) {
			NSString *part = [(NSString *)obj stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
			
			if ([part hasSuffix:@", a"])
				part = [@"a " stringByAppendingString:[part substringToIndex:part.length-3]];
			else if ([part hasSuffix:@", an"])
				part = [@"an " stringByAppendingString:[part substringToIndex:part.length-4]];
			else if ([part hasSuffix:@", the"])
				part = [@"the " stringByAppendingString:[part substringToIndex:part.length-5]];
			
			if (tmp.length)
				[tmp appendString:@": "];
			
			if (ndx == 0)
				names[part] = part;
			
			[tmp appendString:part];
		}];
		
		_name = [NSString stringWithString:tmp];
		names[_name] = _name;
	}
	
	// swap ampersand for "and"
	{
		_name = [_name stringByReplacingOccurrencesOfRegex:@" & " withString:@" and "];
		names[_name] = _name;
	}
	
	// strip punctuation
	{
		NSString *tmp = [_name stringByReplacingOccurrencesOfRegex:@"[^A-Za-z0-9\\s]" withString:@""];
		tmp = [tmp stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
		tmp = [tmp stringByReplacingOccurrencesOfRegex:@"  " withString:@" "];
		names[tmp] = tmp;
	}
	
	// strip colons
	{
		NSString *tmp = [_name stringByReplacingOccurrencesOfRegex:@"\\:" withString:@""];
		tmp = [tmp stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
		tmp = [tmp stringByReplacingOccurrencesOfRegex:@"  " withString:@" "];
		names[tmp] = tmp;
	}
	
	return [names.allKeys sortedArrayUsingComparator:^ NSComparisonResult (id obj1, id obj2) {
		NSString *s1=(NSString *)obj1, *s2=(NSString *)obj2;
		
		if (s1.length > s2.length)
			return NSOrderedAscending;
		else if (s1.length < s2.length)
			return NSOrderedDescending;
		else
			return NSOrderedSame;
	}];
}

/**
 * Some Movie, The (1979) - The Final Chapter
 *
 */
+ (NSString *)titleForName:(NSString *)aName
{
	__block NSString *name = aName;
	
	// remave the year
	name = [name stringByReplacingOccurrencesOfRegex:@"\\(\\d\\d\\d\\d\\)" withString:@""];
	name = [name stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
	name = [name stringByReplacingOccurrencesOfRegex:@"  " withString:@" "];
	name = [name stringByReplacingOccurrencesOfRegex:@" \\- " withString:@": "];
	
	// move articles from the end to the beginning of the title
	{
		NSArray *parts = [name componentsSeparatedByString:@": "];
		NSMutableString *tmp = [[NSMutableString alloc] init];
		
		[parts enumerateObjectsUsingBlock:^ (id obj, NSUInteger ndx, BOOL *stop) {
			NSString *part = [(NSString *)obj stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
			
			if ([part hasSuffix:@", A"])
				part = [@"A " stringByAppendingString:[part substringToIndex:part.length-3]];
			else if ([part hasSuffix:@", An"])
				part = [@"An " stringByAppendingString:[part substringToIndex:part.length-4]];
			else if ([part hasSuffix:@", The"])
				part = [@"The " stringByAppendingString:[part substringToIndex:part.length-5]];
			
			if (tmp.length)
				[tmp appendString:@": "];
			
			name = part;
			*stop = TRUE;
		}];
	}
	
	return name;
}

/**
 * Some Movie, The (1979) - The Final Chapter
 *
 */
+ (NSNumber *)yearForName:(NSString *)name
{
	NSString *year = nil;
	
	year = [name stringByMatching:@"\\((\\d\\d\\d\\d)\\)"];
	year = [year substringWithRange:NSMakeRange(1, 4)];
	
	return @(year.integerValue);
}





#pragma mark - TMDb

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
 */
+ (NSArray *)tmdbSearchMovieWithTitle:(NSString *)title andYear:(NSNumber *)year andRuntime:(NSNumber *)runtime
{
	if (![self tmdbApiKey].length) {
		NSLog(@"%s.. can't use TMDb without an api key!", __PRETTY_FUNCTION__);
		return nil;
	}
	
	NSMutableString *searchQuery = [[NSMutableString alloc] init];
	[searchQuery appendString:@"http://api.themoviedb.org/3/search/movie?api_key="];
	[searchQuery appendString:[self tmdbApiKey]];
	[searchQuery appendString:@"&include_adult=1&query="];
	[searchQuery appendString:[title stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
	[searchQuery appendString:@"&year="];
	
	if (year.integerValue)
		[searchQuery appendString:year.stringValue];
	
	NSData *searchData = [self doUrlQuery:searchQuery];
	
	NSDictionary *tmdb_info = [[[SBJsonParser alloc] init] objectWithData:searchData];
	NSArray *movies = tmdb_info[@"results"];
	NSMutableArray *results = [[NSMutableArray alloc] init];
	
	//NSLog(@"%@", tmdb_info);
	
	[movies enumerateObjectsUsingBlock:^ (id obj, NSUInteger ndx, BOOL *stop) {
		[results addObject:[[IDTmdbMovie alloc] initWithDictionary:obj]];
	}];
	
	return results;
}





#pragma mark - IMDb

/**
 * http://code.google.com/p/imdb-php/source/browse/trunk/Imdbphp/Person.php?r=5
 * https://app.imdb.com/find?api=1&appid=iphone1_1&apiPolicy=app1_1&apiKey=2wex6aeu6a8q9e49k7sfvufd6rhh0n&locale=en_US&timestamp=1350964228&q=To%20End%20All%20Wars&sig=app1-OLsUOga+h8w3CRb8iXoVgRyJONg=
 *
 * {
 *   "@meta":{"serverTimeMs":75,"requestId":"12Q7WAG1SFYCYJSMD7B1"},
 *   "data":
 *     {
 *       "fields":["title","name"],
 *       "q":"to end all wars",
 *       "results":[
 *         {
 *           "label":"Search results",
 *           "list":[
 *             {
 *               "tconst":"tt0243609",
 *               "type":"feature",
 *               "title":"To End All Wars",
 *               "principals":[
 *                 {"nconst":"nm0001015","name":"Robert Carlyle"},
 *                 {"nconst":"nm0000662","name":"Kiefer Sutherland"},
 *                 {"nconst":"nm0573223","name":"CiarÃ¡n McMenamin"}
 *               ],
 *               "image":{"width":400,"url":"http://ia.media-imdb.com/images/M/MV5BMjAyMDMxMTExOV5BMl5BanBnXkFtZTcwNzEwMjYyMQ@@._V1_.jpg","height":573},
 *               "year":"2001"
 *             },
 *             {
 *               "tconst":"tt1857613",
 *               "type":"feature",
 *               "title":"A War to End All Wars",
 *               "principals":[{"nconst":"nm4358930","name":"John Duncan"},{"nconst":"nm1145364","name":"Taff Gillingham"},{"nconst":"nm4358834","name":"Ian Livesey"}],
 *               "image":{"width":1110,"url":"http://ia.media-imdb.com/images/M/MV5BMTM5OTk4Mjk3OF5BMl5BanBnXkFtZTcwNDMxMTQxOA@@._V1_.jpg","height":1600},
 *               "year":"2010"
 *             },
 *             {
 *               "tconst":"tt1365602",
 *               "type":"feature",
 *               "title":"Fennario's War: The War to End All Wars",
 *               "principals":[{"nconst":"nm1739896","name":"David Fennario"},{"nconst":"nm0533859","name":"Alec G. MacLeod"},{"nconst":"nm3299095","name":"Patrick Barnard"}],
 *               "year":"2008"
 *             },
 *           ]
 *         }
 *       ]
 *     },
 *     "@type":"mobile.find.results",
 *     "copyright":"For use only by clients authorized in writing by IMDb.  Authors and users of unauthorized clients accept full legal exposure/liability for their actions."
 *   }
 *
 *   title/maindetails
 *   name/maindetails
 *   name/photos
 *
 */
+ (NSArray *)imdbSearchMovieWithTitle:(NSString *)title andYear:(NSNumber *)year andRuntime:(NSNumber *)runtime
{
	if ([title hasPrefix:@"tt"])
		return @[[[IDIMDbMovie alloc] initWithDictionary:@{@"tconst":title}]];
	
	SBJsonParser *parser = [[SBJsonParser alloc] init];
	NSData *searchData = [[self class] doUrlQuery:[[self class] imdbQueryUrlWithAction:@"find" method:@"q" query:title anonymous:FALSE]];
	NSDictionary *imdbinfo = [parser objectWithData:searchData];
	NSArray *movies = imdbinfo[@"data"][@"results"][0][@"list"];
	NSMutableArray *results = [[NSMutableArray alloc] init];
	
	[movies enumerateObjectsUsingBlock:^ (id obj, NSUInteger ndx, BOOL *stop) {
		NSDictionary *result = (NSDictionary *)obj;
		
		if (result[@"tconst"])
			[results addObject:[[IDIMDbMovie alloc] initWithDictionary:(NSDictionary *)obj]];
	}];
	
	return results;
}

/**
 *
 *
 */
+ (NSString *)imdbQueryUrlWithAction:(NSString *)action method:(NSString *)method query:(NSString *)query anonymous:(BOOL)anonymous
{
	NSMutableString *searchQuery = [[NSMutableString alloc] init];
	
	if (anonymous)
		[searchQuery appendString:@"http://anonymouse.org/cgi-bin/anon-www.cgi/"];
	
	[searchQuery appendString:@"https://app.imdb.com/"];
	[searchQuery appendString:action];
	[searchQuery appendString:@"?api=1&appid=iphone1_1&apiPolicy=app1_1&apiKey=2wex6aeu6a8q9e49k7sfvufd6rhh0n&locale=en_US&timestamp="];
	[searchQuery appendString:[[NSNumber numberWithUnsignedLongLong:(unsigned long long)[[NSDate date] timeIntervalSince1970]] stringValue]];
	[searchQuery appendString:@"&"];
	[searchQuery appendString:method];
	[searchQuery appendString:@"="];
	[searchQuery appendString:[query stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
	
	{
		NSString *key = @"2wex6aeu6a8q9e49k7sfvufd6rhh0n";
		
		const char *cKey  = [key cStringUsingEncoding:NSASCIIStringEncoding];
		const char *cData = [searchQuery cStringUsingEncoding:NSASCIIStringEncoding];
		unsigned char cHMAC[CC_SHA1_DIGEST_LENGTH];
		
		CCHmac(kCCHmacAlgSHA1, cKey, strlen(cKey), cData, strlen(cData), cHMAC);
		NSData *HMAC = [[NSData alloc] initWithBytes:cHMAC length:sizeof(cHMAC)];
		NSString *hash = [HMAC base64EncodedString];
		
		[searchQuery appendString:@"&sig=app1-"];
		[searchQuery appendString:hash];
	}
	
	//NSLog(@"%@", searchQuery);
	
	return searchQuery;
}





#pragma mark - Helper

/**
 *
 *
 */
+ (NSData *)doUrlQuery:(NSString *)query
{
	//NSLog(@"%@", query);
	
	NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
	request.HTTPMethod = @"GET";
	request.timeoutInterval = 60;
	request.URL = [NSURL URLWithString:query];
	
	NSError *error = nil;
	NSURLResponse *response = nil;
	NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
	
	if (error) {
		NSLog(@"%s.. request failed: %@", __PRETTY_FUNCTION__, error.localizedDescription);
		return nil;
	}
	
	return data;
}

@end
