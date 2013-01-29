//
//  MBDataManager.m
//  MovieBrowse
//
//  Created by Curtis Jones on 2012.09.05.
//  Copyright (c) 2012 Curtis Jones. All rights reserved.
//
//  ------------------------------------------------------------------------------------------------
//
//  Stores a set of "sources" (directory paths) that are scanned for movies.

#import "MBDataManager.h"
#import "MBAppDelegate.h"
#import "MBGenre.h"
#import "MBMovie.h"
#import "MBPerson.h"
#import "NSString+Additions.h"
#import "NSThread+Additions.h"
#import <MovieID/APLevelDB.h>
#import <MovieID/IDMediaInfo.h>
#import <MovieID/IDSearch.h>
#import <MovieID/IDMovie.h>
#import <MovieID/IDPerson.h>
#import <MovieID/IDRating.h>
#import <MovieID/IDTmdbMovie.h>
#import <MovieID/RegexKitLite.h>

@interface MBDataManager ()
{
	NSMutableDictionary *mSources;
	
	APLevelDB *mMovieDb;
	APLevelDB *mActorDb;
	
	NSMutableDictionary *mActors;
	NSMutableDictionary *mGenres;
	NSMutableDictionary *mMovies;
}
@end

@implementation MBDataManager

@synthesize actorsByName = mActors;

#pragma mark - Structors

/**
 *
 *
 */
- (id)init
{
	self = [super init];
	
	if (self) {
		mSources = [[NSMutableDictionary alloc] init];
		
		mActors = [[NSMutableDictionary alloc] initWithCapacity:250000];
		mGenres = [[NSMutableDictionary alloc] initWithCapacity:100];
		mMovies = [[NSMutableDictionary alloc] initWithCapacity:25000];
		
		[self openDb];
		
		/*
		__block NSUInteger count = 0;
		
		[NSThread performBlockInBackground:^{
			[self loadActors];
			count += 1;
		}];
		
		[NSThread performBlockInBackground:^{
			[self loadMovies];
			count += 1;
		}];
		
		while (count < 2)
			usleep(100000);
		
		NSLog(@"movies.count = %lu", mMovies.count);
		NSLog(@"actors.count = %lu", mActors.count);
		*/
		
	}
	
	return self;
}

/**
 *
 *
 */
- (void)openDb
{
	NSString *desktop = [@"~/Desktop" stringByExpandingTildeInPath];
	NSString *path = nil;
	
	if ((path = [[NSBundle mainBundle] pathForResource:@"MovieBrowse-Actors" ofType:@"db"]))
		mActorDb = [APLevelDB levelDBWithPath:path error:nil];
	else
		mActorDb = [APLevelDB levelDBWithPath:[desktop stringByAppendingPathComponent:@"MovieBrowse-Actors.db"] error:nil];
	
	if ((path = [[NSBundle mainBundle] pathForResource:@"MovieBrowse-Movies" ofType:@"db"]))
		mMovieDb = [APLevelDB levelDBWithPath:path error:nil];
	else
		mMovieDb = [APLevelDB levelDBWithPath:[desktop stringByAppendingPathComponent:@"MovieBrowse-Movies.db"] error:nil];
}

/**
 *
 *
 */
- (void)closeDb
{
#ifdef DEBUG
	NSLog(@"%s", __PRETTY_FUNCTION__);
	[mMovieDb compact];
	[mActorDb compact];
#endif
}





#pragma mark - Load

/**
 *
 *
 */
- (void)loadActors:(void (^)(NSUInteger, NSString*))handler
{
	__block MBPerson *mbperson = nil;
	__block NSMutableDictionary *movies = nil;
	__block NSUInteger actorCount = 0;
	
	[mActorDb enumerateKeysAndValuesAsStrings:^ (NSString *key, NSString *value, BOOL *stop) {
		NSArray *keyParts = [key componentsSeparatedByString:@"--"];
		
		if (keyParts.count >= 2) {
			NSString *actor = keyParts[0];
			NSString *label = keyParts[1];
			
			if (mbperson && ![actor isEqualToString:mbperson.name]) {
				mActors[mbperson.name] = mbperson;
				actorCount += 1;
				if (handler && !(actorCount % 1000))
					handler(actorCount, mbperson.name);
				mbperson = nil;
				movies = nil;
			}
			
			if (mbperson == nil) {
				mbperson = [[MBPerson alloc] init];
				mbperson.movies = (movies = [[NSMutableDictionary alloc] init]);
				mbperson.name = actor;
			}
			
			if ([label isEqualToString:@"image"]) {
				if (keyParts.count == 3) {
					if ([keyParts[2] isEqual:@"id"])
						mbperson.imageId = value;
					else if ([keyParts[2] isEqual:@"url"])
						mbperson.imageUrl = [NSURL URLWithString:value];
				}
			}
			else if ([label isEqualToString:@"tmdbid" ]) mbperson.tmdbId = value;
			else if ([label isEqualToString:@"rtid"   ]) mbperson.rtId   = value;
			else if ([label isEqualToString:@"imdbid" ]) mbperson.imdbId = value;
			else if ([label isEqualToString:@"bio"    ]) mbperson.bio    = value;
			else if ([label isEqualToString:@"dob"    ]) mbperson.dob    = value;
			else if ([label isEqualToString:@"dod"    ]) mbperson.dod    = value;
			else if ([label isEqualToString:@"web"    ]) mbperson.web    = value;
			else if ([label isEqualToString:@"movie"  ] && keyParts.count == 4) {
				NSMutableString *key = [[NSMutableString alloc] init];
				[key appendString:keyParts[2]];
				[key appendString:@"--"];
				[key appendString:keyParts[3]];
				movies[key] = @"";
			}
		}
	}];
	
	if (mbperson)
		mActors[mbperson.name] = mbperson;
}

/**
 *
 *
 */
