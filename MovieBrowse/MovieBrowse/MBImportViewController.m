//
//  MBImportViewController.m
//  MovieBrowse
//
//  Created by Curtis Jones on 2012.10.24.
//  Copyright (c) 2012 Curtis Jones. All rights reserved.
//

#import "MBImportViewController.h"
#import "MBStuff.h"
#import "MBAppDelegate.h"
#import "MBDataManager.h"
#import "NSThread+Additions.h"
#import <MovieID/IDMediaInfo.h>
#import <MovieID/IDMovie.h>
#import <MovieID/IDSearch.h>
#import <MovieID/IDTimecode.h>

@interface MBImportViewController ()
{
	NSMutableArray *mMovies;
	NSInteger mCurrentMovieNdx;
	
	NSString *mDirPath;
	NSNumber *mRuntime;
	NSNumber *mFilesize;
	NSNumber *mBitrate;
	NSNumber *mWidth;
	NSNumber *mHeight;
	NSDate *mModtime;
	
	dispatch_queue_t mImportQueue;
}
@end

@implementation MBImportViewController

/**
 *
 *
 */
- (void)awakeFromNib
{
	mImportQueue = dispatch_queue_create("import-queue", DISPATCH_QUEUE_SERIAL);
	
	[self.prevBtn setEnabled:FALSE];
	[self.nextBtn setEnabled:FALSE];
	[self.applyBtn setEnabled:FALSE];
	
	self.resultsArray = [[NSMutableArray alloc] init];
	[self.resultsController setSortDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"title" ascending:TRUE]]];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(doNotificationResultSelectionChanged:) name:NSTableViewSelectionDidChangeNotification object:self.searchResultTbl];
}

/**
 *
 *
 */
- (void)scanSource:(NSString *)dirPath
{
	mCurrentMovieNdx = -1;
	mMovies = [[NSMutableArray alloc] init];
	
	[self findMissingMovies];
	[self doActionNext:nil];
}

/**
 *
 *
 */
- (void)findMissingMovies
{
	[mMovies setArray:[[MBAppDelegate sharedInstance].dataManager findMissingMovies]];
	NSMutableIndexSet *indexes = [NSMutableIndexSet indexSet];
	
	[mMovies enumerateObjectsUsingBlock:^ (id movie, NSUInteger movieNdx, BOOL *movieStop) {
		NSNumber *year = [IDSearch yearForName:[(NSString *)movie lastPathComponent]];
		
		if (!year.integerValue)
			[indexes addIndex:movieNdx];
	}];
	
	[mMovies removeObjectsAtIndexes:indexes];
	
	[mMovies setArray:[mMovies sortedArrayUsingComparator:^ NSComparisonResult (id obj1, id obj2) {
		return [(NSString *)obj1 compare:obj2];
	}]];
}

/**
 *
 *
 */
