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
#import <MovieID/APLevelDB.h>
#import <MovieID/IDMediaInfo.h>
#import <MovieID/IDSearch.h>
#import <MovieID/IDMovie.h>
#import <MovieID/IDPerson.h>
#import <MovieID/IDTmdbMovie.h>

@interface MBDataManager ()
{
	NSMutableDictionary *mSources;
	
	APLevelDB *mMovieDb;
	APLevelDB *mGenreDb;
	APLevelDB *mActorDb;
	
	NSMutableDictionary *mActors;
	NSMutableDictionary *mGenres;
	NSMutableDictionary *mMovies;
}
@end

@implementation MBDataManager

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
		
		mActors = [[NSMutableDictionary alloc] init];
		mGenres = [[NSMutableDictionary alloc] init];
		mMovies = [[NSMutableDictionary alloc] init];
		
		[self openDb];
		
		[self loadActors];
		[self loadGenres];
		[self loadMovies];
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
	
	if ((path = [[NSBundle mainBundle] pathForResource:@"MovieBrowse-Genres" ofType:@"db"]))
		mGenreDb = [APLevelDB levelDBWithPath:path error:nil];
	else
		mGenreDb = [APLevelDB levelDBWithPath:[desktop stringByAppendingPathComponent:@"MovieBrowse-Genres.db"] error:nil];
	
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
	NSLog(@"%s.. compacting...", __PRETTY_FUNCTION__);
	[mMovieDb compact];
	[mGenreDb compact];
	[mActorDb compact];
	NSLog(@"%s.. compacting...done", __PRETTY_FUNCTION__);
#endif
}





#pragma mark - Load

/**
 *
 *
 */
- (void)loadActors
{
	__block MBPerson *mbperson = nil;
	__block NSMutableDictionary *movies = nil;
	
	[mActorDb enumerateKeys:^ (NSString *key, BOOL *stop) {
		NSArray *keyParts = [key componentsSeparatedByString:@"--"];
		
		if (keyParts.count < 2)
			return;
		
		NSString *actor = keyParts[0];
		NSString *label = keyParts[1];
		NSString *value = mActorDb[key];
		
		if (mbperson && ![actor isEqualToString:mbperson.name]) {
			mActors[mbperson.name] = mbperson;
			mbperson = nil;
			movies = nil;
		}
		
		if (mbperson == nil) {
			mbperson = [[MBPerson alloc] init];
			mbperson.movies = (movies = [[NSMutableDictionary alloc] init]);
			mbperson.name = actor;
		}
		
		if ([label isEqualToString:@"image"] && keyParts.count == 3 && [keyParts[2] isEqual:@"id"])
			mbperson.imageId = value;
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
	}];
	
	if (mbperson)
		mActors[mbperson.name] = mbperson;
}

/**
 *
 *
 */
- (void)loadGenres
{
	__block MBGenre *mbgenre = nil;
	__block NSMutableDictionary *actors = nil;
	__block NSMutableDictionary *movies = nil;
	__block NSMutableDictionary *years = nil;
	
	[mGenreDb enumerateKeys:^ (NSString *key, BOOL *stop) {
		NSArray *keyParts = [key componentsSeparatedByString:@"--"];
		
		if (keyParts.count < 3)
			return;
		
		NSString *genre = keyParts[0];
		NSString *label = keyParts[1];
		NSString *title = keyParts[2];
		
#ifndef DEBUG
		if ([genre isEqualToString:@"Adult"])
			return;
#endif
		
		if (mbgenre && ![genre isEqualToString:mbgenre.name]) {
			mGenres[mbgenre.name] = mbgenre;
			mbgenre = nil;
			actors = nil;
			movies = nil;
			years = nil;
		}
		
		if (!mbgenre) {
			mbgenre = [[MBGenre alloc] init];
			mbgenre.name = genre;
			mbgenre.actors = (actors = [[NSMutableDictionary alloc] init]);
			mbgenre.movies = (movies = [[NSMutableDictionary alloc] init]);
			mbgenre.years =  (years  = [[NSMutableDictionary alloc] init]);
		}
		
		if ([label isEqualToString:@"actor"])
			actors[title] = @"";
		else if ([label isEqualToString:@"movie"]) {
			NSMutableString *key = [[NSMutableString alloc] init];
			[key appendString:title];
			[key appendString:@"--"];
			[key appendString:keyParts[3]];
			movies[key] = @"";
//		movies[[NSString stringWithFormat:@"%@--%@", title, keyParts[3]]] = @"";
			years[@(((NSString *)keyParts[3]).integerValue)] = @"";
		}
	}];
}

