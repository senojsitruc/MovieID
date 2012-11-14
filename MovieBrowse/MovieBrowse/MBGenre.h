//
//  MBGenre.h
//  MovieBrowse
//
//  Created by Curtis Jones on 2012.09.07.
//  Copyright (c) 2012 Curtis Jones. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MBGenre : NSObject

@property (readwrite, strong) NSString *name;
@property (readwrite, strong) NSMutableDictionary *actors;
@property (readwrite, strong) NSMutableDictionary *movies;
@property (readwrite, strong) NSMutableDictionary *years;

@end
