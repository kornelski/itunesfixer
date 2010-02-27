//
//  pathReplacementController.h
//  iTunesFixer
//
//  Created by Brett Park on 10-02-06.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "iTunesFixer.h"
#import "TrackFunctions.h"
#import "FindTrackViaPathReplacement.h"

@class iTunesFixer;

@interface pathReplacementController : NSWindowController <FindTrackViaPathReplacementDelegate> {
   iTunesFixer * fixer;
   NSTableView *lostFilesTableView;
   NSTableView *foundFilesTableView;   
   NSMutableDictionary * lostFiles;
   NSMutableDictionary * foundFiles;
   NSArray * lostFilesToDisplay;
   NSArray * foundFilesToDisplay;
   NSString * lastOpenLocation;
   NSTextField *status;
   NSButton *fixTracks;
   BOOL ignoreSelection;
   NSTimer *timer;
   BOOL userWantsTracksFixed;
 	NSOperationQueue *checkDeadTracksQueue;
   NSProgressIndicator *processingAnimation;
   NSTextField * processingCurrentNumber;
   NSTextField * processingTotalNumber;
   NSInteger numberProcessed;
}

-(IBAction)fixTracksButtonPressed:(id)sender;

@property (assign) IBOutlet NSTableView *lostFilesTableView;
@property (assign) IBOutlet NSTableView *foundFilesTableView;
@property (assign) IBOutlet NSTextField *status;
@property (assign) IBOutlet NSButton    *fixTracks;
@property (assign) IBOutlet NSProgressIndicator * processingAnimation;
@property (assign) IBOutlet NSTextField * processingCurrentNumber;
@property (assign) IBOutlet NSTextField * processingTotalNumber;


- (int)numberOfRowsInTableView:(NSTableView *)tv;
- (id)tableView:(NSTableView *)tv objectValueForTableColumn:(NSTableColumn *)tableColumn row:(int)row;
- (void)tableViewSelectionDidChange:(NSNotification *)notification;

//Needed for FindTrackViaPathReplacementDelegate

-(void)foundTrack:(NSDictionary*)trackInfo atPath:(NSString*)filepath  forFile:(NSString *)oldPath;
-(void)didNotFindTrackViaPathReplacement:(NSDictionary*)trackInfo atPath:(NSString*)filepath;
-(void)searchFinished;
   
@property (retain) iTunesFixer * fixer;
@property (retain) NSMutableDictionary * lostFiles;
@property (retain) NSMutableDictionary * foundFiles;
@property (retain) NSArray * lostFilesToDisplay;
@property (retain) NSArray * foundFilesToDisplay;
@property (retain) NSString * lastOpenLocation;

- (void) reloadTableData;
@end
