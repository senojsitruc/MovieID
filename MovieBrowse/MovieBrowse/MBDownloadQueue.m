//
//  MBDownloadQueue.m
//  MovieBrowse
//
//  Created by Curtis Jones on 2012.10.22.
//  Copyright (c) 2012 Curtis Jones. All rights reserved.
//

#import "MBDownloadQueue.h"

static MBDownloadQueue *gQueue;

@interface MBDownloadQueue ()
{
	NSMutableArray *mQueue;
	NSMutableArray *mWorkers;
	dispatch_queue_t mDispatch;
	dispatch_semaphore_t mSem;
}
@end

@implementation MBDownloadQueue

/**
 *
 *
 */
+ (void)load
{
	gQueue = [[MBDownloadQueue alloc] init];
}

/**
 *
 *
 */
+ (id)sharedInstance
{
	return gQueue;
}

/**
 *
 *
 */
- (id)init
{
	self = [super init];
	
	if (self) {
		mQueue = [[NSMutableArray alloc] init];
		mDispatch = dispatch_queue_create("download-queue", NULL);
		mSem = dispatch_semaphore_create(0);
		mWorkers = [[NSMutableArray alloc] init];
		
		[mWorkers addObject:[[NSThread alloc] initWithTarget:self selector:@selector(worker) object:nil]];
		[mWorkers addObject:[[NSThread alloc] initWithTarget:self selector:@selector(worker) object:nil]];
		[mWorkers addObject:[[NSThread alloc] initWithTarget:self selector:@selector(worker) object:nil]];
		[mWorkers addObject:[[NSThread alloc] initWithTarget:self selector:@selector(worker) object:nil]];
		[mWorkers addObject:[[NSThread alloc] initWithTarget:self selector:@selector(worker) object:nil]];
		
		[mWorkers enumerateObjectsUsingBlock:^ (id obj, NSUInteger ndx, BOOL *stop) { [(NSThread *)obj start]; }];
	}
	
	return self;
}

/**
 *
 *
 */
- (void)dispatchBeg:(void (^)())block
{
	dispatch_async(mDispatch, ^{
		[mQueue insertObject:block atIndex:0];
		dispatch_semaphore_signal(mSem);
	});
}

/**
 *
 *
 */
- (void)dispatchEnd:(void (^)())block
{
	dispatch_async(mDispatch, ^{
		[mQueue addObject:block];
		dispatch_semaphore_signal(mSem);
	});
}

/**
 *
 *
 */
- (void)worker
{
	while (TRUE) {
		__block void (^block)() = nil;
		
		dispatch_semaphore_wait(mSem, dispatch_time(DISPATCH_TIME_NOW,5000000000LL));
		
		dispatch_sync(mDispatch, ^{
			if (mQueue.count) {
				block = mQueue[0];
				[mQueue removeObjectAtIndex:0];
			}
		});
		
		if (block)
			block();
	}
}

@end
