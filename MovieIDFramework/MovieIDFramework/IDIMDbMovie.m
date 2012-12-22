//
//  IDIMDbMovie.m
//  MovieIDFramework
//
//  Created by Curtis Jones on 2012.10.21.
//  Copyright (c) 2012 Curtis Jones. All rights reserved.
//

#import "IDIMDbMovie.h"
#import "IDIMDbPerson.h"
#import "IDSearch.h"
#import "SBJson.h"
#import "NSData+Base64.h"
#import <CommonCrypto/CommonCrypto.h>
#import <CommonCrypto/CommonDigest.h>

@interface IDIMDbMovie ()
{
	NSMutableDictionary *mInfo;
	NSMutableArray *mCast;
	
	BOOL mGotMovie;
	BOOL mGotCast;
}
@end

@implementation IDIMDbMovie

/**
 * https://app.imdb.com/find?api=1&appid=iphone1_1&apiPolicy=app1_1&apiKey=2wex6aeu6a8q9e49k7sfvufd6rhh0n&locale=en_US&timestamp=1350964228&q=To%20End%20All%20Wars&sig=app1-OLsUOga+h8w3CRb8iXoVgRyJONg=
 *
 * {
 *   "tconst":"tt0243609",
 *   "type":"feature",
 *   "title":"To End All Wars",
 *   "principals":[
 *     {"nconst":"nm0001015","name":"Robert Carlyle"},
 *     {"nconst":"nm0000662","name":"Kiefer Sutherland"},
 *     {"nconst":"nm0573223","name":"CiarÃ¡n McMenamin"}
 *   ],
 *   "image":{"width":400,"url":"http://ia.media-imdb.com/images/M/MV5BMjAyMDMxMTExOV5BMl5BanBnXkFtZTcwNzEwMjYyMQ@@._V1_.jpg","height":573},
 *   "year":"2001"
 * }
 *
 */
- (id)initWithDictionary:(NSDictionary *)info
{
	self = [super init];
	
	if (self) {
		
		//SBJsonParser *parser = [[SBJsonParser alloc] init];
		
		mInfo = [[NSMutableDictionary alloc] init];
		mCast = [[NSMutableArray alloc] init];
//	mGenres = [[NSMutableArray alloc] init];
		
		[info enumerateKeysAndObjectsUsingBlock:^ (id key, id obj, BOOL *stop) {
			mInfo[key] = obj;
		}];
		
//	NSData *searchData = [IDSearch doUrlQuery:[IDSearch imdbQueryUrlWithAction:@"title/maindetails" method:@"tconst" query:mInfo[@"tconst"] anonymous:FALSE]];
//	NSData *searchData = [IDSearch doUrlQuery:[IDSearch imdbQueryUrlWithAction:@"title/fullcredits" method:@"tconst" query:mInfo[@"tconst"] anonymous:FALSE]];
//	NSDictionary *imdbinfo = [parser objectWithData:searchData];
//	NSData *searchData = [IDSearch doUrlQuery:[IDSearch imdbQueryUrlWithAction:@"name/maindetails" method:@"nconst" query:@"nm0005261" anonymous:FALSE]];
//	NSLog(@"hello!");
		
		/*
		NSArray *people = mInfo[@"principals"];
		
		[people enumerateObjectsUsingBlock:^ (id obj, NSUInteger ndx, BOOL *stop) {
			NSDictionary *person = (NSDictionary *)obj;
			NSString *imdbId = person[@"nconst"];
			
			NSData *searchData = [IDSearch doUrlQuery:[IDSearch imdbQueryUrlWithAction:@"name/maindetails" method:@"nconst" query:imdbId anonymous:FALSE]];
			NSDictionary *imdbinfo = [parser objectWithData:searchData];
		}];
		*/
		
	}
	
	return self;
}

