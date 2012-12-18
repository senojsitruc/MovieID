//
//  NSThread+Additions.m
//  Spamass
//
//  Created by Curtis Jones on 2012.08.11.
//  Copyright (c) 2012 Curtis Jones. All rights reserved.
//

#import "NSThread+Additions.h"
#import "pthread.h"

@implementation SMThreadBlock
@end

@implementation NSThread (BlocksAdditions)

- (void)performBlock:(void (^)())block
{
	if ([[NSThread currentThread] isEqual:self])
		block();
	else
		[self performBlock:block waitUntilDone:NO];
}

- (void)performBlock:(void (^)())block waitUntilDone:(BOOL)wait
{
	[NSThread performSelector:@selector(ng_runBlock:)
									 onThread:self
								 withObject:[block copy]
							waitUntilDone:wait];
}

- (void)performAfterDelay:(NSTimeInterval)delay block:(void (^)())theBlock
{
	void (^block)() = [theBlock copy];
	[self performBlock:^{
		[NSThread performSelector:@selector(ng_runBlock:) withObject:block afterDelay:delay];
	}];
}

+ (void)ng_runBlock:(void (^)())block
{
	@autoreleasepool { block(); }
}

+ (void)performBlockInBackground:(void (^)())block
{
	[NSThread performSelectorInBackground:@selector(ng_runBlock:) withObject:[block copy]];
}

/**
 *
 *
 */
+ (NSThread *)detachNewThreadBlock:(void (^)())block
{
	NSThread *thread = [[NSThread alloc] initWithBlock:block];
	[thread start];
	return thread;
}

/**
 * Detaches and returns a new thread with the given block. You can use the returned thread object
 * to determine when the thread has finished executing, for instance. Also, we're going to set the
 * stack size of this new thread to something sane.
 */
- (id)initWithBlock:(void (^)())block
{
	SMThreadBlock *threadBlock = [[SMThreadBlock alloc] init];
	
	threadBlock->mBlock = [block copy];
	
	self = [self initWithTarget:self selector:@selector(ng_runThreadBlock:) object:threadBlock];
	
	if (self) {
		[self setStackSize:1024 * 1024 * 8];
		self.name = @"NSThread+Additions";
	}
	
	return self;
}

- (void)ng_runThreadBlock:(SMThreadBlock *)threadBlock
{
	threadBlock->mBlock();
}

@end





@implementation NSThread (NamingAdditions)

+ (void)sm_setCurrentThreadName:(NSString *)name
{
	if (name != nil)
		pthread_setname_np([name UTF8String]);
}

+ (void)sm_updateCurrentThreadName
{
	[NSThread sm_setCurrentThreadName:[[NSThread currentThread] name]];
}

@end



@implementation CZThread

- (void)main
{
	@autoreleasepool {
		[NSThread sm_updateCurrentThreadName];
		[super main];
	}
}

@end
