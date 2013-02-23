//
//  MBPopUpMenu.m
//  MovieBrowse
//
//  Created by Curtis Jones on 2/23/13.
//  Copyright (c) 2013 Curtis Jones. All rights reserved.
//

#import "MBPopUpMenu.h"
#import <objc/runtime.h>

@class MBPopUpMenuSection;

NSString * const MBPopUpMenuSectionModeAny = @"MBPopUpMenuSectionModeAny";
NSString * const MBPopUpMenuSectionModeOne = @"MBPopUpMenuSectionModeOne";





@interface MBPopUpMenuItem : NSObject
{
@public
	NSMenuItem *mMenuItem;
	MBPopUpMenuItemHandler mHandler;
	__unsafe_unretained MBPopUpMenuSection *mSection;
}
@end

@implementation MBPopUpMenuItem
@end





@interface MBPopUpMenuSection : MBPopUpMenuItem
{
@public
	NSMutableDictionary *mItems;
	NSMenuItem *mSeparator;
	NSString *mMode;
}
@end

@implementation MBPopUpMenuSection
@end





@interface MBPopUpMenu ()
{
	NSMenu *mMenu;
	NSMutableDictionary *mItems;
}
@end

@implementation MBPopUpMenu

/**
 *
 *
 */
- (id)initWithFrame:(NSRect)frame
{
	self = [super initWithFrame:frame];
	
	if (self) {
		mMenu = [[NSMenu alloc] initWithTitle:@"Default Title"];
		mItems = [[NSMutableDictionary alloc] init];
	}
	
	return self;
}

/**
 *
 *
 */
- (void)drawRect:(NSRect)dirtyRect
{
	static NSDictionary *textAttrs = nil;
	NSRect frame = self.bounds;
	
	if (!textAttrs)
		textAttrs = @{ NSFontAttributeName:[NSFont boldSystemFontOfSize:10] };
	
	[[NSColor whiteColor] setFill];
	[NSBezierPath fillRect:frame];
	
	[[NSColor blackColor] setStroke];
	NSBezierPath *path = [NSBezierPath bezierPath];
	[path moveToPoint:NSMakePoint(0, 0)];
	[path lineToPoint:NSMakePoint(frame.size.width, 0)];
	[path stroke];
	
	if (!_label)
		_label = @"";
	
	NSSize textSize = [_label sizeWithAttributes:textAttrs];
	NSRect textFrame = NSMakeRect(frame.origin.x+5, frame.origin.y+((frame.size.height-textSize.height)/2), frame.size.width-10, textSize.height);
	
	[_label drawInRect:textFrame withAttributes:textAttrs];
	
	NSImage *image = [NSImage imageNamed:@"UpDownArrow.png"];
	[image drawAtPoint:NSMakePoint(frame.origin.x+5+textSize.width+5, frame.origin.y+9) fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1];
}





#pragma mark - NSControl

- (void)mouseDown:(NSEvent *)theEvent
{
	if (_willDisplayHandler)
		_willDisplayHandler();
	
	NSEvent *event = [NSEvent mouseEventWithType:NSLeftMouseUp
																			location:self.frame.origin
																 modifierFlags:0
																		 timestamp:NSTimeIntervalSince1970
																	windowNumber:self.window.windowNumber
																			 context:nil
																	 eventNumber:0
																		clickCount:0
																			pressure:0.1];
	
	[NSMenu popUpContextMenu:mMenu withEvent:event forView:self.window.contentView];
}





#pragma mark - Accessors

/**
 *
 *
 */
- (void)setLabel:(NSString *)label
{
	_label = label;
	[self setNeedsDisplay:TRUE];
}

/**
 *
 *
 */
- (void)addSectionWithTitle:(NSString *)title mode:(NSString *)sectionMode
{
	MBPopUpMenuSection *mbMenuSection = [[MBPopUpMenuSection alloc] init];
	
	if (mItems.count)
		[mMenu addItem:(mbMenuSection->mSeparator = [NSMenuItem separatorItem])];
	
	mbMenuSection->mItems = [[NSMutableDictionary alloc] init];
	mbMenuSection->mMenuItem = [mMenu addItemWithTitle:title action:nil keyEquivalent:@""];
	mbMenuSection->mMode = sectionMode;
	
	mItems[title] = mbMenuSection;
}

