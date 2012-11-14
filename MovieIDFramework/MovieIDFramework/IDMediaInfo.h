//
//  IDMediaInfo.h
//  MovieIDFramework
//
//  Created by Curtis Jones on 2012.09.05.
//  Copyright (c) 2012 Curtis Jones. All rights reserved.
//

#import <Foundation/Foundation.h>

@class IDTimecode;

@interface IDMediaInfo : NSObject

@property (readwrite, strong) NSString *filePath;
@property (readwrite, strong) IDTimecode *timecode;
@property (readwrite, strong) NSDate *mtime;
@property (readwrite, strong) NSNumber *fileSize;
//@property (readwrite, strong) NSNumber *duration;        // seconds
@property (readwrite, strong) NSNumber *width;
@property (readwrite, strong) NSNumber *height;
@property (readwrite, strong) NSNumber *bitrate;
@property (readonly, getter=duration2) NSNumber *duration2;



/*
@property (readwrite, strong) NSString *dirPath;
@property (readwrite, strong) NSArray *filePaths;
//@property (readwrite, strong) IDTimecode *timecode;
//@property (readwrite, strong) NSDate *mtime;
@property (readwrite, strong) NSNumber *size;
@property (readwrite, strong) NSNumber *duration;        // seconds
//@property (readwrite, strong) NSNumber *width;
//@property (readwrite, strong) NSNumber *height;
//@property (readwrite, strong) NSNumber *bitrate;

@property (readwrite, strong) NSString *dbkey;
@property (readwrite, strong) NSString *imdbId;
@property (readwrite, strong) NSString *rtId;
@property (readwrite, strong) NSString *tmdbId;
@property (readwrite, strong) NSURL *posterUrl;
@property (readwrite, strong) NSString *title;
@property (readwrite, strong) NSString *year;
@property (readwrite, strong) NSString *rating;
@property (readwrite, strong) NSString *synopsis;
@property (readwrite, strong) NSNumber *runtime;
@property (readonly, strong) NSMutableArray *cast;
@property (readonly, strong) NSMutableArray *genres;
*/

- (id)initWithFilePath:(NSString *)filePath;
//- (id)initWithFilePaths:(NSArray *)paths;

@end
