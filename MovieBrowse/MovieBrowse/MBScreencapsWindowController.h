//
//  MBScreencapsWindowController.h
//  MovieBrowse
//
//  Created by Curtis Jones on 2012.12.16.
//  Copyright (c) 2012 Curtis Jones. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class MBMovie;
@class MBScreencapsThumbnailView;

@interface MBScreencapsWindowController : NSWindowController

// row 0
@property (readwrite, assign, nonatomic) IBOutlet MBScreencapsThumbnailView *thumbnailRow0Col0;
@property (readwrite, assign, nonatomic) IBOutlet MBScreencapsThumbnailView *thumbnailRow0Col1;
@property (readwrite, assign, nonatomic) IBOutlet MBScreencapsThumbnailView *thumbnailRow0Col2;
@property (readwrite, assign, nonatomic) IBOutlet MBScreencapsThumbnailView *thumbnailRow0Col3;

// row 1
@property (readwrite, assign, nonatomic) IBOutlet MBScreencapsThumbnailView *thumbnailRow1Col0;
@property (readwrite, assign, nonatomic) IBOutlet MBScreencapsThumbnailView *thumbnailRow1Col1;
@property (readwrite, assign, nonatomic) IBOutlet MBScreencapsThumbnailView *thumbnailRow1Col2;
@property (readwrite, assign, nonatomic) IBOutlet MBScreencapsThumbnailView *thumbnailRow1Col3;

// row 2
@property (readwrite, assign, nonatomic) IBOutlet MBScreencapsThumbnailView *thumbnailRow2Col0;
@property (readwrite, assign, nonatomic) IBOutlet MBScreencapsThumbnailView *thumbnailRow2Col1;
@property (readwrite, assign, nonatomic) IBOutlet MBScreencapsThumbnailView *thumbnailRow2Col2;
@property (readwrite, assign, nonatomic) IBOutlet MBScreencapsThumbnailView *thumbnailRow2Col3;

// row 3
@property (readwrite, assign, nonatomic) IBOutlet MBScreencapsThumbnailView *thumbnailRow3Col0;
@property (readwrite, assign, nonatomic) IBOutlet MBScreencapsThumbnailView *thumbnailRow3Col1;
@property (readwrite, assign, nonatomic) IBOutlet MBScreencapsThumbnailView *thumbnailRow3Col2;
@property (readwrite, assign, nonatomic) IBOutlet MBScreencapsThumbnailView *thumbnailRow3Col3;

// controls
@property (readwrite, assign, nonatomic) IBOutlet NSButton *prevBtn;
@property (readwrite, assign, nonatomic) IBOutlet NSButton *nextBtn;
@property (readwrite, assign, nonatomic) IBOutlet NSButton *closeBtn;

// other
@property (readwrite, assign, nonatomic) IBOutlet NSTextField *infoTxt;
@property (readwrite, strong, nonatomic) MBMovie *movie;

/**
 * Show / hide
 */
- (void)showInWindow:(NSWindow *)parentWindow forMovie:(MBMovie *)movie;
- (void)hide;

@end