- (void)loadMovies:(void (^)(NSUInteger, NSString*))handler
{
	__block MBMovie *mbmovie = nil;
	__block NSString *curTitle = nil;
	__block NSMutableDictionary *actors = nil;
	__block NSMutableDictionary *genres = nil;
	__block NSMutableArray *languages = nil;
	__block NSUInteger movieCount = 0;
	
	[mMovieDb enumerateKeysAndValuesAsStrings:^ (NSString *key, NSString *value, BOOL *stop) {
		NSArray *keyParts = [key componentsSeparatedByString:@"--"];
		
		if (keyParts.count < 3)
			return;
		
		NSString *title = keyParts[0];
		NSNumber *year  = @(((NSString *)keyParts[1]).integerValue);
		NSString *label = keyParts[2];
		
		if (mbmovie && (![curTitle isEqualToString:title] || ![mbmovie.year isEqual:year])) {
			/*
			NSString *_yearPath = [mbmovie.dirpath stringByMatching:@"\\((\\d\\d\\d\\d)\\)"];
			_yearPath = [_yearPath substringWithRange:NSMakeRange(1, 4)];
			
			if (mbmovie.year.integerValue != _yearPath.integerValue) {
				NSLog(@"Year Mismatch for '%@' [%@ vs %@]", mbmovie.title, mbmovie.year, _yearPath);
				//[self deleteMovie:mbmovie];
			}
			*/
			
			mMovies[mbmovie.dbkey] = mbmovie;
			movieCount += 1;
			if (handler && !(movieCount % 100))
				handler(movieCount, mbmovie.title);
			mbmovie = nil;
			actors = nil;
			genres = nil;
			languages = nil;
		}
		
		if (!mbmovie) {
			NSMutableString *key = [[NSMutableString alloc] init];
			[key appendString:title];
			[key appendString:@"--"];
			[key appendString:year.stringValue];
			curTitle = title;
			mbmovie = [[MBMovie alloc] init];
			mbmovie.actors = (actors = [[NSMutableDictionary alloc] init]);
			mbmovie.genres = (genres = [[NSMutableDictionary alloc] init]);
			mbmovie.languages = (languages = [[NSMutableArray alloc] init]);
			mbmovie.dbkey = key;
			mbmovie.year = year;
		}
		
		if ([label isEqualToString:@"path"])
			mbmovie.dirpath = value;
		else if ([label isEqualToString:@"updated"]) {
			if (value.integerValue)
				mbmovie.updated = [NSDate dateWithTimeIntervalSinceReferenceDate:value.integerValue];
		}
		else if ([label isEqualToString:@"title"])
			mbmovie.title = value;
		else if ([label isEqualToString:@"year"])
			mbmovie.year = @(value.integerValue);
		else if ([label isEqualToString:@"runtime"])
			mbmovie.runtime = @(value.integerValue);
		else if ([label isEqualToString:@"rating"])
			mbmovie.rating = value;
		else if ([label isEqualToString:@"hidden"])
			mbmovie.hidden = @(value.integerValue);
		else if ([label isEqualToString:@"score"])
			mbmovie.score = @(value.integerValue);
		else if ([label isEqualToString:@"synopsis"])
			mbmovie.synopsis = value;
		else if ([label isEqualToString:@"tmdbid"])
			mbmovie.tmdbId = value;
		else if ([label isEqualToString:@"rtid"])
			mbmovie.rtId = value;
		else if ([label isEqualToString:@"imdbid"])
			mbmovie.imdbId = value;
		else if ([label isEqualToString:@"duration"])
			mbmovie.duration = @(value.integerValue);
		else if ([label isEqualToString:@"size"])
			mbmovie.filesize = @(value.longLongValue);
		else if ([label isEqualToString:@"width"])
			mbmovie.width = @(value.longLongValue);
		else if ([label isEqualToString:@"height"])
			mbmovie.height = @(value.longLongValue);
		else if ([label isEqualToString:@"bitrate"])
			mbmovie.bitrate = @(value.longLongValue);
		else if ([label isEqualToString:@"mtime"])
			mbmovie.mtime = [NSDate dateWithTimeIntervalSinceReferenceDate:value.doubleValue];
		else if ([label isEqualToString:@"poster"])
			mbmovie.posterId = value;
		else if ([label isEqualToString:@"actor"])
			actors[value] = @"";
		else if ([label isEqualToString:@"language"]) {
			if (keyParts.count >= 4)
				[languages addObject:keyParts[3]];
		}
		else if ([label isEqualToString:@"genre"]) {
			if (keyParts.count >= 4) {
				NSString *genre = keyParts[3];
				MBGenre *mbgenre = mGenres[genre];
				if (!mbgenre)
					mGenres[genre] = (mbgenre = [[MBGenre alloc] initWithGenre:genre]);
				genres[genre] = mbgenre;
			}
		}
	}];
	
	if (mbmovie)
		mMovies[mbmovie.dbkey] = mbmovie;
	
#if !defined DEBUG
	[mGenres removeObjectForKey:@"Adult"];
	[mGenres removeObjectForKey:@"Erotic"];
#endif
}





#pragma mark - Queries

/**
 *
 *
 */
- (BOOL)doesMovie:(MBMovie *)mbmovie haveActor:(MBPerson *)mbperson
{
	if (!mbmovie || !mbperson)
		return FALSE;
	else
		return nil != mbmovie.actors[mbperson.name];
}

/**
 *
 *
 */
- (BOOL)doesMovie:(MBMovie *)mbmovie haveGenre:(MBGenre *)mbgenre
{
	if (!mbmovie || !mbgenre)
		return FALSE;
	else
		return nil != mbmovie.genres[mbgenre.name];
//	return nil != mbgenre.movies[mbmovie.dbkey];
}

/**
 *
 *
 */
- (BOOL)doesMovie:(MBMovie *)mbmovie haveLanguage:(NSString *)language
{
	if (!mbmovie || !language.length)
		return FALSE;
	else if ([language isEqualToString:@"Unknown"] && !mbmovie.languages.count)
		return TRUE;
	else
		return NSNotFound != [mbmovie.languages indexOfObject:language];
}

/**
 *
 *
 */
- (MBMovie *)movieWithKey:(NSString *)dbkey
{
	return mMovies[dbkey];
}

/**
 *
 *
 */
- (MBPerson *)personWithKey:(NSString *)dbkey
{
	return mActors[dbkey];
}

/**
 *
 *
 */
- (void)person:(MBPerson *)person updateWithName:(NSString *)name
{
	
}

/**
 *
 *
 */
- (void)person:(MBPerson *)mbperson updateWithValues:(NSDictionary *)values
{
	id value = nil;
	NSString *dbkey = mbperson.name;
	
	// bio
	if (nil != (value = values[@"bio"]) && [value isKindOfClass:NSString.class]) {
		mActorDb[[dbkey stringByAppendingString:@"--bio"]] = value;
		mbperson.bio = value;
	}
	
	// dob
	if (nil != (value = values[@"dob"]) && [value isKindOfClass:NSString.class]) {
		mActorDb[[dbkey stringByAppendingString:@"--dob"]] = value;
		mbperson.dob = value;
	}
	
	// dod
	if (nil != (value = values[@"dod"]) && [value isKindOfClass:NSString.class]) {
		mActorDb[[dbkey stringByAppendingString:@"--dod"]] = value;
		mbperson.dod = value;
	}
	
	// web
	if (nil != (value = values[@"web"]) && [value isKindOfClass:NSString.class]) {
		mActorDb[[dbkey stringByAppendingString:@"--web"]] = value;
		mbperson.web = value;
	}
	
	// imdb
	if (nil != (value = values[@"imdb"]) && [value isKindOfClass:NSString.class]) {
		mActorDb[[dbkey stringByAppendingString:@"--imdbid"]] = value;
		mbperson.imdbId = value;
	}
	
	// tmdb
	if (nil != (value = values[@"tmdb"]) && [value isKindOfClass:NSString.class]) {
		mActorDb[[dbkey stringByAppendingString:@"--tmdbid"]] = value;
		mbperson.tmdbId = value;
	}
	
	// rtid
	if (nil != (value = values[@"rtid"]) && [value isKindOfClass:NSString.class]) {
		mActorDb[[dbkey stringByAppendingString:@"--rtid"]] = value;
		mbperson.rtId = value;
	}
	
	// poster
	if (nil != (value = values[@"poster"]) && [value isKindOfClass:NSData.class]) {
		NSString *imageId = mbperson.imageId;
		NSFileManager *fileManager = [[NSFileManager alloc] init];
		NSString *baseDir = [[NSUserDefaults standardUserDefaults] stringForKey:MBDefaultsKeyImageCache];
		NSString *actorBaseDir = [baseDir stringByAppendingPathComponent:@"Actors"];
		
		if (!imageId.length) {
			imageId = [NSString randomStringOfLength:32];
			mbperson.imageId = imageId;
		}
		
		NSString *dataDir = [actorBaseDir stringByAppendingPathComponent:[imageId substringToIndex:2].lowercaseString];
		NSString *dataPath = [dataDir stringByAppendingPathComponent:imageId];
		
		[fileManager createDirectoryAtPath:dataDir withIntermediateDirectories:TRUE attributes:nil error:nil];
		
		mActorDb[[dbkey stringByAppendingString:@"--image--id"]] = imageId;
		
		[(NSData *)value writeToFile:dataPath atomically:FALSE];
	}
}

/**
 *
 *
 */
