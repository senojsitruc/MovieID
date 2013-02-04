//
//  MBFileMetadata.h
//  MovieBrowse
//
//  Created by Curtis Jones on 2013.02.04.
//  Copyright (c) 2013 Curtis Jones. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MBFileMetadata : NSObject

+ (BOOL)setValue:(NSObject *)value forName:(NSString *)name onFile:(NSString *)filePath;
+ (NSString *)getStringValueForName:(NSString *)name onFile:(NSString *)filePath;
+ (NSData *)getDataValueForName:(NSString *)name onFile:(NSString *)filePath;
+ (NSDictionary *)getAllValuesOnFile:(NSString *)filePath;

@end
