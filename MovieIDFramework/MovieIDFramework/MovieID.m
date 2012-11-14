//
//  MovieID.m
//  MovieID
//
//  Created by Curtis Jones on 2012.09.05.
//  Copyright (c) 2012 Curtis Jones. All rights reserved.
//

#import "MovieID.h"
#import "IDMediaInfo.h"
#import "IDTimecode.h"
#import "RegexKitLite.h"
#import "APLevelDB.h"
#import "SBJson.h"
#import "NSData+Base64.h"
#import <CommonCrypto/CommonCrypto.h>
#import <CommonCrypto/CommonDigest.h>

@interface MovieID ()
{
	NSString *mBaseDir;
	
	NSString *mNameOrig;
	NSString *mNameNorm;
	NSString *mYear;
	NSMutableArray *mNames;
	
	IDMediaInfo *mMediaInfo;
	NSTimeInterval mDuration;
	SBJsonParser *mJsonParser;
	
	dispatch_queue_t mQueue;
}
@end

@implementation MovieID

/**
 *
 *
 */
- (id)init
{
	self = [super init];
	
	if (self) {
		mBaseDir = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, TRUE)[0];
		mJsonParser = [[SBJsonParser alloc] init];
		mNames = [[NSMutableArray alloc] init];
	}
	
	return self;
}

/**
 *
 *
 */
- (IDMediaInfo *)basicInfoForMovieWithName:(NSString *)name
{
	mNameOrig = name;
	[mNames removeAllObjects];
	
	if (![self normalizeMovieName])
		return nil;
	
	mMediaInfo = [[IDMediaInfo alloc] init];
	mMediaInfo.title = mNames[0];
	mMediaInfo.year = mYear;
	
	return mMediaInfo;
}

/**
 *
 *
 */
- (IDMediaInfo *)infoForMovieWithName:(NSString *)name filePaths:(NSArray *)paths
{
	NSFileManager *fileManager = [[NSFileManager alloc] init];
	
	mNameOrig = name;
	
	if (![self normalizeMovieName])
		return nil;
	
	NSDictionary *attrs = [fileManager attributesOfItemAtPath:paths[0] error:nil];
	
	//mMediaInfo = [[IDMediaInfo alloc] initWithFilePaths:paths];
	mDuration = mMediaInfo.timecode.duration;
	mMediaInfo.dirPath = [paths[0] stringByDeletingLastPathComponent];
	mMediaInfo.duration = [NSNumber numberWithInteger:(NSInteger)mMediaInfo.timecode.duration];
	mMediaInfo.title = name;
	mMediaInfo.year = mYear;
	mMediaInfo.mtime = [attrs fileModificationDate];
	mMediaInfo.posterUrl = [self getPosterUrlInDir:[paths[0] stringByDeletingLastPathComponent]];
	
	// file size
	{
		__block unsigned long long size = 0;
		
		[paths enumerateObjectsUsingBlock:^ (id obj1, NSUInteger ndx1, BOOL *stop1) {
			size += [attrs fileSize];
		}];
		
		mMediaInfo.size = [NSNumber numberWithUnsignedLongLong:size];
	}
	
	if (![self getTmdbInfo])
		if (![self getRTInfo])
			return nil;
			; //[self getImdbInfo];
	
	return mMediaInfo;
}

// http://api.themoviedb.org/2.1/current-apps

