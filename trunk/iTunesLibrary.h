//
//  iTunesLibrary.h
//  iTunesFixer
//
//  Created by porneL on 17.sty.10.
//  Copyright 2010 porneL. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "iTunes.h"

@interface iTunesLibrary : NSObject {
	NSString *path;
	
	iTunesApplication *iTunes;
	iTunesLibraryPlaylist *library;
	
	NSOperationQueue *libraryQueue;	
}


-(void)abort;
-(NSString*)libraryPath;

-(id)initWithPath:(NSString*)path;

-(NSDictionary*)tracksDictionary;

/*! thread-safe */
-(void)setPath:(NSString*)path ofTrack:(NSDictionary*)trackInfo;

-(void)waitForUpdates;

// private
-(iTunesFileTrack *)fileTrackForDictionary:(NSDictionary*)trackInfo;


@end
