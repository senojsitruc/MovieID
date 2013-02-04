//
//  main.m
//  MovieBrowse
//
//  Created by Curtis Jones on 2012.09.05.
//  Copyright (c) 2012 Curtis Jones. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MBFileMetadata.h"

int
main (int argc, char *argv[])
{
	srandomdev();
	
	/*
	com.apple.metadata:kMDItemDownloadedDate:
	00000000  62 70 6C 69 73 74 30 30 A1 01 33 41 B6 BF 5C 0E  |bplist00..3A....|
	00000010  29 C0 EC 08 0A 00 00 00 00 00 00 01 01 00 00 00  |)...............|
	00000020  00 00 00 00 02 00 00 00 00 00 00 00 00 00 00 00  |................|
	00000030  00 00 00 00 13                                   |.....|
	00000035
	com.apple.metadata:kMDItemWhereFroms:
	00000000  62 70 6C 69 73 74 30 30 A2 01 02 5F 10 40 68 74  |bplist00..._.@ht|
	00000010  74 70 3A 2F 2F 63 75 72 74 69 73 6A 6F 6E 65 73  |tp://curtisjones|
	00000020  2E 75 73 2F 4D 6F 76 69 65 42 72 6F 77 73 65 2F  |.us/MovieBrowse/|
	00000030  72 65 6C 65 61 73 65 73 2F 4D 6F 76 69 65 42 72  |releases/MovieBr|
	00000040  6F 77 73 65 2D 31 2E 31 2E 30 2E 7A 69 70 5F 10  |owse-1.1.0.zip_.|
	00000050  22 68 74 74 70 3A 2F 2F 63 75 72 74 69 73 6A 6F  |"http://curtisjo|
	00000060  6E 65 73 2E 75 73 2F 4D 6F 76 69 65 42 72 6F 77  |nes.us/MovieBrow|
	00000070  73 65 2F 08 0B 4E 00 00 00 00 00 00 01 01 00 00  |se/..N..........|
	00000080  00 00 00 00 00 03 00 00 00 00 00 00 00 00 00 00  |................|
	00000090  00 00 00 00 00 73                                |.....s|
	00000096
	com.apple.progress.fractionCompleted: 0.076
	com.apple.quarantine: 0000;510f248e;Safari;
	*/
	
	/*
	NSDictionary *info = [MBFileMetadata getAllValuesOnFile:@"/Users/cjones/Downloads/MovieBrowse-1.1.0.zip.download"];
	NSObject *dateInfo = [NSPropertyListSerialization propertyListFromData:info[@"com.apple.metadata:kMDItemDownloadedDate"] mutabilityOption:0 format:nil errorDescription:nil];
	NSObject *fromInfo = [NSPropertyListSerialization propertyListFromData:info[@"com.apple.metadata:kMDItemWhereFroms"] mutabilityOption:0 format:nil errorDescription:nil];
//NSObject *quarantine =
	
	NSLog(@"date = [%@] %@", NSStringFromClass(dateInfo.class), dateInfo);
	NSLog(@"from = [%@] %@", NSStringFromClass(fromInfo.class), fromInfo);
	*/
	
	return NSApplicationMain(argc, (const char **)argv);
}