- (void)movie:(MBMovie *)mbmovie updateWithTitle:(NSString *)newTitle
{
	NSString *dbkeyOld = mbmovie.dbkey;
	NSString *dbkeyNew = [[newTitle stringByAppendingString:@"--"] stringByAppendingString:mbmovie.year.stringValue];
	NSMutableDictionary *keys = [[NSMutableDictionary alloc] init];
	
	NSLog(@"%s.. %@ ===> %@", __PRETTY_FUNCTION__, dbkeyOld, dbkeyNew);
	
	// get all of the old keys/values
	{
		NSString *keyOld = dbkeyOld;
		
		APLevelDBIterator *iter = [APLevelDBIterator iteratorWithLevelDB:mMovieDb];
		
		if (![iter seekToKey:keyOld]) {
			NSLog(@"%s.. could not find starting point [%@]", __PRETTY_FUNCTION__, dbkeyOld);
			return;
		}
		
		do {
			if (![keyOld hasPrefix:dbkeyOld])
				break;
			keys[keyOld] = [iter valueAsString];
		}
		while (nil != (keyOld = [iter nextKey]));
	}
	
	[keys enumerateKeysAndObjectsUsingBlock:^ (id keyOld, id value, BOOL *stop) {
		NSString *keyNew = [dbkeyNew stringByAppendingString:[keyOld substringFromIndex:dbkeyOld.length]];
		[mMovieDb removeKey:keyOld];
		mMovieDb[keyNew] = value;
	}];
	
	mMovieDb[[dbkeyNew stringByAppendingString:@"--title"]] = newTitle;
	mMovieDb[mbmovie.dirpath.lastPathComponent] = dbkeyNew;
	
	mbmovie.title = newTitle;
}

/**
 *
 *
 */
- (void)movie:(MBMovie *)mbmovie updateWithValues:(NSDictionary *)values
{
	id value = nil;
	NSString *dbkey = mbmovie.dbkey;
	
	// year
	if (nil != (value = values[@"year"]) && [value isKindOfClass:NSNumber.class]) {
		mMovieDb[[dbkey stringByAppendingString:@"--year"]] = value;
		mbmovie.year = value;
	}
	
	// rating
	if (nil != (value = values[@"rating"]) && [value isKindOfClass:NSString.class]) {
		mMovieDb[[dbkey stringByAppendingString:@"--rating"]] = value;
		mbmovie.rating = value;
	}
	
	// dirpath
	if (nil != (value = values[@"dirpath"]) && [value isKindOfClass:NSString.class]) {
		mMovieDb[[dbkey stringByAppendingString:@"--dirpath"]] = value;
		[mMovieDb removeKey:mbmovie.dirpath.lastPathComponent];
		mMovieDb[((NSString *)value).lastPathComponent] = dbkey;
		mbmovie.dirpath = value;
	}
	
	// synopsis
	if (nil != (value = values[@"synopsis"]) && [value isKindOfClass:NSString.class]) {
		mMovieDb[[dbkey stringByAppendingString:@"--synopsis"]] = value;
		mbmovie.synopsis = value;
	}
	
	// duration
	if (nil != (value = values[@"duration"]) && [value isKindOfClass:NSNumber.class]) {
		mMovieDb[[dbkey stringByAppendingString:@"--duration"]] = value;
		mbmovie.duration = value;
	}
	
	// score
	if (nil != (value = values[@"score"]) && [value isKindOfClass:NSNumber.class]) {
		mMovieDb[[dbkey stringByAppendingString:@"--score"]] = value;
		mbmovie.score = value;
	}
	
	// imdb
	if (nil != (value = values[@"imdb"]) && [value isKindOfClass:NSString.class]) {
		mMovieDb[[dbkey stringByAppendingString:@"--imdbid"]] = value;
		mbmovie.imdbId = value;
	}
	
	// tmdb
	if (nil != (value = values[@"tmdb"]) && [value isKindOfClass:NSString.class]) {
		mMovieDb[[dbkey stringByAppendingString:@"--tmdbid"]] = value;
		mbmovie.tmdbId = value;
	}
	
	// rtid
	if (nil != (value = values[@"rtid"]) && [value isKindOfClass:NSString.class]) {
		mMovieDb[[dbkey stringByAppendingString:@"--rtid"]] = value;
		mbmovie.rtId = value;
	}
	
	// poster
	if (nil != (value = values[@"poster"]) && [value isKindOfClass:NSData.class]) {
		NSString *imageId = mbmovie.posterId;
		NSFileManager *fileManager = [[NSFileManager alloc] init];
		NSString *baseDir = [[NSUserDefaults standardUserDefaults] stringForKey:MBDefaultsKeyImageCache];
		NSString *movieBaseDir = [baseDir stringByAppendingPathComponent:@"Movies"];
		
		if (!imageId.length) {
			imageId = [NSString randomStringOfLength:32];
			mbmovie.posterId = imageId;
		}
		
		NSString *dataDir = [movieBaseDir stringByAppendingPathComponent:[imageId substringToIndex:2].lowercaseString];
		NSString *dataPath = [dataDir stringByAppendingPathComponent:imageId];
		
		[fileManager createDirectoryAtPath:dataDir withIntermediateDirectories:TRUE attributes:nil error:nil];
		
		mMovieDb[[dbkey stringByAppendingString:@"--poster"]] = imageId;
		
		[(NSData *)value writeToFile:dataPath atomically:FALSE];
		
		// purge any cached resized versions of the image
		{
			NSString *prefix = [imageId stringByAppendingString:@"--"];
			
			[[fileManager contentsOfDirectoryAtPath:dataDir error:nil] enumerateObjectsUsingBlock:^ (id fileObj, NSUInteger fileNdx, BOOL *fileStop) {
				if ([fileObj hasPrefix:prefix])
					[fileManager removeItemAtPath:[dataDir stringByAppendingPathComponent:fileObj] error:nil];
			}];
		}
	}
}

/**
 *
 *
 */
- (MBGenre *)genreWithKey:(NSString *)dbkey
{
	return mGenres[dbkey];
}

/**
 *
 *
 */
- (void)genre:(MBGenre *)mbgenre updateWithName:(NSString *)newName
{
	if (!newName.length || [mbgenre.name isEqualToString:newName])
		return;
	
	NSString *oldName = mbgenre.name;
	MBGenre *newGenre = [self genreWithKey:newName];
	
	if (!newGenre)
		mGenres[newName] = (newGenre = [[MBGenre alloc] initWithGenre:newName]);
	
	[mMovieDb enumerateKeys:^ (NSString *key, BOOL *stop) {
		NSArray *keyParts = [key componentsSeparatedByString:@"--"];
		
		if (keyParts.count < 4)
			return;
		
		NSString *title = keyParts[0];
		NSNumber *year  = @(((NSString *)keyParts[1]).integerValue);
		NSString *label = keyParts[2];
		NSString *genre = keyParts[3];
		
		if ([label isEqualToString:@"genre"] && [genre isEqualToString:oldName]) {
			NSString *dbkey = [[title stringByAppendingString:@"--"] stringByAppendingString:year.stringValue];
			NSString *genreKey = [[dbkey stringByAppendingString:@"--genre--"] stringByAppendingString:newName];
			MBMovie *mbmovie = [self movieWithKey:dbkey];
			
			if (mbmovie) {
				[mbmovie.genres removeObjectForKey:oldName];
				mbmovie.genres[newName] = newGenre;
			}
			
			[mMovieDb removeKey:key];
			mMovieDb[genreKey] = @"";
			
			NSLog(@"  Removing '%@'", key);
			NSLog(@"  Adding '%@'", genreKey);
		}
	}];
	
	mbgenre.name = newName;
}

/**
 *
 *
 */
- (void)genreDelete:(MBGenre *)mbgenre
{
	NSString *name = mbgenre.name;
	
	[mMovieDb enumerateKeys:^ (NSString *key, BOOL *stop) {
		NSArray *keyParts = [key componentsSeparatedByString:@"--"];
		
		if (keyParts.count < 4)
			return;
		
//	NSString *title = keyParts[0];
//	NSNumber *year  = @(((NSString *)keyParts[1]).integerValue);
		NSString *label = keyParts[2];
		NSString *genre = keyParts[3];
		
		if ([label isEqualToString:@"genre"] && [genre isEqualToString:name]) {
			[mMovieDb removeKey:key];
			NSLog(@"  Removing '%@'", key);
		}
	}];
}





#pragma mark - Delete

/**
 *
 *
 */
