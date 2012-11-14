//
//  IDTimecode.m
//  MovieIDFramework
//
//  Created by Curtis Jones on 2012.09.05.
//  Copyright (c) 2012 Curtis Jones. All rights reserved.
//

#import "IDTimecode.h"

@interface IDTimecode ()
{
	NSUInteger mHours;                   // hours
	NSUInteger mMinutes;                 // minutes
	NSUInteger mSeconds;                 // seconds
	NSUInteger mFrames;                  // frames
	
	NSUInteger mFramesPerSecond;         // frames per second
	BOOL mDropFrame;                     // true if this is a dropFrame timecode
}
- (double)realFramerate;
@end

@implementation IDTimecode

@synthesize hours = mHours;
@synthesize minutes = mMinutes;
@synthesize seconds = mSeconds;
@synthesize frames = mFrames;
@synthesize framesPerSecond = mFramesPerSecond;
@synthesize dropFrame = mDropFrame;

/**
 *
 *
 */
- (id)init
{
	self = [super init];
	
	if (self) {
		self.framesPerSecond = 30;
		self.dropFrame = TRUE;
	}
	
	return self;
}

/**
 *
 *
 */
+ (IDTimecode *)timecodeWithString:(NSString *)timecodeString
{
	IDTimecode *tc = [[IDTimecode alloc] init];
	[tc setStringValue:timecodeString];
	return tc;
}

/**
 *
 *
 */
+ (IDTimecode *)timecodeWithFrames:(NSUInteger)frames framerate:(NSUInteger)framerate ntsc:(BOOL)ntsc
{
	IDTimecode *timecode = [[IDTimecode alloc] init];
	[timecode setFramesPerSecond:framerate];
	[timecode setDropFrame:ntsc];
	if (frames != (NSUInteger)-1)
		[timecode setTotalFrames:frames];
	return timecode;
}

/**
 *
 */
+ (IDTimecode *)timecodeWithTimeInterval:(NSTimeInterval)interval framerate:(NSUInteger)fps ntsc:(BOOL)df
{
	IDTimecode *timecode = [[IDTimecode alloc] init];
	
	[timecode setFramesPerSecond:fps];
	[timecode setDropFrame:df];
	
	if (interval > 0.0)
		[timecode setTotalFrames:interval * [IDTimecode realFramerateWithFramesPerSecond:fps dropFrame:df]];
	
	return timecode;
}

/**
 *
 *
 */
- (NSUInteger)totalFrames
{
	NSUInteger totalFrames = (mHours * 3600 + mMinutes * 60 + mSeconds) * mFramesPerSecond + mFrames;
	
	if (mDropFrame)
	{
		NSUInteger minutes = mMinutes + mHours * 60;
		totalFrames -= minutes * 2; // Subtract off 2x the number of minutes.
		totalFrames += (minutes / 10) * 2; // Add back the the frames that were not skipped every 10 minutes.
	}
	
	return totalFrames;
}

/**
 * Assign the hh:mm:ss:ff based on a number of frames.
 * Uses the values of mDropFrame and mFramesPerSecond.
 */
- (void)setTotalFrames:(NSUInteger)newTotalFrames
{
	// if the fps is zero, we're going to skip the rest of this function to avoid some divide-by-
	// zeroes. this timecode is not valid with a zero fps, but it'll continue happily.
	if (mFramesPerSecond == 0) {
		mFrames = 0;
		return;
	}
	
	NSUInteger totalFramesNDF = 0; // non-drop-frame total frames
	
	if(mDropFrame) { // NTSC only; no need for generalization for PAL (it's 25 even).
		// 1798*10+2 is number of NDF frames in 10 minutes.
		NSUInteger leftoverFrames = newTotalFrames % (1798*10 + 2);
		totalFramesNDF = 18000 * (int)(newTotalFrames / (1798*10 + 2));        // Add NDF frames for each ten minutes in the input.
		totalFramesNDF += leftoverFrames;                            // Add leftover frames (DF).
		totalFramesNDF += 2 * ((int)(leftoverFrames - 2) / 1798);    // Add correction for leftover frames (to make NDF).
	}
	else
	{
		totalFramesNDF = newTotalFrames;
	}
	
	// Now break up into hour, minute, second, frame.
	mHours = (int)(totalFramesNDF / (60 * 60 * mFramesPerSecond));
	totalFramesNDF -= mHours * 60 * 60 * mFramesPerSecond;
	
	mMinutes = (int)(totalFramesNDF / (60 * mFramesPerSecond));
	totalFramesNDF -= mMinutes * 60 * mFramesPerSecond;
	
	mSeconds = (int)(totalFramesNDF / mFramesPerSecond);
	totalFramesNDF -= mSeconds * mFramesPerSecond;
	
	mFrames = totalFramesNDF;
}

/**
 *
 *
 */
- (NSTimeInterval)timeInterval
{
	return (double)[self totalFrames] / [self realFramerate];
}

/**
 *
 *
 */
- (void)adjustByFrames:(NSInteger)frames
{
	[self setTotalFrames:[self totalFrames] + frames];
}

/**
 *
 */
+ (double)realFramerateWithFramesPerSecond:(NSUInteger)fps dropFrame:(BOOL)df
{
	if (df)
	{
		switch (fps)
		{
			case 24:
				return 23.97602397;
			case 30:
				return 29.97002997;
			case 60:
				return 59.94005994;
		}
	}
	return fps;
}

/**
 *
 *
 */
- (double)realFramerate
{
	return [IDTimecode realFramerateWithFramesPerSecond:mFramesPerSecond dropFrame:mDropFrame];
}

/**
 *
 *
 */
- (NSString *)toString
{
	return [NSString stringWithFormat:@"%02lu:%02lu:%02lu%c%02lu", mHours, mMinutes, mSeconds, mDropFrame ? ';':':', mFrames];
}

- (NSString *)description
{
	return [self toString];
}

/**
 *
 *
 */
- (void)setStringValue:(NSString *)str
{
	NSArray *components = [str componentsSeparatedByCharactersInSet:[NSCharacterSet punctuationCharacterSet]];
	if ([components count] != 4)
	{
		NSLog(@"Failed to set timecode from string; wrong number of components %lu, expected 4.", components.count);
		return;
	}
	[self setHours:[[components objectAtIndex:0] intValue]];
	[self setMinutes:[[components objectAtIndex:1] intValue]];
	[self setSeconds:[[components objectAtIndex:2] intValue]];
	[self setFrames:[[components objectAtIndex:3] intValue]];
}

/**
 *
 *
 */
- (BOOL)isLessThan:(IDTimecode *)aTimecode
{
	return [self compare:aTimecode] == NSOrderedAscending;
}

/**
 *
 *
 */
- (BOOL)isGreaterThan:(IDTimecode *)aTimecode
{
	return [self compare:aTimecode] == NSOrderedDescending;
}

/**
 *
 *
 */
- (BOOL)isEqual:(IDTimecode *)aTimecode
{
	return [self compare:aTimecode] == NSOrderedSame;
}

/**
 *
 *
 */
- (NSComparisonResult)compare:(IDTimecode *)timecode;
{
	NSUInteger selfTotalFrames = [self totalFrames];
	NSUInteger themTotalFrames = [timecode totalFrames];
	if (selfTotalFrames > themTotalFrames)
		return NSOrderedDescending;
	else if (selfTotalFrames < themTotalFrames)
		return NSOrderedAscending;
	else
		return NSOrderedSame;
}

@end
