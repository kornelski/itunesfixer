//
//  TrackFunctions.h
//  iTunesFixer
//
//  Created by Brett Park on 10-02-07.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <AudioToolbox/AudioToolbox.h>

@interface TrackFunctions : NSObject {

}
+ (BOOL) getPrefixComponents:(NSString *) oldPath new:(NSString *) newPath oldCompsToSet:(NSString **)oldUncommonPrefix
   newCompsToSet:(NSString **) newUncommonPrefix;
+ (BOOL) compareMinFilePath:(NSString *) filePath1 secondFile:(NSString *) filePath2;
+ (BOOL) performAdditionalMetaDataCheckOnFile:(NSString *) newPath withTrackInfo:(NSDictionary *) trackInfo;
@end