/**
 * https://app.imdb.com/title/maindetails?api=1&appid=iphone1_1&apiPolicy=app1_1&apiKey=2wex6aeu6a8q9e49k7sfvufd6rhh0n&locale=en_US&timestamp=1350967534&tconst=tt0243609&sig=app1-MRzm7HYWoq0LJiPrEujfEjHa97c=
 * http://code.google.com/p/imdbmobile/source/browse/trunk/0.7/ImdbMobile/IMDBData/API.cs?spec=svn23&r=21
 *
 * {
 *   "exp":1350971154,
 *   "@meta":{"serverTimeMs":41,"requestId":"1FY6PVCNQS22M8MEHJCT"},
 *   "data":
 *     {
 *       "photos":[{"link":"http://www.imdb.com/rg/appphoto/link/media/rm2658507776/tt0243609","image":{"width":290,"url":"http://ia.media-imdb.com/images/M/MV5BMjE1MDY5NzY1MV5BMl5BanBnXkFtZTcwMDE0MDMyMQ@@._V1_.jpg","height":475}}],
 *       "directors_summary":[{"name":{"nconst":"nm0192289","name":"David L. Cunningham","image":{"width":450,"url":"http://ia.media-imdb.com/images/M/MV5BMTI1Mjg3OTgxNF5BMl5BanBnXkFtZTYwMjY3Njgy._V1_.jpg","height":705}}}],
 *       "user_comment":{
 *         "user_rating":9,
 *         "status":"G",
 *         "date":"2005-07-05",
 *         "user_name":"rsimanski",
 *         "summary":"A \"War\" Movie That's About Values, Not War",
 *         "user_score":35,
 *         "text":"I am a serious film lover who keeps up with the best new ...has become. Thankfully it is available on DVD.",
 *         "user_location":"Sterling, Virginia, USA",
 *         "user_score_count":41
 *       },
 *       "certificate":{"certificate":"R","attr":"(original cut)"},
 *       "has":["more_cast","trivia","goofs","quotes","more_plot","parentalguide","user_comments","external_reviews","photos"],
 *       "writers_summary":[{"name":{"nconst":"nm0323725","name":"Brian Godawa"},"attr":"(screenplay)"},{"name":{"nconst":"nm0330174","name":"Ernest Gordon"},"attr":"(book)"}],
 *       "rating":7,
 *       "num_votes":6254,
 *       "tconst":"tt0243609",
 *       "genres":["Drama","War","Action"],
 *       "best_plot":{
 *         "summary":"A true story about four Allied POW's who endure harsh treatment from their Japanese captors ...their enemies. Based on the true story of Ernest Gordon.",
 *         "total_summaries":2},
 *       "quote":{
 *         "lines":[
 *           {"quote":"Colonel, I've been watching these Nips. There's never more than...closely. It just doesn't make sense to me unless... ","chars":[{"nconst":"nm0000662","char":"Lt. Jim Reardon"}]},
 *           {"quote":"Unless what? ","chars":[{"nconst":"nm0181920","char":"McLean"}]},
 *           {"quote":"Well, unless every prisoner's been caught or died in a thousand...in a POW for a bowl of rice. Unless - escape is impossible.","chars":[{"nconst":"nm0339583","char":"Dr. Coates"}]}
 *         ],
 *         "qconst":"qt0270029"
 *       },
 *       "can_rate":true,
 *       "trailer":{
 *         "encodings":{
 *           "H.264 640x480":{"format":"H.264 640x480","url":"http://www.totaleclips.com/Player/Bounce.aspx?eclipid=e19643&bitrateid=471&vendorid=102&type=.mp4"},
 *           "H.264 480x360":{"format":"H.264 480x360","url":"http://www.totaleclips.com/Player/Bounce.aspx?eclipid=e19643&bitrateid=455&vendorid=102&type=.mp4"}
 *         },
 *         "description":"US Home Video Trailer from 20th Century Fox",
 *         "relatedTitle":{
 *           "title":"To End All Wars","type":"feature","title_id":"tt0243609","year":"2001","image":{"width":400,"url":"http://ia.media-imdb.com/images/M/MV5BMjAyMDMxMTExOV5BMl5BanBnXkFtZTcwNzEwMjYyMQ@@._V1_.jpg","height":573}
 *         },
 *         "duration_seconds":81,
 *         "slates":[{"width":304,"url":"http://ia.media-imdb.com/images/M/MV5BMTQ4NDk3MTQwOF5BMl5BanBnXkFtZTcwMDI3OTc2MQ@@._V1_.jpg","height":228}],
 *         "content_type":"Trailer",
 *         "relatedName":{"nconst":"nm0339583","name":"John Gregg"},
 *         "id":"vi2717319449",
 *         "title":"To End All Wars",
 *         "@type":"mobile.media.video"
 *       },
 *       "trivium":"The opening prologue states: \"The following account is based on actual events during World War II, when 61,000 Allied POWs were forced to build the Thailand-Burma Railway.\"",
 *       "goof":"During the funeral scene for the Colonel, a piper begins to play a rendition of \"Amazing Grace\". While this hymn was published in 1779, it was not performed on bagpipes until 1972 by the Royal Scots Dragoon Guards.",
 *       "image":{"width":400,"url":"http://ia.media-imdb.com/images/M/MV5BMjAyMDMxMTExOV5BMl5BanBnXkFtZTcwNzEwMjYyMQ@@._V1_.jpg","height":573},
 *       "tagline":"In a jungle war of survival, they learned sacrifice. In a prison of brutal confinement, they found true freedom.",
 *       "runtime":{"time":7020},
 *       "cast_summary":[
 *         {"char":"Maj. Ian Campbell","name":{"nconst":"nm0001015","name":"Robert Carlyle","image":{"width":1725,"url":"http://ia.media-imdb.com/images/M/MV5BMTM2Njc1MjgyOF5BMl5BanBnXkFtZTcwMjY2NTAwNw@@._V1_.jpg","height":2304}}},
 *         {"char":"Lt. Jim 'Yankee' Reardon","name":{"nconst":"nm0000662","name":"Kiefer Sutherland","image":{"width":289,"url":"http://ia.media-imdb.com/images/M/MV5BMjQ1MjI5ODI3Nl5BMl5BanBnXkFtZTcwNTQzOTM0Mw@@._V1_.jpg","height":400}}},
 *         {"char":"Capt. Ernest 'Ernie' Gordon","name":{"nconst":"nm0573223","name":"CiarÃ¡n McMenamin","image":{"width":2600,"url":"http://ia.media-imdb.com/images/M/MV5BMTUzMDc0MzY2NF5BMl5BanBnXkFtZTcwNzA4MzYxNA@@._V1_.jpg","height":3888}}},
 *         {"char":"Dusty Miller","name":{"nconst":"nm0835016","name":"Mark Strong","image":{"width":400,"url":"http://ia.media-imdb.com/images/M/MV5BMTA2MzAyMDc2NTheQTJeQWpwZ15BbWU3MDUzNTQyNjg@._V1_.jpg","height":471}}}
 *       ],
 *       "plot":{"outline":"A true story about four Allied POW's who endure harsh treatment from their Japanese captors during World...","more":1},
 *       "news":{
 *         "channel":"tt0243609",
 *         "total":4,
 *         "sources":{
 *           "ns0000365":{"logo":"http://ia.media-imdb.com/images/M/MV5BMTk4NTI3NjgxMF5BMl5BanBnXkFtZTcwNDQ4OTE2Mw@@._V1._SY140_.jpg","url":"http://www.heyuguys.co.uk","label":"HeyUGuys"},
 *           "ns0000055":{"logo":"http://ia.media-imdb.com/images/M/MV5BMjI0OTAwNjEwNF5BMl5BanBnXkFtZTcwMDY0MjQzOA@@._V1.jpg","url":"http://www.ropeofsilicon.com/","label":"Rope Of Silicon"},
 *           "ns0000001":{"logo":"http://ia.media-imdb.com/images/M/MV5BMTgyNjIzNDk1NF5BMl5BanBnXkFtZTcwOTE1NDEwNA@@._V1_.jpg","url":"http://www.hollywoodreporter.com","label":"The Hollywood Reporter"}
 *         },
 *         "markup":"flat",
 *         "label":"To End All Wars",
 *         "limit":3,
 *         "start":0,
 *         "items":[
 *           {"source":"ns0000365","head":"British Independent Film Festival 2012 â€“ Lineup Announced","id":"ni26949208","datetime":"2012-04-25T11:19:00Z"},
 *           {"source":"ns0000001","head":"MPAA ratings: Aug. 11, 2010","id":"ni3749966","datetime":"2010-08-11T16:07:00Z"},
 *           {"source":"ns0000055","head":"Latest MPAA Ratings: Bulletin No: 2133","id":"ni3739940","datetime":"2010-08-11T07:13:00Z"}
 *         ],
 *         "@type":"mobile.news.list"
 *       },
 *       "type":"feature",
 *       "title":"To End All Wars",
 *       "year":"2001"
 *     },
 *   "copyright":"For use only by clients authorized in writing by IMDb.  Authors and users of unauthorized clients accept full legal exposure/liability for their actions."
 * }
 *
 */
- (void)getMovieDetails
{
	mGotMovie = TRUE;
	
	SBJsonParser *parser = [[SBJsonParser alloc] init];
	NSData *searchData = [IDSearch doUrlQuery:[IDSearch imdbQueryUrlWithAction:@"title/maindetails" method:@"tconst" query:mInfo[@"tconst"] anonymous:TRUE]];
	NSDictionary *imdbinfo = [parser objectWithData:searchData];
	
	[imdbinfo[@"data"] enumerateKeysAndObjectsUsingBlock:^ (id key, id obj, BOOL *stop) {
		mInfo[key] = obj;
	}];
}