- (void)showMovie
{
	[self.resultsController removeObjects:self.resultsArray];
	[self.applyBtn setEnabled:FALSE];
	
	if (mMovies.count <= mCurrentMovieNdx)
		return;
	
	if (mCurrentMovieNdx == 0)
		[self.prevBtn setEnabled:FALSE];
	else
		[self.prevBtn setEnabled:TRUE];
	
	if (mCurrentMovieNdx == mMovies.count - 1)
		[self.nextBtn setEnabled:FALSE];
	else
		[self.nextBtn setEnabled:TRUE];
	
	NSString *dirPath = mMovies[mCurrentMovieNdx];
	NSMutableArray *idinfos = [[NSMutableArray alloc] init];
	NSString *title = [IDSearch titleForName:[dirPath lastPathComponent]];
	NSNumber *year = [IDSearch yearForName:[dirPath lastPathComponent]];
	
	mDirPath = dirPath;
	
	[[self getMovieFilesInDir:dirPath] enumerateObjectsUsingBlock:^ (id file, NSUInteger fileNdx, BOOL *fileStop) {
		IDMediaInfo *idinfo = [[IDMediaInfo alloc] initWithFilePath:file];
		
		if (idinfo)
			[idinfos addObject:idinfo];
	}];
	
	if (idinfos.count) {
		__block NSUInteger _runtime = 0;
		__block long long _filesize = 0;
		__block NSUInteger _bitrate = 0;
		__block NSUInteger _width = 0;
		__block NSUInteger _height = 0;
		
		[idinfos enumerateObjectsUsingBlock:^ (id obj1, NSUInteger ndx1, BOOL *stop1) {
			IDMediaInfo *idinfo = (IDMediaInfo *)obj1;
			
			_runtime += idinfo.duration2.integerValue;
			_filesize += idinfo.fileSize.integerValue;
			
			if (idinfo.bitrate.integerValue > _bitrate)
				_bitrate = idinfo.bitrate.integerValue;
			
			if (idinfo.width.integerValue * idinfo.height.integerValue > _width * _height) {
				_width = idinfo.width.integerValue;
				_height = idinfo.height.integerValue;
			}
		}];
		
		mRuntime = @(_runtime);
		mFilesize = @(_filesize);
		mBitrate = @(_bitrate);
		mWidth = @(_width);
		mHeight = @(_height);
		mModtime = ((IDMediaInfo *)idinfos[0]).mtime;
	}
	else {
		mRuntime = @(0);
		mFilesize = @(0);
		mBitrate = @(0);
		mWidth = @(0);
		mHeight = @(0);
		mModtime = nil;
	}
	
	self.sourcePathTxt.stringValue = dirPath;
	self.sourceInfo1Txt.stringValue = [NSString stringWithFormat:@""];
	self.searchQueryTxt.stringValue = title;
	
	//
	// title, year, duration
	//
	{
		NSMutableString *info = [[NSMutableString alloc] init];
		
		//
		// title
		//
		[info appendString:title];
		
		//
		// year
		//
		if (year.integerValue) {
			if (info.length)
				[info appendString:@", "];
			
			[info appendString:@"Year: "];
			[info appendString:year.stringValue];
		}
		
		//
		// duration
		//
		if (mRuntime.integerValue) {
			if (info.length)
				[info appendString:@", "];
			
			NSInteger duration = mRuntime.integerValue;
			
			NSInteger hours = duration / 60 / 60;
			duration -= (hours * 60 * 60);
			
			NSInteger minutes = duration / 60;
			duration -= (minutes * 60);
			
			NSInteger seconds = duration;
			
			[info appendString:@"Runtime: "];
			
			// hours
			[info appendFormat:@"%ld", hours];
			[info appendString:@"h"];
			[info appendString:@" "];
			
			// minutes
			[info appendFormat:@"%ld", minutes];
			[info appendString:@"m"];
			[info appendString:@" "];
			
			// seconds
			[info appendFormat:@"%ld", seconds];
			[info appendString:@"s"];
		}
		
		self.sourceInfo1Txt.stringValue = info;
	}
	
	//
	// size, dim, bitrate
	//
	{
		NSMutableString *info = [[NSMutableString alloc] init];
		
		//
		// file size
		//
		if (mFilesize.longLongValue) {
			if (info.length)
				[info appendString:@", "];
			
			[info appendString:@"Size: "];
			[info appendString:[MBStuff humanReadableFileSize:mFilesize.longLongValue]];
		}
		
		//
		// movie size
		//
		if (mWidth && mHeight) {
			if (info.length)
				[info appendString:@", "];
			
			[info appendString:@"Dim: "];
			[info appendString:mWidth.stringValue];
			[info appendString:@"x"];
			[info appendString:mHeight.stringValue];
		}
		
		//
		// bitrate
		//
		if (mBitrate) {
			if (info.length)
				[info appendString:@", "];
			
			[info appendString:@"Bitrate: "];
			[info appendString:[MBStuff humanReadableBitRate:mBitrate.longLongValue]];
		}
		
		self.sourceInfo2Txt.stringValue = info;
	}
}





#pragma mark - Actions

/**
 *
 *
 */
