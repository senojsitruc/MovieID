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

- (id)copyWithZone:(NSZone *)zone
{
	MBGenre *copy = [[MBGenre allocWithZone:zone] init];
	copy.name = self.name;
	return copy;
}

@end
