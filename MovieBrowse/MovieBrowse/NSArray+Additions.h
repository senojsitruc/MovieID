//
//  NSArray+Additions.h
//  MovieBrowse
//
//  Created by Curtis Jones on 2012.12.12.
//  Copyright (c) 2012 Curtis Jones. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSArray (Additions)

- (void)enumerateObjectsFromIndex:(NSUInteger)index usingBlock:(void (^)(id, NSUInteger, BOOL*))block;

@end