- (void)deleteMovie:(MBMovie*)movie
{
	NSString *dbkey = movie.dbkey;
	
	//
	// movie
	//
	{
		APLevelDBIterator *iter = [APLevelDBIterator iteratorWithLevelDB:mMovieDb];
		
		if ([iter seekToKey:dbkey]) {
			NSString *key = dbkey;
			do {
				NSLog(@"  MOVIE [%@]", key);
				[mMovieDb removeKey:key];
			}
			while (nil != (key = [iter nextKey]) && [key hasPrefix:dbkey]);
		}
		
		[mMovieDb removeKey:[movie.dirpath lastPathComponent]];
	}
	
	//
	// actor
	//
	{
		APLevelDBIterator *iter = [APLevelDBIterator iteratorWithLevelDB:mActorDb];
		NSString *key=nil, *suffix = [@"--movie--" stringByAppendingString:dbkey];
		
		while (nil != (key = [iter nextKey])) {
			if ([key hasSuffix:suffix]) {
				NSLog(@"  ACTOR [%@]", key);
				[mActorDb removeKey:key];
			}
		}
	}
}

/**
 *
 *
 */
- (void)saveMovie:(MBMovie *)mbmovie
{
	NSString *dbkey = mbmovie.dbkey;
	
	mMovieDb[[dbkey stringByAppendingString:@"--path"    ]] = mbmovie.dirpath;
	mMovieDb[[dbkey stringByAppendingString:@"--title"   ]] = mbmovie.title;
	mMovieDb[[dbkey stringByAppendingString:@"--year"    ]] = mbmovie.year.stringValue;
	mMovieDb[[dbkey stringByAppendingString:@"--rating"  ]] = mbmovie.rating;
	mMovieDb[[dbkey stringByAppendingString:@"--score"   ]] = mbmovie.score.stringValue;
	mMovieDb[[dbkey stringByAppendingString:@"--hidden"  ]] = mbmovie.hidden.stringValue;
	mMovieDb[[dbkey stringByAppendingString:@"--synopsis"]] = mbmovie.synopsis;
	mMovieDb[[dbkey stringByAppendingString:@"--duration"]] = mbmovie.runtime.stringValue;
	mMovieDb[[dbkey stringByAppendingString:@"--runtime" ]] = mbmovie.runtime.stringValue;
	mMovieDb[[dbkey stringByAppendingString:@"--size"    ]] = mbmovie.filesize.stringValue;
	mMovieDb[[dbkey stringByAppendingString:@"--width"   ]] = mbmovie.width.stringValue;
	mMovieDb[[dbkey stringByAppendingString:@"--height"  ]] = mbmovie.height.stringValue;
	mMovieDb[[dbkey stringByAppendingString:@"--bitrate" ]] = mbmovie.bitrate.stringValue;
	mMovieDb[[dbkey stringByAppendingString:@"--mtime"   ]] = @(mbmovie.mtime.timeIntervalSinceReferenceDate).stringValue;
	
	if (mbmovie.imdbId ) mMovieDb[[dbkey stringByAppendingString:@"--imdbid" ]] = mbmovie.imdbId;
	if (mbmovie.rtId   ) mMovieDb[[dbkey stringByAppendingString:@"--rtid"   ]] = mbmovie.rtId;
	if (mbmovie.tmdbId ) mMovieDb[[dbkey stringByAppendingString:@"--tmdbid" ]] = mbmovie.tmdbId;
}



#pragma mark - Enumerate

/**
 *
 *
 */
- (void)enumerateMovies:(void (^)(MBMovie*, NSUInteger, BOOL*))handler
{
	[[mMovies allValues] enumerateObjectsUsingBlock:^ (id obj, NSUInteger ndx, BOOL *stop) {
		handler((MBMovie *)obj, ndx, stop);
	}];
}

/**
 *
 *
 */
- (void)enumerateMoviesForPerson:(MBPerson *)mbperson handler:(void (^)(MBMovie*, BOOL*))handler
{
	[mbperson.movies.allKeys enumerateObjectsUsingBlock:^ (id obj, NSUInteger ndx, BOOL *stop) {
		handler(mMovies[obj], stop);
	}];
}

/**
 *
 *
 */
- (void)enumerateGenres:(void (^)(MBGenre*, BOOL*))handler
{
	[[mGenres allValues] enumerateObjectsUsingBlock:^ (id obj, NSUInteger ndx, BOOL *stop) {
		handler(obj, stop);
	}];
}

/**
 *
 *
 */
- (void)enumerateActors:(void (^)(MBPerson*, NSUInteger, BOOL*))handler
{
	[[mActors allValues] enumerateObjectsUsingBlock:^ (id obj, NSUInteger ndx, BOOL *stop) {
		handler((MBPerson *)obj, ndx, stop);
	}];
}

/**
 *
 *
 */
- (void)enumerateActorsForMovie:(MBMovie *)mbmovie handler:(void (^)(MBPerson*, BOOL*))handler
{
	[mbmovie.actors.allKeys enumerateObjectsUsingBlock:^ (id obj, NSUInteger ndx, BOOL *stop) {
		handler(mActors[obj], stop);
	}];
}





#pragma mark - Import

/**
 *
 *
 */
- (void)moveGenresToMovies
{
	[mMovies.allValues enumerateObjectsUsingBlock:^ (id movieObj, NSUInteger movieNdx, BOOL *movieStop) {
		MBMovie *mbmovie = movieObj;
		NSString *dbkey = mbmovie.dbkey;
		NSString *genreKey = [dbkey stringByAppendingString:@"--genre--"];
		
		[mbmovie.genres.allKeys enumerateObjectsUsingBlock:^ (id genreObj, NSUInteger genreNdx, BOOL *genreStop) {
			NSLog(@" [%@] adding genre for key '%@'", mbmovie.title, [genreKey stringByAppendingString:genreObj]);
			mMovieDb[[genreKey stringByAppendingString:genreObj]] = @"";
		}];
	}];
}

/**
 *
 *
 */
- (NSArray *)findMissingMovies
{
	NSArray *sources = [[NSUserDefaults standardUserDefaults] arrayForKey:MBDefaultsKeySources];
	NSFileManager *fileManager = [[NSFileManager alloc] init];
	NSMutableArray *movies = [[NSMutableArray alloc] init];
	
	NSLog(@"[DM] Found %lu sources", sources.count);
	
	[sources enumerateObjectsUsingBlock:^ (id obj, NSUInteger ndx, BOOL *stop) {
		NSString *source = ((NSDictionary *)obj)[MBDefaultsKeySourcesPath];
		NSLog(@"[DM]   [%02lu] Looking at source, '%@'", ndx, source);
		
		if (FALSE == [fileManager fileExistsAtPath:source]) {
			NSLog(@"[DM]   Skipping because the directory does not exist!");
			return;
		}
		
		NSArray *files = [fileManager contentsOfDirectoryAtPath:source error:nil];
		
		[files enumerateObjectsUsingBlock:^ (id obj2, NSUInteger ndx2, BOOL *stop2) {
			if (mMovieDb[obj2] && mMovies[mMovieDb[obj2]])
				return;
			
			NSLog(@"[DM]     %@", obj2);
			[movies addObject:[source stringByAppendingPathComponent:obj2]];
		}];
	}];
	
	return movies;
}

/**
 *
 *
 */
- (void)findDuplicateMovies
{
	NSMutableDictionary *movies = [[NSMutableDictionary alloc] init];
	
	[mMovies.allValues enumerateObjectsUsingBlock:^ (id movieObj, NSUInteger movieNdx, BOOL *movieStop) {
		MBMovie *mbmovie1 = movieObj;
		MBMovie *mbmovie2 = movies[mbmovie1.dirpath];
		
		if (mbmovie2)
			NSLog(@"  [%@] dir path already in use! [%@, %@]", mbmovie1.dirpath, mbmovie1.title, mbmovie2.title);
		else
			movies[mbmovie1.dirpath] = mbmovie1;
	}];
}

/**
 *
 *
 */
- (NSArray *)findMissingFiles
{
	NSFileManager *fileManager = [[NSFileManager alloc] init];
	NSMutableArray *movies = [[NSMutableArray alloc] init];
	
	[mMovies.allValues enumerateObjectsUsingBlock:^ (id movie, NSUInteger movieNdx, BOOL *movieStop) {
		if (FALSE == [fileManager fileExistsAtPath:((MBMovie *)movie).dirpath])
			[movies addObject:movie];
	}];
	
	return movies;
}

