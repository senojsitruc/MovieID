//
//  MBStuff.m
//  MovieBrowse
//
//  Created by Curtis Jones on 2012.10.18.
//  Copyright (c) 2012 Curtis Jones. All rights reserved.
//

#import "MBStuff.h"

@implementation MBStuff

/**
 * Duration in seconds.
 *
 */
+ (NSString *)humanReadableDuration:(unsigned long long)duration
{
	NSMutableString *string = [[NSMutableString alloc] init];
	
	// days
	if (duration > 86400) {
		NSUInteger days = duration / 86400;
		[string appendFormat:@"%lu", days];
		duration -= (days * 86400);
		[string appendString:@"d"];
	}
	
	// hours
	if (duration > 3600) {
		if (string.length)
			[string appendString:@" "];
		
		NSUInteger hours = duration / 3600;
		[string appendFormat:@"%lu", hours];
		duration -= (hours * 3600);
		[string appendString:@"h"];
	}
	
	// minutes
	if (duration > 60) {
		if (string.length)
			[string appendString:@" "];
		
		NSUInteger minutes = duration / 60;
		[string appendFormat:@"%lu", minutes];
		duration -= (minutes * 60);
		[string appendString:@"m"];
	}
	
	// seconds
	if (duration > 0) {
		if (string.length)
			[string appendString:@" "];
		
		[string appendFormat:@"%llu", duration];
		[string appendString:@"s"];
	}
	
	return string;
}

/**
 *
 *
 */
+ (NSString *)humanReadableFileSize:(unsigned long long)fileSize
{
	static unsigned long long tb = 1000ULL * 1000ULL * 1000ULL * 1000ULL;
	static unsigned long long gb = 1000ULL * 1000ULL * 1000ULL;
	static unsigned long long mb = 1000ULL * 1000ULL;
	static unsigned long long kb = 1000ULL;
	
	unsigned long long divisor = 0;
	NSString *magnitude = nil;
	
	if (fileSize == 0)
		return @"Zero bytes";
	else if (fileSize > tb) {
		divisor = tb;
		magnitude = @"TB";
	}
	else if (fileSize > gb) {
		divisor = gb;
		magnitude = @"GB";
	}
	else if (fileSize > mb) {
		divisor = mb;
		magnitude = @"MB";
	}
	else if (fileSize > kb) {
		divisor = kb;
		magnitude = @"KB";
	}
	else
		return [@(fileSize).stringValue stringByAppendingString:@" bytes"];
	
	unsigned long long whole = (fileSize / divisor);
	unsigned long long part = (fileSize - (whole * divisor)) / (divisor / 1000);
	unsigned long long tenths = part / 100;
	unsigned long long hundredths = (part - (tenths * 100)) / 10;
	
	NSMutableString *fileSizeStr = [[NSMutableString alloc] init];
	[fileSizeStr appendFormat:@"%llu", whole];
	
	if (tenths) {
		[fileSizeStr appendString:@"."];
		[fileSizeStr appendFormat:@"%llu", tenths];
		
		if (hundredths)
			[fileSizeStr appendFormat:@"%llu", hundredths];
	}
	else if (hundredths) {
		[fileSizeStr appendString:@".0"];
		[fileSizeStr appendFormat:@"%llu", hundredths];
	}
	
	[fileSizeStr appendString:@" "];
	[fileSizeStr appendString:magnitude];
	
	return fileSizeStr;
}

/**
 *
 *
 */
+ (NSString *)humanReadableBitRate:(unsigned long long)bitRate
{
	static unsigned long long tb = 1024ULL * 1024ULL * 1024ULL * 1024ULL;
	static unsigned long long gb = 1024ULL * 1024ULL * 1024ULL;
	static unsigned long long mb = 1024ULL * 1024ULL;
	static unsigned long long kb = 1024ULL;
	
	unsigned long long divisor = 0;
	NSString *magnitude = nil;
	
	if (bitRate == 0)
		return @"0";
	else if (bitRate > tb) {
		divisor = tb;
		magnitude = @"Tbit/s";
	}
	else if (bitRate > gb) {
		divisor = gb;
		magnitude = @"GBit/s";
	}
	else if (bitRate > mb) {
		divisor = mb;
		magnitude = @"Mbit/s";
	}
	else if (bitRate > kb) {
		divisor = kb;
		magnitude = @"Kbit/s";
	}
	else
		return [NSString stringWithFormat:@"%llu Bit/s", bitRate];
	
	unsigned long long whole = (bitRate / divisor);
	unsigned long long part = (bitRate - (whole * divisor)) / (divisor / 1024);
	unsigned long long tenths = part / 100;
	unsigned long long hundredths = (part - (tenths * 100)) / 10;
	
	NSMutableString *fileSizeStr = [[NSMutableString alloc] init];
	[fileSizeStr appendFormat:@"%llu", whole];
	
	if (tenths) {
		[fileSizeStr appendString:@"."];
		[fileSizeStr appendFormat:@"%llu", tenths];
		
		if (hundredths)
			[fileSizeStr appendFormat:@"%llu", hundredths];
	}
	else if (hundredths) {
		[fileSizeStr appendString:@".0"];
		[fileSizeStr appendFormat:@"%llu", hundredths];
	}
	
	[fileSizeStr appendString:@" "];
	[fileSizeStr appendString:magnitude];
	
	return fileSizeStr;
}

@end
