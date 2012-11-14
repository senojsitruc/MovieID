//
//  IDIMDbPerson.m
//  MovieIDFramework
//
//  Created by Curtis Jones on 2012.10.21.
//  Copyright (c) 2012 Curtis Jones. All rights reserved.
//

#import "IDIMDbPerson.h"
#import "SBJson.h"
#import "IDSearch.h"

@interface IDIMDbPerson ()
{
	NSMutableDictionary *mInfo;
	BOOL mGotPerson;
}
@end

@implementation IDIMDbPerson

/**
 * {"nconst":"nm0573223","name":"CiarÃ¡n McMenamin","image":{"width":2600,"url":"http://ia.media-imdb.com/images/M/MV5BMTUzMDc0MzY2NF5BMl5BanBnXkFtZTcwNzA4MzYxNA@@._V1_.jpg","height":3888}}},
 */
- (id)initWithDictionary:(NSDictionary *)info
{
	self = [super init];
	
	if (self) {
		mInfo = [[NSMutableDictionary alloc] initWithDictionary:info];
	}
	
	return self;
}

/**
 * https://app.imdb.com/name/maindetails?api=1&appid=iphone1_1&apiPolicy=app1_1&apiKey=2wex6aeu6a8q9e49k7sfvufd6rhh0n&locale=en_US&timestamp=1350966941&nconst=nm0001015&sig=app1-acw91D7e08wlN5O5LS5312gWj9I=
 *
 * {
 *   "exp":1350970565,
 *   "@meta":{"serverTimeMs":38,"requestId":"13PN9WJA4F10S65FAT3G"},
 *   "data":{
 *     "photos":[
 *       {"link":"http://www.imdb.com/rg/appphoto/link/media/rm3357980160/nm0001015","image":{"width":1711,"url":"http://ia.media-imdb.com/images/M/MV5BNzUzNTM4NjEwNV5BMl5BanBnXkFtZTcwNTg5MTE1Nw@@._V1_.jpg","height":2048}},
 *       {"link":"http://www.imdb.com/rg/appphoto/link/media/rm3160583680/nm0001015","image":{"width":640,"url":"http://ia.media-imdb.com/images/M/MV5BMTQyMDc2MTYwOF5BMl5BanBnXkFtZTcwMzc4OTg1OA@@._V1_.jpg","height":426}},
 *       {"link":"http://www.imdb.com/rg/appphoto/link/media/rm469415680/nm0001015","image":{"width":427,"url":"http://ia.media-imdb.com/images/M/MV5BMTgwNDQ4Mjc4N15BMl5BanBnXkFtZTcwNDIyNDU1Nw@@._V1_.jpg","height":640}},
 *       {"link":"http://www.imdb.com/rg/appphoto/link/media/rm26581248/nm0001015","image":{"width":475,"url":"http://ia.media-imdb.com/images/M/MV5BMTI4NTg5NTIzOV5BMl5BanBnXkFtZTYwMzkyOTU3._V1_.jpg","height":323}},
 *       {"link":"http://www.imdb.com/rg/appphoto/link/media/rm419084032/nm0001015","image":{"width":640,"url":"http://ia.media-imdb.com/images/M/MV5BMTQyODI4MTEzN15BMl5BanBnXkFtZTcwNzIyNDU1Nw@@._V1_.jpg","height":427}},
 *       {"link":"http://www.imdb.com/rg/appphoto/link/media/rm2204282368/nm0001015","image":{"width":640,"url":"http://ia.media-imdb.com/images/M/MV5BMTU5MTEzOTA4Nl5BMl5BanBnXkFtZTcwMjg4OTg1OA@@._V1_.jpg","height":426}}
 *     ],
 *     "birth":{"date":{"normal":"1961-04-14"},"place":"Glasgow, Scotland, UK"},
 *     "has":["trivia","quotes","photos"],
 *     "known_for":[
 *       {"title":{"tconst":"tt0463854","type":"feature","title":"28 Weeks Later","image":{"width":510,"url":"http://ia.media-imdb.com/images/M/MV5BMTUxMjc2MTcxNV5BMl5BanBnXkFtZTcwMzgzOTY0MQ@@._V1_.jpg","height":755},"year":"2007"},"attr":"Actor"},
 *       {"title":{"tconst":"tt0117951","type":"feature","title":"Trainspotting","image":{"width":348,"url":"http://ia.media-imdb.com/images/M/MV5BMTQ4MTg5Nzc3NF5BMl5BanBnXkFtZTcwMTM4OTUyMQ@@._V1_.jpg","height":500},"year":"1996"},"attr":"Actor"},
 *       {"title":{"tconst":"tt0119164","type":"feature","title":"The Full Monty","image":{"width":335,"url":"http://ia.media-imdb.com/images/M/MV5BMTg2NDM5NTQzM15BMl5BanBnXkFtZTcwMzg0OTMyMQ@@._V1_.jpg","height":475},"year":"1997"},"attr":"Actor"},
 *       {"title":{"tconst":"tt0143145","type":"feature","title":"The World Is Not Enough","image":{"width":682,"url":"http://ia.media-imdb.com/images/M/MV5BMjA0MzUyNjg0MV5BMl5BanBnXkFtZTcwNDY5MDg0NA@@._V1_.jpg","height":1023},"year":"1999"},"attr":"Actor"}
 *     ],
 *     "name":"Robert Carlyle",
 *     "image":{"width":1725,"url":"http://ia.media-imdb.com/images/M/MV5BMTM2Njc1MjgyOF5BMl5BanBnXkFtZTcwMjY2NTAwNw@@._V1_.jpg","height":2304},
 *     "nconst":"nm0001015",
 *     "news":{
 *       "channel":"nm0001015","total":796,
 *       "sources":{
 *         "ns0000262":{"logo":"http://ia.media-imdb.com/images/M/MV5BMTczMzkzNDUyN15BMl5BanBnXkFtZTcwOTk5OTk1Mg@@._V1._SY140_.jpg","url":"http://www.soundonsight.org","label":"SoundOnSight"},
 *         "ns0000040":{"logo":"http://ia.media-imdb.com/images/M/MV5BMTIzNzk4MDU5NF5BMl5BanBnXkFtZTcwNjE1MDY3MQ@@._V1_.jpg","url":"http://screenrant.com/","label":"Screen Rant"},
 *         "ns0000345":{"logo":"http://ia.media-imdb.com/images/M/MV5BMTM0NDgzNDYxMV5BMl5BanBnXkFtZTcwMzgwNjk3Mg@@._V1._SY140_.jpg","url":"http://insidetv.ew.com/","label":"EW.com - Inside TV"}
 *       },
 *       "markup":"flat",
 *       "label":"Robert Carlyle",
 *       "limit":3,
 *       "items":[
 *         {"source":"ns0000262","head":"Once Upon A Time, Ep. 2.04, â€œThe Crocodileâ€: Enter the Hook","id":"ni38959355","datetime":"2012-10-22T15:48:00Z"},
 *         {"source":"ns0000040","head":"â€˜Once Upon A Timeâ€™ Season 2, Episode 4: â€˜The Crocodileâ€™ Recap","id":"ni38958861","datetime":"2012-10-22T15:21:00Z"},
 *         {"source":"ns0000345","head":"'Once Upon' showrunners reveal which famous characters they'd consider adding","id":"ni38919189","datetime":"2012-10-22T02:27:00Z"}
 *       ],
 *       "@type":"mobile.news.list",
 *       "start":0
 *     },
 *     "bio":"Robert Carlyle was raised in Maryhill, Glasgow, Scotland, by his father Joseph, after his mother left him when he was only four. At the age of 21, after reading Arthur Miller's \"The Crucible,\" he enrolled in acting classes at the Glasgow Arts Centre. In 1991, together with four other actors, he founded the Raindog theatre company (named after Tom Waits' album \"Rain Dog,\" one of Carlyle's favorites), a company dedicated to innovative work."
 *   },
 *   "copyright":"For use only by clients authorized in writing by IMDb.  Authors and users of unauthorized clients accept full legal exposure/liability for their actions."
 * }
 *
 */
