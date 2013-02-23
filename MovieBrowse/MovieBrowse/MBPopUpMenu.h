//
//  MBPopUpMenu.h
//  MovieBrowse
//
//  Created by Curtis Jones on 2/23/13.
//  Copyright (c) 2013 Curtis Jones. All rights reserved.
//

#import <Cocoa/Cocoa.h>

extern NSString * const MBPopUpMenuSectionModeAny;
extern NSString * const MBPopUpMenuSectionModeOne;

@interface MBPopUpMenu : NSControl

@property (readwrite, strong, nonatomic) NSString *label;
@property (readwrite, copy, nonatomic) void (^willDisplayHandler)();

typedef void (^MBPopUpMenuItemHandler) (NSString *itemTitle, NSInteger itemTag, NSInteger state);

- (void)addSectionWithTitle:(NSString *)title mode:(NSString *)sectionMode;
- (void)addItemWithTitle:(NSString *)itemTitle toSection:(NSString *)sectionTitle withHandler:(MBPopUpMenuItemHandler)handler;
- (void)addItemWithTitle:(NSString *)itemTitle andTag:(NSInteger)tag toSection:(NSString *)sectionTitle withHandler:(MBPopUpMenuItemHandler)handler;

- (void)removeSectionWithTitle:(NSString *)title;

- (void)setState:(int)state forItem:(NSString *)itemTitle inSection:(NSString *)sectionTitle;

@end
