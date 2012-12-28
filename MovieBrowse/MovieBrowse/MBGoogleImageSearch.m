//
//  MBGoogleImageSearch.m
//  MovieBrowse
//
//  Created by Curtis Jones on 2012.12.28.
//  Copyright (c) 2012 Curtis Jones. All rights reserved.
//

#import "MBGoogleImageSearch.h"

@implementation MBGoogleImageSearch

/**
 * https://developers.google.com/image-search/v1/jsondevguide
 * http://stackoverflow.com/questions/10404033/how-to-get-result-of-searching-google-images-in-json
 * https://ajax.googleapis.com/ajax/services/search/images?v=1.0&imgsz=large|xlarge&safe=off&start=0&q=we+own+the+night+poster
 *
 * {"responseData": {
 *   "results":[
 *     {"GsearchResultClass":"GimageSearch","width":"503","height":"755","imageId":"ANd9GcQurmwUG9HzWHU9Dxr35DlXQfIH7Kf99LFecRG-VLV3MZx9ZN7TsYEFJmg","tbWidth":"95","tbHeight":"142","unescapedUrl":"http://www.impawards.com/2007/posters/we_own_the_night_ver2.jpg","url":"http://www.impawards.com/2007/posters/we_own_the_night_ver2.jpg","visibleUrl":"www.impawards.com","title":"\u003cb\u003eWe Own\u003c/b\u003e the \u003cb\u003eNight\u003c/b\u003e Movie \u003cb\u003ePoster\u003c/b\u003e #2 - Internet Movie \u003cb\u003ePoster\u003c/b\u003e Awards \u003cb\u003e...\u003c/b\u003e","titleNoFormatting":"We Own the Night Movie Poster #2 - Internet Movie Poster Awards ...","originalContextUrl":"http://www.impawards.com/2007/we_own_the_night_ver2.html","content":"\u003cb\u003eWe Own\u003c/b\u003e the \u003cb\u003eNight Poster\u003c/b\u003e #2","contentNoFormatting":"We Own the Night Poster #2","tbUrl":"http://t1.gstatic.com/images?q\u003dtbn:ANd9GcQurmwUG9HzWHU9Dxr35DlXQfIH7Kf99LFecRG-VLV3MZx9ZN7TsYEFJmg"},
 *     {"GsearchResultClass":"GimageSearch","width":"600","height":"892","imageId":"ANd9GcSlwSHa32qrqoTwzEJfvmLZnF0HvrmZsmjlbMe-8SsnSMvhCxmvSaOmv4EF","tbWidth":"98","tbHeight":"146","unescapedUrl":"http://www.craigerscinemacorner.com/Images/we-own-the-night-poster.jpg","url":"http://www.craigerscinemacorner.com/Images/we-own-the-night-poster.jpg","visibleUrl":"www.craigerscinemacorner.com","title":"\u003cb\u003eWE OWN\u003c/b\u003e THE \u003cb\u003eNIGHT\u003c/b\u003e","titleNoFormatting":"WE OWN THE NIGHT","originalContextUrl":"http://www.craigerscinemacorner.com/Reviews/we_own_the_night.htm","content":"\u003cb\u003eWE OWN\u003c/b\u003e THE \u003cb\u003eNIGHT\u003c/b\u003e,","contentNoFormatting":"WE OWN THE NIGHT,","tbUrl":"http://t3.gstatic.com/images?q\u003dtbn:ANd9GcSlwSHa32qrqoTwzEJfvmLZnF0HvrmZsmjlbMe-8SsnSMvhCxmvSaOmv4EF"},
 *     {"GsearchResultClass":"GimageSearch","width":"502","height":"755","imageId":"ANd9GcTplJ7W-pvm_giXY6aqnhKgSXT_xJLPddrNuLVjulBOwg3FK__lgDkDY5Z2","tbWidth":"94","tbHeight":"142","unescapedUrl":"http://www.impawards.com/2007/posters/we_own_the_night_ver8.jpg","url":"http://www.impawards.com/2007/posters/we_own_the_night_ver8.jpg","visibleUrl":"www.impawards.com","title":"\u003cb\u003eWe Own\u003c/b\u003e the \u003cb\u003eNight\u003c/b\u003e Movie \u003cb\u003ePoster\u003c/b\u003e #8 - Internet Movie \u003cb\u003ePoster\u003c/b\u003e Awards \u003cb\u003e...\u003c/b\u003e","titleNoFormatting":"We Own the Night Movie Poster #8 - Internet Movie Poster Awards ...","originalContextUrl":"http://www.impawards.com/2007/we_own_the_night_ver8.html","content":"\u003cb\u003eWe Own\u003c/b\u003e the \u003cb\u003eNight Poster\u003c/b\u003e #8","contentNoFormatting":"We Own the Night Poster #8","tbUrl":"http://t3.gstatic.com/images?q\u003dtbn:ANd9GcTplJ7W-pvm_giXY6aqnhKgSXT_xJLPddrNuLVjulBOwg3FK__lgDkDY5Z2"},
 *     {"GsearchResultClass":"GimageSearch","width":"300","height":"418","imageId":"ANd9GcSwr18qby3Pt98OKo1Ph2GxNKzj_Y8w0Owy1X8KIJtRg1A7xrtCrnZORw","tbWidth":"90","tbHeight":"125","unescapedUrl":"http://www.movieposterdb.com/posters/07_12/2007/498399/l_498399_03d8ac4f.jpg","url":"http://www.movieposterdb.com/posters/07_12/2007/498399/l_498399_03d8ac4f.jpg","visibleUrl":"www.movieposterdb.com","title":"All \u003cb\u003eposters\u003c/b\u003e for \u003cb\u003eWe Own\u003c/b\u003e the \u003cb\u003eNight\u003c/b\u003e","titleNoFormatting":"All posters for We Own the Night","originalContextUrl":"http://www.movieposterdb.com/movie/0498399/We-Own-the-Night.html","content":"\u003cb\u003eWe Own\u003c/b\u003e the \u003cb\u003eNight\u003c/b\u003e Unset","contentNoFormatting":"We Own the Night Unset","tbUrl":"http://t2.gstatic.com/images?q\u003dtbn:ANd9GcSwr18qby3Pt98OKo1Ph2GxNKzj_Y8w0Owy1X8KIJtRg1A7xrtCrnZORw"}
 *   ],
 *   "cursor":{
 *     "resultCount":"72,300,000",
 *     "pages":[
 *       {"start":"0","label":1},
 *       {"start":"4","label":2},
 *       {"start":"8","label":3},
 *       {"start":"12","label":4},
 *       {"start":"16","label":5},
 *       {"start":"20","label":6},
 *       {"start":"24","label":7},
 *       {"start":"28","label":8}
 *     ],
 *     "estimatedResultCount":"72300000",
 *     "currentPageIndex":0,
 *     "moreResultsUrl":"http://www.google.com/images?oe\u003dutf8\u0026ie\u003dutf8\u0026source\u003duds\u0026start\u003d0\u0026safe\u003doff\u0026imgsz\u003dlarge%7Cxlarge\u0026hl\u003den\u0026q\u003dwe+own+the+night+poster",
 *     "searchResultTime":"0.24"
 *   }
 * },
 * "responseDetails": null, 
 * "responseStatus": 200}
 *
 */
