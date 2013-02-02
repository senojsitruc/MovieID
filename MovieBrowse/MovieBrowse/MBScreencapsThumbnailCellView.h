//
//  MBScreencapsThumbnailView.h
//  MovieBrowse
//
//  Created by Curtis Jones on 2012.12.16.
//  Copyright (c) 2012 Curtis Jones. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface MBScreencapsThumbnailCellView : NSTableCellView

@property (readwrite, assign, nonatomic) BOOL loading;
@property (readwrite, strong, nonatomic) NSString *timestamp;
@property (readwrite, copy, nonatomic) NSImage* (^loadImage)();

@end