/**
 *
 *
 */
- (void)getMissingImages
{
	NSString *moviesDir = [[[NSUserDefaults standardUserDefaults] stringForKey:MBDefaultsKeyImageCache] stringByAppendingPathComponent:@"Movies"];
	NSString *actorsDir = [[[NSUserDefaults standardUserDefaults] stringForKey:MBDefaultsKeyImageCache] stringByAppendingPathComponent:@"Actors"];
	NSFileManager *fileManager = [[NSFileManager alloc] init];
	
	[self enumerateMovies:^ (MBMovie *mbmovie, NSUInteger count, BOOL *stop) {
		NSString *imdbId = mbmovie.imdbId;
		NSString *imageId = mbmovie.posterId;
		
		if (!imdbId.length)
			return;
		
		if (!imageId.length)
			return;
		
		NSString *imageDir = [moviesDir stringByAppendingPathComponent:[imageId substringToIndex:2].lowercaseString];
		NSString *imagePath = [imageDir stringByAppendingPathComponent:imageId];
		
		if ([fileManager fileExistsAtPath:imagePath])
			return;
		
		NSArray *movies = [IDSearch imdbSearchMovieWithTitle:imdbId andYear:nil andRuntime:nil];
		
		if (!movies.count)
			return;
		
		IDMovie *idmovie = movies[0];
		NSURL *imageUrl = idmovie.imageUrl;
//	NSURL *anonUrl = [NSURL URLWithString:[@"http://anonymouse.org/cgi-bin/anon-www.cgi/" stringByAppendingString:imageUrl.absoluteString]];
//	NSData *imageData = [NSData dataWithContentsOfURL:anonUrl];
		NSData *imageData = [NSData dataWithContentsOfURL:imageUrl];
		NSImage *image = [[NSImage alloc] initWithData:imageData];
		
		if (!image)
			return;
		
		[fileManager createDirectoryAtPath:imageDir withIntermediateDirectories:TRUE attributes:nil error:nil];
		[imageData writeToFile:imagePath atomically:FALSE];
		
		NSLog(@"%@", mbmovie.dbkey);
	}];
	
	NSLog(@"Done with movies");
	
	[self enumerateActors:^ (MBPerson *mbactor, NSUInteger actorNdx, BOOL *stop) {
		NSURL *imageUrl = mbactor.imageUrl;
		NSString *imageId = mbactor.imageId;
		
		if (!imageId.length)
			return;
		
		if (!imageUrl)
			return;
		
		NSString *imageDir = [actorsDir stringByAppendingPathComponent:[imageId substringToIndex:2].lowercaseString];
		NSString *imagePath = [imageDir stringByAppendingPathComponent:imageId];
		
		if ([fileManager fileExistsAtPath:imagePath])
			return;
		
//	NSURL *anonUrl = [NSURL URLWithString:[@"http://anonymouse.org/cgi-bin/anon-www.cgi/" stringByAppendingString:imageUrl.absoluteString]];
//	NSData *imageData = [NSData dataWithContentsOfURL:anonUrl];
		NSData *imageData = [NSData dataWithContentsOfURL:imageUrl];
		NSImage *image = [[NSImage alloc] initWithData:imageData];
		
		if (!image)
			return;
		
		[fileManager createDirectoryAtPath:imageDir withIntermediateDirectories:TRUE attributes:nil error:nil];
		[imageData writeToFile:imagePath atomically:FALSE];
		
		NSLog(@"%@", mbactor.name);
	}];
	
	NSLog(@"Done with actors");
}

/**
 *
 *
 */
- (void)upgradeTmdbToImdb
{
	__block BOOL _stop = FALSE;
	__block NSUInteger current=0, total=0;
	
	[self enumerateMovies:^ (MBMovie *mbmovie, NSUInteger count, BOOL *stop) {
		NSString *tmdbId = mbmovie.tmdbId;
		NSString *imdbId = mbmovie.imdbId;
		
		if (mbmovie.updated)
			return;
		
		if (tmdbId.length && imdbId.length)
			total += 1;
	}];
	
	[self enumerateMovies:^ (MBMovie *mbmovie, NSUInteger count, BOOL *stop) {
		if (_stop) {
			*stop = TRUE;
			return;
		}
		
		NSString *tmdbId = mbmovie.tmdbId;
		NSString *imdbId = mbmovie.imdbId;
		
		if (mbmovie.updated)
			return;
		
		if (tmdbId.length && imdbId.length) {
			NSLog(@"[%04lu of %04lu] %@ [%@, %@]", ++current, total, mbmovie.dbkey, tmdbId, imdbId);
			
			NSArray *movies = [IDSearch imdbSearchMovieWithTitle:imdbId andYear:nil andRuntime:nil];
			
			if (!movies.count)
				return;
			
			IDMovie *idmovie = movies[0];
			
			if (!idmovie.title || !idmovie.year.integerValue)
				return;
			
			idmovie.title = mbmovie.title;
			idmovie.year = mbmovie.year;
			
			[self addMovie:idmovie
				 withDirPath:mbmovie.dirpath
						duration:mbmovie.duration
						filesize:mbmovie.filesize
							 width:mbmovie.width
							height:mbmovie.height
						 bitrate:mbmovie.bitrate
							 mtime:mbmovie.mtime
					 languages:mbmovie.languages];
		}
	}];
}

/**
 *
 *
 */
- (void)ratingsNormalize
{
	NSMutableDictionary *ratings = [[NSMutableDictionary alloc] init];
	
	[self enumerateMovies:^ (MBMovie *mbmovie, NSUInteger count, BOOL *stop) {
		NSString *rating = mbmovie.rating;
		
		if (rating.length)
			ratings[rating] = @(1 + ((NSNumber *)ratings[rating]).integerValue);
	}];
	
	NSLog(@"%@", ratings);
	
	[self enumerateMovies:^ (MBMovie *mbmovie, NSUInteger count, BOOL *stop) {
		NSString *rating = [IDRating normalizedRating:mbmovie.rating];
		
		if (rating.length && ![mbmovie.rating isEqualToString:rating]) {
			NSLog(@" [%@] change %@ to %@", mbmovie.dbkey, mbmovie.rating, rating);
			NSString *ratingKey = [mbmovie.dbkey stringByAppendingString:@"--rating"];
			mMovieDb[ratingKey] = rating;
		}
	}];
}

/**
 *
 *
 */