/**
 *
 *
 */
- (void)removeSectionWithTitle:(NSString *)title
{
	MBPopUpMenuSection *mbMenuSection = mItems[title];
	
	if (!mbMenuSection)
		return;
	
	if (mbMenuSection->mSeparator)
		[mMenu removeItem:mbMenuSection->mSeparator];
	
	[mMenu removeItem:mbMenuSection->mMenuItem];
	
	[mbMenuSection->mItems.allValues enumerateObjectsUsingBlock:^ (MBPopUpMenuItem *mbMenuItem, NSUInteger mbMenuItemNdx, BOOL *mbMenuItemStop) {
		[mMenu removeItem:mbMenuItem->mMenuItem];
	}];
}

/**
 *
 *
 */
- (void)addItemWithTitle:(NSString *)itemTitle toSection:(NSString *)sectionTitle withHandler:(MBPopUpMenuItemHandler)handler
{
	[self addItemWithTitle:itemTitle andTag:0 toSection:sectionTitle withHandler:handler];
}

/**
 *
 *
 */
- (void)addItemWithTitle:(NSString *)itemTitle andTag:(NSInteger)tag toSection:(NSString *)sectionTitle withHandler:(MBPopUpMenuItemHandler)handler
{
	MBPopUpMenuSection *section = mItems[sectionTitle];
	MBPopUpMenuItem *item = [[MBPopUpMenuItem alloc] init];
	item->mMenuItem = [mMenu addItemWithTitle:itemTitle action:@selector(doActionMenuItem:) keyEquivalent:@""];
	item->mMenuItem.target = self;
	item->mMenuItem.tag = tag;
	item->mHandler = [handler copy];
	item->mSection = section;
	objc_setAssociatedObject(item->mMenuItem, "MBPopUpMenuItem", item, OBJC_ASSOCIATION_ASSIGN);
	section->mItems[itemTitle] = item;
}

/**
 *
 *
 */
- (void)setState:(int)state forItem:(NSString *)itemTitle inSection:(NSString *)sectionTitle
{
	MBPopUpMenuSection *mbMenuSection = mItems[sectionTitle];
	
	if (!mbMenuSection)
		return;
	
	MBPopUpMenuItem *mbMenuItem = mbMenuSection->mItems[itemTitle];
	
	if (!mbMenuItem)
		return;
	
	mbMenuItem->mMenuItem.state = state;
}





#pragma mark - Actions

/**
 * Called when a menu item is selected. The associated object is our MBPopUpMenuItem instance. This
 * instance holds the handler that we need to call, to inform someone that the menu item was
 * clicked.
 */
- (void)doActionMenuItem:(NSMenuItem *)menuItem
{
	MBPopUpMenuItem *mbMenuItem = objc_getAssociatedObject(menuItem, "MBPopUpMenuItem");
	
	if (!mbMenuItem)
		return;
	
	BOOL state = mbMenuItem->mMenuItem.state;
	MBPopUpMenuSection *mbMenuSection = mbMenuItem->mSection;
	NSString *sectionMode = mbMenuSection->mMode;
	
	if ([sectionMode isEqualToString:MBPopUpMenuSectionModeAny])
		mbMenuItem->mMenuItem.state = !state;
	
	else if ([sectionMode isEqualToString:MBPopUpMenuSectionModeOne]) {
		[mbMenuSection->mItems.allValues enumerateObjectsUsingBlock:^ (MBPopUpMenuItem *_item, NSUInteger _itemNdx, BOOL *_itemStop) {
			_item->mMenuItem.state = NSOffState;
		}];
		mbMenuItem->mMenuItem.state = !state;
	}
	
	if (mbMenuItem && mbMenuItem->mHandler)
		mbMenuItem->mHandler(mbMenuItem->mMenuItem.title, mbMenuItem->mMenuItem.tag, mbMenuItem->mMenuItem.state);
}

@end