/**
 * https://app.imdb.com/title/fullcredits?api=1&appid=iphone1_1&apiPolicy=app1_1&apiKey=2wex6aeu6a8q9e49k7sfvufd6rhh0n&locale=en_US&timestamp=1350968826&tconst=tt0243609&sig=app1-ykVqqSajShTM/KTtyNU70NQ5bxc=
 *
 * {
 *   "exp":1350972443,
 *   "@meta":{"serverTimeMs":49,"requestId":"1YY3FPMY235HE64NQQDP"},
 *   "data":
 *     {
 *       "credits":[
 *         {
 *           "label":"Directed by",
 *           "token":"directors",
 *           "list":[
 *             {"name":{"nconst":"nm0192289","name":"David L. Cunningham","image":{"width":450,"url":"http://ia.media-imdb.com/images/M/MV5BMTI1Mjg3OTgxNF5BMl5BanBnXkFtZTYwMjY3Njgy._V1_.jpg","height":705}}}
 *           ]
 *         },
 *         {"label":"Writing credits","token":"writers","list":[
 *           {"rewrite":[[{"name":{"nconst":"nm0323725","name":"Brian Godawa"},"attr":"screenplay"}]]},
 *           {"rewrite":[[{"name":{"nconst":"nm0330174","name":"Ernest Gordon"},"attr":"book"}]]}
 *         ]},
 *         {"label":"Cast","token":"cast","list":[
 *           {"char":"Capt. Ernest 'Ernie' Gordon","name":{"nconst":"nm0573223","name":"CiarÃ¡n McMenamin","image":{"width":2600,"url":"http://ia.media-imdb.com/images/M/MV5BMTUzMDc0MzY2NF5BMl5BanBnXkFtZTcwNzA4MzYxNA@@._V1_.jpg","height":3888}}},
 *           {"char":"Maj. Ian Campbell","name":{"nconst":"nm0001015","name":"Robert Carlyle","image":{"width":1725,"url":"http://ia.media-imdb.com/images/M/MV5BMTM2Njc1MjgyOF5BMl5BanBnXkFtZTcwMjY2NTAwNw@@._V1_.jpg","height":2304}}},
 *           {"char":"Lt. Jim 'Yankee' Reardon","name":{"nconst":"nm0000662","name":"Kiefer Sutherland","image":{"width":289,"url":"http://ia.media-imdb.com/images/M/MV5BMjQ1MjI5ODI3Nl5BMl5BanBnXkFtZTcwNTQzOTM0Mw@@._V1_.jpg","height":400}}},
 {"char":"Dusty Miller","name":{"nconst":"nm0835016","name":"Mark Strong","image":{"width":400,"url":"http://ia.media-imdb.com/images/M/MV5BMTA2MzAyMDc2NTheQTJeQWpwZ15BbWU3MDUzNTQyNjg@._V1_.jpg","height":471}}},
 {"char":"Takashi Nagase","name":{"nconst":"nm0765897","name":"Yugo Saso","image":{"width":600,"url":"http://ia.media-imdb.com/images/M/MV5BMTAxNTY2ODkyNjVeQTJeQWpwZ15BbWU3MDQxODEyNzU@._V1_.jpg","height":759}}},
 {"char":"Sgt. Ito","name":{"nconst":"nm0454109","name":"Sakae Kimura","image":{"width":325,"url":"http://ia.media-imdb.com/images/M/MV5BMTcxMTIyNTQxN15BMl5BanBnXkFtZTcwNDU1MTE4Mg@@._V1_.jpg","height":486}}},
 {"char":"Lt. Col. Stuart McLean","name":{"nconst":"nm0181920","name":"James Cosmo","image":{"width":450,"url":"http://ia.media-imdb.com/images/M/MV5BMzE4MDUzMzgyNl5BMl5BanBnXkFtZTcwNjgwNDcyMQ@@._V1_.jpg","height":454}}},
 {"char":"Capt. Noguchi","name":{"nconst":"nm0950784","name":"Masayuki Yui"}},
 {"char":"Camp Doctor Coates","name":{"nconst":"nm0339583","name":"John Gregg"}},
 {"as":"(as Shu Nakajima)","char":"Nagatomo","name":{"nconst":"nm0620059","name":"ShÃ» Nakajima"}},
 {"char":"Sgt. Roger Primrose","name":{"nconst":"nm0254862","name":"Greg Ellis","image":{"width":2400,"url":"http://ia.media-imdb.com/images/M/MV5BMTk4NzI2ODU4MF5BMl5BanBnXkFtZTcwNjA0MjQ1Mg@@._V1_.jpg","height":3600}}},
 {"char":"Lt. Foxworth","name":{"nconst":"nm0868476","name":"Pip Torrens","image":{"width":1079,"url":"http://ia.media-imdb.com/images/M/MV5BMjI1NzQ0MzcwMl5BMl5BanBnXkFtZTcwOTE4NzE1Nw@@._V1_.jpg","height":1406}}},
 {"char":"Norman","name":{"nconst":"nm0565153","name":"James McCarthy"}},
 {"char":"Wallace Hamilton","name":{"nconst":"nm0184698","name":"Brendan Cowell","image":{"width":1194,"url":"http://ia.media-imdb.com/images/M/MV5BMTgyNDc5NjcwNl5BMl5BanBnXkFtZTYwOTY5MTcy._V1_.jpg","height":1502}}},
 {"char":"Duncan","name":{"nconst":"nm0629934","name":"Winton Nicholson"}},
 {"char":"Crazy Man","name":{"nconst":"nm0027535","name":"Tracy Anderson"}},
 {"char":"Jan","name":{"nconst":"nm0035571","name":"Duff Armour"}},
 {"char":"Lars","name":{"nconst":"nm0423375","name":"Robert Jobe"}},
 {"char":"Young Dutch Soldier","name":{"nconst":"nm0685018","name":"Jeremy Pippin"}},
 {"char":"John","name":{"nconst":"nm0801554","name":"Adam Sinclair","image":{"width":532,"url":"http://ia.media-imdb.com/images/M/MV5BMjA5NjkyNjgzMV5BMl5BanBnXkFtZTcwNTA4MTc1NQ@@._V1_.jpg","height":800}}},
 {"char":"Cockney","name":{"nconst":"nm0924619","name":"Christopher Gyre"}},{"as":"(as Sergio Alarcon)","char":"Irishman","name":{"nconst":"nm0016015","name":"Sergio Jones"}},{"char":"Scottish Mother","name":{"nconst":"nm2526803","name":"Kelli Walchek"}},{"char":"Server","name":{"nconst":"nm0152418","name":"Jonathan Chapman"}},
 {"char":"Captain Paratrooper","name":{"nconst":"nm0498115","name":"Robert Lee","image":{"width":480,"url":"http://ia.media-imdb.com/images/M/MV5BMTU0Njc3ODUwMl5BMl5BanBnXkFtZTcwNjE0MjA4NQ@@._V1_.jpg","height":698}}},
 {"as":"(as Richard Lafond Jr.)","char":"American Soldier","name":{"nconst":"nm0480921","name":"Richard Joseph Lafond Jr."}},{"char":"Young Scot","name":{"nconst":"nm0399656","name":"Ben Huddleston"}},{"char":"Young POW","name":{"nconst":"nm0094612","name":"Daryl Bonilla"}},{"char":"Japanese NCO","name":{"nconst":"nm0945608","name":"Clyde Yamashita"}},{"char":"Guard #1","name":{"nconst":"nm0948885","name":"Joji Yoshida","image":{"width":2912,"url":"http://ia.media-imdb.com/images/M/MV5BMTM2NzUxMjMxM15BMl5BanBnXkFtZTcwMTU0NTEyOA@@._V1_.jpg","height":3756}}},{"char":"Guard #2","name":{"nconst":"nm1662053","name":"Koji Haga"}},{"char":"Himself","name":{"nconst":"nm0330174","name":"Ernest Gordon"},"attr":"(uncredited)"},{"char":"Soldier","name":{"nconst":"nm1216867","name":"Masa Kanome"},"attr":"(uncredited)"},
 {"name":{"nconst":"nm0575164","name":"Nick Meaney"},"attr":"(uncredited)"},{"char":"Himself","name":{"nconst":"nm0619186","name":"Takashi Nagase"},"attr":"(uncredited)"},{"char":"Paratrooper","name":{"nconst":"nm1146243","name":"Teddy Sears","image":{"width":587,"url":"http://ia.media-imdb.com/images/M/MV5BMTg0NjAxMTkyOF5BMl5BanBnXkFtZTcwNzQ5ODYyMg@@._V1_.jpg","height":885}},"attr":"(uncredited)"}]},
 {"label":"Produced by","token":"producers","list":[{"name":{"nconst":"nm0192289","name":"David L. Cunningham","image":{"width":450,"url":"http://ia.media-imdb.com/images/M/MV5BMTI1Mjg3OTgxNF5BMl5BanBnXkFtZTYwMjY3Njgy._V1_.jpg","height":705}},"job":"producer"},
 {"name":{"nconst":"nm0000356","name":"Sybil Danning","image":{"width":2400,"url":"http://ia.media-imdb.com/images/M/MV5BMTcyMDkxNDMxOV5BMl5BanBnXkFtZTcwNjIxNTQ1OA@@._V1_.jpg","height":3600}},"job":"executive producer"},
 {"name":{"nconst":"nm0287996","name":"Penelope L. Foster"},"job":"co-producer"},
 {"name":{"nconst":"nm0293844","name":"Enock N. Freire"},"job":"associate producer"},
 {"name":{"nconst":"nm0353094","name":"Jack Hafer","image":{"width":450,"url":"http://ia.media-imdb.com/images/M/MV5BMzk4ODM4OTQ5OV5BMl5BanBnXkFtZTcwMTQyNzAzMQ@@._V1_.jpg","height":677}},"job":"producer"},
 {"name":{"nconst":"nm0505685","name":"Nava Levin"},"job":"line producer"},
 {"name":{"nconst":"nm0550859","name":"Edwin L. Marshall"},"job":"associate producer"},
 {"name":{"nconst":"nm0628104","name":"Greg Newman"},"job":"executive producer"},
 {"name":{"nconst":"nm1041108","name":"Page Ostrow","image":{"width":1206,"url":"http://ia.media-imdb.com/images/M/MV5BMTgyMTI0ODQ2MF5BMl5BanBnXkFtZTcwMjQ0Mzk3NQ@@._V1_.jpg","height":1688}},"job":"co-producer"},
 {"name":{"nconst":"nm0703361","name":"John Quested"},"job":"executive producer"},
 {"name":{"nconst":"nm0906951","name":"Scott Walchek"},"job":"executive producer"}]},{"label":"Original Music by","token":"music_original","list":[
 {"name":{"nconst":"nm0131624","name":"John Cameron"}}]},{"label":"Cinematography by","token":"cinematographers","list":[
 {"name":{"nconst":"nm0306755","name":"Greg Gardiner"},"attr":"(director of photography)"}]},{"label":"Film Editing by","token":"editors","list":[
 {"name":{"nconst":"nm0797803","name":"Tim Silano"}}]},{"label":"Casting by","token":"casting_directors","list":[
 {"name":{"nconst":"nm0184777","name":"Allison Cowitt"}},
 {"name":{"nconst":"nm0272067","name":"Mike Fenton"}},
 {"name":{"nconst":"nm0288911","name":"Celestia Fox"}}]},{"label":"Production Design by","token":"production_designers","list":[
 {"name":{"nconst":"nm0843128","name":"Paul Sylbert"}}]},{"label":"Art Direction by","token":"art_directors","list":[
 {"name":{"nconst":"nm0525846","name":"Patrick Lumb"}}]},{"label":"Set Decoration by","token":"set_decorators","list":[
 {"name":{"nconst":"nm0561908","name":"Daniel Loren May"}}]},{"label":"Costume Design by","token":"costume_designers","list":[{"as":"(as Tammy Mor)","name":{"nconst":"nm0602222","name":"Tami Mor"}},
 {"name":{"nconst":"nm0708483","name":"Rina Ramon"}}]},{"label":"Makeup Department","token":"make_up_department","list":[
 {"name":{"nconst":"nm0120945","name":"Christopher Burdett"},"job":"special makeup technician"},
 {"name":{"nconst":"nm0361849","name":"Anna Harasimiak"},"job":"makeup department head"},
 {"name":{"nconst":"nm0441694","name":"Emily Katz"},"job":"key makeup artist"},
 {"name":{"nconst":"nm0441761","name":"Kea Katz"},"job":"additional makeup artist"},
 {"name":{"nconst":"nm0445404","name":"Susan J. Kelber"},"job":"head hair stylist"},
 {"name":{"nconst":"nm0529053","name":"Erin Lyons"},"job":"makeup artist"},
 {"name":{"nconst":"nm0548722","name":"Cheryl Markowitz"},"job":"makeup artist"},
 {"name":{"nconst":"nm0752618","name":"Joanne Ryan"},"job":"additional makeup artist"},
 {"name":{"nconst":"nm0876683","name":"Gary J. Tunnicliffe","image":{"width":1502,"url":"http://ia.media-imdb.com/images/M/MV5BMTQzMTY4NzI5Ml5BMl5BanBnXkFtZTcwNzc0NzQ0Ng@@._V1_.jpg","height":2253}},"job":"special makeup effects artist"},{"as":"(as Stella)","name":{"nconst":"nm0826288","name":"Stella Tzanidakis"},"job":"makeup artist"}]},{"label":"Production Management","token":"production_managers","list":[
 {"name":{"nconst":"nm0041030","name":"Philippa Atterton"},"job":"production manager: Scotland"},
 {"name":{"nconst":"nm0072636","name":"Roy Benson"},"job":"post-production supervisor"},
 {"name":{"nconst":"nm0205944","name":"Jordan Dawes"},"job":"post-production supervisor"},
 {"name":{"nconst":"nm0335532","name":"Lizz Grant"},"job":"production supervisor"},
 {"name":{"nconst":"nm0505685","name":"Nava Levin"},"job":"unit production manager"},
 {"name":{"nconst":"nm0004196","name":"Verne Nobles"},"job":"executive in charge of production"},
 {"name":{"nconst":"nm0649930","name":"John Orland"},"job":"post-production supervisor"},
 {"name":{"nconst":"nm0676111","name":"Piya Pestonji"},"job":"unit production manager: Thailand"}]},{"label":"Second Unit Director or Assistant Director","token":"assistant_directors","list":[
 {"name":{"nconst":"nm0565465","name":"Cara McCastlain"},"job":"second assistant director"},
 {"name":{"nconst":"nm0632723","name":"Joel Jeffrey Nishimine"},"job":"first assistant director"},
 {"as":"(as Eileen Sue O'Brien)","name":{"nconst":"nm0639534","name":"Eileen O'Brien"},"job":"second second assistant director"},
 {"name":{"nconst":"nm0691627","name":"Don Poquette"},"job":"first assistant director"},
 {"name":{"nconst":"nm0782981","name":"Fay Selby"},"job":"first assistant director: additional Scotland second unit"},
 {"name":{"nconst":"nm0003487","name":"Lon Takiguchi"},"job":"second second assistant director"},
 {"name":{"nconst":"nm0879165","name":"J.B. Tyson"},"job":"second assistant director"}]},{"label":"Art Department","token":"art_department","list":[
 {"name":{"nconst":"nm0062048","name":"Randy Bauling"},"job":"storyboard artist"},
 {"name":{"nconst":"nm1094219","name":"Richard Beach"},"job":"head greensman"},
 {"name":{"nconst":"nm0154779","name":"Brian 'Junior' Chebatoris"},"job":"greens person"},
 {"name":{"nconst":"nm0172340","name":"Harold Collins"},"job":"construction coordinator"},
 {"name":{"nconst":"nm0197001","name":"David Dahlberg"},"job":"construction foremen"},
 {"name":{"nconst":"nm0198223","name":"Don Dalstra"},"job":"construction foremen"},
 {"name":{"nconst":"nm0270155","name":"Mitchell Fedi"},"job":"assistant props"},
 {"name":{"nconst":"nm0327371","name":"Dana Gonsalves"},"job":"constructor"},
 {"name":{"nconst":"nm0339600","name":"Michael J. Gregg"},"job":"greens person"},
 {"name":{"nconst":"nm0353423","name":"Leo 'The Wheel' Hagen"},"job":"greens person"},
 {"name":{"nconst":"nm0358639","name":"Alfred Hammond"},"job":"constructor"},
 {"name":{"nconst":"nm0375245","name":"Kory Hellebust"},"job":"on-set dresser"},
 {"name":{"nconst":"nm0377831","name":"Gene Henry"},"job":"constructor"},{"name":{"nconst":"nm0383387","name":"Gabriel Higgins"},"job":"property master"},
 {"name":{"nconst":"nm0406802","name":"Ics"},"job":"property master"},{"name":{"nconst":"nm0422773","name":"Jesse Jimenez"},"job":"stand-by scenic artist"},{"name":{"nconst":"nm0434656","name":"Andrew Kahale"},"job":"constructor"},{"name":{"nconst":"nm0489025","name":"Ken Larson"},"job":"property associate"},{"name":{"nconst":"nm0500185","name":"Brenda Leigh"},"job":"charge scenic artist"},{"name":{"nconst":"nm0502888","name":"Harold Leone"},"job":"constructor"},{"name":{"nconst":"nm0519867","name":"Chucka Lopes"},"job":"constructor"},{"name":{"nconst":"nm1418782","name":"JosÃ© LÃ³pez"},"job":"constructor"},{"name":{"nconst":"nm0530334","name":"Raymond LÃ³pez"},"job":"constructor"},{"name":{"nconst":"nm0562089","name":"Nicholas May"},"job":"lead person"},{"name":{"nconst":"nm0573982","name":"David McNelly"},"job":"construction foremen"},{"name":{"nconst":"nm0647971","name":"Naomi Olson"},"job":"constructor"},{"name":{"nconst":"nm0664424","name":"Darall Pascua"},"job":"constructor"},{"name":{"nconst":"nm0715527","name":"Kevin Reed"},"job":"constructor"},{"name":{"nconst":"nm0717988","name":"Chris Reiner"},"job":"stand-by carpenter"},{"name":{"nconst":"nm0821133","name":"Edith Stadig"},"job":"assistant designer"},{"name":{"nconst":"nm0863844","name":"Thomas Tin"},"job":"constructor"},{"name":{"nconst":"nm0864413","name":"Kelly Tissot"},"job":"art department coordinator"}]},{"label":"Sound Department","token":"sound_department","list":[{"name":{"nconst":"nm0028522","name":"Lydia Andrew"},"job":"assistant sound editor"},{"name":{"nconst":"nm0042042","name":"Paul Aulicino"},"job":"assistant sound editor"},{"name":{"nconst":"nm0053203","name":"Gregg Barbanell"},"job":"foley artist"},{"name":{"nconst":"nm0086899","name":"Brian Blamey"},"job":"sound effects editor"},{"name":{"nconst":"nm0143854","name":"Michael C. Casper"},"job":"sound re-recording mixer"},{"name":{"nconst":"nm0147229","name":"William Cawley"},"job":"sound assistant"},{"name":{"nconst":"nm1121283","name":"Simon Chase"},"job":"assistant sound editor"},{"name":{"nconst":"nm0167187","name":"Bradley Clouse"},"job":"first assistant sound editor"},{"name":{"nconst":"nm0268058","name":"Robert Farr"},"job":"sound re-recording mixer"},{"name":{"nconst":"nm0305305","name":"Keith A. Garcia"},"job":"additional sound recordist"},{"name":{"nconst":"nm0368571","name":"Daniel Hastings"},"job":"boom operator"},{"name":{"nconst":"nm0409870","name":"John Ireland"},"job":"dialogue editor"},{"as":"(as Itamar Ben-Jacob)","name":{"nconst":"nm0070067","name":"Ben Jacob"},"job":"sound mixer"},{"name":{"nconst":"nm0451794","name":"Chai Khongsirawat"},"job":"sound mixer: Thailand"},{"name":{"nconst":"nm0534000","name":"David MacMillan"},"job":"boom operator: Scotland"},{"name":{"nconst":"nm0542977","name":"Steve Mann"},"job":"sound effects editor"},{"name":{"nconst":"nm0574596","name":"Dennis McTaggart"},"job":"sound effects editor"},{"name":{"nconst":"nm0625760","name":"Steve Nelson"},"job":"sound effects editor"},{"name":{"nconst":"nm0003013","name":"Jay Nierenberg","image":{"width":1440,"url":"http://ia.media-imdb.com/images/M/MV5BMjUwMzQzMzc4OV5BMl5BanBnXkFyZXN1bWU@._V1_.jpg","height":1016}},"job":"supervising sound editor"},{"name":{"nconst":"nm0699897","name":"Pipat Puengmai"},"job":"boom operator: Thailand"},{"name":{"nconst":"nm0821801","name":"Bruce Stambler"},"job":"supervising sound editor"},{"name":{"nconst":"nm0167915","name":"Becky Sullivan","image":{"width":863,"url":"http://ia.media-imdb.com/images/M/MV5BOTQ2NTkxOTk2NF5BMl5BanBnXkFtZTcwNTcxNzA1NA@@._V1_.jpg","height":1406}},"job":"supervising adr editor"},{"name":{"nconst":"nm0859854","name":"Andy Thompson"},"job":"sound re-recording mixer"},{"name":{"nconst":"nm0909949","name":"Tim Walston"},"job":"sound designer"},{"name":{"nconst":"nm0004446","name":"Bernard Weiser"},"job":"sound editor"},
 {"name":{"nconst":"nm0926435","name":"Jack Whittaker"},"job":"sound editor"},{"as":"(as Robin Quinn)","name":{"nconst":"nm0703980","name":"Robin Whittaker"},"job":"assistant sound editor"},{"name":{"nconst":"nm0939892","name":"Mike Wood"},"job":"sound editor"},{"name":{"nconst":"nm0940993","name":"Simon Woodward"},"job":"sound recordist: Scotland"},{"name":{"nconst":"nm1051779","name":"Mark Kenna"},"attr":"(uncredited)","job":"consultant: Dolby film sound"}]},{"label":"Special Effects by","token":"special_effects_department","list":[{"as":"(as Archie K. Ahuna)","name":{"nconst":"nm0014397","name":"Archie Ahuna"},"job":"special effects coordinator"},{"name":{"nconst":"nm1094846","name":"Fern N. Ahuna"},"job":"special effects assistant"},{"name":{"nconst":"nm0014401","name":"Patricia P. Ahuna"},"job":"special effects p.a."},{"name":{"nconst":"nm2336965","name":"Tim Baxter"},"job":"optical effects"},{"name":{"nconst":"nm0517531","name":"Clarence Logan"},"job":"special effects assistant"}]},{"label":"Visual Effects by","token":"visual_effects_department","list":[{"name":{"nconst":"nm1008783","name":"Tom Baker"},"job":"digital effects coordinator"},{"name":{"nconst":"nm0104313","name":"Kristen Branan"},"job":"executive producer: digital.art.media"},{"name":{"nconst":"nm0145275","name":"James Castle"},"job":"digital effects supervisor: Digital.Art.Media"},{"as":"(as Craig Mumma)","name":{"nconst":"nm0612600","name":"Craig A. Mumma","image":{"width":394,"url":"http://ia.media-imdb.com/images/M/MV5BMTc2MzAzMTcwMl5BMl5BanBnXkFtZTcwNTMyODI3MQ@@._V1_.jpg","height":581}},"job":"visual effects supervisor: Digital.Art.Media"},{"name":{"nconst":"nm0664902","name":"Rocco Passionino"},"job":"digital effects supervisor: Digital.Art.Media"},{"name":{"nconst":"nm0741495","name":"Joshua D. Rose"},"job":"visual effects producer: Whisdom Entertainment"},{"name":{"nconst":"nm0796886","name":"Kathy Siegel"},"job":"visual effects supervisor"},{"name":{"nconst":"nm0864532","name":"James D. Tittle"},"job":"facility manager: digital.art.media"}]},{"label":"Stunts","token":"stunts","list":[{"name":{"nconst":"nm0575820","name":"John Medlen"},"job":"stunt coordinator"},{"name":{"nconst":"nm0575820","name":"John Medlen"},"job":"stunts"}]},{"label":"Camera and Electrical Department","token":"camera_department","list":[{"name":{"nconst":"nm0082610","name":"Julie Bills"},"job":"second assistant camera: Scotland"},{"name":{"nconst":"nm0117959","name":"Lewis Buchan"},"job":"first assistant camera: Scotland"},{"name":{"nconst":"nm0158706","name":"Khumban Chockanan"},"job":"assistant camera: Thailand"},{"name":{"nconst":"nm0242000","name":"John Duncan"},"job":"grip electric: Scotland"},{"name":{"nconst":"nm0292075","name":"Austin G. Fraser"},"job":"best boy grip"},{"name":{"nconst":"nm0292352","name":"Jason Fratis"},"job":"assistant chief lighting technician"},{"name":{"nconst":"nm0296615","name":"Christian Froude"},"job":"best boy accountant"},{"name":{"nconst":"nm0339581","name":"Jeffrey B. Gregg"},"job":"lamp operator"},{"name":{"nconst":"nm0339600","name":"Michael J. Gregg"},"job":"company grip"},{"name":{"nconst":"nm0375886","name":"Julie Helton"},"job":"second assistant camera: \"b\" camera"},{"name":{"nconst":"nm0424618","name":"Bob Johnson"},"job":"camera operator: \"b\" camera"},{"name":{"nconst":"nm0424618","name":"Bob Johnson"},"job":"gaffer"},{"name":{"nconst":"nm0435569","name":"Mark Kalaugher"},"job":"lamp operator"},{"name":{"nconst":"nm0437470","name":"Lee Kaneakua"},"job":"key grip"},{"name":{"nconst":"nm0449074","name":"Michael Keola Jones"},"job":"lamp operator"},{"name":{"nconst":"nm0552837","name":"Ned Martin"},"job":"vistavision camera operator"},{"name":{"nconst":"nm0560711","name":"J. Steven Matzinger","image":{"width":462,"url":"http://ia.media-imdb.com/images/M/MV5BMTUzNjAxODI1M15BMl5BanBnXkFtZTcwMzUzNDE2Mw@@._V1_.jpg","height":617}},"job":"first assistant camera"},{"name":{"nconst":"nm0568533","name":"Annie McEveety","image":{"width":800,"url":"http://ia.media-imdb.com/images/M/MV5BMTMwNzkzMDUwOF5BMl5BanBnXkFtZTcwNjY3OTQyNQ@@._V1_.jpg","height":600}},"job":"first assistant camera: \"b\" camera"},{"name":{"nconst":"nm0568538","name":"John McEveety"},"job":"second assistant camera"},
 {"name":{"nconst":"nm0572626","name":"Ossie McLean"},"job":"camera operator: \"b\" camera"},{"name":{"nconst":"nm0622614","name":"Jason Naumann","image":{"width":450,"url":"http://ia.media-imdb.com/images/M/MV5BMTY3MjI2NTA5OF5BMl5BanBnXkFtZTYwNzE5NzAz._V1_.jpg","height":718}},"job":"videographer: behind-the-scenes footage"},{"name":{"nconst":"nm0623029","name":"Willie Navarro"},"job":"videographer: behind-the-scenes footage"},{"name":{"nconst":"nm1344942","name":"Kevin O'Brien"},"job":"first assistant camera: Scotland"},{"name":{"nconst":"nm0656910","name":"Voranon Paipad"},"job":"loader: Thailand"},{"name":{"nconst":"nm0003997","name":"Derrick Peters"},"job":"second assistant camera: Scotland"},{"name":{"nconst":"nm0702276","name":"Mario PÃ©rez"},"job":"still photographer"},{"name":{"nconst":"nm0804058","name":"John Skeo"},"job":"company grip"},{"name":{"nconst":"nm0809682","name":"Reid Keoki Smith"},"job":"dolly grip"},{"as":"(as Russell D. Steen)","name":{"nconst":"nm0824796","name":"Russell Steen"},"job":"director of photography: Scotland and Thailand"},{"name":{"nconst":"nm0864623","name":"Sambut Tiyasutiporn"},"job":"grip: Thailand"},{"name":{"nconst":"nm1901219","name":"Rick Wood"},"job":"director of photography: additional second unit, Scotland"},{"name":{"nconst":"nm0947031","name":"Michael Yaeger"},"job":"camera loader"}]},{"label":"Casting Department","token":"casting_department","list":[{"as":"(as Ros Breeden)","name":{"nconst":"nm0106682","name":"Ros Bellenger"},"job":"casting: Austrailia"},{"name":{"nconst":"nm0279330","name":"Anna Fishburn"},"job":"casting: Honolulu"},{"name":{"nconst":"nm0317886","name":"Elisa Gil-Osorio"},"job":"casting assistant"},{"name":{"nconst":"nm0334186","name":"Linda Graham"},"job":"extras casting: Kauai"},{"name":{"nconst":"nm0420407","name":"Tamara Jeffries"},"job":"extras casting: Kauai"},{"name":{"nconst":"nm0863451","name":"Angela Tillson"},"job":"extras casting"},{"name":{"nconst":"nm0950784","name":"Masayuki Yui"},"job":"casting: Japan"}]},{"label":"Costume and Wardrobe Department","token":"costume_department","list":[{"name":{"nconst":"nm0517532","name":"Courtney Dawn Logan"},"job":"wardrobe production assistant"},{"name":{"nconst":"nm0637554","name":"Rotem Noyfeld"},"job":"set costumer"},{"name":{"nconst":"nm0674650","name":"Tony Perri"},"job":"set costumer"},{"name":{"nconst":"nm0806349","name":"Andrew Slyder"},"job":"set costumer"}]},{"label":"Editorial Department","token":"editorial_department","list":[{"name":{"nconst":"nm0205944","name":"Jordan Dawes"},"job":"first assistant editor"},{"name":{"nconst":"nm0292201","name":"Mike Fraser"},"job":"negative cutter"},{"name":{"nconst":"nm0399173","name":"Ezra Hubbard"},"job":"first assistant editor"},{"name":{"nconst":"nm1332081","name":"Scott Juergens"},"job":"assistant editor: avid"},{"name":{"nconst":"nm0004314","name":"Angie Luckey"},"job":"assistant editor"},{"name":{"nconst":"nm0533449","name":"Conor Mackey"},"job":"assistant editor"},{"as":"(as Larry P. Manke)","name":{"nconst":"nm0542518","name":"Larry Manke"},"job":"telecine colorist"},{"name":{"nconst":"nm2253170","name":"J. Aaron Stinde"},"job":"post-production assistant"},{"name":{"nconst":"nm0933014","name":"Anne Marie Wilson"},"job":"post-production assistant: Los Angeles"}]},{"label":"Music Department","token":"music_department","list":[{"name":{"nconst":"nm0131624","name":"John Cameron"},"job":"conductor"},{"name":{"nconst":"nm0131624","name":"John Cameron"},"job":"music supervisor"},{"name":{"nconst":"nm0131624","name":"John Cameron"},"job":"orchestrator"},{"name":{"nconst":"nm0132393","name":"Dirk Campbell"},"job":"musician: bagpipes"},{"name":{"nconst":"nm1068107","name":"Oliver Cohen"},"job":"assistant music editor"},{"name":{"nconst":"nm0250399","name":"Terry Edwards"},"job":"chorus director: London Voices Chorus"},{"name":{"nconst":"nm0316833","name":"Alex Gibson"},"job":"music editor"},{"name":{"nconst":"nm0368899","name":"Robert Hathaway"},"job":"music editor"},{"name":{"nconst":"nm2010860","name":"Sarah Zilesnick"},"job":"music production assistant"}]},{"label":"Transportation Department","token":"transportation_department","list":[{"name":{"nconst":"nm0095540","name":"Santi Boonkanok"},"job":"driver: Thailand"},{"name":{"nconst":"nm0358690","name":"Fred Hammond"},"job":"production driver"},{"name":{"nconst":"nm0387262","name":"Nathan Ho'okano"},"job":"production driver"},{"name":{"nconst":"nm0430161","name":"Robert Jordan"},"job":"production driver"},{"name":{"nconst":"nm0440501","name":"Lee Kasena"},"job":"driver: Thailand"},{"name":{"nconst":"nm0475498","name":"Alfred Kupo Jr."},"job":"production driver"},{"name":{"nconst":"nm0637862","name":"Ton Nukrob"},"job":"driver: Thailand"},{"name":{"nconst":"nm0681125","name":"Petch Phuengsap"},"job":"driver: Thailand"},{"name":{"nconst":"nm0768944","name":"Ray Scanlan"},"job":"production driver"},{"name":{"nconst":"nm0839506","name":"Nui Supreecha"},"job":"driver: Thailand"},{"name":{"nconst":"nm0880011","name":"Harry Ueshiro"},"job":"transportation captain"},{"name":{"nconst":"nm0896499","name":"Kurt Vidinha"},"job":"production driver"},{"name":{"nconst":"nm0896500","name":"Richard R. Vidinha"},"job":"assistant transportation captain"},{"name":{"nconst":"nm0915027","name":"Lin Wattana"},"job":"driver: Thailand"},{"name":{"nconst":"nm0934039","name":"Robert Wilson"},"job":"production driver"},{"name":{"nconst":"nm0949083","name":"Warren Yoshioka"},"job":"production driver"}]},{"label":"Other crew","token":"miscellaneous","list":[{"name":{"nconst":"nm0014396","name":"Donovan K. Ahuna Jr."},"job":"craft service assistant"},{"name":{"nconst":"nm0014400","name":"Donovan Ahuna"},"job":"head craft service"},{"name":{"nconst":"nm0014717","name":"Lucero Ainstein"},"job":"intern"},{"name":{"nconst":"nm1581913","name":"Stuart Andrews"},"job":"keyboard programmer"},{"name":{"nconst":"nm0032068","name":"Clifford Apo"},"job":"production assistant"},{"name":{"nconst":"nm0062048","name":"Randy Bauling"},"job":"stand-in"},{"name":{"nconst":"nm0095540","name":"Santi Boonkanok"},"job":"production assistant: Thailand"},{"name":{"nconst":"nm0119767","name":"Frank Bukoski"},"job":"security officer"},{"name":{"nconst":"nm0120768","name":"Lesley Burbridge"},"job":"unit publicist"},{"name":{"nconst":"nm0123961","name":"Chrysten Busch"},"job":"intern"},{"name":{"nconst":"nm0131359","name":"Jack Cambra Jr."},"job":"craft service assistant"},{"name":{"nconst":"nm0137916","name":"Ginger Carlson"},"job":"caterer"},{"name":{"nconst":"nm0149805","name":"Peter Chakra"},"job":"intern"},{"name":{"nconst":"nm0189421","name":"Paul L. Crotty"},"job":"military advisor: allied forces"},{"name":{"nconst":"nm0189422","name":"Robert D. Crotty"},"job":"location scout"},{"name":{"nconst":"nm0192359","name":"Judith Cunningham"},"job":"production coordinator: Scotland"},{"name":{"nconst":"nm0202211","name":"Helene Rhye Daub"},"job":"production office assistant"},{"name":{"nconst":"nm0243057","name":"Maurice Dunster"},"job":"assistant: Kiefer Sutherland"},{"name":{"nconst":"nm0255186","name":"Don Ellison"},"job":"staff: University of the nations"},{"name":{"nconst":"nm0264136","name":"Stephen Eyer"},"job":"assistant production coordinator"},{"name":{"nconst":"nm0264310","name":"Fidelis Ezch"},"job":"intern"},{"name":{"nconst":"nm0268403","name":"Lauralee Farrer","image":{"width":300,"url":"http://ia.media-imdb.com/images/M/MV5BMTI1NjAzNzAwOF5BMl5BanBnXkFtZTcwNTg3OTUyMQ@@._V1_.jpg","height":414}},"job":"assistant: Jack Hafer"},{"name":{"nconst":"nm0269681","name":"Richard A. Faye"},"job":"wrangler"},{"name":{"nconst":"nm0007039","name":"Lori Grabowski","image":{"width":150,"url":"http://ia.media-imdb.com/images/M/MV5BMTczMjkwNTE3OF5BMl5BanBnXkFtZTcwNjk3MDEzNA@@._V1_.jpg","height":202}},"job":"script supervisor"},{"name":{"nconst":"nm0339416","name":"Alonzo Greer"},"job":"key set production assistant"},{"name":{"nconst":"nm0359169","name":"Kichang Han"},"job":"intern"},{"name":{"nconst":"nm0373077","name":"Peter Heckmann"},"job":"website and multimedia designer"},{"name":{"nconst":"nm2652190","name":"Paul Hendison"},"job":"production executive"},{"name":{"nconst":"nm0391153","name":"Rita Hollingsworth"},"job":"unit publicist"},{"name":{"nconst":"nm0397047","name":"Trisha Hoving"},"job":"intern"},{"name":{"nconst":"nm0399386","name":"Paul Huber"},"job":"intern"},{"name":{"nconst":"nm0399503","name":"Ingrid Hubik Friere"},"job":"Los Angeles coordinator: Scotland"},{"name":{"nconst":"nm0399503","name":"Ingrid Hubik Friere"},"job":"associate to producer"},{"name":{"nconst":"nm0399504","name":"Julieta B. Hubik"},"job":"unit intercessor"},{"name":{"nconst":"nm0399656","name":"Ben Huddleston"},"job":"set production assistant"},{"name":{"nconst":"nm0399787","name":"Bill Hudson"},"job":"insurance provider"},{"name":{"nconst":"nm0411698","name":"Inori Ito"},"job":"script translator: Japanese"},{"name":{"nconst":"nm0411755","name":"Takashi Ito"},"job":"script translator: Japanese"},{"name":{"nconst":"nm0421247","name":"Sandra Jennings"},"job":"caterer"},{"name":{"nconst":"nm0431581","name":"Natalie Joyce"},"job":"assistant accountant"},{"name":{"nconst":"nm0431773","name":"Veronica Juarez"},"job":"staff: University of the nations"},{"name":{"nconst":"nm0434657","name":"Peter Kahale"},"job":"production assistant"},{"name":{"nconst":"nm0440501","name":"Lee Kasena"},"job":"production assistant: Thailand"},{"name":{"nconst":"nm0441883","name":"Harriet Katz-Stevens"},"job":"post-production accountant"},{"name":{"nconst":"nm0489753","name":"Elaine Lasota"},"job":"assistant: Penelope L. Foster"},{"name":{"nconst":"nm0505667","name":"Maya Levin"},"job":"production office assistant"},{"name":{"nconst":"nm0514858","name":"Mark Litwak","image":{"width":585,"url":"http://ia.media-imdb.com/images/M/MV5BODg5NTAwMjA2M15BMl5BanBnXkFtZTcwNzQ0MzgyNA@@._V1_.jpg","height":640}},"job":"attorney"},{"name":{"nconst":"nm0514858","name":"Mark Litwak","image":{"width":585,"url":"http://ia.media-imdb.com/images/M/MV5BODg5NTAwMjA2M15BMl5BanBnXkFtZTcwNzQ0MzgyNA@@._V1_.jpg","height":640}},"job":"producer's representative"},{"name":{"nconst":"nm0517441","name":"Suzanne Lofthus"},"job":"craft service: Scotland"},{"name":{"nconst":"nm0522446","name":"Marcus Love-McGuirk"},"job":"assistant: Robert Carlyle"},{"name":{"nconst":"nm0550859","name":"Edwin L. Marshall"},"job":"production coordinator: los angeles"},{"name":{"nconst":"nm0564576","name":"Lynda McCaig"},"job":"location manager: Scotland"},{"name":{"nconst":"nm0590616","name":"Jessica A. Milstein"},"job":"production coordinator"},{"name":{"nconst":"nm0598834","name":"Alyssa Montalbano"},"job":"intern"},{"name":{"nconst":"nm0622986","name":"Patricia Navarro"},"job":"staff: university of the nations"},{"name":{"nconst":"nm1392463","name":"Tim Norton"},"job":"caterer"},{"name":{"nconst":"nm0637862","name":"Ton Nukrob"},"job":"production assistant: Thailand"},{"name":{"nconst":"nm0642367","name":"Ryan O'Quinn"},"job":"adr voice"},{"name":{"nconst":"nm0652695","name":"Melvin S. Ota"},"job":"production assistant"},{"name":{"nconst":"nm0653650","name":"Eric Outcalf"},"job":"stand-in"},{"name":{"nconst":"nm0669804","name":"Mark Pecqueur"},"job":"location coordinator: Scotland"},{"name":{"nconst":"nm0681125","name":"Petch Phuengsap"},"job":"production assistant: Thailand"},{"name":{"nconst":"nm0722112","name":"Holly Rezentes-Leayman"},"job":"production secretary"},{"name":{"nconst":"nm0727844","name":"Peter Riopta"},"job":"production assistant"},{"name":{"nconst":"nm0741188","name":"John Roscoe"},"job":"on-set medic"},{"name":{"nconst":"nm0771073","name":"Jessie Scherle"},"job":"staff: university of the nations"},{"name":{"nconst":"nm0820275","name":"Nitad 'Lek' Srisomsap"},"job":"location manager: Thailand"},{"name":{"nconst":"nm0837907","name":"David Suliven"},"job":"production assistant"},{"name":{"nconst":"nm0839506","name":"Nui Supreecha"},"job":"production assistant: Thailand"},{"name":{"nconst":"nm1887270","name":"Chris Thornton"},"job":"production office assistant"},{"name":{"nconst":"nm0878451","name":"Brian Tuzon"},"job":"production assistant"},{"name":{"nconst":"nm0886140","name":"Bas Van Den Eijkhof"},"job":"intern"},{"name":{"nconst":"nm0896500","name":"Richard R. Vidinha"},"job":"wrangler"},{"name":{"nconst":"nm0915027","name":"Lin Wattana"},"job":"production assistant: Thailand"},{"name":{"nconst":"nm0929639","name":"Whitney J. Willard"},"job":"production accountant"},{"name":{"nconst":"nm0933014","name":"Anne Marie Wilson"},"job":"intern: Kauai"},
 {"name":{"nconst":"nm0950784","name":"Masayuki Yui"},"job":"advisor: Japanese military and culture"}
 ]},
 {"label":"Thanks","token":"thanks","list":[
   {"name":{"nconst":"nm0034597","name":"Argyll"},"job":"special thanks"},
   {"name":{"nconst":"nm0122557","name":"Al Burns"},"job":"special thanks: Iatse Local 665"},
   {"name":{"nconst":"nm0137086","name":"Gavin Cargill"},"job":"special thanks"},
 {"name":{"nconst":"nm0921437","name":"Larry Werner"},"job":"thanks"}
 ]}
 
 ],
 "tconst":"tt0243609","type":"feature","title":"To End All Wars","year":"2001"},
 "copyright":"For use only by clients authorized in writing by IMDb.  Authors and users of unauthorized clients accept full legal exposure/liability for their actions."}
 *
 */
