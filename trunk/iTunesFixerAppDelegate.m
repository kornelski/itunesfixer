//
//  iTunesFixerAppDelegate.m
//  iTunesFixer
//
//  Created by porneL on 16.sty.10.
//  Copyright 2010 porneL. All rights reserved.
//

#import "iTunesFixerAppDelegate.h"
#import "SSD.h"


@implementation iTunesFixerAppDelegate

@synthesize window, progressbar, status, startStop, spotlightSearch, pathReplacement;

-(void) updateProgress:(id)anything {
	
	fixerProgressInfo t = [fixer progress];
	double progress = t.total;
	
   
   //NO Was added so we don't stop during testing
	if (NO && progress >= 1.0) {
		[self stopProgress];
		return;
	}
	else
	{
		if (progress > 0)
		{
			if (progress == lastProgress) return;		
			
			[startStop setEnabled:YES];	
			
			NSString *sText=nil;
			NSString *lastFile = [fixer lastFile]; if (!lastFile) lastFile = @"…";
			
			if (t.filesChecked < t.filesAdded*0.7 || !t.filesSearched) {
				sText = [NSString stringWithFormat:@"Scanning… %d of %d: %@",t.filesChecked,t.filesAdded, lastFile];
			}
			else if (t.filesSearched < t.filesMissing)
			{
				sText = [NSString stringWithFormat:@"Searching… %d of %d: %@",t.filesSearched,t.filesMissing, lastFile];
			}
			else if (t.filesUpdated < t.filesFound)
			{
				sText = [NSString stringWithFormat:@"Fixing… %d of %d: %@", t.filesUpdated, t.filesFound, lastFile];
			}
			else
			{
				sText = @"Finishing…";				
			}
			[status setStringValue:sText];
		}
		
		// don't back out so easily
		if (progress < lastProgress) {
			backwardUpdates++;
			if (backwardUpdates < 15) {
				progress = lastProgress;
			}
			else {
				backwardUpdates=0;
			}
		}
		else
		{
			backwardUpdates=0;
		}
		lastProgress = progress;
		[progressbar setIndeterminate:!(progress > 0)];
	}
	[progressbar setDoubleValue:progress];
}

-(void)stopProgress {
	[startStop setTitle:@"Start"];
	[startStop setEnabled:YES];
	
	[timer invalidate]; timer = nil;
	if (fixer)
	{
		[[NSNotificationCenter defaultCenter] removeObserver:self name:iTunesFixerProgressNotification object:fixer];

		fixerProgressInfo t = [fixer progress];		
		fixer = nil;
		
		[status setStringValue:[NSString stringWithFormat:@"Done. Fixed %d of %d files.", t.filesUpdated, t.filesMissing]];		
	}
	[progressbar setDoubleValue:1.0];
	[progressbar stopAnimation:self];
	lastProgress = 1.0;
}

-(void)startProgress {	
	[startStop setEnabled:NO];	
	[startStop setTitle:@"Abort"];
	
	lastProgress=0;backwardUpdates=0;

	[progressbar setIndeterminate:YES];
	[progressbar setUsesThreadedAnimation:YES];
	[progressbar startAnimation:self];
	[status setStringValue:@"Loading iTunes Library…"];
}

- (void)openPanelDidEnd:(NSOpenPanel *)panel returnCode:(int)returnCode  contextInfo:(void  *)contextInfo {
	NSLog(@"Panel end");
	if (returnCode == NSOKButton)
	{
		libraryPath = [[[panel URLs] lastObject] path];
		[self performSelectorOnMainThread:@selector(startStop:) withObject:nil waitUntilDone:NO];
	}
	else
	{
		[[NSApplication sharedApplication] terminate:self];
	}
}
 
-(NSString *)findLibraryPath {
	
	NSString *lib = [[[NSHomeDirectory() 
							   stringByAppendingPathComponent:@"Music"] 
							  stringByAppendingPathComponent:@"iTunes"] 
							 stringByAppendingPathComponent:@"iTunes Music Library.xml"];
	
	if ([[NSFileManager defaultManager] fileExistsAtPath:lib])
	{
		return lib;
	}

	NSString *musicDir = [NSHomeDirectory() stringByAppendingPathComponent:@"Music"];
	
	NSOpenPanel *panel = [NSOpenPanel openPanel];	
	[panel setExtensionHidden:NO];
	[panel setTitle:@"Select iTunes Music Library XML file"];
	[panel setMessage:@"Please select “iTunes Music Library.xml” file from your default iTunes library. This file will not be modified directly."]; 
	[panel setPrompt:@"Scan"];
	[panel setCanChooseFiles:YES];
	[panel setCanChooseDirectories:NO];
	[panel setResolvesAliases:YES];
	[panel setAllowsMultipleSelection:NO];
	[panel beginSheetForDirectory:musicDir file:nil types:[NSArray arrayWithObject:@"xml"] 
				   modalForWindow:self.window 
					modalDelegate:self didEndSelector:@selector(openPanelDidEnd:returnCode:contextInfo:) contextInfo:nil];
	 return nil;
}



- (void)windowWillClose:(NSNotification *)aNotification
{
    [[NSApplication sharedApplication] performSelectorOnMainThread:@selector(terminate:) withObject:self waitUntilDone:NO];
}

-(void)applicationWillTerminate:(NSNotification*)n { 
	[fixer abort];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {

	libraryPath = [self findLibraryPath];
	
	isSSD = isSolidState((UInt8 const*)"/");
	
	[startStop setEnabled:!!libraryPath];
	
	if (libraryPath)
	{
		NSString *st = [NSString stringWithFormat:@"Ready to fix library in %@",[libraryPath stringByDeletingLastPathComponent]];
		if (isSSD) {
			st = [st stringByAppendingString:@"\nSSD found — nice!"];
		}
		[status setStringValue:st];
	}
}



-(IBAction)startStop:(id)sender {

	if (fixer)
	{
		[startStop setEnabled:NO];
		[fixer abort];
		return;
	}
	
	if (!libraryPath && !fixer) {
		NSBeep();
		return;
	}
	
	[self startProgress];
	
	iTunesLibrary *lib = [[iTunesLibrary alloc] initWithPath:libraryPath];
	
	fixer = [[iTunesFixer alloc] initWithLibrary:lib];
	
	[fixer optimizeForSSD:isSSD];
   [fixer setPathReplacement:[pathReplacement state] == NSOnState];
   [fixer setSpotlightSearch:[spotlightSearch state] == NSOnState];
    
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateProgress:) name:iTunesFixerProgressNotification object:fixer];
	
	timer = [NSTimer timerWithTimeInterval:0.5 target:self selector:@selector(updateProgress:) userInfo:nil repeats:YES];
	[[NSRunLoop currentRunLoop] addTimer:timer forMode:NSDefaultRunLoopMode];
	
	[fixer performSelectorInBackground:@selector(fixLibrary) withObject:nil];
}

@end
