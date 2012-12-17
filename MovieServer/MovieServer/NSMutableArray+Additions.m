//
//  NSMutableArray+Additions.m
//  mosaic
//
//  Created by Curtis Jones on 2012.07.23.
//  Copyright (c) 2012 Kenzie Lane Services. All rights reserved.
//

#import <stdlib.h>
#import "NSMutableArray+Additions.h"

@implementation NSMutableArray (Shuffling)

/**
 * http://stackoverflow.com/questions/56648/whats-the-best-way-to-shuffle-an-nsmutablearray
 *
 */
- (void)shuffle
{
	static BOOL seeded = NO;
	
	if (!seeded) {
		seeded = YES;
		srandomdev();
	}
	
	NSUInteger count = [self count];
	
	for (NSUInteger i = 0; i < count; ++i) {
		NSUInteger nElements = count - i;
		NSUInteger n = (random() % nElements) + i;
		[self exchangeObjectAtIndex:i withObjectAtIndex:n];
	}
}

/**
 *
 *
 */
- (id)randomObject
{
	return [self objectAtIndex:(arc4random() % [self count])];
}

/**
 *
 *
 */
- (id)firstObject
{
	if ([self count] == 0)
		return nil;
	else
		return [self objectAtIndex:0];
}

/**
 *
 *
 */
- (void)removeFirstObject
{
	if (self.count)
		[self removeObjectAtIndex:0];
}

@end
