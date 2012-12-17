//
//  MBMovieCastView.h
//  MovieBrowse
//
//  Created by Curtis Jones on 2012.10.17.
//  Copyright (c) 2012 Curtis Jones. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class MBMovie;

@interface MBMovieCastView : NSView

@property (readwrite, assign, nonatomic, setter=setMovie:) MBMovie *movie;

@end
