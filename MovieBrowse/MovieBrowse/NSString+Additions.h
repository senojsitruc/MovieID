//
//  NSString+Additions.h
//  Spamass
//
//  Created by Curtis Jones on 2012.08.07.
//  Copyright (c) 2012 Curtis Jones. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (Additions)

@property (readonly, getter=UTF8Length) NSUInteger UTF8Length;

+ (id)randomStringOfLength:(NSUInteger)length;

- (NSUInteger)UTF8Length;

@end
