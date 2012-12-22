//
//  MBRenameWindowController.h
//  MovieBrowse
//
//  Created by Curtis Jones on 2012.12.22.
//  Copyright (c) 2012 Curtis Jones. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface MBRenameWindowController : NSWindowController

@property (readwrite, assign, nonatomic) IBOutlet NSTextField *renameTxt;

/**
 *
 */
- (void)showInWindow:(NSWindow *)parentWindow withName:(NSString *)name handler:(void (^)(NSString *))handler;

@end
