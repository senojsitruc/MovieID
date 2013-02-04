//
//  MBURLConnection.m
//  MovieBrowse
//
//  Created by Curtis Jones on 2013.02.03.
//  Copyright (c) 2013 Curtis Jones. All rights reserved.
//

#import "MBURLConnection.h"
#import "NSString+Additions.h"

@interface MBURLConnection ()
{
	MBURLConnectionDataHandler mDataHandler;
	MBURLConnectionProgressHandler mProgressHandler;
	NSHTTPURLResponse *mResponse;
	NSMutableData *mData;
	BOOL mDone;
}
@property (readwrite, assign, nonatomic) long long contentLength;
@property (readwrite, assign, nonatomic) NSString *fileName;
@property (readwrite, assign, nonatomic) NSString *mimeType;
@property (readwrite, assign, nonatomic) NSString *textEncoding;
@property (readwrite, assign, nonatomic) NSURL *url;
@end

@implementation MBURLConnection

/**
 *
 *
 */
- (id)initWithRequest:(NSURLRequest *)request progressHandler:(MBURLConnectionProgressHandler)progressHandler dataHandler:(MBURLConnectionDataHandler)dataHandler
{
	self = [super initWithRequest:request delegate:self startImmediately:FALSE];
	
	if (self) {
		mDone = FALSE;
		mDataHandler = [dataHandler copy];
		mProgressHandler = [progressHandler copy];
	}
	
	return self;
}





#pragma mark - Other

/**
 *
 *
 */
- (void)runInBackground:(BOOL)background
{
	if (background) {
		[self scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
		[self start];
	}
	else {
		NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
		NSDate *date = [NSDate distantFuture];
		
		[self scheduleInRunLoop:runLoop forMode:@"WSURLConnection"];
		[self start];
		
		while (!mDone && [runLoop runMode:@"WSURLConnection" beforeDate:date])
			;
	}
}





#pragma mark - NSURLConnectionDelegate

/**
 * Sent to determine whether the delegate is able to respond to a protection space’s form of
 * authentication.
 *
 */
- (BOOL)connection:(NSURLConnection *)connection canAuthenticateAgainstProtectionSpace:(NSURLProtectionSpace *)protectionSpace
{
  return [protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust];
}

/**
 * Sent when a connection cancels an authentication challenge.
 *
 */
/*
 - (void)connection:(NSURLConnection *)connection didCancelAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
 {
 
 }
 */

/**
 * Sent when a connection fails to load its request successfully.
 *
 */
/*
 - (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
 {
 mStateHandler(WFURLConnectionFailed);
 }
 */

/**
 * Sent when a connection must authenticate a challenge in order to download its request.
 *
 */
/*
 - (void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
 {
 
 }
 */

/**
 * Tells the delegate that the connection will send a request for an authentication challenge.
 *
 */
- (void)connection:(NSURLConnection *)connection willSendRequestForAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{
	if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust])
//if ([trustedHosts containsObject:challenge.protectionSpace.host])
		[challenge.sender useCredential:[NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust] forAuthenticationChallenge:challenge];
	
	[challenge.sender continueWithoutCredentialForAuthenticationChallenge:challenge];
}

/**
 * Sent to determine whether the URL loader should consult the credential storage for authenticating
 * the connection.
 *
 */
/*
 - (BOOL)connectionShouldUseCredentialStorage:(NSURLConnection *)connection
 {
 
 }
 */

/**
 * connectionDidFinishLoading: is called when all connection processing has completed successfully,
 * before the delegate is released by the connection.
 *
 */
- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
	mDone = TRUE;
	
	if (mProgressHandler && _contentLength)
		mProgressHandler(mData.length, _contentLength, _fileName, _mimeType, _textEncoding, _url, nil);
	
	if (mResponse) {
		if (mDataHandler)
			mDataHandler(@(mResponse.statusCode), [mResponse allHeaderFields], mData);
		mResponse = nil;
		mData = nil;
	}
}





#pragma mark - NSURLConnectionDataDelegate

