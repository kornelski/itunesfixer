//
//  FindTrackViaPathReplacement.m
//  iTunesFixer
//
//  Created by Brett Park on 10-02-07.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//
 
#import "FindTrackViaPathReplacement.h"


@implementation FindTrackViaPathReplacement
@synthesize isExecuting, isFinished; // NSOperation wants KVO, I'm lazy.
@synthesize delegate;

-(id)initWithTrackInfo:(NSDictionary*)atrackInfo originalPath:(NSString*)apath usingOldUncommonPrefix:(NSString *) aoldUncommonPrefix 
      usingNewUncommonPrefix:(NSString *) anewUncommonPrefix  useMinPathSearch:(BOOL) aminPathSearch
{
	if (self = [super init])
	{
		trackInfo = atrackInfo;
		path = apath;
      oldUncommonPrefix = aoldUncommonPrefix;
      newUncommonPrefix = anewUncommonPrefix;
      minPathSearch = aminPathSearch;
	}
	return self;
}

- (BOOL)isConcurrent {
	return YES;
}


- (BOOL) manuallySearchForTrack
{
   //Ignore last component of path
   //Find the new path
   //Get a listing of files in the new path
   //Do a check on each file to see if we can match using a minPathSearch
   //If found, check file perform a filesize check as verification
   BOOL exists = NO;
   
   NSString * oUPrefix = [NSString stringWithString:oldUncommonPrefix];
   NSString * nUPrefix = [NSString stringWithString:newUncommonPrefix];
   
   if (minPathSearch) {
      [TrackFunctions getPrefixComponents:[oUPrefix stringByDeletingLastPathComponent] new:[nUPrefix stringByDeletingLastPathComponent] oldCompsToSet:&oUPrefix newCompsToSet:&nUPrefix];
   
   }
   
   if ([path hasPrefix:oUPrefix]) {
      NSRange searchRange;
      searchRange.location = 0;
      searchRange.length = [oUPrefix length];
      NSString * newPath = [path stringByReplacingOccurrencesOfString:oUPrefix withString:nUPrefix options: NSAnchoredSearch range:searchRange];

      exists = [[NSFileManager defaultManager] fileExistsAtPath:newPath];
   
      if (! exists && minPathSearch) {
         NSArray * files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:[newPath stringByDeletingLastPathComponent] error:nil];
         for (NSString * fileName in files) {
            //Min FileName are the same, and we are in a "found" folder. If file size matches we should be a go
            NSString * checkPath = [[newPath stringByDeletingLastPathComponent] stringByAppendingFormat:@"/%@",fileName];
            if ([TrackFunctions compareMinFilePath:checkPath secondFile:path]) {
               newPath = checkPath;
               exists = YES;
               break;
            } 
         }
      }

      //We found a file
      if (exists) {
         //Do an additional MetaData check
         if ([TrackFunctions performAdditionalMetaDataCheckOnFile:newPath withTrackInfo:trackInfo]) {
            //NSLog(@"Found good file: %@", newPath);
            [delegate foundTrack:trackInfo atPath:newPath forFile:path];
            
         } else {
            exists = NO;
         }
      }
   }
   
   if (! exists)
      [delegate didNotFindTrackViaPathReplacement:trackInfo atPath:path];
         
   return exists;
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
      [self setStatusFinished];
		return;
	}
   

   [self setStatusExecuting];
   [self manuallySearchForTrack];
   delegate = nil;
   [self setStatusFinished];
}


-(void) setStatusExecuting {
   [self willChangeValueForKey:@"isExecuting"];
   isExecuting = true;
   [self didChangeValueForKey:@"isExecuting"];
}

-(void) setStatusFinished {
   [self willChangeValueForKey:@"isExecuting"];
   isExecuting = false;
   [self didChangeValueForKey:@"isExecuting"];

	[self willChangeValueForKey:@"isFinished"];
   isFinished = true;
   [self didChangeValueForKey:@"isFinished"];
}

-(void)cancel {
	[self setStatusFinished];
	[super cancel];
}

@end
