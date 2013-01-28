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

@property (readonly) NSDictionary *actorsByName;

- (void)addSource:(NSString *)sourcePath;
- (void)scanSource:(NSString *)sourcePath;

- (void)moveGenresToMovies;
- (NSArray *)findMissingMovies;
- (void)findDuplicateMovies;
- (NSArray *)findMissingFiles;
- (void)ratingsNormalize;
- (void)updateFileStats;
- (void)upgradeTmdbToImdb;
- (void)getMissingImages;

- (void)enumerateMovies:(void (^)(MBMovie*, NSUInteger, BOOL*))handler;
- (void)enumerateGenres:(void (^)(MBGenre*, BOOL*))handler;
- (void)enumerateActors:(void (^)(MBPerson*, NSUInteger, BOOL*))handler;
- (void)enumerateMoviesForPerson:(MBPerson *)mbperson handler:(void (^)(MBMovie*, BOOL*))handler;
- (void)enumerateActorsForMovie:(MBMovie *)mbmovie handler:(void (^)(MBPerson*, BOOL*))handler;

- (void)deleteMovie:(MBMovie *)movie;
- (void)saveMovie:(MBMovie *)movie;

- (BOOL)doesMovie:(MBMovie *)mbmovie haveActor:(MBPerson *)mbperson;
- (BOOL)doesMovie:(MBMovie *)mbmovie haveGenre:(MBGenre *)mbgenre;
- (BOOL)doesMovie:(MBMovie *)mbmovie haveLanguage:(NSString *)language;
- (MBMovie *)movieWithKey:(NSString *)dbkey;
- (void)movie:(MBMovie *)movie updateWithTitle:(NSString *)newTitle;
- (void)movie:(MBMovie *)movie updateWithValues:(NSDictionary *)values;
- (MBPerson *)personWithKey:(NSString *)dbkey;
- (void)person:(MBPerson *)person updateWithName:(NSString *)name;
- (void)person:(MBPerson *)person updateWithValues:(NSDictionary *)values;
- (MBGenre *)genreWithKey:(NSString *)dbkey;
- (void)genre:(MBGenre *)mbgenre updateWithName:(NSString *)newName;
- (void)genreDelete:(MBGenre *)genre;

- (void)addMovie:(IDMovie *)idmovie withDirPath:(NSString *)dirPath duration:(NSNumber *)duration filesize:(NSNumber *)filesize width:(NSNumber *)width height:(NSNumber *)height bitrate:(NSNumber *)bitrate mtime:(NSDate *)mtime languages:(NSArray *)languages;

- (void)closeDb;
- (void)loadActors:(void (^)(NSUInteger, NSString*))handler;
- (void)loadMovies:(void (^)(NSUInteger, NSString*))handler;

@end
