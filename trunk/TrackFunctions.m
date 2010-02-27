//
//  TrackFunctions.m
//  iTunesFixer
//
//  Created by Brett Park on 10-02-07.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "TrackFunctions.h"


@implementation TrackFunctions

+ (BOOL) getPrefixComponents:(NSString *) oldPath new:(NSString *) newPath oldCompsToSet:(NSString **)oldUncommonPrefix
   newCompsToSet:(NSString **) newUncommonPrefix
{
            
   NSArray * oldPathComps = [oldPath componentsSeparatedByString:@"/"];
   NSArray * newPathComps = [newPath componentsSeparatedByString:@"/"];

   int oldPathSize = [oldPathComps count];
   int newPathSize = [newPathComps count];

   NSString * oldCompToReplace = [NSString string];
   NSString * newCompToReplaceOld = [NSString string];

   int o = oldPathSize - 1;
   int n = newPathSize - 1;
   for (; n > -1 && o > -1; n--) {
      NSString * newComp = [newPathComps objectAtIndex:n];
      NSString * oldComp = [oldPathComps objectAtIndex:o];            
      
      if (! [newComp isEqualToString:oldComp]) {
         for (int i = 0; i < o + 1; i++) 
            oldCompToReplace = [oldCompToReplace stringByAppendingFormat:@"%@/", [oldPathComps objectAtIndex:i]];
         for (int i = 0; i < n + 1; i++) 
            newCompToReplaceOld = [newCompToReplaceOld stringByAppendingFormat:@"%@/",[newPathComps objectAtIndex:i]];
         break;
      }
      o--;
   }

   //We need to take into account that if the files are fully different a / will be added after the filename
   // check for it and remove it if it exists
   BOOL fullPathDiff = NO;
   if ([oldCompToReplace length] > [oldPath length]) {
      oldCompToReplace = [oldCompToReplace substringToIndex:[oldCompToReplace length] - 1]; 
      newCompToReplaceOld = [newCompToReplaceOld substringToIndex:[newCompToReplaceOld length] - 1];
      fullPathDiff = YES;
   }

   (* oldUncommonPrefix) = [[NSString alloc] initWithString:oldCompToReplace];
   (* newUncommonPrefix) = [[NSString alloc] initWithString:newCompToReplaceOld];

   return fullPathDiff;          
}

+ (BOOL) compareMinFilePath:(NSString *) filePath1 secondFile:(NSString *) filePath2 {
   BOOL minPathEqual = NO;

   NSString * oldFilename = [filePath1 lastPathComponent];
   NSString * newFilename = [filePath2 lastPathComponent];

   //Cases we could check for:
   // Period was added/removed after track number
   // Track Number was added/removed
   // Case has changed
   // Character added or removed?
   // Extension Change - Lets not touch this one, might requrie metadata update


   //Screw this, lets simplify and look for similarities rather than differences
   NSMutableString * checkOldString = [NSMutableString stringWithString:oldFilename];           
   NSRange oldCharRange = [checkOldString rangeOfCharacterFromSet:[NSCharacterSet letterCharacterSet]];
   NSMutableString * minOldString = [NSMutableString stringWithCapacity:[checkOldString length]];

   while (oldCharRange.length > 0) {
      [minOldString appendString:[checkOldString substringWithRange:oldCharRange]];
      NSRange delRange;
      delRange.location = 0;
      delRange.length = oldCharRange.location + oldCharRange.length;
      [checkOldString deleteCharactersInRange:delRange];
      oldCharRange = [checkOldString rangeOfCharacterFromSet:[NSCharacterSet letterCharacterSet]];               
   }

   NSMutableString * checkNewString = [NSMutableString stringWithString:newFilename];           
   NSRange newCharRange = [checkNewString rangeOfCharacterFromSet:[NSCharacterSet letterCharacterSet]];
   NSMutableString * minNewString = [NSMutableString stringWithCapacity:[checkNewString length]];

   while (newCharRange.length > 0) {
      [minNewString appendString:[checkNewString substringWithRange:newCharRange]];
      NSRange delRange;
      delRange.location = 0;
      delRange.length = newCharRange.location + newCharRange.length;
      [checkNewString deleteCharactersInRange:delRange];
      newCharRange = [checkNewString rangeOfCharacterFromSet:[NSCharacterSet letterCharacterSet]];               
   }

   //Finally check case
   minPathEqual = (NSOrderedSame == [minNewString compare:minOldString options:NSCaseInsensitiveSearch]);
   
   return minPathEqual;
}

