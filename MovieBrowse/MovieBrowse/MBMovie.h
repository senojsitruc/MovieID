//
//  MBMovie.h
//  MovieBrowse
//
//  Created by Curtis Jones on 2012.09.05.
//  Copyright (c) 2012 Curtis Jones. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MBMovie : NSObject

@property (readwrite, strong) NSString *dbkey;
@property (readwrite, nonatomic, setter=setTitle:) NSString *title;
@property (readonly) NSString *displayTitle;
@property (readonly) NSString *sortTitle;
@property (readwrite, strong) NSNumber *year;
@property (readwrite, strong) NSString *rating;
@property (readwrite, strong) NSNumber *score;
@property (readwrite, strong) NSString *posterId;
@property (readwrite, strong) NSNumber *runtime;
@property (readwrite, strong) NSMutableDictionary *actors;
@property (readwrite, strong) NSString *synopsis;
@property (readwrite, strong) NSNumber *hidden;

@property (readwrite, strong) NSString *tmdbId;
@property (readwrite, strong) NSString *imdbId;
@property (readwrite, strong) NSString *rtId;

@property (readwrite, strong) NSString *dirpath;
@property (readwrite, strong) NSNumber *duration;
@property (readwrite, strong) NSNumber *width;
@property (readwrite, strong) NSNumber *height;
@property (readwrite, strong) NSNumber *bitrate;
@property (readwrite, strong) NSNumber *filesize;
@property (readwrite, strong) NSDate *mtime;
@property (readwrite, strong) NSArray *languages;

@property (readonly, getter=info1) NSString *info1;
@property (readonly, getter=info2) NSString *info2;

@end
