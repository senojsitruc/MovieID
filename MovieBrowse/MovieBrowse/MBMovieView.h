//
//  MBMovieView.h
//  MovieBrowse
//
//  Created by Curtis Jones on 2012.09.09.
//  Copyright (c) 2012 Curtis Jones. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface MBMovieView : NSView

@property (assign) IBOutlet NSImageView *image;
@property (assign) IBOutlet NSTextField *title;
@property (assign) IBOutlet NSTextField *info;
@property (assign) IBOutlet NSTextField *path;

@end