/**
 * http://www.imdb.com/xml/find?xml=1&nr=1&tt=on&q=the+donner+party
 *
 * <html>
 *   <head><style type="text/css"></style><link id="_shutUp" rel="stylesheet" type="text/css" href="data:text/css;base64,LyogCiAqIHNodXR1cC5jc3MgMjAxMi0wOC0yMwogKiB3ZWIgLSBwZWFudXQgZ2FsbGVyeSA9IGJsaXNzCiAqCiAqIGJ5IFN0ZXZlbiBGcmFuayA8c3RldmVuZkBwYW5pYy5jb20+CiAqIDxodHRwOi8vc3RldmVuZi5jb20vcGFnZXMvc2h1dHVwLz4KICoKICogTm90ZXM6CiAqCiAqIDEuIElmIHlvdSB3YW50IHRvIFJFLUVOQUJMRSBjb21tZW50cyBmb3IgYSBzcGVjaWZpYyBzaXRlLCBhZGQgYW4KICogb3ZlcnJpZGUgYWZ0ZXIgaW1wb3J0aW5nIHRoaXMgZmlsZS4gIEZvciBleGFtcGxlLCB0byByZS1lbmFibGUKICoganVzdCBTbGFzaGRvdCBjb21tZW50czoKICogIAogKiBAaW1wb3J0IHVybCgiaHR0cDovL3N0ZXZlbmYuY29tL3BhZ2VzL3NodXR1cC9zaHV0dXAtbGF0ZXN0LmNzcyIpOwogKiAKICogI2NvbW1lbnRsaXN0aW5nIHsKICogICAgIGRpc3BsYXk6IGluaGVyaXQgIWltcG9ydGFudDsKICogfQogKgogKiBCZSBhd2FyZSB0aGF0IHNvbWUgc2l0ZXMgbWF5IGJlIGFmZmVjdGVkIGJ5IG1vcmUgdGhhbiBvbmUgcnVsZS4KICoKICogMi4gSWYgeW91J2QgbGlrZSB0byBqdXN0IGZhZGUgY29tbWVudHMgb3V0IHJhdGhlciB0aGFuIGNvbXBsZXRlbHkgCiAqIHJlbW92ZSB0aGVtIGZyb20gdGhlIHBhZ2U6CiAqIAogKiBSZXBsYWNlOgogKiAgICAgZGlzcGxheTogbm9uZSAhaW1wb3J0YW50OwogKgogKiBXaXRoIHNvbWV0aGluZyBsaWtlOgogKiAgICAgb3BhY2l0eTogMC4xOwogKgogKi8KCi8qIFlvdVR1YmUgKHN0YW5kYXJkIGFuZCBGZWF0aGVyIGludGVyZmFjZXMpICovCgojd2F0Y2gtY29tbWVudC1wYW5lbCwKI2NtLAojd2F0Y2gtY29tbWVudHMtY29yZSwKCi8qIERpZ2cgYW5kIG90aGVyIHNpdGVzIHRoYXQgdXNlICJjb21tZW50cyIgZGl2cyAqLwoKLmNvbW1lbnRzLAojY29tbWVudHMsCgovKiBDTk4gYW5kIG90aGVyIHNpdGVzIHRoYXQgdXNlIERpc3F1cyAqLwoKI2Rpc3F1c190aHJlYWQsCiNkc3EtY29udGVudCwKCi8qIEFpbid0IEl0IENvb2wgTmV3cyAqLwoKLmJsb2NrLXRhbGtiYWNrX3N0b3J5LAoKLyogVmVyc2lvblRyYWNrZXIgKi8KCiNwcm9kUmV2aWV3cywKCi8qIE1hY1VwZGF0ZSAqLwoKLnJldmNvbnRlbnQsCgovKiBXb3JkUHJlc3MgZGVmYXVsdCBLdWJyaWNrIHRoZW1lIGFuZCBkZXNjZW5kZW50cyAqLwoKLmNvbW1lbnRsaXN0LAoKLyogU2xhc2hkb3QgKi8KCiNjb21tZW50bGlzdGluZywKCi8qIENCQyBOZXdzICovCgojc29jaWFsY29tbWVudHMsCgovKiBDfE5ldCBOZXdzLmNvbSAqLwoKLmNvbW1lbnR3cmFwcGVyLAoKLyogUmVkZGl0ICovCgouY29tbWVudGFyZWEsCgovKiBPcmVnb25MaXZlIGFuZCBnZW5lcmljICJjb21tZW50IiBjbGFzcyAqLwoKLmNvbW1lbnQsCgovKiBLQVRVICovCgojY29tbWVudGZvcm0sCgovKiBXYXNoaW5ndG9uIFBvc3QgYW5kIG90aGVyIHNpdGVzIHRoYXQgdXNlICJjb21tZW50VGV4dCIgZGl2cyAqLwoKLmNvbW1lbnRUZXh0LAoKLyogR2FubmV0dCBuZXdzcGFwZXJzIGFuZCBvdGhlciBzaXRlcyB0aGF0IHVzZSBQbHVjayAqLwoKZGl2I3BsdWNrY29tbWVudHMsCgovKiBMYXN0LmZtIHNob3V0Ym94ICovCgpkaXYjcGFnZSBkaXYjY29udGVudCBoMiNzaG91dGJveCwgZGl2I3BhZ2UgZGl2I2NvbnRlbnQgZGl2I3Nob3V0Ym94Q29udGFpbmVyLAoKLyogVGhlIEdsb2JlIGFuZCBNYWlsICovCgojbGF0ZXN0LWNvbW1lbnRzLAoKLyogRVcgKi8KCi5jb21tZW50SG9sZGVyLAoKLyogVW5rbm93biAqLwoKLmNvbW1lbnRzLWxpc3QsCiNibG9nQ29tbWVudHMsCiNjb21tZW50c19wYW5lLAojY29tbWVudGNvbnRhaW5lciwKI2NvbW1lbnRzRGl2LAoKLyogQm94ZWUgKi8KCi5jb21tZW50LWNvbnRhaW5lciwgCiNjb21tZW50LWNvbnRhaW5lciwKCi8qIE1MQiAqLwoKI2NvbW1lbnRfY29udGFpbmVyLAoKLyogQ05OICovCgojY29tbWVudGJsb2IsCiNjbm5Db21tZW50cywKCi8qIFRoZSBTdHJhbmdlciAqLwoKI0Jyb3dzZUNvbW1lbnRzLAoKLyogWWFob28gTmV3cyAqLwoKLm13cHBodS1jb21tZW50cywKLnVnY2NtdC1jb21tZW50cywKCi8qIENvZGluZyBIb3Jyb3IgKi8KCi5jb21tZW50cy1ib2R5LAoKLyogc2VlbiBvbiBSZXV0ZXJzICovCgouYXJ0aWNsZUNvbW1lbnRzLAoKLyogbmF0aW9uYWxwb3N0LmNvbSAoUGx1Y2spICovCgoucGx1Y2stY29tbSwKCi8qIEtBVFUgKi8KCi5wYWdlLWNvbW1lbnRzLAoKLyogRGV2aWFudEFydCAqLwoKI2dtaS1DQ29tbWVudE1hc3RlciwKCi8qIFNvbWUgYmxvZ3MgKi8KCi5jb21tZW50cy1jb250YWluZXIsCgovKiBPcHJhaCAqLwoKI21lZGlhX2NvbW1lbnRzLAoKLyogOXRvNW1hYyAqLwoKI2lkYy1jb250YWluZXItcGFyZW50LAoKLyogTGl2ZWZ5cmUgKi8KCiNsaXZlZnlyZS1ib2R5LAoKLyogUEMgV29ybGQgKi8KCiNhcnRpY2xlQ29tbWVudHMsCgovKiBTbGF0ZSAqLwoKLmpzLUNvbW1lbnRzQXJlYSwKCi8qIE5ZVGltZXMgQmxvZ3MgKi8KCiNyZWFkZXJDb21tZW50cywKLnJlYWRlckNvbW1lbnRzLAouY29tbWVudHNNb2R1bGUsCgovKiBCQkMgTmV3cyAqLwoKLmRuYS1jb21tZW50LAoKLyogWkROZXQgKi8KCi52aWV3LTYsIAouc3BhY2UtXzUsCgovKiBHYW1hc3V0cmEgKi8KCi5hbGxfY29tbWVudHMsCgovKiBkdmljZS5jb20gKi8KCiNkaXNwbGF5X2NvbW1lbnRzLAoKLyogaHAuY29tICovCgouYXJ0aWNsZS1jb21tZW50cywKCi8qIHVuaW9ubGVhZGVyLmNvbSAqLwoKI2NvbW1lbnRzY29udGFpbmVyLAoKLyogaWZjLmNvbSAqLwoKLmVjaG8tc3RyZWFtLWNvbnRhaW5lciwKCi8qIGNyZWF0aXZlcmV2aWV3LmNvLnVrICovCgojZmVlZGJhY2ssCgovKiB3d2Vlay5jb20gKi8KCi5Db21tZW50cywKCi8qIHRoZW5leHR3ZWIuY29tICovCgojbGZfY29tbWVudHMsCiNsZl90d2l0dGVyX2NvbW1lbnRzLAojbGZfZmFjZWJvb2tfY29tbWVudHMsCgovKiBNYWNXb3JsZCAqLwoKI2NvbW1lbnRMaXN0LAoKLyogZnQuY29tICovCgojaW5mZXJuby1jb21tZW50cywKCi8qIHRpZGJpdHMuY29tICovCgouY2JfYmxvY2ssCgovKiBkaWxiZXJ0LmNvbSAqLwoKLkNNVF9Db21tZW50TGlzdCwKCi8qIENyYWNrZWQgKi8KIAojY29tbWVudHNfc2VjdGlvbiwKCi8qIEZhY2Vib29rIGZlZWRiYWNrICovCgouZmItY29tbWVudHMsCgovKiBidXp6ZmVlZCAqLwoKI3Jlc3BvbnNlcywKI2ZhY2Vib29rX3Jlc3BvbnNlcywKCi8qIHNwaWVnZWwuZGUgKi8KCi5zcENvbW1lbnRzQm94Qm9keSwKCi8qIGF1dG8tbW90b3ItdW5kLXNwb3J0LmRlICovCgoua29tbWVudGFyZV91ZWJlcnNpY2h0LAoKLyogY29ycmllcmUuaXQgKi8KCiNib2R5X2RsdCwKCi8qIHJlcHViYmxpY2EuaXQgKi8KCiN1Z2MtY29udGFpbmVyLAoKLyogZmF6Lm5ldCAqLwoKLkFydGlrZWxLb21tZW50aWVyZW4sCgovKiBHaWFudCBCb21iIGF2YXRhcnMgKi8KCi5jb21tZW50LWF2YXRhci13cmFwLAoKLyogaGxudHYuY29tICovCgouZmJGZWVkYmFja0NvbnRlbnQsCgovKiBtaXJyb3IuY28udWsgKi8KCi5wbHVjay13cmFwLAoKLyogVHdpdFBpYyAqLwoKI21lZGlhLWNvbW1lbnRzLAoKLyogLi4ubWlzYy4uLiAqLwoKLmRpc2N1c3Npb25Db250YWluZXIsCi5jb21tZW50Qm94U3R5bGUsCi5wYWdlY29tbWVudCwKLnBhZ2Vjb21tZW50aGVhZGVyLAouY29tX3RleHQsCi5jb21tZW50dHh0LAoucG9zdC1jb21tZW50LWxpc3QKCnsKCWRpc3BsYXk6IG5vbmUgIWltcG9ydGFudDsKfQo="></head>
 *   <body><imdbresults>
 *     <resultset type="title_popular">
 *       <imdbentity id="tt0372237">The Dinner Party<description>2005,     <a href="/name/nm0838198/">Kevin Rodney Sullivan</a></description></imdbentity>
 *     </resultset>
 *     <resultset type="title_exact">
 *       <imdbentity id="tt1219336">The Donner Party<description>2009,     <a href="/name/nm1149911/">T.J. Martin</a></description></imdbentity>
 *     </resultset>
 *     <resultset type="title_approx">
 *       <imdbentity id="tt0210948">Right Out of History: The Making of Judy Chicago's Dinner Party<description>1980 documentary,     <a href="/name/nm0218393/">Johanna Demetrakas</a></description></imdbentity>
 *       <imdbentity id="tt1062350">The Dinner Party<description>2007 TV movie,     <a href="/name/nm0343929/">Tony Grounds</a></description></imdbentity>
 *       <imdbentity id="tt0432368">The Dinner Party<description>2004 short,     <a href="/name/nm0229992/">Guy Ducker</a></description></imdbentity>
 *       <imdbentity id="tt0251667">The Dinner Party<description>1995,     <a href="/name/nm0386931/">Michael Hite</a></description></imdbentity>
 *       <imdbentity id="tt1451708">The Dinner Party<description>2009/II,     <a href="/name/nm3481015/">Scott Murden</a></description></imdbentity>
 *       <imdbentity id="tt1382427">The Dinner Party<description>2009/III short,     <a href="/name/nm3339588/">Gretchen von Tongeln</a></description></imdbentity>
 *       <imdbentity id="tt1546035">The Dinner Party<description>2010/I short,     <a href="/name/nm2871592/">Peter Glanz</a></description></imdbentity>
 *       <imdbentity id="tt1792629">The Dinner Party<description>2010/II,     <a href="/name/nm3636835/">Si Wall</a></description></imdbentity>
 *       <imdbentity id="tt1475243">Dinner Party of the Damned<description>2008 video short,     <a href="/name/nm2478287/">Brian Wimer</a></description></imdbentity>
 *       <imdbentity id="tt1535530">Judy Chicago and the Dinner Party<description>1983 TV documentary,     <a href="/name/nm0075731/">Brigitte Berman</a></description></imdbentity>
 *     </resultset>
 *   </imdbresults></body>
 * </html>
 *
 * -------------------------------------------------------------------------------------------------
 *
 * {
 *   "title_popular": [
 *     {
 *       "id":"tt0372237", 
 *       "title":"Guess Who",
 *       "name":"",
 *       "title_description":"2005, Kevin Rodney Sullivan",
 *       "episode_title":"",
 *       "description":"2005, Kevin Rodney Sullivan"
 *     }
 *   ],
 *   "title_exact": [{ "id":"tt1219336", "title":"The Donner Party", "name":"","title_description":"2009, T.J. Martin","episode_title":"","description":"2009, T.J. Martin"}],
 *   "title_approx": [{ "id":"tt0210948", "title":"Right Out of History: The Making of Judy Chicago's Dinner Party", "name":"","title_description":"1980 documentary, Johanna Demetrakas","episode_title":"","description":"1980 documentary, Johanna Demetrakas"},{ "id":"tt1062350", "title":"The Dinner Party", "name":"","title_description":"2007 TV movie, Tony Grounds","episode_title":"","description":"2007 TV movie, Tony Grounds"},{ "id":"tt0432368", "title":"Telling Mark", "name":"","title_description":"2004 short, Guy Ducker","episode_title":"","description":"2004 short, Guy Ducker"},{ "id":"tt0251667", "title":"The Dinner Party", "name":"","title_description":"1995, Michael Hite","episode_title":"","description":"1995, Michael Hite"},{ "id":"tt1451708", "title":"The Dinner Party", "name":"","title_description":"2009/II, Scott Murden","episode_title":"","description":"2009/II, Scott Murden"},{ "id":"tt1382427", "title":"The Dinner Party", "name":"","title_description":"2009/III short, Gretchen von Tongeln","episode_title":"","description":"2009/III short, Gretchen von Tongeln"},{ "id":"tt1546035", "title":"The Dinner Party", "name":"","title_description":"2010/I short, Peter Glanz","episode_title":"","description":"2010/I short, Peter Glanz"},{ "id":"tt1792629", "title":"The Dinner Party", "name":"","title_description":"2010/II, Si Wall","episode_title":"","description":"2010/II, Si Wall"},{ "id":"tt1475243", "title":"Dinner Party of the Damned", "name":"","title_description":"2008 video short, Brian Wimer","episode_title":"","description":"2008 video short, Brian Wimer"},{ "id":"tt1535530", "title":"Judy Chicago and the Dinner Party", "name":"","title_description":"1983 TV documentary, Brigitte Berman","episode_title":"","description":"1983 TV documentary, Brigitte Berman"},{ "id":"tt2125324", "title":"The Devil's Dinner Party", "name":"","title_description":"2011 TV series, Simon Staffurth","episode_title":"","description":"2011 TV series, Simon Staffurth"},{ "id":"tt0455062", "title":"The Dinner Party", "name":"","title_description":"2004 TV series, Mark Wooderson","episode_title":"","description":"2004 TV series, Mark Wooderson"},{ "id":"tt1661895", "title":"The Dinner Party", "name":"","title_description":"2008 short, Benjamin Mennell","episode_title":"","description":"2008 short, Benjamin Mennell"},{ "id":"tt1419650", "title":"The Dinner Party", "name":"","title_description":"2009/I short, Shiraz Jafri","episode_title":"","description":"2009/I short, Shiraz Jafri"},{ "id":"tt2014363", "title":"The Dinner Party", "name":"","title_description":"2011 short, Rick Green","episode_title":"","description":"2011 short, Rick Green"},{ "id":"tt1378313", "title":"The Dinner Party", "name":"","title_description":"1994 short, James Colman","episode_title":"","description":"1994 short, James Colman"},{ "id":"tt0124394", "title":"The Dinner Party", "name":"","title_description":"1994 video, Cameron Grant","episode_title":"","description":"1994 video, Cameron Grant"},{ "id":"tt0283313", "title":"Dinner Party II: The Buffet", "name":"","title_description":"1998 video, ...","episode_title":"","description":"1998 video, ..."}]
 * }
 *
 * http://anonymouse.org/cgi-bin/anon-www.cgi/https://app.imdb.com/title/maindetails?api=1&appid=iphone1_1&apiPolicy=app1_1&apiKey=2wex6aeu6a8q9e49k7sfvufd6rhh0n&locale=en_US&timestamp=0&tconst=tt0068646
 *
 */
