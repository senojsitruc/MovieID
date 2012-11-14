//
//  MBStuff.h
//  MovieBrowse
//
//  Created by Curtis Jones on 2012.10.18.
//  Copyright (c) 2012 Curtis Jones. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MBStuff : NSObject

+ (NSString *)humanReadableDuration:(unsigned long long)duration;
+ (NSString *)humanReadableFileSize:(unsigned long long)fileSize;
+ (NSString *)humanReadableBitRate:(unsigned long long)bitRate;

@end
