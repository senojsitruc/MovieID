//
//  MBPopUpButtonCell.h
//  MovieBrowse
//
//  Created by Curtis Jones on 2012.10.22.
//  Copyright (c) 2012 Curtis Jones. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface MBPopUpButtonCell : NSCell

@property (readwrite, strong) NSMenu *menu;
@property (readwrite, strong) NSString *label;

@end
