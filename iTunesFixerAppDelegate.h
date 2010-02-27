//
//  iTunesFixerAppDelegate.h
//  iTunesFixer
//
//  Created by porneL on 16.sty.10.
//  Copyright 2010 porneL. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "iTunesFixer.h"

@interface iTunesFixerAppDelegate : NSObject <NSApplicationDelegate> {
    NSWindow *window;
   

	NSProgressIndicator *progressbar;
	NSTextField *status;
	NSButton *startStop;
	
	NSTimer *timer;
	
	double lastProgress;
	NSInteger backwardUpdates;
	iTunesFixer *fixer;
	
	NSString *libraryPath;
   NSMenuItem * spotlightSearch;
   NSMenuItem * pathReplacement;
   	
	BOOL isSSD;
}


-(void)stopProgress;

-(IBAction)startStop:(id)sender;

@property (assign) IBOutlet NSButton *startStop;
@property (assign) IBOutlet NSWindow *window;
@property (assign) IBOutlet NSProgressIndicator *progressbar;
@property (assign) IBOutlet NSTextField *status;
@property (assign) IBOutlet NSMenuItem *spotlightSearch;
@property (assign) IBOutlet NSMenuItem *pathReplacement;

@end
