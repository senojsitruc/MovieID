//
//  MBGenreCellView.h
//  MovieBrowse
//
//  Created by Curtis Jones on 2012.12.15.
//  Copyright (c) 2012 Curtis Jones. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class MBGenreBadgeView;

@interface MBGenreCellView : NSTableCellView

@property (assign) IBOutlet MBGenreBadgeView *badgeView;

@end