- (void)getCastDetails
{
	mGotCast = TRUE;
	
	SBJsonParser *parser = [[SBJsonParser alloc] init];
	NSData *searchData = [IDSearch doUrlQuery:[IDSearch imdbQueryUrlWithAction:@"title/fullcredits" method:@"tconst" query:mInfo[@"tconst"] anonymous:TRUE]];
	NSDictionary *imdbinfo = [parser objectWithData:searchData];
	NSDictionary *data = imdbinfo[@"data"];
	
	[data enumerateKeysAndObjectsUsingBlock:^ (id key, id obj, BOOL *stop) {
		mInfo[key] = obj;
	}];
	
	NSArray *credits = mInfo[@"credits"];
	
	[credits enumerateObjectsUsingBlock:^ (id obj, NSUInteger ndx, BOOL *stop) {
		NSDictionary *credit = (NSDictionary *)obj;
		
		if ([credit[@"label"] isEqual:@"Cast"]) {
			[credit[@"list"] enumerateObjectsUsingBlock:^ (id obj, NSUInteger ndx, BOOL *stop) {
				NSDictionary *entry = (NSDictionary *)obj;
				[mCast addObject:[[IDIMDbPerson alloc] initWithDictionary:entry[@"name"]]];
			}];
		}
	}];
}





