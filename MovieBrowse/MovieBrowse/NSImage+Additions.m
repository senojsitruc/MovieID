//
//  NSImage+Additions.m
//  MovieBrowse
//
//  Created by Curtis Jones on 2012.12.28.
//  Copyright (c) 2012 Curtis Jones. All rights reserved.
//

#import "NSImage+Additions.h"

@implementation NSImage (Additions)

- (CGImageRef)CGImage
{
	NSData *data = self.TIFFRepresentation;
	
	if (!data) {
		NSLog(@"%s.. failed to TIFFRepresentation()", __PRETTY_FUNCTION__);
		return nil;
	}
	
	CGImageSourceRef source = CGImageSourceCreateWithData((__bridge CFDataRef)data, NULL);
	
	if (!source) {
		NSLog(@"%s.. failed to CGImageSourceCreateWithData()", __PRETTY_FUNCTION__);
		return nil;
	}
	
	CGImageRef maskRef = CGImageSourceCreateImageAtIndex(source, 0, NULL);
	CFRelease(source);
	
	return maskRef;
}

@end