- (NSString *)imdbQueryUrlWithAction:(NSString *)action method:(NSString *)method query:(NSString *)query anonymous:(BOOL)anonymous
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
	
	return searchQuery;
}

- (void)imdbInfoForMovieWithName:(NSString *)name year:(NSString *)year runtime:(NSNumber *)runtime
{
	NSData *searchData = [self doUrlQuery:[self imdbQueryUrlWithAction:@"find" method:@"q" query:name anonymous:FALSE]];
//NSLog(@"%@", [[NSString alloc] initWithBytes:searchData.bytes length:searchData.length encoding:NSUTF8StringEncoding]);
	NSDictionary *imdbinfo = [mJsonParser objectWithData:searchData];
	NSArray *results = imdbinfo[@"data"][@"results"];
	
	[results enumerateObjectsUsingBlock:^ (id obj, NSUInteger ndx, BOOL *stop) {
		NSDictionary *result = (NSDictionary *)obj;
		NSString *label = result[@"label"];
		NSArray *list = result[@"list"];
		
		NSLog(@"%lu entries for %@", list.count, label);
		
		[list enumerateObjectsUsingBlock:^ (id obj, NSUInteger ndx, BOOL *stop) {
			NSDictionary *entry = (NSDictionary *)obj;
			
			if (![entry[@"year"] isEqual:year])
				return;
			
			NSData *movieData = [self doUrlQuery:[self imdbQueryUrlWithAction:@"title/maindetails" method:@"tconst" query:entry[@"tconst"] anonymous:TRUE]];
			NSDictionary *movieInfo = [mJsonParser objectWithData:movieData];
//		NSArray *_genres = movieInfo[@"data"][@"genres"];
			NSString *_runtime = movieInfo[@"data"][@"runtime"][@"time"];
			
			if (600 > labs([_runtime integerValue] - [runtime integerValue])) {
				NSLog(@"  tconst=%@", entry[@"tconst"]);
				NSLog(@"  title=%@", entry[@"title"]);
				NSLog(@"  year=%@", entry[@"year"]);
				NSLog(@"  runtime=%@ vs %@", _runtime, runtime);
			}
			
			//NSLog(@"%@", movieInfo);
		}];
	}];
	
	//NSLog(@"%@", imdbinfo);
}