#pragma mark - IDMovie

- (NSString *)imdbId
{
	if (mInfo[@"tconst"] && [mInfo[@"tconst"] isKindOfClass:[NSString class]])
		return mInfo[@"tconst"];
	else
		return nil;
}

- (NSString *)title
{
	if (!mInfo[@"title"] && !mGotMovie)
		[self getMovieDetails];
	
	if (mInfo[@"title"] && [mInfo[@"title"] isKindOfClass:[NSString class]])
		return mInfo[@"title"];
	else
		return nil;
}

- (void)setTitle:(NSString *)title
{
	mInfo[@"title"] = title;
}

- (NSNumber *)year
{
	if (!mInfo[@"year"] && !mGotMovie)
		[self getMovieDetails];
	
	if (mInfo[@"year"] && [mInfo[@"year"] isKindOfClass:[NSString class]])
		return @(((NSString *)mInfo[@"year"]).integerValue);
	else
		return nil;
}

- (void)setYear:(NSNumber *)year
{
	mInfo[@"year"] = year.stringValue;
}

- (NSString *)rating
{
	if (!mGotMovie)
		[self getMovieDetails];
	
	NSString *rating = mInfo[@"certificate"][@"certificate"];
	
	if (rating && [rating isKindOfClass:[NSString class]] && ![rating isEqualToString:@"Not Rated"])
		return rating;
	else
		return nil;
}

