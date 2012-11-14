//
//  MBMovie.m
//  MovieBrowse
//
//  Created by Curtis Jones on 2012.09.05.
//  Copyright (c) 2012 Curtis Jones. All rights reserved.
//

#import "MBMovie.h"
#import "MBStuff.h"
#import <MovieID/RegexKitLite.h>

@interface MBMovie ()
{
	NSString *mInfo1;
	NSString *mInfo2;
	NSString *mDisplayTitle;
	NSString *mSortTitle;
}
@end

@implementation MBMovie

- (id)copyWithZone:(NSZone *)zone
{
	MBMovie *copy = [[MBMovie allocWithZone:zone] init];
	copy->_title = _title;
	copy->mDisplayTitle = mDisplayTitle;
	copy->mSortTitle = mSortTitle;
	copy.posterId = self.posterId;
	copy.actors = self.actors;
	return copy;
}

- (void)setTitle:(NSString *)title
{
	NSRange range = NSMakeRange(0, 0);
	
	if ([title hasPrefix:@"A "])
		range.length = 1;
	else if ([title hasPrefix:@"An "])
		range.length = 2;
	else if ([title hasPrefix:@"The "])
		range.length = 3;
	
	if (range.length) {
		mDisplayTitle = [[[title substringFromIndex:range.length+1] stringByAppendingString:@", "] stringByAppendingString:[title substringToIndex:range.length]];
		mSortTitle = [title substringFromIndex:range.length+1];
	}
	else
		mDisplayTitle = mSortTitle = title;
	
	mSortTitle = [mSortTitle stringByReplacingOccurrencesOfRegex:@" \\- " withString:@" "];
	mSortTitle = [mSortTitle stringByReplacingOccurrencesOfRegex:@"[^A-Za-z0-9\\s]" withString:@""];
	mSortTitle = [mSortTitle stringByReplacingOccurrencesOfRegex:@"  " withString:@" "];
	mSortTitle = [mSortTitle lowercaseString];
	
	_title = title;
}

- (NSString *)displayTitle
{
	return mDisplayTitle;
}

- (NSString *)sortTitle
{
	return mSortTitle;
}

- (NSString *)info1
{
	if (!mInfo1) {
		NSMutableString *info = [[NSMutableString alloc] init];
		NSNumber *year = self.year;
		NSInteger duration = self.duration.integerValue;
		NSNumber *score = self.score;
		NSString *rating = self.rating;
		
		// if the runtime isn't available (that's the value we got from some official movie source)
		// then work with the actual movie file duration (as found on disk)
		if (!duration)
			duration = self.runtime.integerValue * 60;
		
		//
		// release date
		//
		if (year.integerValue) {
			if (info.length)
				[info appendString:@", "];
			
			[info appendString:@"Year: "];
			[info appendString:year.stringValue];
		}
		
		//
		// runtime
		//
		if (duration) {
			if (info.length)
				[info appendString:@", "];
			
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
		
		//
		// score
		//
		if (score.integerValue) {
			if (info.length)
				[info appendString:@", "];
			
			[info appendString:@"Score: "];
			[info appendString:score.stringValue];
		}
		
		//
		// rating
		//
		if (rating.length) {
			if (info.length)
				[info appendString:@", "];
			
			[info appendString:@"Rating: "];
			[info appendString:rating];
		}
		
		mInfo1 = [NSString stringWithString:info];
	}
	
	return mInfo1;
}

- (NSString *)info2
{
	if (!mInfo2) {
		NSMutableString *info = [[NSMutableString alloc] init];
		NSNumber *fileSize = self.filesize;
		NSNumber *width = self.width;
		NSNumber *height = self.height;
		NSNumber *bitrate = self.bitrate;
		
		//
		// file size
		//
		if (fileSize.longLongValue) {
			if (info.length)
				[info appendString:@", "];
			
			[info appendString:@"Size: "];
			[info appendString:[MBStuff humanReadableFileSize:fileSize.longLongValue]];
		}
		
		//
		// movie size
		//
		if (width && height) {
			if (info.length)
				[info appendString:@", "];
			
			[info appendString:@"Dim: "];
			[info appendString:width.stringValue];
			[info appendString:@"x"];
			[info appendString:height.stringValue];
		}
		
		//
		// bitrate
		//
		if (bitrate) {
			if (info.length)
				[info appendString:@", "];
			
			[info appendString:@"Bitrate: "];
			[info appendString:[MBStuff humanReadableBitRate:bitrate.longLongValue]];
		}
		
		mInfo2 = [NSString stringWithString:info];
	}
	
	return mInfo2;
}

@end
