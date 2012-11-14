//
//  MBPerson.h
//  MovieBrowse
//
//  Created by Curtis Jones on 2012.09.05.
//  Copyright (c) 2012 Curtis Jones. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MBPerson : NSObject

@property (readwrite, strong) NSString *name;
@property (readwrite, strong) NSString *bio;
@property (readwrite, strong) NSString *dob;
@property (readwrite, strong) NSString *dod;
@property (readwrite, strong) NSString *web;
@property (readwrite, strong) NSString *tmdbId;
@property (readwrite, strong) NSString *rtId;
@property (readwrite, strong) NSString *imdbId;
@property (readwrite, strong) NSString *imageId;
@property (readwrite, strong) NSMutableDictionary *movies;
@property (readonly) NSNumber *movieCount;

@property (readonly, getter=info) NSString *info;

@end