+ (BOOL) performAdditionalMetaDataCheckOnFile:(NSString *) newPath withTrackInfo:(NSDictionary *) trackInfo {
  //Well, we got the filename. Anything else we should do to validate?

   //perhaps we should check id3 infor:
   /*   Name
   Artist
   Album
   * Bit Rate
   * Total Time
   Size
   * Sample Rate
   Track Number   

   ID3 information can be read retrieving the kAudioFilePropertyInfoDictionary property of an audio file using the AudioFileGetProperty function of the AudioToolbox framework.

   */

   /* Well, Most of the metadata could change easily if track info was updated if the file was a dup. Perhaps we should
         stick to total time as a secondary metric, that should never change */

   //NSDictionary * fileAttrb = [[NSFileManager defaultManager] attributesOfItemAtPath:checkPath error:nil];
   //unsigned long long filesize = [fileAttrb fileSize];
      
   BOOL theSame = NO;
   
   //Lets get some metadata   
   FSRef fileRef;
   AudioFileID fileID;
   UInt32 theSize;
   OSStatus osStatus = noErr;
   NSTimeInterval timeFromFileInSeconds = 0;
                     
   FSPathMakeRef((UInt8 const *) [newPath fileSystemRepresentation],&fileRef,NULL);
   osStatus = AudioFileOpen(&fileRef, fsRdPerm, 0, &fileID);
   if (osStatus == noErr) {


      theSize = sizeof(timeFromFileInSeconds);
      osStatus = AudioFileGetProperty(fileID,kAudioFilePropertyEstimatedDuration,&theSize,&timeFromFileInSeconds);
      if( osStatus == noErr )
      {
         //NSLog(@"Song in seconds %f", timeFromFileInSeconds);
      }

      //ID3 example from site: http://www.iphonedevbook.com/forum/viewtopic.php?f=25&t=864   
      // CFDictionaryRef piDict = nil;
      // UInt32 piDataSize   = sizeof( piDict );

      //Some of the things we can get:
      /*  album = "The Places You Have Come To Fear The Most";
          "approximate duration in seconds" = "147.331";
          artist = "Dashboard Confessional";
          comments = "Adjusted by iVolume 12/17/2008 02:05:49\n";
          genre = "A Cappella";
          title = "The Good Fight";
          "track number" = "6/10";
      */

      //osStatus = AudioFileGetProperty( fileID, kAudioFilePropertyInfoDictionary, &piDataSize, &piDict );
      //if( osStatus == noErr ) {
      //   NSLog( @"property info: %@", (NSDictionary*)piDict );
      //}

      //if (piDict != nil) 
      //   CFRelease(piDict);   

      AudioFileClose(fileID);
   }


   //This will change if id3 info has changed or could change based on file structure of stored location
   //NSNumber * trackSize = [trackInfo objectForKey:@"Size"];
   //unsigned long long trackFileSize = [trackSize unsignedLongLongValue];

   NSNumber * trackTime = [trackInfo objectForKey:@"Total Time"];
   NSTimeInterval timediff = timeFromFileInSeconds - ([trackTime floatValue] / 1000.0f);
   //Should be within 0.03 seconds
   //NSLog(@"Found a time difference of: %f for track %@", timediff, newPath);

   //Seems like 300ms is a good difference. Note, if we get a time of zero, we can't read the audio time, assume we are good
   if (trackTime == 0 || abs(timediff) < 0.03f) {
      theSame = YES;
   }

   return theSame;
}

@end
