//
//  NSMutableArray+Additions.h
//  mosaic
//
//  Created by Curtis Jones on 2012.07.23.
//  Copyright (c) 2012 Kenzie Lane Services. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSMutableArray (Additions)
- (void)shuffle;
- (id)randomObject;
- (id)firstObject;
- (void)removeFirstObject;
@end