/*
- (BOOL)tryExactMatch
{
	
}

- (BOOL)tryFuzzyMatch
{
	
}
*/

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
 *
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
- (BOOL)getTmdbInfo
{
	__block BOOL found = FALSE;
	
	[mNames enumerateObjectsUsingBlock:^ (id obj0, NSUInteger ndx0, BOOL *stop0) {
		NSString *fullName = (NSString *)obj0;
		
		NSLog(@"  [TMDb] Searching for %@ / %@ / %f [name %lu of %lu]", fullName, mYear, (mDuration/60), (ndx0+1), mNames.count);
		
		NSMutableString *searchQuery = [[NSMutableString alloc] init];
		[searchQuery appendString:@"http://api.themoviedb.org/3/search/movie?api_key=d257f5f93714b665cefa48800a6332e2&include_adult=1&query="];
		[searchQuery appendString:[fullName stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
		[searchQuery appendString:@"&year="];
		[searchQuery appendString:mYear];
		NSData *searchData = [self doUrlQuery:searchQuery];
		
		NSInteger runtime = mDuration / 60;
		NSDictionary *tmdb_info = [mJsonParser objectWithData:searchData];
		NSArray *movies = tmdb_info[@"results"];
		NSInteger year = [mYear integerValue];
		
		NSLog(@"  [TMDb]   Got %lu search results", movies.count);
		
		[movies enumerateObjectsUsingBlock:^ (id obj, NSUInteger ndx, BOOL *stop) {
			NSDictionary *_movie = (NSDictionary *)obj;
			NSInteger _runtime=0, _year=0;
			
			NSLog(@"  [TMDb]   [%lu] name=%@, release_date=%@, id=%@", ndx, _movie[@"title"], _movie[@"release_date"], _movie[@"id"]);
			
			// yyyy-mm-dd
			if (((NSString *)_movie[@"release_date"]).length >= 4)
				_year = [[_movie[@"release_date"] substringToIndex:4] integerValue];
			
			if (_year != year) {
				NSLog(@"  [TMDb]     Skipping because the year differs (%ld)", _year);
				return;
			}
			
			if (!_movie[@"id"]) {
				NSLog(@"  [TMDb]     Skipping because it lacks an id");
				return;
			}
			
			NSLog(@"  [TMDb]     Getting details for id = %@", _movie[@"id"]);
			
			// movie info
			{
				NSMutableString *movieQuery = [[NSMutableString alloc] init];
				[movieQuery appendString:@"http://api.themoviedb.org/3/movie/"];
				[movieQuery appendString:[_movie[@"id"] stringValue]];
				[movieQuery appendString:@"?api_key=d257f5f93714b665cefa48800a6332e2"];
				NSData *movieData = [self doUrlQuery:movieQuery];
				
				if (!movieData) {
					NSLog(@"  [TMDb]     Skipping because we didn't get back any data [%@]", movieQuery);
					return;
				}
				
				NSDictionary *movieInfo = [mJsonParser objectWithData:movieData];
				
				// runtime - the runtime must match to within TEN minutes unless both the year and the title
				// match exactly.
				if (!movieInfo[@"runtime"] || [movieInfo[@"runtime"] isKindOfClass:[NSNull class]]) {
					NSLog(@"  [TMDb]     Skipping because it has no runtime information");
					return;
				}
				else {
					_runtime = [movieInfo[@"runtime"] integerValue];
					
					if (10 < labs(_runtime - runtime) && ![fullName isEqualToString:movieInfo[@"title"]]) {
						NSLog(@"  [TMDb]     Skipping because the runtime differs by too much (%ld)", _runtime);
						return;
					}
				}
				
				// genres
				if (movieInfo[@"genres"]) {
					[(NSArray *)movieInfo[@"genres"] enumerateObjectsUsingBlock:^ (id obj2, NSUInteger ndx2, BOOL *stop2) {
						NSDictionary *genre = (NSDictionary *)obj2;
						[mMediaInfo.genres addObject:genre[@"name"]];
					}];
				}
				
			//mMediaInfo.rating = movieInfo[@"mpaa_rating"];
				mMediaInfo.synopsis = movieInfo[@"overview"];
				mMediaInfo.tmdbId = [movieInfo[@"id"] stringValue];
			//mMediaInfo.rtId = ((NSNumber *)movieInfo[@"id"]).stringValue;
				mMediaInfo.imdbId = movieInfo[@"imdb_id"];
				mMediaInfo.runtime = [NSNumber numberWithInteger:_runtime];
				mMediaInfo.title = movieInfo[@"title"];
				mMediaInfo.year = [NSString stringWithFormat:@"%ld", _year];
				
				// poster
				if (movieInfo[@"poster_path"])
					mMediaInfo.posterUrl = [NSURL URLWithString:[NSString stringWithFormat:@"http://cf2.imgobject.com/t/p/original/%@", movieInfo[@"poster_path"]]];
			}
			
			NSLog(@"  [TMDb]     Match! [%@ / %@ / %@]", mMediaInfo.title, mMediaInfo.year, mMediaInfo.duration);
			
			// movie cast
			{
				NSMutableString *castQuery = [[NSMutableString alloc] init];
				[castQuery appendString:@"http://api.themoviedb.org/3/movie/"];
				[castQuery appendString:[_movie[@"id"] stringValue]];
				[castQuery appendString:@"/casts"];
				[castQuery appendString:@"?api_key=d257f5f93714b665cefa48800a6332e2&include_adult=1&query="];
				
				NSLog(@"  [TMDb]     Looking for cast [%@]", castQuery);
				
				NSData *castData = [self doUrlQuery:castQuery];
				
				if (castData) {
					NSDictionary *castInfo = [mJsonParser objectWithData:castData];
					NSArray *cast = (NSArray *)castInfo[@"cast"];
					
					NSLog(@"  [TMDb]     Found %lu cast member(s)", cast.count);
					
					[cast enumerateObjectsUsingBlock:^ (id obj, NSUInteger ndx, BOOL *stop) {
						//sleep(1);
						
						NSDictionary *_cast = (NSDictionary *)obj;
						NSMutableDictionary *idcast = [[NSMutableDictionary alloc] init];
						
						NSLog(@"  [TMDb]     [%lu] %@", ndx, _cast[@"name"]);
						
						NSMutableString *personQuery = [[NSMutableString alloc] init];
						[personQuery appendString:@"http://api.themoviedb.org/3/person/"];
						[personQuery appendString:[_cast[@"id"] stringValue]];
						[personQuery appendString:@"?api_key=d257f5f93714b665cefa48800a6332e2"];
						NSData *personData = [self doUrlQuery:personQuery];
						
						if (!personData) {
							NSLog(@"  [TMDb]       Couldn't find any details for cast meber");
							return;
						}
						
						NSDictionary *personInfo = [mJsonParser objectWithData:personData];
						
						// id
						if (personInfo[@"id"] && ![personInfo[@"id"] isKindOfClass:[NSNull class]])
							idcast[@"tmdbid"] = [personInfo[@"id"] stringValue];
						
						// name
						if (personInfo[@"name"] && ![personInfo[@"name"] isKindOfClass:[NSNull class]])
							idcast[@"name"] = personInfo[@"name"];
						
						// bio
						if (personInfo[@"biography"] && ![personInfo[@"biography"] isKindOfClass:[NSNull class]])
							idcast[@"bio"] = personInfo[@"biography"];
						
						// dob
						if (personInfo[@"birthday"] && ![personInfo[@"birthday"] isKindOfClass:[NSNull class]])
							idcast[@"dob"] = personInfo[@"birthday"];
						
						// dod
						if (personInfo[@"deathday"] && ![personInfo[@"deathday"] isKindOfClass:[NSNull class]])
							idcast[@"dod"] = personInfo[@"deathday"];
						
						// web
						if (personInfo[@"web"] && ![personInfo[@"web"] isKindOfClass:[NSNull class]])
							idcast[@"web"] = personInfo[@"homepage"];
						
						// image
						if (personInfo[@"profile_path"] && ![personInfo[@"profile_path"] isKindOfClass:[NSNull class]])
							idcast[@"imageUrl"] = [NSURL URLWithString:[NSString stringWithFormat:@"http://cf2.imgobject.com/t/p/original/%@", personInfo[@"profile_path"]]];
						
						//NSLog(@"%@", idcast);
						
						[mMediaInfo.cast addObject:idcast];
					}];
				}
				else
					NSLog(@"  [TMDb]     Found no cast members");
			}
			
			found = TRUE;
			*stop = TRUE;
			*stop0 = TRUE;
		}];
	}];
	
	return found;
}

/**
 * http://api.rottentomatoes.com/api/public/v1.0/movies.json?&page_limit=50&q=Toy+Story+3
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
 *
 *
 *
 * http://api.rottentomatoes.com/api/public/v1.0/movies/770672122/cast.json?apikey=
 *
 * {
 *   "id":771252966,
 *   "title":"Arena",
 *   "year":2011,
 *   "genres":["Mystery & Suspense","Action & Adventure"],
 *   "mpaa_rating":"R",
 *   "runtime":94,
 *   "release_dates":{"dvd":"2011-10-11"},
 *   "ratings":{"critics_score":-1,"audience_rating":"Spilled","audience_score":24},
 *   "synopsis":"David Lord finds himself forced into the savage world of a modern gladiatorial arena, where men fight to the death for the entertainment of the online masses.",
 *   "posters":{
 *     "thumbnail":"http://content7.flixster.com/movie/11/16/44/11164425_mob.jpg",
 *     "profile":"http://content7.flixster.com/movie/11/16/44/11164425_pro.jpg",
 *     "detailed":"http://content7.flixster.com/movie/11/16/44/11164425_det.jpg",
 *     "original":"http://content7.flixster.com/movie/11/16/44/11164425_ori.jpg"
 *   },
 *   "abridged_cast":[
 *     {"name":"Kellan Lutz","id":"770685152","characters":["David Lord"]},
 *     {"name":"Samuel L. Jackson","id":"162652156"},
 *     {"name":"Nina Dobrev","id":"528347792"},
 *     {"name":"Daniel Dae Kim","id":"770686469"},
 *     {"name":"James Remar","id":"162667832"}
 *   ],
 *   "abridged_directors":[{"name":"Jonah Loop"}],
 *   "studio":"Sony Pictures Home Entertainment",
 *   "links":{
 *     "self":"http://api.rottentomatoes.com/api/public/v1.0/movies/771252966.json",
 *     "alternate":"http://www.rottentomatoes.com/m/arena_2011/",
 *     "cast":"http://api.rottentomatoes.com/api/public/v1.0/movies/771252966/cast.json",
 *     "clips":"http://api.rottentomatoes.com/api/public/v1.0/movies/771252966/clips.json",
 *     "reviews":"http://api.rottentomatoes.com/api/public/v1.0/movies/771252966/reviews.json",
 *     "similar":"http://api.rottentomatoes.com/api/public/v1.0/movies/771252966/similar.json"}
 *   }
 * }
 *
 */
- (BOOL)getRTInfo
{
	NSString *fullName = mNames[0];
	
	NSLog(@"  [RT  ] Searching for %@ / %@ / %f", fullName, mYear, (mDuration/60));
	
	NSMutableString *searchQuery = [[NSMutableString alloc] init];
	[searchQuery appendString:@"http://api.rottentomatoes.com/api/public/v1.0/movies.json?apikey=p2v39n4putk9j8epvdugptqc&page_limit=50&q="];
	[searchQuery appendString:[fullName stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
	NSData *searchData = [self doUrlQuery:searchQuery];
	
	NSInteger runtime = mDuration / 60;
	NSDictionary *rtinfo = [mJsonParser objectWithData:searchData];
	NSArray *movies = rtinfo[@"movies"];
	NSInteger year = [mYear integerValue];
	__block BOOL found = FALSE;
	
	NSLog(@"  [RT  ]   Got %lu search results", movies.count);
	
	[movies enumerateObjectsUsingBlock:^ (id obj, NSUInteger ndx, BOOL *stop) {
		NSDictionary *_movie = (NSDictionary *)obj;
		NSInteger _year = 0; //[_movie[@"year"] integerValue];
		NSInteger _runtime = [(NSString *)_movie[@"runtime"] integerValue];
		
		NSLog(@"  [RT  ]   [%lu] name=%@, release_date=%@, id=%@", ndx, _movie[@"title"], _movie[@"release_dates"][@"theater"], _movie[@"links"][@"self"]);
		
		// year
		{
			if (!(_year = [_movie[@"year"] integerValue]) || _year != year)
				_year = 0;
			
			if (!year) {
				if (_movie[@"release_dates"][@"theater"]) {
					_year = [[_movie[@"release_dates"][@"theater"] substringToIndex:4] integerValue];
					
					if (!_year || _year != year)
						_year = 0;
				}
			}
			
			if (!year) {
				NSLog(@"  [RT  ]     Skipping because there is no release date");
				return;
			}
		}
		
		// runtime
		if (10 < labs(_runtime - runtime) && ![fullName isEqualToString:_movie[@"title"]]) {
			NSLog(@"  [RT  ]     Skipping because the runtime differs by too much (%ld)", _runtime);
			return;
		}
		
		// movie info
		if (_movie[@"links"][@"self"])
		{
			NSMutableString *movieQuery = [[NSMutableString alloc] init];
			[movieQuery appendString:_movie[@"links"][@"self"]];
			[movieQuery appendString:@"?apikey=p2v39n4putk9j8epvdugptqc"];
			NSData *movieData = [self doUrlQuery:movieQuery];
			
			NSLog(@"  [RT  ]     Getting details for id=%@", _movie[@"links"][@"self"]);
			
			if (movieData) {
				NSDictionary *movieInfo = [mJsonParser objectWithData:movieData];
				//NSLog(@"%@", movieInfo);
				[mMediaInfo.genres addObjectsFromArray:movieInfo[@"genres"]];
				mMediaInfo.rating = movieInfo[@"mpaa_rating"];
				mMediaInfo.synopsis = movieInfo[@"synopsis"];
				mMediaInfo.rtId = ((NSNumber *)movieInfo[@"id"]).stringValue;
				mMediaInfo.imdbId = movieInfo[@"alternate_ids"][@"imdb"];
				mMediaInfo.runtime = [NSNumber numberWithInteger:_runtime];
				mMediaInfo.title = movieInfo[@"title"];
				mMediaInfo.year = ((NSNumber *)movieInfo[@"year"]).stringValue;
				
				// XXX: do some range checking on this string before substringing it
				if (movieInfo[@"release_dates"][@"theater"])
					mMediaInfo.year = [movieInfo[@"release_dates"][@"theater"] substringToIndex:4];
				
				if (movieInfo[@"posters"][@"original"])
					mMediaInfo.posterUrl = [NSURL URLWithString:movieInfo[@"posters"][@"original"]];
				
				NSLog(@"  [RT  ]     match! [%@ / %@ / %@]", mMediaInfo.title, mMediaInfo.year, mMediaInfo.duration);
			}
		}
		
		// movie cast
		if (_movie[@"links"][@"cast"])
		{
			//sleep(1);
			
			NSMutableString *castQuery = [[NSMutableString alloc] init];
			[castQuery appendString:_movie[@"links"][@"cast"]];
			[castQuery appendString:@"?apikey=p2v39n4putk9j8epvdugptqc"];
			NSData *castData = [self doUrlQuery:castQuery];
			
			if (castData) {
				NSDictionary *castInfo = [mJsonParser objectWithData:castData];
				NSArray *cast = castInfo[@"cast"] ? castInfo[@"cast"] : castInfo[@"abridged_cast"];
				
				[cast enumerateObjectsUsingBlock:^ (id obj, NSUInteger ndx, BOOL *stop) {
					NSDictionary *rtcast = (NSDictionary *)obj;
					NSMutableDictionary *idcast = [[NSMutableDictionary alloc] init];
					
					if (rtcast[@"id"]) idcast[@"rtid"] = rtcast[@"id"];
					if (rtcast[@"name"]) idcast[@"name"] = rtcast[@"name"];
					
					[mMediaInfo.cast addObject:idcast];
				}];
			}
		}
		
		found = TRUE;
		*stop = TRUE;
	}];
	
	return found;
}

/**
 *
 *
 */
- (BOOL)normalizeMovieName
{
	NSMutableDictionary *names = [[NSMutableDictionary alloc] init];
	
	mNameNorm = mNameOrig;
	
	// get the year and remove the year
	{
		mYear = [mNameNorm stringByMatching:@"\\((\\d\\d\\d\\d)\\)"];
		
		if (!mYear || mYear.length != 6)
			return FALSE;
		
		mYear = [mYear substringWithRange:NSMakeRange(1, 4)];
		mNameNorm = [mNameNorm stringByReplacingOccurrencesOfRegex:@"\\(\\d\\d\\d\\d\\)" withString:@""];
	}
	
	// move articles from the end to the beginning of the title
	{
		NSArray *parts = [mNameNorm componentsSeparatedByString:@" - "];
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
				[tmp appendString:@" - "];
			
			[tmp appendString:part];
		}];
		
		mNameNorm = [NSString stringWithString:tmp];
		names[mNameNorm] = mNameNorm;
	}
	
	// swap out hyphens with colons
	{
		NSArray *parts = [mNameNorm componentsSeparatedByString:@" - "];
		NSMutableString *tmp = [[NSMutableString alloc] init];
		
		[parts enumerateObjectsUsingBlock:^ (id obj, NSUInteger ndx, BOOL *stop) {
			NSString *part = [(NSString *)obj stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
			
			if (tmp.length)
				[tmp appendString:@": "];
			
			[tmp appendString:part];
		}];
		
		names[tmp] = tmp;
	}
	
	// strip the hyphens
	mNameNorm = [mNameNorm stringByReplacingOccurrencesOfRegex:@" \\- " withString:@" "];
	
	// strip white space
	mNameNorm = [mNameNorm stringByReplacingOccurrencesOfRegex:@"\\s" withString:@""];
	
	// lower case
	mNameNorm = [mNameNorm lowercaseString];
	
	// append year
	mNameNorm = [mNameNorm stringByAppendingString:mYear];
	
	[mNames setArray:names.allKeys];
	
	return TRUE;
}

- (NSData *)doUrlQuery:(NSString *)query
{
	//NSLog(@"%s.. %@", __PRETTY_FUNCTION__, query);
	
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

- (NSURL *)getPosterUrlInDir:(NSString *)dir
{
	NSFileManager *fileManager = [[NSFileManager alloc] init];
	NSArray *files = [fileManager contentsOfDirectoryAtPath:dir error:nil];
	__block NSString *poster = nil;
	
	[files enumerateObjectsUsingBlock:^ (id obj1, NSUInteger ndx1, BOOL *stop1) {
		NSString *file = [(NSString *)obj1 lowercaseString];
		
		if ([file hasSuffix:@".jpg"] ||
				[file hasSuffix:@".gif"] ||
				[file hasSuffix:@".png"]) {
			poster = obj1;
			*stop1 = TRUE;
		}
	}];
	
	if (poster)
		return [NSURL fileURLWithPath:[dir stringByAppendingPathComponent:poster]];
	else
		return nil;
}

@end
