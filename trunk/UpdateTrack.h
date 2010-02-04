//
//  UpdateTrack.h
//  iTunesFixer
//
//  Created by porneL on 17.sty.10.
//  Copyright 2010 porneL. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "iTunesLibrary.h"

@interface UpdateTrack : NSOperation {
	iTunesLibrary *library;
	NSDictionary *trackInfo;
    NSURL*url;
}


-(id)initWithLibrary:(iTunesLibrary *)library dictionary:(NSDictionary*)trackInfo path:(NSString*)path;

@end


NSString *const TrackUpdatedNotification;