//
//  MBPerson.m
//  MovieBrowse
//
//  Created by Curtis Jones on 2012.09.05.
//  Copyright (c) 2012 Curtis Jones. All rights reserved.
//

#import "MBPerson.h"
#import "MBImageCache.h"

@interface MBPerson ()
{
	NSString *mInfo;
}
@end

@implementation MBPerson

- (NSString *)description
{
	return [NSString stringWithFormat:@"<%@: %p> %@", NSStringFromClass(self.class), self, self.name];
}

- (id)copyWithZone:(NSZone *)zone
{
	MBPerson *copy = [[MBPerson allocWithZone:zone] init];
	copy.name = self.name;
	copy.imageId = self.imageId;
	return copy;
}

- (NSString *)info
{
	if (!mInfo) {
		NSMutableString *info = [[NSMutableString alloc] init];
		
		if (self.dob.length) {
			[info appendString:@"Born: "];
			[info appendString:self.dob];
		}
		
		if (self.dod.length) {
			if (info.length)
				[info appendString:@"; "];
			
			[info appendString:@"Died: "];
			[info appendString:self.dod];
		}
		
		if (self.web.length) {
			if (info.length)
				[info appendString:@"; "];
			
			[info appendString:@"Web: "];
			[info appendString:self.web];
		}
		
		mInfo = info;
	}
	
	return mInfo;
}

- (NSNumber *)movieCount
{
	return @(self.movies.count);
}

- (void)updateInfoText
{
	mInfo = nil;
}

@end
