//
//  FindTrackViaSpotlight.m
//  iTunesFixer
//
//  Created by porneL on 17.sty.10.
//  Copyright 2010 porneL. All rights reserved.
//

#import "FindTrackViaSpotlight.h"


@implementation FindTrackViaSpotlight

@synthesize isExecuting, isFinished; // NSOperation wants KVO, I'm lazy.
@synthesize delegate;

-(id)initWithDictionary:(NSDictionary*)atrackInfo path:(NSString*)afilepath
{
	if (self = [super init])
	{
		trackInfo = atrackInfo;
		filepath = afilepath;
	}
	return self;
}

- (BOOL)isConcurrent {
	return YES;
}

-(void)start {
	// 2 hours wasted on that #@$**!%%@ runloop #$%@@**!
	// start may be ran on bg thread, which means no runloop, which means no notificatins, which means it all gets stuck
	if (![NSThread isMainThread])
    {
        [self performSelectorOnMainThread:@selector(start) withObject:nil waitUntilDone:YES];
        return;
    }
		
	if ([self isCancelled])
	{
		[self updateStatus];
		return;
	}
     
   resultIndex=0;
   query = [NSMetadataQuery new];
   [query setNotificationBatchingInterval:0.1];
    [query setSearchScopes:[NSArray arrayWithObjects:NSMetadataQueryUserHomeScope,NSMetadataQueryLocalComputerScope,nil]];
   
    // setup our Spotlight notifications
    NSNotificationCenter *nf = [NSNotificationCenter defaultCenter];
    [nf addObserver:self selector:@selector(queryNotification:) name:nil object:query];
   
   NSString *displayname = nil;
   
   LSCopyDisplayNameForURL((CFURLRef)[NSURL URLWithString:[trackInfo objectForKey:@"Location"]], (CFStringRef*)&displayname);
   if (!displayname) displayname = [filepath lastPathComponent];
   
   // displayname seems to be muuuch faster than fsname
   NSPredicate *pred = [NSPredicate predicateWithFormat: @"%K = %@ && %K = %@",
                   kMDItemDisplayName, displayname,
                   kMDItemFSSize, [trackInfo objectForKey:@"Size"]];
   
    [query setPredicate: pred];
   
   if (pred && [query startQuery])
   {
      //NSLog(@"Started hunt for %@",filepath);
      [self updateStatus];
   }
   else
   {
      NSLog(@"Query start fail %@",filepath);
      [self cancel];
   }
      
   /*   NSUInteger count = [query resultCount];
      
      NSString * newFilePath = [filepath stringByReplacingOccurrencesOfString:@"/ICE/Music/Non-Album/" withString:@"/Green/Music/"];
      BOOL exists = [[NSFileManager defaultManager] fileExistsAtPath:newFilePath];
      
      if (exists)
      {
         [delegate foundTrack:trackInfo atPath:newFilePath];	
      }

      [self updateStatus];
*/
}

-(void)cancel {
	[self cleanup];
	[super cancel];
	[self updateStatus];
}

-(void)cleanup {
	if (query)
	{
		[delegate searchFinished]; delegate = nil;
		//NSLog(@"Ending search for %@",filepath);
		[query stopQuery]; query = nil;
	
		[[NSNotificationCenter defaultCenter] removeObserver:self];
	}
}


-(void)updateStatus
{
	[self willChangeValueForKey:@"isExecuting"];
	isExecuting = query && ([query isGathering]);
	[self didChangeValueForKey:@"isExecuting"];

	[self willChangeValueForKey:@"isFinished"];
	isFinished = !query;
	[self didChangeValueForKey:@"isFinished"];
	
	//NSLog(@"Current status = %d e, %d f",self.isExecuting, self.isFinished);
}

- (void)queryNotification:(NSNotification*)note
{
	BOOL finished = [[note name] isEqualToString:NSMetadataQueryDidFinishGatheringNotification];
	
	[query disableUpdates];
	NSUInteger count = [query resultCount];
	
	if (resultIndex > count) resultIndex = 0; // just in case spotlight does crazy things
	
	for(; resultIndex < count; resultIndex++)
	{
		NSMetadataItem *item = [query resultAtIndex:resultIndex];
		NSString *foundpath = [item valueForAttribute:(NSString *)kMDItemPath];
		
		if (foundpath)
		{
			[delegate foundTrack:trackInfo atPath:foundpath];	
			finished = YES;
			break;
		}
	}
	[query enableUpdates];

	if (finished)
	{
      //Spotlight found a file
		[self cleanup];
	} else if (![query isGathering]) 
   {
      //Spotlight ended without finding file
      [delegate didNotFindTrackViaSpotlight:trackInfo atPath:filepath];
		[self cleanup];   
   }
   
	[self updateStatus];
}

@end