- (void)imagesForQuery:(NSString *)query offset:(NSInteger)_offset count:(NSInteger)count handler:(MBGoogleImageSearchHandler)handler
{
	__block BOOL stop = FALSE;
	__block NSInteger offset = _offset;
	
	while (!stop && offset < count) {
		NSMutableString *queryStr = [[NSMutableString alloc] init];
		[queryStr appendString:@"https://ajax.googleapis.com/ajax/services/search/images?v=1.0&imgsz=large%7Cxlarge&safe=off"];
		[queryStr appendString:@"&start="];
		[queryStr appendString:@(offset).stringValue];
		[queryStr appendString:@"&q="];
		[queryStr appendString:[query stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
		
		NSLog(@"%s.. %@", __PRETTY_FUNCTION__, [NSURL URLWithString:queryStr]);
		NSData *queryData = [NSData dataWithContentsOfURL:[NSURL URLWithString:queryStr]];
		
		if (!queryData) {
			NSLog(@"%s.. failed to get data!", __PRETTY_FUNCTION__);
			return;
		}
		
		NSError *error = nil;
		NSDictionary *jsonRoot = [NSJSONSerialization JSONObjectWithData:queryData options:0 error:&error];
		
		if (!jsonRoot) {
			NSLog(@"%s.. failed to parse json, %@", __PRETTY_FUNCTION__, error.localizedDescription);
			return;
		}
		
		NSDictionary *responseData = jsonRoot[@"responseData"];
		
		if (![responseData isKindOfClass:NSDictionary.class]) {
			NSLog(@"%s.. invalid responseData, %@", __PRETTY_FUNCTION__, NSStringFromClass(responseData.class));
			return;
		}
		
		NSArray *results = responseData[@"results"];
		
		if (![results isKindOfClass:NSArray.class]) {
			NSLog(@"%s.. invalid results, %@", __PRETTY_FUNCTION__, NSStringFromClass(results.class));
			return;
		}
		
		if (!results.count)
			break;
		
		[results enumerateObjectsUsingBlock:^ (id resultObj, NSUInteger resultNdx, BOOL *resultStop) {
			NSDictionary *result = resultObj;
			
			if (![resultObj isKindOfClass:NSDictionary.class]) {
				*resultStop = TRUE;
				return;
			}
			
			NSString *resultUrl = result[@"unescapedUrl"];
			NSNumber *width = result[@"width"];
			NSNumber *height = result[@"height"];
			
			handler([NSURL URLWithString:resultUrl], width.integerValue, height.integerValue, resultStop);
			
			if (*resultStop)
				stop = TRUE;
			
			offset += 1;
		}];
	}
}

@end
