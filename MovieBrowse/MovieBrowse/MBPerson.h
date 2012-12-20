//
//  MBPerson.h
//  MovieBrowse
//
//  Created by Curtis Jones on 2012.09.05.
//  Copyright (c) 2012 Curtis Jones. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MBPerson : NSObject

@property (readwrite, strong, nonatomic) NSString *name;
@property (readwrite, strong, nonatomic) NSString *bio;
@property (readwrite, strong, nonatomic) NSString *dob;
@property (readwrite, strong, nonatomic) NSString *dod;
@property (readwrite, strong, nonatomic) NSString *web;
@property (readwrite, strong, nonatomic) NSString *tmdbId;
@property (readwrite, strong, nonatomic) NSString *rtId;
@property (readwrite, strong, nonatomic) NSString *imdbId;
@property (readwrite, strong, nonatomic) NSString *imageId;
@property (readwrite, strong, nonatomic) NSURL *imageUrl;
@property (readwrite, strong, nonatomic) NSMutableDictionary *movies;

@property (readonly, getter=movieCount) NSNumber *movieCount;
@property (readonly, getter=info) NSString *info;

@end
