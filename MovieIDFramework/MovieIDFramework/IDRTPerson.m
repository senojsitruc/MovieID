//
//  IDRTPerson.m
//  MovieIDFramework
//
//  Created by Curtis Jones on 2012.10.21.
//  Copyright (c) 2012 Curtis Jones. All rights reserved.
//

#import "IDRTPerson.h"
#import "IDSearch.h"
#import "SBJson.h"

@interface IDRTPerson ()
{
	NSMutableDictionary *mInfo;
}
@end

@implementation IDRTPerson

/**
 * http://api.rottentomatoes.com/api/public/v1.0/movies/770672122/cast.json?apikey=
 *
 * {
 *   "cast":[
 *     {"id":"162655641","name":"Tom Hanks","characters":["Woody"]},
 *     {"id":"162655909","name":"Tim Allen","characters":["Buzz Lightyear"]},
 *     {"id":"162655020","name":"Joan Cusack","characters":["Jessie the Cowgirl"]},
 *     {"id":"162672460","name":"Ned Beatty","characters":["Lots-o'-Huggin' Bear","Lotso"]},
 *     {"id":"341817905","name":"Don Rickles","characters":["Mr. Potato Head"]},
 *     {"id":"162652681","name":"Michael Keaton","characters":["Ken"]},
 *     {"id":"162671862","name":"Wallace Shawn","characters":["Rex"]},
 *     {"id":"381422124","name":"John Ratzenberger","characters":["Hamm"]},
 *     {"id":"746742134","name":"Estelle Harris","characters":["Mrs. Potato Head"]},
 *     {"id":"770792145","name":"Kristen Schaal","characters":["Trixie"]},
 *     {"id":"770691950","name":"John Morris","characters":["Andy"]},
 *     {"id":"162655648","name":"Jodi Benson","characters":["Barbie"]},
 *     {"id":"771078865","name":"Emily Hahn","characters":["Bonnie"]},
 *     {"id":"162679021","name":"Laurie Metcalf","characters":["Andy's Mom"]},
 *     {"id":"364614516","name":"Blake Clark","characters":["Slinky Dog"]},
 *     {"id":"770673196","name":"Teddy Newton","characters":["Chatter Telephone"]},
 *     {"id":"770689970","name":"Bud Luckey","characters":["Chuckles"]},
 *     {"id":"770829444","name":"Beatrice Miller","characters":["Molly"]},
 *     {"id":"771078866","name":"Javier Fernandez-Pena","characters":["Spanish Buzz"]},
 *     {"id":"162669781","name":"Timothy Dalton","characters":["Mr. Pricklepants"]},
 *     {"id":"770671962","name":"Lori Alan","characters":["Bonnie's Mom"]},
 *     {"id":"771078867","name":"Charlie Bright","characters":["Pea-in-a-Pod","Young Andy"]},
 *     {"id":"771014702","name":"Jeff Pidgeon","characters":["Aliens"]},
 *     {"id":"162667962","name":"Jeff Garlin","characters":["Buttercup"]},
 *     {"id":"162654629","name":"Bonnie Hunt","characters":["Dolly"]},
 *     {"id":"771029413","name":"John Cygan","characters":["Twitch"]},
 *     {"id":"439092351","name":"Jack Angel","characters":["Chunk"]},
 *     {"id":"162653468","name":"Whoopi Goldberg","characters":["Stretch"]},
 *     {"id":"162662280","name":"R. Lee Ermey","characters":["Sarge"]},
 *     {"id":"770924471","name":"Jan Rabson","characters":["Sparks"]},
 *     {"id":"162657445","name":"Richard Kind","characters":["Bookworm"]},
 *     {"id":"162654813","name":"Erik von Detten","characters":["Sid"]},
 *     {"id":"771078868","name":"Amber Kroner","characters":["Pea-in-a-Pod"]},
 *     {"id":"771078869","name":"Brianna Maiwand","characters":["Pea-in-a-Pod"]},
 *     {"id":"568063685","name":"Jack Willis","characters":["Frog"]},
 *     {"id":"770713272","name":"James Anthony Cotton","characters":[]}
 *   ],
 *   "links":{"rel":"http://api.rottentomatoes.com/api/public/v1.0/movies/770672122.json"}
 * }
 */
- (id)initWithDictionary:(NSDictionary *)info
{
	self = [super init];
	
	if (self) {
		mInfo = [NSMutableDictionary dictionaryWithDictionary:info];
	}
	
	return self;
}





#pragma mark - IDPerson

- (NSString *)rtId
{
	if (mInfo[@"id"] && ![mInfo[@"id"] isKindOfClass:[NSNull class]])
		return mInfo[@"id"];
	else
		return nil;
}

- (NSString *)name
{
	return mInfo[@"name"];
}

- (NSArray *)characters
{
	if (mInfo[@"characters"] && ![mInfo[@"characters"] isKindOfClass:[NSNull class]])
		return mInfo[@"characters"];
	else
		return nil;
}

@end
