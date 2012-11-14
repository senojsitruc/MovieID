//
//  NSThread+Additions.h
//  Spamass
//
//  Created by Curtis Jones on 2012.08.11.
//  Copyright (c) 2012 Curtis Jones. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SMThreadBlock : NSObject
{
@public
	void (^mBlock)();
}
@end

@interface NSThread (BlocksAdditions)
- (void)performBlock:(void (^)())block;
- (void)performBlock:(void (^)())block waitUntilDone:(BOOL)wait;
- (void)performAfterDelay:(NSTimeInterval)delay block:(void (^)())block;
+ (void)performBlockInBackground:(void (^)())block;
+ (NSThread *)detachNewThreadBlock:(void (^)())block;
- (id)initWithBlock:(void (^)())block;
@end


@interface NSThread (NamingAdditions)
+ (void)sm_setCurrentThreadName:(NSString *)name;
+ (void)sm_updateCurrentThreadName;
@end

@interface CZThread : NSThread
@end