- (void)getPersonDetails
{
	mGotPerson = TRUE;
	
	SBJsonParser *parser = [[SBJsonParser alloc] init];
	NSData *searchData = [IDSearch doUrlQuery:[IDSearch imdbQueryUrlWithAction:@"name/maindetails" method:@"nconst" query:mInfo[@"nconst"] anonymous:TRUE]];
	NSDictionary *imdbinfo = [parser objectWithData:searchData];
	
	[imdbinfo[@"data"] enumerateKeysAndObjectsUsingBlock:^ (id key, id obj, BOOL *stop) {
		mInfo[key] = obj;
	}];
}





#pragma mark - IDPerson

- (NSString *)imdbId
{
	if (mInfo[@"nconst"] && [mInfo[@"nconst"] isKindOfClass:[NSString class]])
		return mInfo[@"nconst"];
	else
		return nil;
}

- (NSString *)name
{
	if (mInfo[@"name"] && [mInfo[@"name"] isKindOfClass:[NSString class]])
		return mInfo[@"name"];
	else
		return nil;
}

- (NSArray *)characters
{
	if (!mGotPerson)
		[self getPersonDetails];
	
	if (mInfo[@"character"] && ![mInfo[@"character"] isKindOfClass:[NSNull class]])
		return @[mInfo[@"character"]];
	else
		return nil;
}

- (NSString *)bio
{
	if (!mGotPerson)
		[self getPersonDetails];
	
	if (mInfo[@"bio"] && [mInfo[@"bio"] isKindOfClass:[NSString class]])
		return mInfo[@"bio"];
	else
		return nil;
}

- (NSString *)dob
{
	if (!mGotPerson)
		[self getPersonDetails];
	
	if (mInfo[@"birth"][@"date"][@"normal"] && [mInfo[@"birth"][@"date"][@"normal"] isKindOfClass:[NSString class]])
		return mInfo[@"birth"][@"date"][@"normal"];
	else
		return nil;
}

- (NSString *)dod
{
	if (!mGotPerson)
		[self getPersonDetails];
	
	if (mInfo[@"death"][@"date"][@"normal"] && [mInfo[@"death"][@"date"][@"normal"] isKindOfClass:[NSString class]])
		return mInfo[@"death"][@"date"][@"normal"];
	else
		return nil;
}

- (NSURL *)imageUrl
{
	if (mInfo[@"image"][@"url"] && [mInfo[@"image"][@"url"] isKindOfClass:[NSString class]])
		return [NSURL URLWithString:mInfo[@"image"][@"url"]];
	else
		return nil;
}

@end
