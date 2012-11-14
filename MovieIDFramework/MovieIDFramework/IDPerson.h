//
//  IDPerson.h
//  MovieIDFramework
//
//  Created by Curtis Jones on 2012.10.19.
//  Copyright (c) 2012 Curtis Jones. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface IDPerson : NSObject

@property (readonly) NSString *tmdbId;
@property (readonly) NSString *imdbId;
@property (readonly) NSString *rtId;
@property (readonly) NSString *name;
@property (readonly) NSArray *characters;
@property (readonly) NSString *bio;
@property (readonly) NSString *dob;
@property (readonly) NSString *dod;
@property (readonly) NSURL *web;
@property (readonly) NSURL *imageUrl;

@end
