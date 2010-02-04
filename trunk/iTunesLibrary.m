//
//  iTunesLibrary.m
//  iTunesFixer
//
//  Created by porneL on 17.sty.10.
//  Copyright 2010 porneL. All rights reserved.
//

#import "iTunesLibrary.h"
#import <ScriptingBridge/SBApplication.h>
#import "iTunes.h"
#import "UpdateTrack.h"

static Class iTunesFileTrackClass;

inline static BOOL trackMatches(iTunesFileTrack *track, NSString *persistentID)
{
	return [track isKindOfClass:iTunesFileTrackClass] && [persistentID isEqualToString:[track persistentID]];
}

@implementation iTunesLibrary

-(id)initWithPath:(NSString*)apath {
	if (self = [super init])
	{
		path = apath;
		libraryQueue = [NSOperationQueue new]; // itunes doesn't like concurrent access
		[libraryQueue setMaxConcurrentOperationCount:1];		
	}
	return self;
}


-(NSString*)libraryPath {
	return path;
}

/*! can be called at any time */
-(NSDictionary*)tracksDictionary {
	return [[NSDictionary dictionaryWithContentsOfFile:path] objectForKey:@"Tracks"];
}

-(iTunesApplication*)iTunes {
	if (!iTunes)
	{
		iTunes = [SBApplication applicationWithBundleIdentifier:@"com.apple.iTunes"];	
		
		iTunesFileTrackClass = [iTunes classForScriptingClass:@"file track"];
		//NSLog(@"File track class = %@", iTunesFileTrackClass);
	}
	return iTunes;
}

-(iTunesLibraryPlaylist*)library {
	if (!library) {
		iTunesSource *source = [[[self iTunes] sources] objectAtIndex:0];
		library = [[source libraryPlaylists] objectAtIndex:0];
		//NSLog(@"Using “%@” as source",[library name]);
	}
	return library;
}

-(void)abort {
	[libraryQueue cancelAllOperations];
	[libraryQueue waitUntilAllOperationsAreFinished];
}

/*! must not be called in parallel! */
-(iTunesFileTrack *)fileTrackForDictionary:(NSDictionary*)trackInfo {
	NSString *persistentID = [trackInfo objectForKey:@"Persistent ID"];
	if (!persistentID) return nil;
	
	
	SBElementArray *tracks = [[self library] tracks];
	iTunesFileTrack *track = [tracks objectWithID:[trackInfo objectForKey:@"Track ID"]];
	
	if (trackMatches(track,persistentID)) {
		//NSLog(@"Found by id");
		return track;
	}
	else {
		track = [tracks objectWithName:[trackInfo objectForKey:@"Name"]];
		if (trackMatches(track,persistentID)) {
			//NSLog(@"Found by name, id %@ != found %d",[trackInfo objectForKey:@"Track ID"], [track id]);
			return track;
		} else {
			
			NSString *query = [NSString stringWithFormat:@"%@ %@", [trackInfo objectForKey:@"Name"], [trackInfo objectForKey:@"Artist"]];
			id result = [[self library] searchFor:query only:iTunesESrAAll];
			
			// prototype of searchFor is wrong
			if ([result isKindOfClass:[NSArray class]]) {
				for(iTunesFileTrack *track in (NSArray*)result) {
					if (trackMatches(track,persistentID)) {
						//NSLog(@"Found using search");
						return track;
					}
				}
			}

			//NSLog(@"Track NOT FOUND %@",trackInfo);
			return nil;
		}
	}
}

-(void)setPath:(NSString*)newpath ofTrack:(NSDictionary*)trackInfo {
	[libraryQueue addOperation:[[UpdateTrack alloc] initWithLibrary:self dictionary:trackInfo path:newpath]];
}


-(void)waitForUpdates {
	[libraryQueue waitUntilAllOperationsAreFinished];
}
@end
