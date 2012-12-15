//
//  MBGenreCellView.m
//  MovieBrowse
//
//  Created by Curtis Jones on 2012.12.15.
//  Copyright (c) 2012 Curtis Jones. All rights reserved.
//

#import "MBGenreCellView.h"
#import "MBGenreBadgeView.h"
#import "MBGenre.h"
#import "MBAppDelegate.h"

@interface MBGenreCellView ()
{
	MBGenre *mGenre;
}
@end

@implementation MBGenreCellView

/**
 *
 *
 */
- (id)objectValue
{
	_badgeView.number = [(MBAppDelegate *)[NSApp delegate] movieCountForGenre:(mGenre = [super objectValue])];
	return mGenre;
}

@end
