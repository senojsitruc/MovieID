//
//  MBActorView.h
//  MovieBrowse
//
//  Created by Curtis Jones on 2012.09.06.
//  Copyright (c) 2012 Curtis Jones. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface MBActorView : NSView

@property (readwrite, assign) BOOL selected;
@property (assign) IBOutlet NSImageView *image;
@property (assign) IBOutlet NSTextField *title;

@end
