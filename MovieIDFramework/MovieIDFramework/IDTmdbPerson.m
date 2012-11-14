//
//  IDTmdbPerson.m
//  MovieIDFramework
//
//  Created by Curtis Jones on 2012.10.19.
//  Copyright (c) 2012 Curtis Jones. All rights reserved.
//

#import "IDTmdbPerson.h"
#import "IDSearch.h"
#import "SBJson.h"

@interface IDTmdbPerson ()
{
	NSMutableDictionary *mInfo;
	BOOL mGotPerson;
}
@end

@implementation IDTmdbPerson

/**
 * API Documentation:
 *
 *   http://docs.themoviedb.apiary.io/#movies
 *
 * http://api.themoviedb.org/3/movie/11859/casts?api_key=d257f5f93714b665cefa48800a6332e2
 *
 * {
 *   "id":11859,
 *   "cast":[
 *     {"id":13021,"name":"William Baldwin","character":"Max Kirkpatrick","order":0,"cast_id":1,"profile_path":"/oWiJAC3uhU8n6KJcnAiREsrzOPo.jpg"},
 *     {"id":33665,"name":"Cindy Crawford","character":"Kate McQueen","order":1,"cast_id":2,"profile_path":"/z8gSG4KQ2sDLIvovfnnPYSfAJsr.jpg"},
 *     {"id":782,"name":"Steven Berkoff","character":"Colonel Ilya Kazak","order":2,"cast_id":3,"profile_path":"/gFu5EHbmtADAWUqnmpH28Ham6QB.jpg"},
 *     {"id":4443,"name":"Christopher McDonald","character":"Lieutenant Meyerson","order":3,"cast_id":4,"profile_path":"/8kzIhRn71BcVAoU5ddA9l3STZs1.jpg"}
 *   ],
 *   "crew":[
 *     {"id":70850,"name":"Andrew Sipes","department":"Directing","job":"Director","profile_path":null},
 *     {"id":1091,"name":"Joel Silver","department":"Production","job":"Producer","profile_path":null},
 *     {"id":61572,"name":"Charlie Fletcher","department":"Writing","job":"Screenplay","profile_path":null},
 *     {"id":9989,"name":"Mark Mancina","department":"Sound","job":"Original Music Composer","profile_path":"/wy8OJQsTenNJ43pLnw2yr9l3Orh.jpg"},
 *     {"id":67391,"name":"Richard Bowen","department":"Camera","job":"Director of Photography","profile_path":null},
 *     {"id":6668,"name":"Christian Wagner","department":"Editing","job":"Editor","profile_path":null}
 *   ]
 * }
 *
 *
 *
 * http://api.themoviedb.org/3/person/287?api_key=d257f5f93714b665cefa48800a6332e2
 *
 * {
 *   "adult":false,
 *   "also_known_as":[],
 *   "biography":"From Wikipedia, the free encyclopedia.\n\nWilliam Bradley \"Brad\" Pitt (born December 18, 1963) is an American actor and film producer. Pitt has received two Academy Award nominations and four Golden Globe Award nominations, winning one. He has been described as one of the world's most attractive men, a label for which he has received substantial media attention.\n\nPitt began his acting career with television guest appearances, including a role on the CBS prime-time soap opera Dallas in 1987. He later gained recognition as the cowboy hitchhiker who seduces Geena Davis's character in the 1991 road movie Thelma & Louise. Pitt's first leading roles in big-budget productions came with A River Runs Through It (1992) and Interview with the Vampire (1994). He was cast opposite Anthony Hopkins in the 1994 drama Legends of the Fall, which earned him his first Golden Globe nomination. In 1995 he gave critically acclaimed performances in the crime thriller Seven and the science fiction film 12 Monkeys, the latter securing him a Golden Globe Award for Best Supporting Actor and an Academy Award nomination. Four years later, in 1999, Pitt starred in the cult hit Fight Club. He then starred in the major international hit as Rusty Ryan in Ocean's Eleven (2001) and its sequels, Ocean's Twelve (2004) and Ocean's Thirteen (2007). His greatest commercial successes have been Troy (2004) and Mr. & Mrs. Smith (2005). Pitt received his second Academy Award nomination for his title role performance in the 2008 film The Curious Case of Benjamin Button.\n\nFollowing a high-profile relationship with actress Gwyneth Paltrow, Pitt was married to actress Jennifer Aniston for five years. Pitt lives with actress Angelina Jolie in a relationship that has generated wide publicity. He and Jolie have six children—Maddox, Pax, Zahara, Shiloh, Knox, and Vivienne. Since beginning his relationship with Jolie, he has become increasingly involved in social issues both in the United States and internationally. Pitt owns a production company named Plan B Entertainment, whose productions include the 2007 Academy Award winning Best Picture, The Departed.\n\nDescription above from the Wikipedia article Brad Pitt, licensed under CC-BY-SA, full list of contributors on Wikipedia.",
 *   "birthday":"1963-12-18",
 *   "deathday":"",
 *   "homepage":"http://simplybrad.com/",
 *   "id":287,
 *   "name":"Brad Pitt",
 *   "place_of_birth":"Shawnee, Oklahoma, United States",
 *   "profile_path":"/w8zJQuN7tzlm6FY9mfGKihxp3Cb.jpg"
 * }
 *
 *
 *
 * http://cf2.imgobject.com/t/p/original/g3X5Gk4N0Sll1j3WC24zl1PCvq5.jpg
 *
 */
