//
//  MBPopUpButtonCell.h
//  MovieBrowse
//
//  Created by Curtis Jones on 2012.10.22.
//  Copyright (c) 2012 Curtis Jones. All rights reserved.
//

#import <Cocoa/Cocoa.h>

typedef void (^MBMenuWillDisplay) ();

@interface MBPopUpButtonCell : NSCell

@property (readwrite, strong, nonatomic) NSMenu *menu;
@property (readwrite, strong, nonatomic) NSString *label;
@property (readwrite, copy, nonatomic) MBMenuWillDisplay willDisplayHandler;

@end