- (NSNumber *)score
{
	if (!mGotMovie)
		[self getMovieDetails];
	
	if (mInfo[@"rating"] && [mInfo[@"rating"] isKindOfClass:[NSNumber class]]) {
		return @((NSUInteger)(((NSNumber *)mInfo[@"rating"]).doubleValue * 10.));
	}
	else
		return nil;
}

- (NSString *)synopsis
{
	if (!mGotMovie)
		[self getMovieDetails];
	
	if (mInfo[@"best_plot"][@"summary"] && [mInfo[@"best_plot"][@"summary"] isKindOfClass:[NSString class]])
		return mInfo[@"best_plot"][@"summary"];
	else if (mInfo[@"best_plot"][@"outline"] && [mInfo[@"best_plot"][@"outline"] isKindOfClass:[NSString class]])
		return mInfo[@"best_plot"][@"outline"];
	else
		return nil;
}

- (NSNumber *)runtime
{
	if (!mGotMovie)
		[self getMovieDetails];
	
	NSNumber *runtime = mInfo[@"runtime"][@"time"];
	
	if (runtime && [runtime isKindOfClass:[NSNumber class]])
		return @((NSUInteger)(runtime.doubleValue / 60.));
	else
		return nil;
}

- (NSURL *)imageUrl
{
	if (!mGotMovie)
		[self getMovieDetails];
	
	NSString *url = mInfo[@"image"][@"url"];
	
	if (url && [url isKindOfClass:[NSString class]])
		return [NSURL URLWithString:url];
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
	
	if (mInfo[@"genres"] && [mInfo[@"genres"] isKindOfClass:[NSArray class]])
		return mInfo[@"genres"];
	else
		return nil;
}

@end
