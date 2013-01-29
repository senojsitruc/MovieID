//
//  IDRating.m
//  MovieIDFramework
//
//  Created by Curtis Jones on 2012.12.18.
//  Copyright (c) 2012 Curtis Jones. All rights reserved.
//

#import "IDRating.h"

static NSMutableDictionary *gRatings;

@implementation IDRating

/**
 *
 *
 */
+ (void)load
{
	@autoreleasepool {
		gRatings = [[NSMutableDictionary alloc] init];
		
		gRatings[@"g"] = @"G";
		gRatings[@"0"] = @"G";
		gRatings[@"1"] = @"G";
		gRatings[@"2"] = @"G";
		gRatings[@"3"] = @"G";
		gRatings[@"4"] = @"G";
		gRatings[@"5"] = @"G";
		gRatings[@"6"] = @"G";
		gRatings[@"u"] = @"G";
		gRatings[@"c"] = @"G";
		gRatings[@"f"] = @"G";
		gRatings[@"btl"] = @"G";
		gRatings[@"kn"] = @"G";
		gRatings[@"l"] = @"G";
		gRatings[@"a"] = @"G";
		gRatings[@"aa"] = @"G";
		gRatings[@"o.al."] = @"G";
		gRatings[@"al"] = @"G";
		gRatings[@"all"] = @"G";
		gRatings[@"l"] = @"G";
		gRatings[@"s"] = @"G";
		gRatings[@"t"] = @"G";
		gRatings[@"kt"] = @"G";
		gRatings[@"ea"] = @"G";
		gRatings[@"k-3"] = @"G";
		gRatings[@"m/4"] = @"G";
		
		gRatings[@"pg"] = @"PG";
		gRatings[@"approved"] = @"PG";
		gRatings[@"passed"] = @"PG";
		gRatings[@"e"] = @"PG";
		gRatings[@"m/6"] = @"PG";
		gRatings[@"7"] = @"PG";
		gRatings[@"8"] = @"PG";
		gRatings[@"9"] = @"PG";
		gRatings[@"10"] = @"PG";
		gRatings[@"11"] = @"PG";
		gRatings[@"12"] = @"PG";
		gRatings[@"b"] = @"PG";
		gRatings[@"atp"] = @"PG";
		gRatings[@"k"] = @"PG";
		gRatings[@"i"] = @"PG";
		gRatings[@"12a"] = @"PG";
		gRatings[@"12-a"] = @"PG";
		gRatings[@"k-7"] = @"PG";
		gRatings[@"k-8"] = @"PG";
		gRatings[@"k-11"] = @"PG";
		gRatings[@"k-12"] = @"PG";
		gRatings[@"u"] = @"PG";
		gRatings[@"pg12"] = @"PG";
		gRatings[@"pg-12"] = @"PG";
		
		gRatings[@"pg-13"] = @"PG-13";
		gRatings[@"13"] = @"PG-13";
		gRatings[@"13+"] = @"PG-13";
		gRatings[@"14"] = @"PG-13";
		gRatings[@"14+"] = @"PG-13";
		gRatings[@"14a"] = @"PG-13";
		gRatings[@"15"] = @"PG-13";
		gRatings[@"15a"] = @"PG-13";
		gRatings[@"16"] = @"PG-13";
		gRatings[@"c"] = @"PG-13";
		gRatings[@"gp"] = @"PG-13";
		gRatings[@"m"] = @"PG-13";
		gRatings[@"iia"] = @"PG-13";
		gRatings[@"k-13"] = @"PG-13";
		gRatings[@"k-14"] = @"PG-13";
		gRatings[@"k-15"] = @"PG-13";
		gRatings[@"r15"] = @"PG-13";
		gRatings[@"r15+"] = @"PG-13";
		gRatings[@"r-15"] = @"PG-13";
		gRatings[@"m/12"] = @"PG-13";
		gRatings[@"pg13"] = @"PG-13";
		gRatings[@"r-12"] = @"PG-13";
		gRatings[@"vm14"] = @"PG-13";
		
		gRatings[@"r"] = @"R";
		gRatings[@"17"] = @"R";
		gRatings[@"d"] = @"R";
		gRatings[@"18a"] = @"R";
		gRatings[@"iib"] = @"R";
		gRatings[@"k-16"] = @"R";
		gRatings[@"m/16"] = @"R";
		gRatings[@"ma"] = @"R";
		gRatings[@"ma15+"] = @"R";
		gRatings[@"nc-16"] = @"R";
		gRatings[@"knt"] = @"R";
		gRatings[@"ena"] = @"R";
		gRatings[@"18"] = @"R";
		gRatings[@"m18"] = @"R";
		
		gRatings[@"nc-17"] = @"NC-17";
		gRatings[@"iii"] = @"NC-17";
		gRatings[@"k-18"] = @"NC-17";
		gRatings[@"r-18"] = @"NC-17";
		gRatings[@"r18"] = @"NC-17";
		gRatings[@"r18+"] = @"NC-17";
		gRatings[@"r21"] = @"NC-17";
		gRatings[@"x"] = @"NC-17";
		gRatings[@"(banned)"] = @"NC-17";
		
		gRatings[@"tv-g"] = @"TV-G";
		gRatings[@"tv-y7"] = @"TV-G";
		gRatings[@"tv-pg"] = @"TV-PG";
		gRatings[@"tv-14"] = @"TV-14";
		gRatings[@"tv-ma"] = @"TV-MA";
		
		gRatings[@"unrated"] = @"Unrated";
		gRatings[@"-12"] = @"Unknown";
		gRatings[@"-16"] = @"Unknown";
		gRatings[@"unknown"] = @"Unknown";
	}
}

/**
 *
 *
 */
+ (NSString *)normalizedRating:(NSString *)rating
{
	if (!rating)
		return nil;
	
	rating = gRatings[rating.lowercaseString];
	
	if (!rating)
		rating = @"";
	
	return rating;
}

@end
