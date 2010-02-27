

#import "iTunesFixer.h"
#import "FindTrackViaSpotlight.h"
#import "UpdateTrack.h"


NSString *const iTunesFixerProgressNotification = @"iTunesFixerProgress";

@implementation iTunesFixer 

@synthesize spotlightSearch, pathReplacement, lostFiles, foundFiles;

inline static double estimate(const double filesMissing, const double filesChecked, const double filesTotal, const double fudge1, const double fudge2)
{
	// sometimes total is estimate too, and won't be exact
	if (filesTotal > 1.0 && (filesMissing < 1.0 || filesChecked < filesTotal-0.9))
	{
		double estimatedTotalFilesMissing, confidence;
				
		estimatedTotalFilesMissing = (filesMissing+fudge1) / (filesChecked+fudge2) * (filesTotal);
		confidence = filesChecked / filesTotal;
		
		double totalFilesMissing = (1.0-confidence) * estimatedTotalFilesMissing + confidence * filesMissing;
		
		//NSLog(@"Estimated items %d (%d%% of total, %d%% confidence)",(int)totalFilesMissing,(int)(100.0*((filesMissing+fudge1) / (filesChecked+fudge2))), (int)(100.0*confidence));
				
		return filesMissing > totalFilesMissing ? filesMissing : totalFilesMissing;
	} else {
		return filesMissing;
	}
}

-(id)initWithLibrary:(iTunesLibrary *)lib {

	if (self = [super init]) {
		library = lib;
		
		fixDeadTracksQueue = [NSOperationQueue new];
		[fixDeadTracksQueue setMaxConcurrentOperationCount:1]; // not strictly necessary, but might avoid trashing
      self.lostFiles = [NSMutableDictionary new];
      self.foundFiles = [NSMutableDictionary new];
      prc = [pathReplacementController new];
	}
	return self;
}

-(fixerProgressInfo)progress {
	
	//static NSDate *lastProgress = nil;
//	
//	if (!lastProgress) lastProgress = [NSDate new];
//	
//	NSDate *now = [NSDate new];
//	if ([now timeIntervalSinceDate:lastProgress] < 0.2) return;	
//	lastProgress = now;
	
	double totalWork = 1, workDone = 1;
	
	NSUInteger fTotal, fAdded, fChecked, fMissing, fSearched, fFound, fUpdated;
	@synchronized(self) {
		fUpdated = filesUpdated;
		fFound = filesFound; 
		fSearched = filesSearched; 
		fMissing = filesMissing; 
		fChecked = filesChecked; 
		fAdded = filesAdded; 
		fTotal = filesTotal; 
	}
	
	if (!fTotal) {
		fixerProgressInfo t = {0};
		t.total= aborted ? 1.0 : 0;
		return t;
	}
	
	if (fFound > fSearched) fSearched = fFound; // Search delivers them slightly out of order.
	
	assert(fUpdated <= fFound);
	assert(fFound <= fSearched);
	assert(fSearched <= fMissing);
	assert(fMissing <= fChecked);
	assert(fChecked <= fAdded);
	assert(fAdded <= fTotal);
	
	// adding
	totalWork += 0.01 * fTotal;
	workDone += 0.01 * fAdded;
	
	const double scanningCost = isSSD ? 0.25 : 0.7;
	
	// scanning
	totalWork += fTotal * scanningCost;
	workDone += fChecked * scanningCost;
	
	// estimate how many f will be missing in total (to know number of spotlight runs before scanning finishes)
	double totalfMissing = estimate(fMissing, fChecked, fTotal, 1.0*0.01, 1.0 /* 1% */);
	
	const double spotlightCost = isSSD ? 10 : 12;
	
	// spotlight
	double spotlightTotalWork = totalfMissing * spotlightCost;
	double spotlightWorkDone = fSearched * spotlightCost;
	
	// estimate number of searches that will succeed to know how many itunes changes will be made	
	double totalfFound = estimate(fFound, fSearched, totalfMissing, 7.0, 7.7 /* 90% */);
	double updateTotalWork = totalfFound * 35; // iTunes is ridiculously slow!
	double updateWorkDone = fUpdated * 35;
	
	totalWork += spotlightTotalWork + updateTotalWork;
	workDone += spotlightWorkDone + updateWorkDone;
	//
//		NSLog(@"Checked %d/%d/%d. Searched %d/%d/%d (%d%%). Updated %d/%d/%d (%d%%). Grant total: %d%%", 
//		  fChecked, fAdded, fTotal, 
//		  fSearched, fMissing, (int)totalfMissing, totalfMissing > 1 ? (int)(100*fSearched/totalfMissing) : 0,
//		  fUpdated, fFound, (int)totalfFound, totalfFound > 1 ? (int)(100*fUpdated/totalfFound) : 0,
//		  (int)(100*workDone / totalWork)
//		  );
	
	fixerProgressInfo t;
	t.total = aborted ? 1.0 : (workDone / totalWork);
	t.filesAdded = fAdded;
	t.filesSearched = fSearched;
	t.filesMissing = fMissing;
	t.filesChecked = fChecked;
	t.filesUpdated = fUpdated;
	t.filesFound = fFound;
	return t;
}

