//
//  MBScreencapsWindowController.h
//  MovieBrowse
//
//  Created by Curtis Jones on 2012.12.16.
//  Copyright (c) 2012 Curtis Jones. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class MBMovie;
@class MBScreencapsTableView;
@class MBScreencapsThumbnailCellView;

@interface MBScreencapsWindowController : NSWindowController <NSTableViewDelegate, NSTableViewDataSource>

/**
 * Grid
 */
@property (readwrite, assign, nonatomic) IBOutlet MBScreencapsTableView *tableView;
@property (readwrite, assign, nonatomic) IBOutlet NSButton *closeBtn;

/**
 * Big
 */
@property (readwrite, assign, nonatomic) IBOutlet NSPanel *bigWin;
@property (readwrite, assign, nonatomic) IBOutlet NSImageView *bigImg;
@property (readwrite, assign, nonatomic) IBOutlet NSProgressIndicator *bigPrg;

/**
 * Show / hide
 */
- (void)showInWindow:(NSWindow *)parentWindow forMovie:(MBMovie *)movie;
- (void)hide;

@end
