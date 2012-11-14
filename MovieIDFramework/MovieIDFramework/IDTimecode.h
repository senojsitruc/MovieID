//
//  IDTimecode.h
//  MovieIDFramework
//
//  Created by Curtis Jones on 2012.09.05.
//  Copyright (c) 2012 Curtis Jones. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface IDTimecode : NSObject

@property (readwrite, assign) NSUInteger hours;
@property (readwrite, assign) NSUInteger minutes;
@property (readwrite, assign) NSUInteger seconds;
@property (readwrite, assign) NSUInteger frames;
@property (readwrite, assign) NSUInteger framesPerSecond;
@property (readwrite, assign, getter=isDropFrame) BOOL dropFrame;
@property (readonly, getter=timeInterval) NSTimeInterval duration;

/**
 *
 */
+ (IDTimecode *)timecodeWithFrames:(NSUInteger)frames framerate:(NSUInteger)framerate ntsc:(BOOL)ntsc;

- (void)adjustByFrames:(NSInteger)frames;

@end
