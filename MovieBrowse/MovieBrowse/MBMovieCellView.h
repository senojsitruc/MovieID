//
//  MBMovieCellView.h
//  MovieBrowse
//
//  Created by Curtis Jones on 2012.10.17.
//  Copyright (c) 2012 Curtis Jones. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class MBMovieCastView;

@interface MBMovieCellView : NSTableCellView

@property (assign) IBOutlet MBMovieCastView *castView;
@property (assign) IBOutlet NSImageView *movieImg;
@property (assign) IBOutlet NSMenuItem *hideMenuItem;

@end
