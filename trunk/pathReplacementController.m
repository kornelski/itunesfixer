//
//  pathReplacementController.m
//  iTunesFixer
//
//  Created by Brett Park on 10-02-06.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "pathReplacementController.h"


NSString *const pathReplacementFileCheckProgressNotification;

@implementation pathReplacementController

@synthesize foundFilesTableView, lostFilesTableView, fixer, lostFiles, foundFiles, processingAnimation;
@synthesize lostFilesToDisplay, foundFilesToDisplay, lastOpenLocation, status, fixTracks, processingCurrentNumber, processingTotalNumber;

- (id) init {
   self.lastOpenLocation = NSHomeDirectory();
   checkDeadTracksQueue = [NSOperationQueue new];
   [checkDeadTracksQueue setMaxConcurrentOperationCount:1];
   [checkDeadTracksQueue setSuspended:NO];
   [self initWithWindowNibName:@"pathReplacement"];
   return self;
}

-(void) disableLostTable {
   [lostFilesTableView setEnabled:NO];
   //[[lostFilesTableView animator] setAlphaValue:0.3f];
   [lostFilesTableView setAlphaValue:0.3f];
   [processingAnimation startAnimation:nil];
   [processingAnimation setHidden:NO];
   [processingCurrentNumber setHidden:NO];
   [processingTotalNumber setHidden:NO];   
}

-(void) enableLostTable {
   [lostFilesTableView setEnabled:YES];
   //[[lostFilesTableView animator] setAlphaValue:1.0f];
   [lostFilesTableView setAlphaValue:1.0f];
   [processingAnimation stopAnimation:nil];
   [processingAnimation setHidden:YES];
   [processingCurrentNumber setHidden:YES];
   [processingTotalNumber setHidden:YES];  
}


-(void) updateProgress:(id)anything {
      [self reloadTableData];
      [processingCurrentNumber setStringValue:[NSString stringWithFormat:@"%d", numberProcessed]];
      
      if ([checkDeadTracksQueue operationCount] == 0) {
         [timer invalidate]; timer = nil;
         [self enableLostTable];
      }
}

- (void) reloadTableData {
   @synchronized(self) {
      ignoreSelection = YES;
      self.lostFilesToDisplay = [[lostFiles allKeys] sortedArrayUsingSelector:@selector(localizedStandardCompare:)];
      self.foundFilesToDisplay = [[foundFiles allKeys] sortedArrayUsingSelector:@selector(localizedStandardCompare:)];
      
      [status setStringValue:[NSString stringWithFormat:@"%d of %d files can be fixed currently", [foundFilesToDisplay count], [lostFilesToDisplay count] + [foundFilesToDisplay count]]];
      
      if ([foundFilesToDisplay count] == 0)
         [fixTracks setEnabled:NO];
      else
         [fixTracks setEnabled:YES];
         
      [lostFilesTableView reloadData];
      [foundFilesTableView reloadData];
      ignoreSelection = NO;
   }
}


- (int)numberOfRowsInTableView:(NSTableView *)tv
{
   int count = 0;
   
   if (tv == lostFilesTableView) {
      count = [lostFilesToDisplay count];
   } else {
      count = [foundFilesToDisplay count];
   }
   
   return count;
}

- (id)tableView:(NSTableView *)tv
    objectValueForTableColumn:(NSTableColumn *)tableColumn
                          row:(int)row
{
   NSString * path;

   if (tv == lostFilesTableView) {
      path =  [lostFilesToDisplay  objectAtIndex:row];
   } else {
      path = [foundFilesToDisplay objectAtIndex:row];
   }
   
   return path;
}




