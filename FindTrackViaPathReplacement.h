//
//  FindTrackViaPathReplacement.h
//  iTunesFixer
//
//  Created by Brett Park on 10-02-07.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//
 
#import <Cocoa/Cocoa.h>
#import "TrackFunctions.h"


@protocol FindTrackViaPathReplacementDelegate < NSObject >

-(void)foundTrack:(NSDictionary*)trackInfo atPath:(NSString*)filepath  forFile:(NSString *)oldPath;
-(void)didNotFindTrackViaPathReplacement:(NSDictionary*)trackInfo atPath:(NSString*)filepath;
-(void)searchFinished;


@end

@interface FindTrackViaPathReplacement : NSOperation {
      
	NSDictionary* trackInfo;
	NSString* path;
   NSString* oldUncommonPrefix;
   NSString* newUncommonPrefix;
   BOOL minPathSearch;
	
	id<FindTrackViaPathReplacementDelegate> delegate;
	
	BOOL isExecuting, isFinished;
}

-(id)initWithTrackInfo:(NSDictionary*)atrackInfo originalPath:(NSString*)apath usingOldUncommonPrefix:(NSString *) aoldUncommonPrefix 
      usingNewUncommonPrefix:(NSString *) anewUncommonPrefix  useMinPathSearch:(BOOL) aminPathSearch;

@property (retain) id<FindTrackViaPathReplacementDelegate> delegate;
@property (assign,readonly) BOOL isExecuting, isFinished;

-(void)setStatusFinished;
-(void)setStatusExecuting;
@end
