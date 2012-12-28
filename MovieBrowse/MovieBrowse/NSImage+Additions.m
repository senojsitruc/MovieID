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
	CGImageSourceRef source = CGImageSourceCreateWithData((__bridge CFDataRef)self.TIFFRepresentation, NULL);
	CGImageRef maskRef =  CGImageSourceCreateImageAtIndex(source, 0, NULL);
	
	return maskRef;
}

@end
