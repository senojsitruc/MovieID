//
//  MBGenre.m
//  MovieBrowse
//
//  Created by Curtis Jones on 2012.09.07.
//  Copyright (c) 2012 Curtis Jones. All rights reserved.
//

#import "MBGenre.h"
#import "MBAppDelegate.h"

@implementation MBGenre

/**
 *
 *
 */
- (id)initWithGenre:(NSString *)genre
{
	self = [super init];
	
	if (self) {
		_name = genre;
	}
	
	return self;
}

/**
 *
 *
 */
- (id)copyWithZone:(NSZone *)zone
{
	MBGenre *copy = [[MBGenre allocWithZone:zone] init];
	copy->_name = _name;
	return copy;
}

/**
 *
 *
 */
- (BOOL)isEqual:(id)object
{
	return [_name isEqualToString:((MBGenre *)object)->_name];
}

/**
 *
 *
 */
- (NSString *)description
{
	return _name;
}

@end