- (void)updateFileStats
{
	NSFileManager *fileManager = [[NSFileManager alloc] init];
	
	NSArray *movies = [mMovies.allKeys sortedArrayUsingComparator:^ NSComparisonResult (id obj1, id obj2) {
		return [(NSString *)obj1 caseInsensitiveCompare:(NSString *)obj2];
	}];
	
	NSLog(@"[DM] Found %04lu movies", movies.count);
	
	[movies enumerateObjectsUsingBlock:^ (id obj, NSUInteger ndx, BOOL *stop) {
		NSMutableDictionary *languages = [[NSMutableDictionary alloc] init];
		
		MBMovie *mbmovie = mMovies[obj];
		NSArray *movieFiles = [self getMovieFilesInDir:mbmovie.dirpath];
		NSMutableArray *idinfos = [[NSMutableArray alloc] init];
		NSString *dbkey = mbmovie.dbkey;
		
		__block NSNumber *runtime = nil;
		__block NSNumber *filesize = nil;
		__block NSNumber *bitrate = nil;
		__block NSNumber *width = nil;
		__block NSNumber *height = nil;
		__block NSDate *latest = [NSDate distantPast];
		
		if (!movieFiles.count)
			return;
		
		NSDictionary *attrs = [fileManager attributesOfItemAtPath:movieFiles[0] error:nil];
		
		if (NSOrderedSame == [mbmovie.mtime compare:attrs[NSFileModificationDate]])
			return;
		
		NSLog(@"[DM] [%04lu] %@", (ndx+1), obj);
		NSLog(@"[DM]   Updating because %@ vs %@", mbmovie.mtime, attrs[NSFileModificationDate]);
		
		// media info
		{
			[movieFiles enumerateObjectsUsingBlock:^ (id obj1, NSUInteger ndx1, BOOL *stop1) {
				IDMediaInfo *idinfo = [[IDMediaInfo alloc] initWithFilePath:obj1];
				
				[idinfo.languages enumerateObjectsUsingBlock:^ (id languageObj, NSUInteger languageNdx, BOOL *languageStop) {
					languages[languageObj] = languageObj;
				}];
				
				if (idinfo)
					[idinfos addObject:idinfo];
				else
					NSLog(@"[DM]   [%lu] failed to get media info!", ndx1);
			}];
			
			if (!idinfos.count) {
				NSLog(@"[DM]   Could not get media info for any of the files");
				return;
			}
		}
		
		// runtime - scan through all of the parts of the movie contained within the target directory and
		//           sum the runtimes, file sizes; pick the largest dimensions and best bitrate.
		{
			__block NSUInteger _runtime = 0;
			__block long long _filesize = 0;
			__block NSUInteger _bitrate = 0;
			__block NSUInteger _width = 0;
			__block NSUInteger _height = 0;
			
			[idinfos enumerateObjectsUsingBlock:^ (id obj1, NSUInteger ndx1, BOOL *stop1) {
				IDMediaInfo *idinfo = (IDMediaInfo *)obj1;
				
				_runtime += idinfo.duration.integerValue;
				_filesize += idinfo.filesize.integerValue;
				
				if (idinfo.bitrate.integerValue > _bitrate)
					_bitrate = idinfo.bitrate.integerValue;
				
				if (idinfo.width.integerValue * idinfo.height.integerValue > _width * _height) {
					_width = idinfo.width.integerValue;
					_height = idinfo.height.integerValue;
				}
				
				if (NSOrderedAscending == [latest compare:idinfo.mtime])
					latest = idinfo.mtime;
			}];
			
			runtime = @(_runtime);
			filesize = @(_filesize);
			bitrate = @(_bitrate);
			width = @(_width);
			height = @(_height);
		}
		
		NSLog(@"[DM]   [new] runtime=%@, filesize=%@, bitrate=%@, width=%@, height=%@, languages=%@", runtime, filesize, bitrate, width, height, [languages.allValues componentsJoinedByString:@", "]);
		NSLog(@"[DM]   [old] runtime=%@, filesize=%@, bitrate=%@, width=%@, height=%@", mbmovie.duration, mbmovie.filesize, mbmovie.bitrate, mbmovie.width, mbmovie.height);
		
		if (!runtime.integerValue || !filesize.integerValue) {
			NSLog(@"[DM]         skipping because there's no runtime or filesize");
			return;
		}
		
		[languages.allValues enumerateObjectsUsingBlock:^ (id languageObj, NSUInteger languageNdx, BOOL *languageStop) {
			mMovieDb[[[dbkey stringByAppendingString:@"--language--"] stringByAppendingString:languageObj]] = @"";
		}];
		
		mMovieDb[[dbkey stringByAppendingString:@"--duration"]] = runtime.stringValue;
		mMovieDb[[dbkey stringByAppendingString:@"--size"    ]] = filesize.stringValue;
		mMovieDb[[dbkey stringByAppendingString:@"--width"   ]] = width.stringValue;
		mMovieDb[[dbkey stringByAppendingString:@"--height"  ]] = height.stringValue;
		mMovieDb[[dbkey stringByAppendingString:@"--bitrate" ]] = bitrate.stringValue;
		mMovieDb[[dbkey stringByAppendingString:@"--mtime"   ]] = @(latest.timeIntervalSinceReferenceDate).stringValue;
		
		mbmovie.duration = runtime;
		mbmovie.filesize = filesize;
		mbmovie.width = width;
		mbmovie.height = height;
		mbmovie.bitrate = bitrate;
		mbmovie.mtime = latest;
		mbmovie.languages = languages.allValues;
	}];
}

/**
 *
 *
 */
- (void)addSource:(NSString *)sourcePath
{
	[mSources setObject:sourcePath forKey:sourcePath];
	[self scanSource:sourcePath];
}

/**
 *
 *
 */
- (void)scanSource:(NSString *)sourcePath
{
	NSFileManager *fileManager = [[NSFileManager alloc] init];
	NSArray *movies = [fileManager contentsOfDirectoryAtPath:sourcePath error:nil];
	__block NSUInteger count = 0;
	
	NSLog(@"[DM] Starting scan [%@]", sourcePath);
	
	// sort alphabetically
	movies = [movies sortedArrayUsingComparator:^ NSComparisonResult (id obj1, id obj2) {
		return [(NSString *)obj1 compare:(NSString *)obj2];
	}];
	
	[movies enumerateObjectsUsingBlock:^ (id obj1, NSUInteger ndx1, BOOL *stop1) {
		// skip movies we already know about
		if (mMovieDb[obj1])
			return;
		
		NSLog(@"[DM] Processing %lu of %lu [%@]", (ndx1+1), movies.count, [sourcePath stringByAppendingPathComponent:obj1]);
		
		[self handleMovieWithName:obj1 path:[sourcePath stringByAppendingPathComponent:obj1]];
		
		if (++count >= 1000)
			*stop1 = TRUE;
	}];
	
	NSLog(@"[DM] Scan complete [%@]", sourcePath);
}

/**
 *
 *
 */
- (NSArray *)getMovieFilesInDir:(NSString *)dirPath
{
	NSFileManager *fileManager = [[NSFileManager alloc] init];
	NSArray *files = [fileManager contentsOfDirectoryAtPath:dirPath error:nil];
	NSMutableArray *movieFiles = [[NSMutableArray alloc] init];
	
	[files enumerateObjectsUsingBlock:^ (id obj2, NSUInteger ndx2, BOOL *stop2) {
		NSString *file = [(NSString *)obj2 lowercaseString];
		
		if ([file hasSuffix:@".mp4"] ||
				[file hasSuffix:@".m4v"] ||
				[file hasSuffix:@".mpg"] ||
				[file hasSuffix:@".mov"] ||
				[file hasSuffix:@".wmv"] ||
				[file hasSuffix:@".avi"] ||
				[file hasSuffix:@".mkv"])
			[movieFiles addObject:[dirPath stringByAppendingPathComponent:obj2]];
	}];
	
	return movieFiles;
}

/**
 *
 *
 */
