//
//  MBMovie.h
//  MovieBrowse
//
//  Created by Curtis Jones on 2012.09.05.
//  Copyright (c) 2012 Curtis Jones. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MBMovie : NSObject

@property (readwrite, strong, nonatomic) NSString *dbkey;
@property (readwrite, nonatomic, setter=setTitle:) NSString *title;
@property (readwrite, strong, nonatomic) NSNumber *year;
@property (readwrite, strong, nonatomic) NSString *rating;
@property (readwrite, strong, nonatomic) NSNumber *score;
@property (readwrite, strong, nonatomic) NSString *posterId;
@property (readwrite, strong, nonatomic) NSNumber *runtime;
@property (readwrite, strong, nonatomic) NSMutableDictionary *actors;
@property (readwrite, strong, nonatomic) NSString *synopsis;
@property (readwrite, strong, nonatomic) NSNumber *hidden;

@property (readwrite, strong, nonatomic) NSString *tmdbId;
@property (readwrite, strong, nonatomic) NSString *imdbId;
@property (readwrite, strong, nonatomic) NSString *rtId;

@property (readwrite, strong, nonatomic) NSString *dirpath;
@property (readwrite, strong, nonatomic) NSNumber *duration;
@property (readwrite, strong, nonatomic) NSNumber *width;
@property (readwrite, strong, nonatomic) NSNumber *height;
@property (readwrite, strong, nonatomic) NSNumber *bitrate;
@property (readwrite, strong, nonatomic) NSNumber *filesize;
@property (readwrite, strong, nonatomic) NSDate *mtime;

@property (readwrite, strong, nonatomic) NSArray *languages;
@property (readwrite, strong, nonatomic) NSMutableDictionary *genres;

@property (readonly) NSString *displayTitle;
@property (readonly) NSString *sortTitle;
@property (readonly, getter=info1) NSString *info1;
@property (readonly, getter=info2) NSString *info2;

@end
