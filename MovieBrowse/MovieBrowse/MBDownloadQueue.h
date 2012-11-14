//
//  MBDownloadQueue.h
//  MovieBrowse
//
//  Created by Curtis Jones on 2012.10.22.
//  Copyright (c) 2012 Curtis Jones. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MBDownloadQueue : NSObject

+ (id)sharedInstance;

- (void)dispatchBeg:(void (^)())block;
- (void)dispatchEnd:(void (^)())block;

@end
