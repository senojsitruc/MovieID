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

@property (readwrite, strong) NSString *filepath;
@property (readwrite, strong) NSNumber *framerate;
@property (readwrite, strong) NSDate *mtime;
@property (readwrite, strong) NSNumber *filesize;
@property (readwrite, strong) NSNumber *duration;        // seconds
@property (readwrite, strong) NSNumber *width;
@property (readwrite, strong) NSNumber *height;
@property (readwrite, strong) NSNumber *bitrate;
@property (readwrite, strong) NSMutableArray *languages;

- (id)initWithFilePath:(NSString *)filePath;

@end
