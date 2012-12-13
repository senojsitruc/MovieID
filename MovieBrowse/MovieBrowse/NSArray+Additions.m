//
//  NSArray+Additions.m
//  MovieBrowse
//
//  Created by Curtis Jones on 2012.12.12.
//  Copyright (c) 2012 Curtis Jones. All rights reserved.
//

#import "NSArray+Additions.h"

@implementation NSArray (Additions)

- (void)enumerateObjectsFromIndex:(NSUInteger)index usingBlock:(void (^)(id, NSUInteger, BOOL*))block
{
	NSIndexSet *indexes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(index, self.count-index)];
	[self enumerateObjectsAtIndexes:indexes options:0 usingBlock:block];
}

@end