/**
 * connection:willSendRequest:redirectResponse: is called whenever a connection determines that it
 * must change URLs in order to continue loading a request. This gives the delegate an opportunity
 * inspect and if necessary modify a request. A delegate can cause the request to abort by either
 * calling the connections -cancel method, or by returning nil from this callback.
 *
 * There is one subtle difference which results from this choice. If -cancel is called in the
 * delegate method, all processing for the connection stops, and no further delegate callbacks will
 * be sent. If the delegate returns nil, the connection will continue to process, and this has
 * special relevance in the case where the redirectResponse argument is non-nil. In this case, any
 * data that is loaded for the connection will be sent to the delegate, and the delegate will
 * receive a finished or failure delegate callback as appropriate.
 *
 */
- (NSURLRequest *)connection:(NSURLConnection *)connection willSendRequest:(NSURLRequest *)request redirectResponse:(NSURLResponse *)response
{
	if (response) {
		if (mDataHandler)
			mDataHandler(@(((NSHTTPURLResponse *)response).statusCode), [(NSHTTPURLResponse *)response allHeaderFields], [NSData data]);
		
		[connection cancel];
		
		return nil;
	}
	else
		return request;
}

/**
 * connection:didReceiveResponse: is called when enough data has been read to construct an
 * NSURLResponse object. In the event of a protocol which may return multiple responses (such as
 * HTTP multipart/x-mixed-replace) the delegate should be prepared to inspect the new response and
 * make itself ready for data callbacks as appropriate.
 *
 */
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
	// copy the basic response data into this class so that we can use them later
	_contentLength = response.expectedContentLength;
	_fileName = response.suggestedFilename;
	_mimeType = response.MIMEType;
	_textEncoding = response.textEncodingName;
	_url = response.URL;
	
	if (mProgressHandler)
		mProgressHandler(0, _contentLength, _fileName, _mimeType, _textEncoding, _url, nil);
	
	if ([response isKindOfClass:NSHTTPURLResponse.class]) {
		if (mResponse) {
			if (mDataHandler)
				mDataHandler(@(((NSHTTPURLResponse *)response).statusCode), [mResponse allHeaderFields], mData);
			mResponse = nil;
			mData = nil;
		}
		
		mResponse = (NSHTTPURLResponse *)response;
		mData = [[NSMutableData alloc] init];
	}
}

/**
 * connection:didReceiveData: is called with a single immutable NSData object to the delegate,
 * representing the next portion of the data loaded from the connection. This is the only guaranteed
 * for the delegate to receive the data from the resource load.
 *
 */
- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
	[mData appendData:data];
	
	//NSLog(@"%s.. %llu", __PRETTY_FUNCTION__, mResponse.expectedContentLength);
	
	if (mProgressHandler && _contentLength)
		mProgressHandler(mData.length, _contentLength, _fileName, _mimeType, _textEncoding, _url, data);
}

/**
 * connection:needNewBodyStream: is called when the loader must retransmit a requests payload, due
 * to connection errors or authentication challenges. Delegates should construct a new unopened and
 * autoreleased NSInputStream. If not implemented, the loader will be required to spool the bytes to
 * be uploaded to disk, a potentially expensive operation. Returning nil will cancel the connection.
 *
 */
/*
 - (NSInputStream *)connection:(NSURLConnection *)connection needNewBodyStream:(NSURLRequest *)request
 {
 NSLog(@"%s..", __PRETTY_FUNCTION__);
 }
 */

/**
 * connection:didSendBodyData:totalBytesWritten:totalBytesExpectedToWrite: is called during an
 * upload operation to provide progress feedback. Note that the values may change in unexpected ways
 * if the request needs to be retransmitted.
 *
 */
/*
 - (void)connection:(NSURLConnection *)connection didSendBodyData:(NSInteger)bytesWritten totalBytesWritten:(NSInteger)totalBytesWritten totalBytesExpectedToWrite:(NSInteger)totalBytesExpectedToWrite
 {
 
 }
 */

/**
 * connection:willCacheResponse: gives the delegate an opportunity to inspect and modify the
 * NSCachedURLResponse which will be cached by the loader if caching is enabled for the original
 * NSURLRequest. Returning nil from this delegate will prevent the resource from being cached. Note
 * that the -data method of the cached response may return an autoreleased in-memory copy of the
 * true data, and should not be used as an alternative to receiving and accumulating the data
 * through connection:didReceiveData:
 *
 */
- (NSCachedURLResponse *)connection:(NSURLConnection *)connection willCacheResponse:(NSCachedURLResponse *)cachedResponse
{
	return nil;
}

@end
