//
//  NSProgress.h
//  MovieBrowse
//
//  Created by Curtis Jones on 2013.02.04.
//  Copyright (c) 2013 Curtis Jones. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSProgress : NSObject

- (id)initWithParent:(id)parent userInfo:(NSDictionary*)info;

@property(copy) NSString *kind;

- (void)unpublish;
- (void)publish;

- (void)setUserInfoObject:(id)object forKey:(NSString*)key;
- (NSDictionary*)userInfo;

@property(readonly) double fractionCompleted;

// Set the totalUnitCount to -1 to be indeterminate. The dock shows a non-
// filling progress bar; the Finder is lame and draws its progress bar off the
// right side.
@property(readonly, getter=isIndeterminate) BOOL indeterminate;
@property long long completedUnitCount;
@property long long totalUnitCount;

// Pausing appears to be unimplemented in 10.8.0.
- (void)pause;
@property(readonly, getter=isPaused) BOOL paused;
@property(getter=isPausable) BOOL pausable;
- (void)setPausingHandler:(id)blockOfUnknownSignature;

- (void)cancel;
@property(readonly, getter=isCancelled) BOOL cancelled;
@property(getter=isCancellable) BOOL cancellable;
- (void)setCancellationHandler:(void (^)())block;

// Allows other applications to provide feedback as to whether the progress is
// visible in that app.
// com.apple.dock => BOOL indicating whether the progress bar was visible in the
//                   dock or not (depending whether the download target folder
//                   is in the dock) at the beginning of the download. Note that
//                   if the download target folder is added or removed from the
//                   dock during the duration of the download, no callback will
//                   happen.
// com.apple.Finder => always YES, no matter whether the download target
//                     folder's window is open.
- (void)handleAcknowledgementByAppWithBundleIdentifier:(NSString*)bundle usingBlock:(void (^)(BOOL success))block;

@end