-(void) allowUserToPerformFileFindUsingRow:(int) row {
   NSString * oldPath = [lostFilesToDisplay objectAtIndex:row];
   NSURL * newURL = nil;
   NSOpenPanel * openPan = [NSOpenPanel openPanel];
   [openPan setCanChooseFiles:YES];
   [openPan setAllowsMultipleSelection:NO];
   [openPan setCanChooseDirectories:NO];
   [openPan setExtensionHidden:NO];
   [openPan setTitle:@"Select Missing iTunes File"];
   [openPan setMessage:[NSString stringWithFormat:@"Please select the new location of file: %@", oldPath]]; 
   [openPan setPrompt:@"Found"];
   [openPan setDirectoryURL:[NSURL URLWithString:lastOpenLocation]];
   int result = [openPan runModal];
   if (result == NSOKButton) {
      NSArray * urls = [openPan URLs];      
      newURL = [urls objectAtIndex:0];
   }

   if (newURL != nil) {

      //Start update timers
      [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateProgress:) name:pathReplacementFileCheckProgressNotification object:self];
      
      timer = [NSTimer timerWithTimeInterval:0.5 target:self selector:@selector(updateProgress:) userInfo:nil repeats:YES];
      [[NSRunLoop currentRunLoop] addTimer:timer forMode:NSDefaultRunLoopMode];
      
      //Do some graphics stuff
      [processingCurrentNumber setStringValue:@"0"];
      numberProcessed = 0;
      [processingTotalNumber setStringValue:[NSString stringWithFormat:@"%d", [lostFiles count]]];
      [self disableLostTable];
      


      NSString * newPath = [newURL path];
      
      //Gets allocated during getPrefixComponents Function
      NSString * oldUncommonPrefix;
      NSString * newUncommonPrefix;
      BOOL fullPathDiff = [TrackFunctions getPrefixComponents:oldPath new:newPath oldCompsToSet:&oldUncommonPrefix newCompsToSet:&newUncommonPrefix];
      
      
      //If we have a full path difference, lets try to be smart and check others for similar differences
     BOOL minPathEqual = NO;
      if (fullPathDiff)
         minPathEqual = [TrackFunctions compareMinFilePath:oldUncommonPrefix secondFile:newUncommonPrefix];
      
      self.lastOpenLocation = newUncommonPrefix;
      
      NSMutableArray * justFound = [NSMutableArray arrayWithCapacity:50];
      
      //Finish creating all of the files before doing operations so we can modify lostFiles
      @synchronized(self) {
         for(NSString *path in lostFiles)
         {		
            //This should be abstracted off as operations
            
             FindTrackViaPathReplacement *findTrack = [[FindTrackViaPathReplacement alloc] initWithTrackInfo:[lostFiles objectForKey:path] 
                  originalPath:path usingOldUncommonPrefix:oldUncommonPrefix usingNewUncommonPrefix:newUncommonPrefix 
                  useMinPathSearch:minPathEqual];
            findTrack.delegate = self;
            
            [checkDeadTracksQueue addOperation:findTrack];
                  
         }
      }
   }
}

-(void)foundTrack:(NSDictionary*)trackInfo atPath:(NSString*)filepath forFile:(NSString *)oldPath {
   @synchronized(self) {
      [foundFiles setObject:trackInfo forKey:filepath];
      [lostFiles removeObjectForKey:oldPath];
      numberProcessed++;
   }
}

-(void)didNotFindTrackViaPathReplacement:(NSDictionary*)trackInfo atPath:(NSString*)filepath {
   @synchronized (self) {
      numberProcessed++;
   }
}

-(void)searchFinished {


}

- (void)NSWindowWillCloseNotification:(NSNotification *)notification {
   if (!userWantsTracksFixed)
      [fixer cancelledPathReplacement];
}

- (void)tableViewSelectionDidChange:(NSNotification *)notification
{
   if (! ignoreSelection) {
      id sender = [notification object];
      NSString * name = [notification name];

      if (sender == lostFilesTableView) {
         int row = [lostFilesTableView selectedRow];
         if (row > -1) {
            [self allowUserToPerformFileFindUsingRow:row];
            ignoreSelection = YES;
            [lostFilesTableView deselectRow:row];
            ignoreSelection = NO;
         }
      }
   }
}


-(IBAction)fixTracksButtonPressed:(id)sender {
   userWantsTracksFixed = YES;
   [[self window] close];
   [fixer pathReplacementSelectionFinished];
}
@end

