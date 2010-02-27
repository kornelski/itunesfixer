//
//  iTunesFixer.h
//  iTunesFixer
//
//  Created by porneL on 16.sty.10.
//  Copyright 2010 porneL. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "iTunesLibrary.h"
#import "FindTrackViaSpotlight.h"
#import "pathReplacementController.h"

typedef struct fixerProgressInfo {
	double total;
	int filesChecked, filesAdded;
	int filesMissing, filesSearched;
	int filesFound,filesUpdated;

} fixerProgressInfo;

@class pathReplacementController;

@interface iTunesFixer : NSObject <FindTrackViaSpotlightDelegate> {
	iTunesLibrary *library;
	
	NSUInteger filesTotal, filesAdded, filesChecked, filesMissing, filesSearched, filesFound, filesUpdated;
	
	NSOperationQueue *fixDeadTracksQueue, *queue;
	
	NSString *lastFile;
	
	BOOL isSSD, aborted;
   pathReplacementController * prc;
   NSMutableDictionary * lostFiles;
   NSMutableDictionary * foundFiles;
   BOOL spotlightSearch;
   BOOL pathReplacement;

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
@property (assign) BOOL spotlightSearch;
@property (assign) BOOL pathReplacement;
@property (retain) NSMutableDictionary * lostFiles;
@property (retain) NSMutableDictionary *  foundFiles;
-(void)didNotFindTrackViaSpotlight:(NSDictionary*)trackInfo atPath:(NSString*)filepath;
-(void) pathReplacementSelectionFinished;
- (void) cancelledPathReplacement;


// library update
-(void)trackUpdated:(NSNotification *)note;
@end


NSString *const iTunesFixerProgressNotification;