-(void)waitForSpotlightToEnd {
	
	//NSLog(@"Adding finished");
	[self performSelectorOnMainThread:@selector(notifyProgress) withObject:nil waitUntilDone:NO];
	
	[queue waitUntilAllOperationsAreFinished];
	[fixDeadTracksQueue setSuspended:NO];

	//NSLog(@"Scanning finished");
	[self performSelectorOnMainThread:@selector(notifyProgress) withObject:nil waitUntilDone:NO];
		
	[fixDeadTracksQueue waitUntilAllOperationsAreFinished];
	//NSLog(@"Spotlight finished");
	[self performSelectorOnMainThread:@selector(notifyProgress) withObject:nil waitUntilDone:NO];

   if (pathReplacement) {

      [prc setFixer:self];
      //[lostFiles sortUsingSelector:NSOrderedAscending];
      [prc setLostFiles:[self lostFiles]];
      [prc setFoundFiles:[self foundFiles]];
      [prc reloadTableData];
      [prc showWindow:nil];
   } else {
      [library waitForUpdates];
      NSLog(@"Library update finished");	
      [self performSelectorOnMainThread:@selector(notifyProgress) withObject:nil waitUntilDone:NO];
   }
}

-(NSString*)lastFile {
	NSString *t;
	@synchronized(self) {
		t = lastFile;
	}
	return t;
}

-(void)optimizeForSSD:(BOOL)y {
	isSSD = y;
}

-(void)abort {
	aborted = YES;
	[fixDeadTracksQueue cancelAllOperations];
	[queue cancelAllOperations];
	[library abort];
}

-(void)notifyProgress {
	[[NSNotificationCenter defaultCenter] postNotificationName:iTunesFixerProgressNotification object:self];
}

-(void)fixLibrary {
	
	aborted = NO;
	
	//NSLog(@"Will load library");
	filesTotal = 0;
	lastFile = [[NSFileManager defaultManager] displayNameAtPath:[library libraryPath]];
	
	if (!isSSD) [fixDeadTracksQueue setSuspended:YES]; // avoid spotlight and scanning at the same time

	NSDictionary *tracks = [library tracksDictionary];
	
	if (aborted) return;
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(trackUpdated:) name:TrackUpdatedNotification object:library];
	
	queue = [NSOperationQueue new];
	[queue setMaxConcurrentOperationCount: isSSD ? 2 : 1];
	
	//NSLog(@"Found %d tracks", [tracks count]);
	
	int max = 100000;
	
	filesTotal = MIN(max,[tracks count]);
	filesAdded = filesChecked = filesMissing = filesSearched = filesFound = filesUpdated = 0;

	for(NSString *track in tracks)
	{		
		@synchronized(self) {
			filesAdded++;
		}
		[queue addOperation:[[NSInvocationOperation alloc] initWithTarget:self
																 selector:@selector(fixTrack:) 
																   object:[tracks objectForKey:track]]];
		if (!--max || aborted) break;
	}
	
	[self performSelectorOnMainThread:@selector(notifyProgress) withObject:nil waitUntilDone:NO];
	
	[self performSelectorInBackground:@selector(waitForSpotlightToEnd) withObject:queue];
}

-(void)fixTrack:(NSDictionary *)trackInfo {
	NSURL *url = [NSURL URLWithString: [trackInfo objectForKey:@"Location"]];
	NSString *filepath = [url path];
	
	BOOL exists;
	
	if (!filepath || ![trackInfo objectForKey:@"Size"]) {
		exists = YES; // pretend yes just to update progress accordingly
	}
	else {
		exists = [[NSFileManager defaultManager] fileExistsAtPath:filepath];
	}

	@synchronized(self) {
		if (!filesFound) lastFile = [trackInfo objectForKey:@"Name"];
		if (!exists) filesMissing++;
		filesChecked++;
	}
	
	if (!exists)
	{	
      if ([self spotlightSearch]) {
         FindTrackViaSpotlight *findTrack = [[FindTrackViaSpotlight alloc] initWithDictionary:trackInfo path:filepath];
         findTrack.delegate = self;
         
         [fixDeadTracksQueue addOperation:findTrack];
      } else if ([self pathReplacement]) {
         @synchronized(self) {
            [lostFiles setObject: trackInfo forKey:filepath];
         }
      } else {
         //Apparently they don't want to do either, maybe just want a count?
      
      }
	}
}

-(void)didNotFindTrackViaSpotlight:(NSDictionary*)trackInfo atPath:(NSString*)filepath {
	@synchronized(self) {
      [lostFiles setObject: trackInfo forKey:filepath];
		if (!filesUpdated) lastFile = [trackInfo objectForKey:@"Name"];
	}
}

-(void)foundTrack:(NSDictionary*)trackInfo atPath:(NSString*)filepath {
	@synchronized(self) {
		filesFound++;
		if (!filesUpdated) lastFile = [trackInfo objectForKey:@"Name"];
	}
	if (aborted) return;
	[library setPath:filepath ofTrack:trackInfo];
}

-(void)searchFinished {
	@synchronized(self) {
		filesSearched++;
	}
}

- (void) pathReplacementSelectionFinished {
   filesSearched = filesMissing;
   
   
   for (NSString * path in foundFiles) {
      [self foundTrack:[foundFiles objectForKey:path] atPath:path];
   }

   [self performSelectorInBackground:@selector(finishAfterPathReplacement) withObject:nil];
}

-(void) finishAfterPathReplacement
{
   [library waitForUpdates];
   NSLog(@"Library update finished");	
   [self performSelectorOnMainThread:@selector(notifyProgress) withObject:nil waitUntilDone:NO];
}

- (void) cancelledPathReplacement
{
   [library waitForUpdates];
   NSLog(@"Library update finished");	
   [self performSelectorOnMainThread:@selector(notifyProgress) withObject:nil waitUntilDone:NO];
}

-(void)trackUpdated:(NSNotification *)note {
	//NSLog(@"Received notification %@",note);
	NSString *trackname = [[note userInfo] objectForKey:@"Name"];
	
	@synchronized(self) {
		filesUpdated++;
		lastFile = trackname;
	}
	[self performSelectorOnMainThread:@selector(notifyProgress) withObject:nil waitUntilDone:NO];
}

@end
