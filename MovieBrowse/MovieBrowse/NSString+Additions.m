//
//  NSString+Additions.m
//  Spamass
//
//  Created by Curtis Jones on 2012.08.07.
//  Copyright (c) 2012 Curtis Jones. All rights reserved.
//

#import "NSString+Additions.h"

static char *gAlphaNumeric = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";

@implementation NSString (Additions)

+ (id)randomStringOfLength:(NSUInteger)length
{
	int i = 0;
	NSMutableString *str = [NSMutableString stringWithCapacity:length];
	
	for (i = 0; i < length; ++i)
		[str appendFormat:@"%c", gAlphaNumeric[random() % 62]];
	
	return str;
}

- (NSUInteger)UTF8Length
{
	return [self lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
}

@end
