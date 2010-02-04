//
//  iTunesFixer.h
//  iTunesFixer
//
//  Created by porneL on 16.sty.10.
//  Copyright 2010 porneL. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "iTunesLibrary.h"
#import "FindTrack.h"

typedef struct fixerProgressInfo {
	double total;
	int filesChecked, filesAdded;
	int filesMissing, filesSearched;
	int filesFound,filesUpdated;
} fixerProgressInfo;

@interface iTunesFixer : NSObject <FindTrackDelegate> {
	iTunesLibrary *library;
	
	NSUInteger filesTotal, filesAdded, filesChecked, filesMissing, filesSearched, filesFound, filesUpdated;
	
	NSOperationQueue *spotlightQueue, *queue;
	
	NSString *lastFile;
	
	BOOL isSSD, aborted;
}

-(void)abort;
-(void)notifyProgress;

-(id)initWithLibrary:(iTunesLibrary *)lib;

-(void)optimizeForSSD:(BOOL)y;

-(void)fixLibrary;
-(fixerProgressInfo)progress;
-(NSString*)lastFile;

// search delegate
-(void)foundTrack:(NSDictionary*)trackInfo atPath:(NSString*)filepath;
-(void)searchFinished;

// library update
-(void)trackUpdated:(NSNotification *)note;
@end


NSString *const iTunesFixerProgressNotification;