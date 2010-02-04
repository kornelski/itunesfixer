//
//  FindTrack.h
//  iTunesFixer
//
//  Created by porneL on 17.sty.10.
//  Copyright 2010 porneL. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@protocol FindTrackDelegate < NSObject >

-(void)foundTrack:(NSDictionary*)trackInfo atPath:(NSString*)filepath;
-(void)searchFinished;

@end


@interface FindTrack : NSOperation {

	NSDictionary* trackInfo;
	NSString* filepath;
	NSMetadataQuery *query;
	
	NSUInteger resultIndex;
	
	id<FindTrackDelegate> delegate;
	
	BOOL isExecuting, isFinished;
}

-(id)initWithDictionary:(NSDictionary*)trackInfo path:(NSString*)filepath;

@property (retain) id<FindTrackDelegate> delegate;
@property (assign,readonly) BOOL isExecuting, isFinished;

-(void)updateStatus;
-(void)cleanup;
@end