/**
 *
 *
 */
- (void)loadMovies
{
	__block MBMovie *mbmovie = nil;
	__block NSString *curTitle = nil;
	__block NSMutableDictionary *actors = nil;
	
	[mMovieDb enumerateKeys:^ (NSString *key, BOOL *stop) {
		NSArray *keyParts = [key componentsSeparatedByString:@"--"];
		
		if (keyParts.count < 3)
			return;
		
		NSString *title = keyParts[0];
		NSNumber *year  = @(((NSString *)keyParts[1]).integerValue);
		NSString *label = keyParts[2];
		NSString *value = mMovieDb[key];
		
		if (mbmovie && (![curTitle isEqualToString:title] || ![mbmovie.year isEqual:year])) {
			mMovies[mbmovie.dbkey] = mbmovie;
			mbmovie = nil;
			actors = nil;
		}
		
		if (!mbmovie) {
			NSMutableString *key = [[NSMutableString alloc] init];
			[key appendString:title];
			[key appendString:@"--"];
			[key appendString:year.stringValue];
			curTitle = title;
			mbmovie = [[MBMovie alloc] init];
			mbmovie.actors = (actors = [[NSMutableDictionary alloc] init]);
			mbmovie.dbkey = key;
			mbmovie.year = year;
		}
		
		if ([label isEqualToString:@"path"])
			mbmovie.dirpath = value;
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
	}];
	
	if (mbmovie)
		mMovies[mbmovie.dbkey] = mbmovie;
}





#pragma mark - Queries

/**
 *
 *
 */