- (IBAction)doActionAuto:(id)sender
{
	NSArray *sources = [[NSUserDefaults standardUserDefaults] arrayForKey:MBDefaultsKeySources];
	
	[sources enumerateObjectsUsingBlock:^ (id source, NSUInteger sourceNdx, BOOL *sourceStop) {
		[[MBAppDelegate sharedInstance].dataManager scanSource:((NSDictionary *)source)[MBDefaultsKeySourcesPath]];
	}];
}

/**
 *
 *
 */
- (IBAction)doActionUpdate:(id)sender
{
	[[MBAppDelegate sharedInstance].dataManager updateFileStats];
}

/**
 *
 *
 */
- (IBAction)doActionSearch:(id)sender
{
	NSString *title = self.searchQueryTxt.stringValue;
	NSString *method = self.searchMethodBtn.titleOfSelectedItem;
	NSArray *results = nil;
	
	[self.resultsController removeObjects:self.resultsArray];
	
	if (!title.length)
		return;
	
	if ([method isEqualToString:@"TMDb"])
		results = [IDSearch tmdbSearchMovieWithTitle:title andYear:nil andRuntime:nil];
	else if ([method isEqualToString:@"IMDb"])
		results = [IDSearch imdbSearchMovieWithTitle:title andYear:nil andRuntime:nil];
	
	if (results)
		[self.resultsController addObjects:results];
	
	[self.searchResultTbl reloadData];
}

/**
 *
 *
 */
- (IBAction)doActionPrev:(id)sender
{
	mCurrentMovieNdx -= 1;
	[self showMovie];
}

/**
 *
 *
 */
- (IBAction)doActionNext:(id)sender
{
	mCurrentMovieNdx += 1;
	[self showMovie];
}

/**
 *
 *
 */
- (IBAction)doActionApply:(id)sender
{
	IDMovie *idmovie = _resultsArray[_searchResultTbl.selectedRow];
	
	NSString *dirPath = mDirPath;
	NSNumber *runtime = mRuntime;
	NSNumber *filesize = mFilesize;
	NSNumber *bitrate = mBitrate;
	NSNumber *width = mWidth;
	NSNumber *height = mHeight;
	NSDate *modtime = mModtime;
	
	dispatch_async(mImportQueue, ^{
		[[MBAppDelegate sharedInstance].dataManager addMovie:idmovie withDirPath:dirPath duration:runtime filesize:filesize width:width height:height bitrate:bitrate mtime:modtime];
	});
}

/**
 *
 *
 */
- (IBAction)doActionClose:(id)sender
{
	[NSApp endSheet:self.window];
	[self.window orderOut:sender];
}

/**
 *
 *
 */
- (NSArray *)getMovieFilesInDir:(NSString *)dirPath
{
	NSFileManager *fileManager = [[NSFileManager alloc] init];
	NSArray *files = [fileManager contentsOfDirectoryAtPath:dirPath error:nil];
	NSMutableArray *movieFiles = [[NSMutableArray alloc] init];
	
	[files enumerateObjectsUsingBlock:^ (id obj2, NSUInteger ndx2, BOOL *stop2) {
		NSString *file = [(NSString *)obj2 lowercaseString];
		
		if ([file hasSuffix:@".mp4"] ||
				[file hasSuffix:@".m4v"] ||
				[file hasSuffix:@".mpg"] ||
				[file hasSuffix:@".mov"] ||
				[file hasSuffix:@".wmv"] ||
				[file hasSuffix:@".avi"] ||
				[file hasSuffix:@".mkv"])
			[movieFiles addObject:[dirPath stringByAppendingPathComponent:obj2]];
	}];
	
	return movieFiles;
}

/**
 *
 *
 */
- (void)doNotificationResultSelectionChanged:(NSNotification *)notification
{
	NSArray *selectedObjects = self.resultsController.selectedObjects;
	
	if (selectedObjects.count == 0)
		[self.applyBtn setEnabled:FALSE];
	else
		[self.applyBtn setEnabled:TRUE];
}

@end
