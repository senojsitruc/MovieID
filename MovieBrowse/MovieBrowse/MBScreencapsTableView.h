//
//  MBScreencapsTableView.h
//  MovieBrowse
//
//  Created by Curtis Jones on 2013.02.01.
//  Copyright (c) 2013 Curtis Jones. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface MBScreencapsTableView : NSTableView

@property (readonly) NSEvent *lastMouseDownEvent;
@property (readonly) NSUInteger lastMouseDownFlags;
@property (readwrite, assign, nonatomic) NSIndexSet *selectionIndexes;

@end
