//
//  MBFileMetadata.m
//  MovieBrowse
//
//  Created by Curtis Jones on 2013.02.04.
//  Copyright (c) 2013 Curtis Jones. All rights reserved.
//

#import "MBFileMetadata.h"
#import "NSString+Additions.h"
#import <errno.h>
#import <stdio.h>
#import <sys/xattr.h>

@implementation MBFileMetadata

/**
 *
 *
 */
+ (BOOL)setValue:(NSObject *)value forName:(NSString *)name onFile:(NSString *)filePath
{
	int err;
	const void *bytes = NULL;
	size_t length = 0;
	NSObject *tmp = nil;
	
	if ([value isKindOfClass:NSString.class]) {
		bytes = ((NSString *)value).UTF8String;
		length = ((NSString *)value).UTF8Length;
	}
	else if ([value isKindOfClass:NSData.class]) {
		bytes = ((NSData *)value).bytes;
		length = ((NSData *)value).length;
	}
	else if ([value isKindOfClass:NSDate.class]) {
		
	}
	else if ([value isKindOfClass:NSArray.class]) {
		tmp = [NSPropertyListSerialization dataFromPropertyList:value format:NSPropertyListBinaryFormat_v1_0 errorDescription:nil];
		bytes = ((NSData *)tmp).bytes;
		length = ((NSData *)tmp).length;
	}
	else if ([value isKindOfClass:NSNumber.class]) {
		tmp = ((NSNumber *)value).stringValue;
		bytes = ((NSString *)tmp).UTF8String;
		length = ((NSString *)tmp).UTF8Length;
	}
	else {
		NSLog(@"%s.. unsupported data type, %@", __PRETTY_FUNCTION__, NSStringFromClass([value class]));
		return FALSE;
	}
	
	if (0 != (err = setxattr(filePath.UTF8String, name.UTF8String, bytes, length, 0, 0))) {
		NSLog(@"%s.. failed to setxattr(%@), %s", __PRETTY_FUNCTION__, filePath, strerror(errno));
		return FALSE;
	}
	
	return TRUE;
}

/**
 *
 *
 */
+ (NSString *)getStringValueForName:(NSString *)name onFile:(NSString *)filePath
{
	ssize_t size;
	void *buffer[4096];
	
	if (0 > (size = getxattr(filePath.UTF8String, name.UTF8String, buffer, sizeof(buffer), 0, 0)) || size > sizeof(buffer)) {
		NSLog(@"%s.. failed to getxattr(%@), %s", __PRETTY_FUNCTION__, filePath, strerror(errno));
		return nil;
	}
	
	if (strlen((const char *)buffer) != size)
		return nil;
	else
		return [[NSString alloc] initWithBytes:buffer length:size encoding:NSUTF8StringEncoding];
}

/**
 *
 *
 */
+ (NSData *)getDataValueForName:(NSString *)name onFile:(NSString *)filePath
{
	ssize_t size;
	void *buffer[4096];
	
	if (0 > (size = getxattr(filePath.UTF8String, name.UTF8String, buffer, sizeof(buffer), 0, 0)) || size > sizeof(buffer)) {
		NSLog(@"%s.. failed to getxattr(%@), %s", __PRETTY_FUNCTION__, filePath, strerror(errno));
		return nil;
	}
	
	return [[NSData alloc] initWithBytes:buffer length:size];
}

/**
 *
 *
 */
+ (NSDictionary *)getAllValuesOnFile:(NSString *)filePath
{
	ssize_t size;
	char buffer[4096], *bufferPtr;
	NSMutableDictionary *attributes = [[NSMutableDictionary alloc] init];
	
	if (0 > (size = listxattr(filePath.UTF8String, buffer, sizeof(buffer), 00)) || size > sizeof(buffer)) {
		NSLog(@"%s.. failed to listxattr(%@), %s", __PRETTY_FUNCTION__, filePath, strerror(errno));
		return nil;
	}
	
	bufferPtr = buffer;
	
	for (ssize_t bufferNdx = 0; bufferNdx < size; ) {
		NSString *name = [NSString stringWithCString:bufferPtr encoding:NSUTF8StringEncoding];
		NSData *value = [self getDataValueForName:name onFile:filePath];
		unsigned long namelen = strlen(bufferPtr);
		
		if (name && value)
			attributes[name] = value;
		
		bufferPtr += namelen + 1;
		bufferNdx += namelen + 1;
	}
	
	return attributes;
}

@end
