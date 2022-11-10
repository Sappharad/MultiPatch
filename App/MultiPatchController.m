//
//  MultiPatchController.m
//  MultiPatcher
//
//  Created by Paul Kratt on 12/1/18.
//

#import "MultiPatchController.h"
#import "MPSettings.h"
#if TARGET_OS_OSX
#import <Sparkle/Sparkle.h>
#endif

@implementation MultiPatchController

-(void)applicationDidFinishLaunching:(NSNotification *)notification{
    //Hard-coded to off at startup, to force the user to realize that the output will probably be invalid.
    //Desired workflow:
    //User tries patching, program notifies them that their input file is wrong.
    //User goes into preferences and disables the check and applies patch again.
    //User gets a file that might work, but might not, since their input was wrong.
    MPSettings.IgnoreXDeltaChecksum = NO;
}

- (IBAction)showPreferences:(id)sender {
#if TARGET_OS_OSX
    SUUpdater* sparkle = [SUUpdater sharedUpdater];
    _chkCheckForUpdates.state = sparkle.automaticallyChecksForUpdates ? NSOnState : NSOffState;
#endif
    [_wndPreferences makeKeyAndOrderFront:self];
}

- (IBAction)chkCheckForUpdates_Changed:(id)sender {
#if TARGET_OS_OSX
    SUUpdater* sparkle = [SUUpdater sharedUpdater];
    sparkle.automaticallyChecksForUpdates = (_chkCheckForUpdates.state == NSOnState);
#endif
}

- (IBAction)chkIgnoreXdelta_Changed:(id)sender {
    MPSettings.IgnoreXDeltaChecksum = (_chkIgnoreXDelta.state==NSOnState);
}
@end
