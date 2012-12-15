//
//  MBGenreBadgeView.m
//  MovieBrowse
//
//  Created by Curtis Jones on 2012.12.15.
//  Copyright (c) 2012 Curtis Jones. All rights reserved.
//

#import "MBGenreBadgeView.h"

@implementation MBGenreBadgeView

#define BADGE_HEIGHT            14.
#define BADGE_BACKGROUND_COLOR  [NSColor colorWithCalibratedRed:(152/255.0) green:(168/255.0) blue:(202/255.0) alpha:1]
#define BADGE_FONT              [NSFont boldSystemFontOfSize:11]

- (void)drawRect:(NSRect)dirtyRect
{
	if (!_number)
		return;
	
	NSRect frame = NSMakeRect(0, 0, self.frame.size.width, self.frame.size.height);
	NSBezierPath *badgePath = [NSBezierPath bezierPathWithRoundedRect:frame xRadius:(BADGE_HEIGHT/2.) yRadius:(BADGE_HEIGHT/2.)];
	NSColor *badgeColor = [NSColor whiteColor];
	NSColor *backgroundColor = BADGE_BACKGROUND_COLOR;
	NSDictionary *attributes = @{NSFontAttributeName:BADGE_FONT, NSForegroundColorAttributeName:badgeColor};
	NSAttributedString *badgeAttrString = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%ld", _number] attributes:attributes];
	NSSize stringSize = [badgeAttrString size];
	NSPoint badgeTextPoint = NSMakePoint(NSMidX(frame)-(stringSize.width/2.0), NSMidY(frame)-(stringSize.height/2.0));
	
	[backgroundColor set];
	[badgePath fill];
	[badgeAttrString drawAtPoint:badgeTextPoint];
}

@end
