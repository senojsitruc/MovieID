//
//  MBDataManager.h
//  MovieBrowse
//
//  Created by Curtis Jones on 2012.09.05.
//  Copyright (c) 2012 Curtis Jones. All rights reserved.
//

#import <Foundation/Foundation.h>

@class IDMovie;
@class MBGenre;
@class MBMovie;
@class MBPerson;

@interface MBDataManager : NSObject

- (void)addSource:(NSString *)sourcePath;
- (void)scanSource:(NSString *)sourcePath;
- (NSArray *)findMissingMovies;
- (NSArray *)findMissingFiles;
- (void)updateFileStats;

- (void)enumerateMovies:(void (^)(MBMovie*, BOOL*))handler;
- (void)enumerateMoviesForPerson:(MBPerson *)mbperson handler:(void (^)(MBMovie*, BOOL*))handler;
- (void)enumerateGenres:(void (^)(MBGenre*, NSUInteger, BOOL*))handler;
- (void)enumerateActors:(void (^)(MBPerson*, NSUInteger, BOOL*))handler;
- (void)enumerateActorsForMovie:(MBMovie *)mbmovie handler:(void (^)(MBPerson*, BOOL*))handler;

- (void)deleteMovie:(MBMovie *)movie;
- (void)saveMovie:(MBMovie *)movie;

- (BOOL)doesGenre:(MBGenre *)mbgenre haveActor:(MBPerson *)mbperson;
- (BOOL)doesMovie:(MBMovie *)mbmovie haveActor:(MBPerson *)mbperson;
- (BOOL)doesMovie:(MBMovie *)mbmovie haveGenre:(MBGenre *)mbgenre;
- (BOOL)doesMovie:(MBMovie *)mbmovie haveLanguage:(NSString *)language;
- (MBMovie *)movieWithKey:(NSString *)dbkey;
- (MBPerson *)personWithKey:(NSString *)dbkey;
- (MBGenre *)genreWithKey:(NSString *)dbkey;

- (void)addMovie:(IDMovie *)idmovie withDirPath:(NSString *)dirPath duration:(NSNumber *)duration filesize:(NSNumber *)filesize width:(NSNumber *)width height:(NSNumber *)height bitrate:(NSNumber *)bitrate mtime:(NSDate *)mtime languages:(NSArray *)languages;

- (void)closeDb;

@end
