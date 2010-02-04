//
//  UpdateTrack.m
//  iTunesFixer
//
//  Created by porneL on 17.sty.10.
//  Copyright 2010 porneL. All rights reserved.
//

#import "UpdateTrack.h"

NSString *const TrackUpdatedNotification = @"TrackUpdated";

@implementation UpdateTrack

-(id)initWithLibrary:(iTunesLibrary *)alibrary dictionary:(NSDictionary*)atrackInfo path:(NSString*)apath;
{
	self = [super init];
	if (self != nil) {
		url = [NSURL fileURLWithPath:apath];
		library = alibrary;
		trackInfo = atrackInfo;
 	}
	return self;
}


-(void)main {
	iTunesFileTrack *track = [library fileTrackForDictionary:trackInfo];
	
	if (track && ![track location])
	{
		[track setLocation:url];
		NSLog(@"Changed location of %@ to %@",[track name], [track location]);
	}
	
	//NSLog(@"Posting notification");
	[[NSNotificationCenter defaultCenter] postNotificationName:TrackUpdatedNotification object:library userInfo:trackInfo];
}
@end
