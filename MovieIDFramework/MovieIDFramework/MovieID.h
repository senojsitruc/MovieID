//
//  MovieID.h
//  MovieIDF
//
//  Created by Curtis Jones on 2012.09.05.
//  Copyright (c) 2012 Curtis Jones. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <QTKit/QTKit.h>

@class IDMediaInfo;

typedef void (^MovieIDInfoHandler) (IDMediaInfo*);

@interface MovieID : NSObject

/**
 *
 */
- (IDMediaInfo *)basicInfoForMovieWithName:(NSString *)name;
- (IDMediaInfo *)infoForMovieWithName:(NSString *)name filePaths:(NSArray *)paths;

- (void)imdbInfoForMovieWithName:(NSString *)name year:(NSString *)year runtime:(NSNumber *)runtime;

@end
