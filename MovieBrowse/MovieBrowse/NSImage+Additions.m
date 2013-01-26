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
	CGImageSourceRef source = CGImageSourceCreateWithData((__bridge CFDataRef)data, NULL);
	CGImageRef maskRef = CGImageSourceCreateImageAtIndex(source, 0, NULL);
	
	CFRelease(source);
	
	return maskRef;
}

@end
