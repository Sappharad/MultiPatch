//
//  MultiPatchController.m
//  MultiPatcher
//
//  Created by Paul Kratt on 12/1/18.
//

#import "MultiPatchController.h"

@implementation MultiPatchController

-(void)applicationDidFinishLaunching:(NSNotification *)notification{
    //Hard-coded to off at startup, to force the user to realize that the output will probably be invalid.
    //Desired workflow:
    //User tries patching, program notifies them that their input file is wrong.
    //User goes into preferences and disables the check and applies patch again.
    //User gets a file that might work, but might not, since their input was wrong.
    _ignoreXDeltaChecksum = NO;
}

- (IBAction)showPreferences:(id)sender {
    [_wndPreferences makeKeyAndOrderFront:self];
}

- (IBAction)chkIgnoreXdeltaChecks:(id)sender {
    MultiPatchController.IgnoreXDeltaChecksum = (_chkIgnoreXDelta.state==NSOnState);
}

static BOOL _ignoreXDeltaChecksum;
+(BOOL)IgnoreXDeltaChecksum{
    return _ignoreXDeltaChecksum;
}
+(void)setIgnoreXDeltaChecksum:(BOOL)value{
    _ignoreXDeltaChecksum = value;
}
@end