- (BOOL)doesGenre:(MBGenre *)mbgenre haveActor:(MBPerson *)mbperson
{
	if (!mbgenre || !mbperson)
		return FALSE;
	else
		return nil != mbgenre.actors[mbperson.name];
}

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
		return nil != mbgenre.movies[mbmovie.dbkey];
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
- (MBGenre *)genreWithKey:(NSString *)dbkey
{
	return mGenres[dbkey];
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
	// genre
	//
	{
		APLevelDBIterator *iter = [APLevelDBIterator iteratorWithLevelDB:mGenreDb];
		NSString *key=nil, *suffix = [@"--movie--" stringByAppendingString:dbkey];
		
		while (nil != (key = [iter nextKey])) {
			if ([key hasSuffix:suffix]) {
				NSLog(@"  GENRE [%@]", key);
				[mGenreDb removeKey:key];
			}
		}
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
- (void)enumerateMovies:(void (^)(MBMovie*, BOOL*))handler
{
	[[mMovies allValues] enumerateObjectsUsingBlock:^ (id obj, NSUInteger ndx, BOOL *stop) {
		handler((MBMovie *)obj, stop);
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
- (void)enumerateGenres:(void (^)(MBGenre*, NSUInteger, BOOL*))handler
{
	[[mGenres allValues] enumerateObjectsUsingBlock:^ (id obj, NSUInteger ndx, BOOL *stop) {
		handler((MBGenre *)obj, ((MBGenre *)obj).movies.count, stop);
	}];
}

/**
 *
 *
 */
- (void)enumerateActors:(void (^)(MBPerson*, NSUInteger, BOOL*))handler
{
	[[mActors allValues] enumerateObjectsUsingBlock:^ (id obj, NSUInteger ndx, BOOL *stop) {
		handler((MBPerson *)obj, ((MBPerson *)obj).movies.count, stop);
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
 * Add missing IMDb data to existing TMDb movies.
 *
 */
- (void)updateIMDbData
{
	NSArray *movies = [mMovies.allKeys sortedArrayUsingComparator:^ NSComparisonResult (id obj1, id obj2) {
		return [(NSString *)obj1 compare:(NSString *)obj2];
	}];
	
	NSLog(@"[DM] Found %04lu movies", movies.count);
	
	[movies enumerateObjectsUsingBlock:^ (id obj, NSUInteger ndx, BOOL *stop) {
		MBMovie *mbmovie = mMovies[obj];
		
		if (!mbmovie.tmdbId.length)
			return;
		
		if (mbmovie.imdbId.length) {
			
		}
		else {
			
		}
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
- (void)updateFileStats
{
	NSFileManager *fileManager = [[NSFileManager alloc] init];
	
	NSArray *movies = [mMovies.allKeys sortedArrayUsingComparator:^ NSComparisonResult (id obj1, id obj2) {
		return [(NSString *)obj1 compare:(NSString *)obj2];
	}];
	
	NSLog(@"[DM] Found %04lu movies", movies.count);
	
	[movies enumerateObjectsUsingBlock:^ (id obj, NSUInteger ndx, BOOL *stop) {
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
				
				_runtime += idinfo.duration2.integerValue;
				_filesize += idinfo.fileSize.integerValue;
				
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
		
		NSLog(@"[DM]   runtime=%@, filesize=%@, bitrate=%@, width=%@, height=%@", runtime, filesize, bitrate, width, height);
		
		mMovieDb[[dbkey stringByAppendingString:@"--duration"]] = runtime.stringValue;
		mMovieDb[[dbkey stringByAppendingString:@"--size"    ]] = filesize.stringValue;
		mMovieDb[[dbkey stringByAppendingString:@"--width"   ]] = width.stringValue;
		mMovieDb[[dbkey stringByAppendingString:@"--height"  ]] = height.stringValue;
		mMovieDb[[dbkey stringByAppendingString:@"--bitrate" ]] = bitrate.stringValue;
		mMovieDb[[dbkey stringByAppendingString:@"--mtime"   ]] = @(latest.timeIntervalSinceReferenceDate).stringValue;
		
		mbmovie.runtime = runtime;
		mbmovie.filesize = filesize;
		mbmovie.width = width;
		mbmovie.height = height;
		mbmovie.bitrate = bitrate;
		mbmovie.mtime = latest;
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
			
			if (idinfo) {
				NSLog(@"[DM]   [%lu] %@ x %@, %@ seconds", ndx1, idinfo.width, idinfo.height, idinfo.duration2);
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
			
			_runtime += idinfo.duration2.integerValue;
			_filesize += idinfo.fileSize.integerValue;
			
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
				
				if (![_idmovie.year isEqual:year]) {
					NSLog(@"[DM]       Skipping because of the year");
					return;
				}
				
				if (10 < labs(_idmovie.runtime.integerValue - (runtime.integerValue/60)) /*&& FALSE == [self title:_idmovie.title matchesTitles:titles]*/ ) {
					NSLog(@"[DM]       Skipping because of the runtime");
					return;
				}
				
				idmovie = _idmovie;
				
				NSLog(@"[DM]       Matched!");
				
				if (idmovie)
					*stop2 = TRUE;
			}];
			
			if (idmovie)
				*stop1 = TRUE;
		}];
		
		if (!idmovie) {
			NSLog(@"[DM]   Could not find a match!");
			return;
		}
	}
	
	[self addMovie:idmovie withDirPath:dirPath duration:runtime filesize:filesize width:width height:height bitrate:bitrate mtime:latest];
}

/**
 *
 *
 */
- (void)addMovie:(IDMovie *)idmovie withDirPath:(NSString *)dirPath duration:(NSNumber *)duration filesize:(NSNumber *)filesize width:(NSNumber *)width height:(NSNumber *)height bitrate:(NSNumber *)bitrate mtime:(NSDate *)mtime
{
	if (!idmovie)
		return;
	
	NSMutableString *dbkey = [[NSMutableString alloc] init];
	[dbkey appendString:idmovie.title];
	[dbkey appendString:@"--"];
	[dbkey appendString:idmovie.year.stringValue];
	
	NSFileManager *fileManager = [[NSFileManager alloc] init];
//NSString *dbkey = [NSString stringWithFormat:@"%@--%@", idmovie.title, idmovie.year];
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
		mMovieDb[[dbkey stringByAppendingString:@"--path"    ]] = dirPath;
		mMovieDb[[dbkey stringByAppendingString:@"--title"   ]] = idmovie.title;
		mMovieDb[[dbkey stringByAppendingString:@"--year"    ]] = idmovie.year.stringValue;
		mMovieDb[[dbkey stringByAppendingString:@"--rating"  ]] = idmovie.rating;
		mMovieDb[[dbkey stringByAppendingString:@"--score"   ]] = idmovie.score.stringValue;
		mMovieDb[[dbkey stringByAppendingString:@"--synopsis"]] = idmovie.synopsis;
		mMovieDb[[dbkey stringByAppendingString:@"--duration"]] = duration.stringValue;
		mMovieDb[[dbkey stringByAppendingString:@"--runtime" ]] = idmovie.runtime.stringValue;
		mMovieDb[[dbkey stringByAppendingString:@"--size"    ]] = filesize.stringValue;
		mMovieDb[[dbkey stringByAppendingString:@"--width"   ]] = width.stringValue;
		mMovieDb[[dbkey stringByAppendingString:@"--height"  ]] = height.stringValue;
		mMovieDb[[dbkey stringByAppendingString:@"--bitrate" ]] = bitrate.stringValue;
		mMovieDb[[dbkey stringByAppendingString:@"--mtime"   ]] = @(mtime.timeIntervalSinceReferenceDate).stringValue;
		
		if (idmovie.imdbId ) mMovieDb[[dbkey stringByAppendingString:@"--imdbid" ]] = idmovie.imdbId;
		if (idmovie.rtId   ) mMovieDb[[dbkey stringByAppendingString:@"--rtid"   ]] = idmovie.rtId;
		if (idmovie.tmdbId ) mMovieDb[[dbkey stringByAppendingString:@"--tmdbid" ]] = idmovie.tmdbId;
		
		// get the image (if we don't already have it)
		if (nil != idmovie.imageUrl) {
			NSString *imageId = mMovieDb[[dbkey stringByAppendingString:@"--poster"]];
			
			NSLog(@"[DM]         Found image at %@", idmovie.imageUrl);
			
			NSData *imageData = [NSData dataWithContentsOfURL:(NSURL *)idmovie.imageUrl];
			
			NSLog(@"[DM]           Got %lu bytes", imageData.length);
			
			if (imageData) {
				if (!imageId) {
					imageId = [NSString randomStringOfLength:32];
					NSLog(@"[DM]           Assigning new image id [%@]", imageId);
				}
				else
					NSLog(@"[DM]           Using existing image id [%@]", imageId);
				
				NSString *dataPath = [movieBaseDir stringByAppendingPathComponent:imageId];
				
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
		NSArray *genres = idmovie.genres;
		NSArray *casts = idmovie.cast;
		
		NSLog(@"[DM]       Got %lu genre(s)", genres.count);
		
		[genres enumerateObjectsUsingBlock:^ (id obj1, NSUInteger ndx1, BOOL *stop1) {
			NSLog(@"[DM]       [%lu] %@", ndx1, obj1);
			
			NSMutableString *key = [[NSMutableString alloc] init];
			[key appendString:obj1];
			[key appendString:@"--movie--"];
			[key appendString:dbkey];
			
			mGenreDb[key] = @"";
//		mGenreDb[[NSString stringWithFormat:@"%@--movie--%@", obj1, dbkey]] = @"";
			
			[casts enumerateObjectsUsingBlock:^ (id obj2, NSUInteger ndx2, BOOL *stop2) {
				NSMutableString *_key = [[NSMutableString alloc] init];
				[_key appendString:obj1];
				[_key appendString:@"--actor--"];
				[_key appendString:((IDPerson *)obj2).name];
				
				mGenreDb[_key] = @"";
//			[mGenreDb setString:@"" forKey:[NSString stringWithFormat:@"%@--actor--%@", obj1, ((IDPerson *)obj2).name]];
			}];
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
//			mActorDb[[NSString stringWithFormat:@"%@--movie--%@", name, dbkey]] = @(ndx1).stringValue;
			}
			
			// for each CAST member for this MOVIE, map the person to the movie
			{
				NSMutableString *key = [[NSMutableString alloc] init];
				[key appendString:dbkey];
				[key appendString:@"--actor--"];
				[key appendString:name];
				
				mMovieDb[key] = name;
//			mMovieDb[[NSString stringWithFormat:@"%@--actor--%@", dbkey, name]] = name;
			}
			
			NSString *imageId = mActorDb[[name stringByAppendingString:@"--image--id"]];
			NSString *imageUrl = mActorDb[[name stringByAppendingString:@"--image--url"]];
			
			// get the image (if we don't already have one)
			if ((!imageId.length || !imageUrl.length) && nil != (value = idperson.imageUrl)) {
				NSLog(@"[DM]         Found image at %@", value);
				
				NSData *imageData = [NSData dataWithContentsOfURL:(NSURL *)value];
				
				NSLog(@"[DM]           Got %lu bytes", imageData.length);
				
				if (imageData) {
					if (!imageId) {
						imageId = [NSString randomStringOfLength:32];
						NSLog(@"[DM]           Assigning new image id [%@]", imageId);
					}
					else
						NSLog(@"[DM]           Using existing image id [%@]", imageId);
					
					NSString *dataPath = [actorBaseDir stringByAppendingPathComponent:imageId];
					
					mActorDb[[name stringByAppendingString:@"--image--id"]] = imageId;
					mActorDb[[name stringByAppendingString:@"--image--url"]] = ((NSURL *)value).absoluteString;
					
					[imageData writeToFile:dataPath atomically:FALSE];
					
					NSLog(@"[DM]           %@", dataPath);
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
