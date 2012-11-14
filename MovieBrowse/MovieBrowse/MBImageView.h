//
//  MBImageView.h
//  MovieBrowse
//
//  Created by Curtis Jones on 2012.10.18.
//  Copyright (c) 2012 Curtis Jones. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MBImageView : NSImageView

@property (readwrite, assign) id doubleTarget;
@property (readwrite, assign) id doubleContext;
@property (readwrite, assign) SEL doubleAction;

@end
