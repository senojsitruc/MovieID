//
//  IDMediaInfo.m
//  MovieIDFramework
//
//  Created by Curtis Jones on 2012.09.05.
//  Copyright (c) 2012 Curtis Jones. All rights reserved.
//

#import "IDMediaInfo.h"
#import "IDTimecode.h"
#import <QTKit/QTKit.h>

@interface IDMediaInfo ()

/*
{
	NSArray *mFilePaths;
	IDTimecode *mTimecode;
}
*/

@property (readwrite, strong) NSMutableArray *cast;
@property (readwrite, strong) NSMutableArray *genres;
@end

@implementation IDMediaInfo

/**
 *
 *
 */
- (id)initWithFilePath:(NSString *)filePath
{
	self = [super init];
	
	if (self) {
		NSDictionary *attrs = [[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:nil];
		
		self.filePath = filePath;
		self.fileSize = @(attrs.fileSize);
		self.mtime = attrs.fileModificationDate;
		
		if (FALSE == [self getQTInfo])
			return nil;
	}
	
	return self;
}

/**
 *
 *
 */
- (BOOL)getQTInfo
{
	BOOL ntsc;
	double timebase, fractional, integral;
	NSError *error = nil;
	QTMovie *qtmovie = [[QTMovie alloc] initWithURL:[NSURL fileURLWithPath:self.filePath] error:&error];
	
	if (!qtmovie) {
		NSLog(@"%s.. failed to QTMovie::initWithURL(%@), %@", __PRETTY_FUNCTION__, self.filePath, error.localizedDescription);
		return FALSE;
	}
	
	// get a list of all of the video tracks
	NSArray *tracks = [qtmovie tracksOfMediaType:QTMediaTypeVideo];
	
	if (tracks.count == 0) {
		NSLog(@"%s.. no video tracks [%@]", __PRETTY_FUNCTION__, self.filePath);
		return FALSE;
	}
	
	QTTrack *qttrack = [tracks objectAtIndex:0];
	QTMedia *qtmedia = [qttrack media];
	
	// get the duration and sample count from the media
	QTTime qtduration = [[qtmedia attributeForKey:QTMediaDurationAttribute] QTTimeValue];
	long samples = [[qtmedia attributeForKey:QTMediaSampleCountAttribute] longValue];
	
	// get the fraction and integral parts of the duration
	fractional = modf((double)samples / ((double)qtduration.timeValue / (double)qtduration.timeScale), &integral);
	
	if (samples == qtduration.timeValue) {
		timebase = qtduration.timeScale;
		ntsc = FALSE;
	}
	else if (0.01 > fabs(0. - fractional)) {
		timebase = integral;
		ntsc = FALSE;
	}
	else if (0.5 > fractional) {
		timebase = integral;
		ntsc = FALSE;
	}
	else {
		timebase = integral + 1.;
		ntsc = TRUE;
	}
	
	self.timecode = [IDTimecode timecodeWithFrames:samples framerate:timebase ntsc:ntsc];
	
	NSSize movieSize = ((NSValue *)qtmovie.movieAttributes[QTMovieNaturalSizeAttribute]).sizeValue;
	NSNumber *dataSize = qtmovie.movieAttributes[QTMovieDataSizeAttribute];
	
	if (movieSize.width && movieSize.height) {
		self.width = [NSNumber numberWithInteger:movieSize.width];
		self.height = [NSNumber numberWithInteger:movieSize.height];
	}
	
	if (dataSize.longLongValue && self.timecode.duration)
		self.bitrate = @(8 * (dataSize.longLongValue / self.timecode.duration));
	
	return TRUE;
}

- (NSNumber *)duration2
{
	return @((NSUInteger)self.timecode.duration);
}







/*
@synthesize filePaths = mFilePaths;
@synthesize timecode = mTimecode;

- (id)init
{
	self = [super init];
	
	if (self) {
		self.cast = [[NSMutableArray alloc] init];
		self.genres = [[NSMutableArray alloc] init];
	}
	
	return self;
}
*/

/**
 *
 *
 */
/*
- (id)initWithFilePaths:(NSArray *)paths
{
	self = [self init];
	
	if (self) {
		mFilePaths = [NSArray arrayWithArray:paths];
		
		if (![self getQTInfo])
			NSLog(@"%s.. failed to getQTInfo()!", __PRETTY_FUNCTION__);
	}
	
	return self;
}
*/

/**
 *
 *
 */
/*
- (BOOL)getQTInfo
{
	__block BOOL success = TRUE;
	
	[mFilePaths enumerateObjectsUsingBlock:^ (id obj1, NSUInteger ndx1, BOOL *stop1) {
		BOOL ntsc;
		double timebase, fractional, integral;
		NSError *error = nil;
		NSString *filePath = (NSString *)obj1;
		QTMovie *qtmovie = [[QTMovie alloc] initWithURL:[NSURL fileURLWithPath:filePath] error:&error];
		
		if (!qtmovie) {
			if (error)
				NSLog(@"%s.. failed to QTMovie::initWithURL(%@), %@", __PRETTY_FUNCTION__, filePath, error.localizedDescription);
			
			success = FALSE;
			*stop1 = TRUE;
			return;
		}
		
		// get a list of all of the video tracks
		NSArray *tracks = [qtmovie tracksOfMediaType:QTMediaTypeVideo];
		
		if (tracks.count == 0) {
			NSLog(@"%s.. no video tracks [%@]", __PRETTY_FUNCTION__, filePath);
			success = FALSE;
			*stop1 = TRUE;
			return;
		}
		
		QTTrack *qttrack = [tracks objectAtIndex:0];
		QTMedia *qtmedia = [qttrack media];
		
		// get the duration and sample count from the media
		QTTime qtduration = [[qtmedia attributeForKey:QTMediaDurationAttribute] QTTimeValue];
		long samples = [[qtmedia attributeForKey:QTMediaSampleCountAttribute] longValue];
		
		// get the fraction and integral parts of the duration
		fractional = modf((double)samples / ((double)qtduration.timeValue / (double)qtduration.timeScale), &integral);
		
		if (samples == qtduration.timeValue) {
			timebase = qtduration.timeScale;
			ntsc = FALSE;
		}
		else if (0.01 > fabs(0. - fractional)) {
			timebase = integral;
			ntsc = FALSE;
		}
		else if (0.5 > fractional) {
			timebase = integral;
			ntsc = FALSE;
		}
		else {
			timebase = integral + 1.;
			ntsc = TRUE;
		}
		
		IDTimecode *idtimecode = [IDTimecode timecodeWithFrames:samples framerate:timebase ntsc:ntsc];
		
		// XXX: this won't work if the framerates differ between files
		if (!mTimecode)
			mTimecode = idtimecode;
		else
			[mTimecode adjustByFrames:idtimecode.frames];
		
		NSSize movieSize = ((NSValue *)qtmovie.movieAttributes[QTMovieNaturalSizeAttribute]).sizeValue;
		NSNumber *dataSize = qtmovie.movieAttributes[QTMovieDataSizeAttribute];
		
		if (movieSize.width && movieSize.height) {
			self.width = [NSNumber numberWithInteger:movieSize.width];
			self.height = [NSNumber numberWithInteger:movieSize.height];
		}
		
		if (dataSize.longLongValue && mTimecode.duration)
			self.bitrate = [NSNumber numberWithInteger:(8 * (dataSize.longLongValue / mTimecode.duration))];
	}];
	
	return success;
}
*/

@end