- (void)handleMovieWithName:(NSString *)dirName path:(NSString *)dirPath
{
	NSFileManager *fileManager = [[NSFileManager alloc] init];
	NSMutableArray *idinfos = [[NSMutableArray alloc] init];
	NSArray *movieFiles = [self getMovieFilesInDir:dirPath];
	NSArray *titles = [IDSearch titlesForName:dirName];
	NSNumber *year = [IDSearch yearForName:dirName];
	NSString *movieBaseDir=nil, *actorBaseDir=nil;
	NSString *baseDir = [[NSUserDefaults standardUserDefaults] stringForKey:MBDefaultsKeyImageCache];
	NSMutableDictionary *languages = [[NSMutableDictionary alloc] init];
	
	NSLog(@"[DM]   Title is %@", titles[0]);
	NSLog(@"[DM]   Year is %@", year);
	
	if (year.integerValue < 1000) {
		NSLog(@"[DM]   Skipping because of the year");
		return;
	}
	
	[movieFiles enumerateObjectsUsingBlock:^ (id obj, NSUInteger ndx, BOOL *stop) {
		NSLog(@"[DM]   %@", obj);
	}];
	
	__block NSNumber *runtime = nil;
	__block NSNumber *filesize = nil;
	__block NSNumber *bitrate = nil;
	__block NSNumber *width = nil;
	__block NSNumber *height = nil;
	__block IDMovie *idmovie = nil;
	__block NSDate *latest = [NSDate distantPast];
	
	// directory prefixes for storing actor/movie images
	if (baseDir) {
		actorBaseDir = [baseDir stringByAppendingPathComponent:@"Actors"];
		movieBaseDir = [baseDir stringByAppendingPathComponent:@"Movies"];
		
		if (![fileManager fileExistsAtPath:actorBaseDir])
			[fileManager createDirectoryAtPath:actorBaseDir withIntermediateDirectories:TRUE attributes:nil error:nil];
		
		if (![fileManager fileExistsAtPath:movieBaseDir])
			[fileManager createDirectoryAtPath:movieBaseDir withIntermediateDirectories:TRUE attributes:nil error:nil];
	}
	
	// stop short if we couldn't find any movie files in the target directory
	if (!movieFiles.count) {
		NSLog(@"[DM]   Didn't find any movie files!");
		return;
	}
	
	NSLog(@"[DM]   Found %lu movie file(s)", movieFiles.count);
	
	// media info
	{
		[movieFiles enumerateObjectsUsingBlock:^ (id obj1, NSUInteger ndx1, BOOL *stop1) {
			IDMediaInfo *idinfo = [[IDMediaInfo alloc] initWithFilePath:obj1];
			
			[idinfo.languages enumerateObjectsUsingBlock:^ (id languageObj, NSUInteger languageNdx, BOOL *languageStop) {
				languages[languageObj] = languageObj;
			}];
			
			if (idinfo) {
				NSLog(@"[DM]   [%lu] %@ x %@, %@ seconds", ndx1, idinfo.width, idinfo.height, idinfo.duration);
				[idinfos addObject:idinfo];
			}
			else
				NSLog(@"[DM]   [%lu] failed to get media info!", ndx1);
		}];
		
		if (!idinfos.count) {
			NSLog(@"[DM]   Could not get media info for any of the files");
			return;
		}
	}
	
	// runtime - scan through all of the parts of the movie contained within the target directory and
	//           sum the runtimes, file sizes; pick the largest dimensions and best bitrate.
	{
		__block NSUInteger _runtime = 0;
		__block long long _filesize = 0;
		__block NSUInteger _bitrate = 0;
		__block NSUInteger _width = 0;
		__block NSUInteger _height = 0;
		
		[idinfos enumerateObjectsUsingBlock:^ (id obj1, NSUInteger ndx1, BOOL *stop1) {
			IDMediaInfo *idinfo = (IDMediaInfo *)obj1;
			
			_runtime += idinfo.duration.integerValue;
			_filesize += idinfo.filesize.integerValue;
			
			if (idinfo.bitrate.integerValue > _bitrate)
				_bitrate = idinfo.bitrate.integerValue;
			
			if (idinfo.width.integerValue * idinfo.height.integerValue > _width * _height) {
				_width = idinfo.width.integerValue;
				_height = idinfo.height.integerValue;
			}
			
			if (NSOrderedAscending == [latest compare:idinfo.mtime])
				latest = idinfo.mtime;
		}];
		
		runtime = @(_runtime);
		filesize = @(_filesize);
		bitrate = @(_bitrate);
		width = @(_width);
		height = @(_height);
	}
	
	NSLog(@"[DM]   Runtime is %@", runtime);
	
	// search
	{
		[titles enumerateObjectsUsingBlock:^ (id obj1, NSUInteger ndx1, BOOL *stop1) {
			NSLog(@"[DM]     Searching for %@ / %@ / %@", obj1, year, runtime);
			NSMutableArray *results = [[NSMutableArray alloc] init];
			
			// TMDb
			/*
			{
				NSArray *tmdbResults = [IDSearch tmdbSearchMovieWithTitle:obj1 andYear:year andRuntime:runtime];
				if (tmdbResults)
					[results addObjectsFromArray:tmdbResults];
				NSLog(@"[DM]       Got %lu result(s) from TMDb", tmdbResults.count);
			}
			*/
			
			// IMDb
			{
				NSArray *imdbResults = [IDSearch imdbSearchMovieWithTitle:obj1 andYear:year andRuntime:runtime];
				if (imdbResults)
					[results addObjectsFromArray:imdbResults];
				NSLog(@"[DM]       Got %lu result(s) from IMDb", imdbResults.count);
			}
			
			[results enumerateObjectsUsingBlock:^ (id obj2, NSUInteger ndx2, BOOL *stop2) {
				IDMovie *_idmovie = (IDMovie *)obj2;
				
				NSLog(@"[DM]       [%lu] %@ / %@ / %@", ndx2, _idmovie.title, _idmovie.year, _idmovie.runtime);
				
				// compare the year of the metadata to the year in the file name
				if (![_idmovie.year isEqual:year]) {
					NSLog(@"[DM]       Skipping because of the year");
					return;
				}
				
				// compare the runtime of the metadata to the runtime of the movie file; they shouldn't be
				// allowed to differ by too much
				if (10 < labs(_idmovie.runtime.integerValue - (runtime.integerValue/60)) /*&& FALSE == [self title:_idmovie.title matchesTitles:titles]*/ ) {
					NSLog(@"[DM]       Skipping because of the runtime");
					return;
				}
				
				// don't duplicate entries, even if there are duplicate movies on disk
				if (mMovieDb[[[_idmovie.title stringByAppendingString:@"--"] stringByAppendingString:_idmovie.year.stringValue]]) {
					NSLog(@"[DM]       Skipping because this exact title/year is already in use");
					return;
				}
				
				idmovie = _idmovie;
				*stop2 = TRUE;
				
				NSLog(@"[DM]       Matched!");
			}];
			
			if (idmovie)
				*stop1 = TRUE;
		}];
		
		if (!idmovie) {
			NSLog(@"[DM]   Could not find a match!");
			return;
		}
	}
	
	[self addMovie:idmovie withDirPath:dirPath duration:runtime filesize:filesize width:width height:height bitrate:bitrate mtime:latest languages:languages.allValues];
}

/**
 *
 *
 */