- (id)initWithDictionary:(NSDictionary *)info
{
	self = [super init];
	
	if (self) {
		mInfo = [[NSMutableDictionary alloc] init];
		
		[info enumerateKeysAndObjectsUsingBlock:^ (id key, id obj, BOOL *stop) {
			mInfo[key] = obj;
		}];
	}
	
	return self;
}





#pragma mark - Other

- (void)getPersonDetails
{
	mGotPerson = TRUE;
	
	NSMutableString *personQuery = [[NSMutableString alloc] init];
	[personQuery appendString:@"http://api.themoviedb.org/3/person/"];
	[personQuery appendString:[mInfo[@"id"] stringValue]];
	[personQuery appendString:@"?api_key=d257f5f93714b665cefa48800a6332e2"];
	
	NSData *personData = [IDSearch doUrlQuery:personQuery];
	
	if (personData) {
		NSDictionary *info = [[[SBJsonParser alloc] init] objectWithData:personData];
		
		[info enumerateKeysAndObjectsUsingBlock:^ (id key, id obj, BOOL *stop) {
			mInfo[key] = obj;
		}];
	}
}





#pragma mark - IDPerson

- (NSString *)tmdbId
{
	return ((NSNumber *)mInfo[@"id"]).stringValue;
}

- (NSString *)imdbId
{
	if (!mGotPerson)
		[self getPersonDetails];
	
	if (mInfo[@"imdb_id"] && ![mInfo[@"imdb_id"] isKindOfClass:[NSNull class]])
		return mInfo[@"imdb_id"];
	else
		return nil;
}

- (NSString *)name
{
	return mInfo[@"name"];
}

- (NSArray *)characters
{
	if (mInfo[@"character"] && ![mInfo[@"character"] isKindOfClass:[NSNull class]])
		return @[mInfo[@"character"]];
	else
		return nil;
}

- (NSString *)bio
{
	if (!mGotPerson)
		[self getPersonDetails];
	
	if (mInfo[@"biography"] && ![mInfo[@"biography"] isKindOfClass:[NSNull class]])
		return mInfo[@"biography"];
	else
		return nil;
}

- (NSString *)dob
{
	if (!mGotPerson)
		[self getPersonDetails];
	
	if (mInfo[@"birthday"] && ![mInfo[@"birthday"] isKindOfClass:[NSNull class]])
		return mInfo[@"birthday"];
	else
		return nil;
}

- (NSString *)dod
{
	if (!mGotPerson)
		[self getPersonDetails];
	
	if (mInfo[@"deathday"] && ![mInfo[@"deathday"] isKindOfClass:[NSNull class]])
		return mInfo[@"deathday"];
	else
		return nil;
}

- (NSURL *)web
{
	if (!mGotPerson)
		[self getPersonDetails];
	
	if (mInfo[@"homepage"] && ![mInfo[@"homepage"] isKindOfClass:[NSNull class]])
		return [NSURL URLWithString:mInfo[@"homepage"]];
	else
		return nil;
}

- (NSURL *)imageUrl
{
	if (mInfo[@"profile_path"] && ![mInfo[@"profile_path"] isKindOfClass:[NSNull class]])
		return [NSURL URLWithString:[@"http://cf2.imgobject.com/t/p/original" stringByAppendingPathComponent:mInfo[@"profile_path"]]];
	else
		return nil;
}

@end
