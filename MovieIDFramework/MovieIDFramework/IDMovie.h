//
//  IDMovie.h
//  MovieIDFramework
//
//  Created by Curtis Jones on 2012.10.19.
//  Copyright (c) 2012 Curtis Jones. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface IDMovie : NSObject

@property (readonly) NSString *tmdbId;
@property (readonly) NSString *imdbId;
@property (readonly) NSString *rtId;
@property (readonly) NSString *title;
@property (readonly) NSNumber *year;
@property (readonly) NSString *rating;
@property (readonly) NSNumber *score;
@property (readonly) NSString *synopsis;
@property (readonly) NSNumber *runtime;
@property (readonly) NSURL *imageUrl;
@property (readonly) NSArray *cast;
@property (readonly) NSArray *genres;

@end