- (void)addMovie:(IDMovie *)idmovie withDirPath:(NSString *)dirPath duration:(NSNumber *)duration filesize:(NSNumber *)filesize width:(NSNumber *)width height:(NSNumber *)height bitrate:(NSNumber *)bitrate mtime:(NSDate *)mtime languages:(NSArray *)languages
{
	if (!idmovie)
		return;
	
	NSMutableString *dbkey = [[NSMutableString alloc] init];
	[dbkey appendString:idmovie.title];
	[dbkey appendString:@"--"];
	[dbkey appendString:idmovie.year.stringValue];
	
	NSFileManager *fileManager = [[NSFileManager alloc] init];
	NSString *dirName = [dirPath lastPathComponent];
	NSString *movieBaseDir=nil, *actorBaseDir=nil;
	NSString *baseDir = [[NSUserDefaults standardUserDefaults] stringForKey:MBDefaultsKeyImageCache];
	
	// directory prefixes for storing actor/movie images
	if (baseDir) {
		actorBaseDir = [baseDir stringByAppendingPathComponent:@"Actors"];
		movieBaseDir = [baseDir stringByAppendingPathComponent:@"Movies"];
		
		if (![fileManager fileExistsAtPath:actorBaseDir])
			[fileManager createDirectoryAtPath:actorBaseDir withIntermediateDirectories:TRUE attributes:nil error:nil];
		
		if (![fileManager fileExistsAtPath:movieBaseDir])
			[fileManager createDirectoryAtPath:movieBaseDir withIntermediateDirectories:TRUE attributes:nil error:nil];
	}
	
	//
	// movie
	//
	{
		mMovieDb[dirName] = dbkey;
		mMovieDb[dbkey] = @"";
		mMovieDb[[dbkey stringByAppendingString:@"--updated" ]] = @((NSUInteger)[[NSDate date] timeIntervalSinceReferenceDate]).stringValue;
		mMovieDb[[dbkey stringByAppendingString:@"--path"    ]] = dirPath;
		mMovieDb[[dbkey stringByAppendingString:@"--title"   ]] = idmovie.title;
		mMovieDb[[dbkey stringByAppendingString:@"--year"    ]] = idmovie.year.stringValue;
		mMovieDb[[dbkey stringByAppendingString:@"--rating"  ]] = [IDRating normalizedRating:idmovie.rating];
		mMovieDb[[dbkey stringByAppendingString:@"--score"   ]] = idmovie.score.stringValue;
		mMovieDb[[dbkey stringByAppendingString:@"--synopsis"]] = idmovie.synopsis;
		mMovieDb[[dbkey stringByAppendingString:@"--duration"]] = duration.stringValue;
		mMovieDb[[dbkey stringByAppendingString:@"--runtime" ]] = idmovie.runtime.stringValue;
		mMovieDb[[dbkey stringByAppendingString:@"--size"    ]] = filesize.stringValue;
		mMovieDb[[dbkey stringByAppendingString:@"--width"   ]] = width.stringValue;
		mMovieDb[[dbkey stringByAppendingString:@"--height"  ]] = height.stringValue;
		mMovieDb[[dbkey stringByAppendingString:@"--bitrate" ]] = bitrate.stringValue;
		mMovieDb[[dbkey stringByAppendingString:@"--mtime"   ]] = @(mtime.timeIntervalSinceReferenceDate).stringValue;
		mMovieDb[[dbkey stringByAppendingString:@"--imdbid"  ]] = idmovie.imdbId;
		mMovieDb[[dbkey stringByAppendingString:@"--rtid"    ]] = idmovie.rtId;
		mMovieDb[[dbkey stringByAppendingString:@"--tmdbid"  ]] = idmovie.tmdbId;
		
		[languages enumerateObjectsUsingBlock:^ (id languageObj, NSUInteger languageNdx, BOOL *languageStop) {
			mMovieDb[[[dbkey stringByAppendingString:@"--language--"] stringByAppendingString:languageObj]] = @"";
		}];
		
		NSString *imageId = mMovieDb[[dbkey stringByAppendingString:@"--poster"]];
		NSURL *imageUrl = idmovie.imageUrl;
		
		// get the image (if we don't already have it)
		if (!imageId.length && imageUrl) {
			NSLog(@"[DM]         Found image at %@", idmovie.imageUrl);
			
//		imageUrl = [NSURL URLWithString:[@"http://anonymouse.org/cgi-bin/anon-www.cgi/" stringByAppendingString:imageUrl.description]];
			NSData *imageData = [NSData dataWithContentsOfURL:imageUrl];
			
			NSLog(@"[DM]           Got %lu bytes", imageData.length);
			
			if (imageData) {
				imageId = [NSString randomStringOfLength:32];
				NSLog(@"[DM]           Assigning new image id [%@]", imageId);
				
				NSString *dataDir = [movieBaseDir stringByAppendingPathComponent:[imageId substringToIndex:2].lowercaseString];
				NSString *dataPath = [dataDir stringByAppendingPathComponent:imageId];
				
				[fileManager createDirectoryAtPath:dataDir withIntermediateDirectories:TRUE attributes:nil error:nil];
				
				mMovieDb[[dbkey stringByAppendingString:@"--poster"]] = imageId;
				
				[imageData writeToFile:dataPath atomically:FALSE];
				
				NSLog(@"[DM]           %@", dataPath);
			}
		}
	}
	
	//
	// genres
	//
	{
		NSString *genreKey = [dbkey stringByAppendingString:@"--genre--"];
		NSArray *genres = idmovie.genres;
		
		NSLog(@"[DM]       Got %lu genre(s)", genres.count);
		
		[genres enumerateObjectsUsingBlock:^ (id obj1, NSUInteger ndx1, BOOL *stop1) {
			NSLog(@"[DM]       [%lu] %@", ndx1, obj1);
			mMovieDb[[genreKey stringByAppendingString:obj1]] = @"";
		}];
	}
	
	//
	// actors
	//
	{
		NSArray *casts = idmovie.cast;
		
		NSLog(@"[DM]       Got %lu people(s)", casts.count);
		
		[casts enumerateObjectsUsingBlock:^ (id obj1, NSUInteger ndx1, BOOL *stop1) {
			IDPerson *idperson = (IDPerson *)obj1;
			NSString *name = idperson.name;
			NSObject *value = nil;
			
			NSLog(@"[DM]       [%lu] %@", ndx1, name);
			
			if (nil != (value = idperson.tmdbId )) mActorDb[[name stringByAppendingString:@"--tmdbid" ]] = value;
			if (nil != (value = idperson.imdbId )) mActorDb[[name stringByAppendingString:@"--imdbid" ]] = value;
			if (nil != (value = idperson.rtId   )) mActorDb[[name stringByAppendingString:@"--rtid"   ]] = value;
			
			if (!mActorDb[name]) {
				mActorDb[name] = @"";
				
				if (nil != (value = idperson.bio)) mActorDb[[name stringByAppendingString:@"--bio"]] = value;
				if (nil != (value = idperson.dob)) mActorDb[[name stringByAppendingString:@"--dob"]] = value;
				if (nil != (value = idperson.dod)) mActorDb[[name stringByAppendingString:@"--dod"]] = value;
				if (nil != (value = idperson.web)) mActorDb[[name stringByAppendingString:@"--web"]] = ((NSURL *)value).absoluteString;
			}
			else
				NSLog(@"[DM]         Skipping");
			
			// for each CAST member for this MOVIE, store the person's position within the credits list
			{
				NSMutableString *key = [[NSMutableString alloc] init];
				[key appendString:name];
				[key appendString:@"--movie--"];
				[key appendString:dbkey];
				mActorDb[key] = @(ndx1).stringValue;
			}
			
			// for each CAST member for this MOVIE, map the person to the movie
			{
				NSMutableString *key = [[NSMutableString alloc] init];
				[key appendString:dbkey];
				[key appendString:@"--actor--"];
				[key appendString:name];
				mMovieDb[key] = name;
			}
			
			NSString *imageId = mActorDb[[name stringByAppendingString:@"--image--id"]];
			NSString *imageUrl = mActorDb[[name stringByAppendingString:@"--image--url"]];
			
			// get the image (if we don't already have one)
			if ((!imageId.length || !imageUrl.length) && nil != (value = idperson.imageUrl)) {
				NSLog(@"[DM]         Found image at %@", value);
				
//			NSURL *imageUrl = [NSURL URLWithString:[@"http://anonymouse.org/cgi-bin/anon-www.cgi/" stringByAppendingString:((NSURL *)value).absoluteString]];
				NSURL *imageUrl = (NSURL *)value;
				NSData *imageData = [NSData dataWithContentsOfURL:imageUrl];
				
				NSLog(@"[DM]           %@", imageUrl);
				NSLog(@"[DM]           Got %lu bytes", imageData.length);
				
				if (imageData) {
					NSImage *image = [[NSImage alloc] initWithData:imageData];
					
					if (image) {
						if (!imageId) {
							imageId = [NSString randomStringOfLength:32];
							NSLog(@"[DM]           Assigning new image id [%@]", imageId);
						}
						else
							NSLog(@"[DM]           Using existing image id [%@]", imageId);
						
						NSString *dataDir = [actorBaseDir stringByAppendingPathComponent:[imageId substringToIndex:2].lowercaseString];
						NSString *dataPath = [dataDir stringByAppendingPathComponent:imageId];
						
						[fileManager createDirectoryAtPath:dataDir withIntermediateDirectories:TRUE attributes:nil error:nil];
						
						mActorDb[[name stringByAppendingString:@"--image--id"]] = imageId;
						mActorDb[[name stringByAppendingString:@"--image--url"]] = ((NSURL *)value).absoluteString;
						
						[imageData writeToFile:dataPath atomically:FALSE];
						
						NSLog(@"[DM]           %@", dataPath);
					}
					else
						NSLog(@"[DM]           Invalid image data");
				}
			}
		}];
	}
	
	NSLog(@"[DM] Done");
}

/**
 *
 *
 */
- (BOOL)title:(NSString *)title matchesTitles:(NSArray *)titles
{
	__block BOOL matched = FALSE;
	
	title = [title lowercaseString];
	
	[titles enumerateObjectsUsingBlock:^ (id obj, NSUInteger ndx, BOOL *stop) {
		if (NSOrderedSame == [title compare:obj options:NSDiacriticInsensitiveSearch]) {
			matched = TRUE;
			*stop = TRUE;
		}
	}];
	
	return matched;
}

@end
