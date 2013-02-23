//
//  MBImportCellView.m
//  MovieBrowse
//
//  Created by Curtis Jones on 2012.10.24.
//  Copyright (c) 2012 Curtis Jones. All rights reserved.
//

#import "MBImportCellView.h"
#import <MovieID/IDMovie.h>
#import <MovieID/IDIMDbMovie.h>
#import <MovieID/IDTmdbMovie.h>

@interface MBImportCellView ()
{
	IDMovie *mIdMovie;
	NSString *mInfo1;
	NSString *mInfo2;
}
@end

@implementation MBImportCellView

/**
 *
 *
 */
- (void)setObjectValue:(id)obj
{
	super.objectValue = obj;
	
	if (obj == mIdMovie)
		return;
	
	mInfo1 = nil;
	mInfo2 = nil;
	
	if (nil == (mIdMovie = obj))
		return;
	
	self.info1.stringValue = [self getInfo1Txt];
	self.info2.stringValue = [self getInfo2Txt];
}

/**
 * Title, year, duration
 *
 */
- (NSString *)getInfo1Txt
{
	if (!mInfo1) {
		NSMutableString *info = [[NSMutableString alloc] init];
		
		//
		// title
		//
		{
			if (!mIdMovie.title) {
				NSLog(@"%s.. no title for movie!", __PRETTY_FUNCTION__);
				return @"";
			}
			else
				[info appendString:mIdMovie.title];
		}
		
		//
		// year
		//
		if (mIdMovie.year.integerValue) {
			if (info.length)
				[info appendString:@", "];
			
			[info appendString:@"Year: "];
			[info appendString:mIdMovie.year.stringValue];
		}
		
		//
		// duration
		//
		if (mIdMovie.runtime.integerValue) {
			if (info.length)
				[info appendString:@", "];
			
			NSInteger duration = 60 * mIdMovie.runtime.integerValue;
			
			NSInteger hours = duration / 60 / 60;
			duration -= (hours * 60 * 60);
			
			NSInteger minutes = duration / 60;
			duration -= (minutes * 60);
			
			NSInteger seconds = duration;
			
			[info appendString:@"Runtime: "];
			
			// hours
			[info appendFormat:@"%ld", hours];
			[info appendString:@"h"];
			[info appendString:@" "];
			
			// minutes
			[info appendFormat:@"%ld", minutes];
			[info appendString:@"m"];
			[info appendString:@" "];
			
			// seconds
			[info appendFormat:@"%ld", seconds];
			[info appendString:@"s"];
		}
		
		mInfo1 = info;
	}
	
	return mInfo1;
}

/**
 *
 *
 */
- (NSString *)getInfo2Txt
{
	if (!mInfo2) {
		if (nil == (mInfo2 = mIdMovie.synopsis))
			mInfo2 = @"";
	}
	
	return mInfo2;
}

@end
