//
//  MBActorMovieView.h
//  MovieBrowse
//
//  Created by Curtis Jones on 2012.10.20.
//  Copyright (c) 2012 Curtis Jones. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class MBPerson;

@interface MBActorMovieView : NSScrollView

@property (readwrite, assign, nonatomic, setter=setPerson:) MBPerson *person;

@end
