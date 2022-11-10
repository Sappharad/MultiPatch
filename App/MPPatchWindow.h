#import <Cocoa/Cocoa.h>
#include "mbFlipWindow.h"
#include "MPFileTextField.h"

typedef enum PatchTypes{
	UNKNOWNPAT, UPSPAT, XDELTAPAT, IPSPAT, PPFPAT, BSDIFFPAT, BPSPAT, BPSDELTA, RUPPAT
} PatchFormat;

@interface MPPatchWindow : NSWindow{
    IBOutlet MPFileTextField *txtPatchPath;
    IBOutlet MPFileTextField *txtRomPath;
	IBOutlet NSTextField *txtOutputPath;
	IBOutlet id lblPatchFormat;
    IBOutlet NSWindow *wndCreator;
	IBOutlet id pnlPatching;
	IBOutlet id	barProgress;
	IBOutlet id btnApply;
	IBOutlet NSTextField *lblStatus;
	PatchFormat currentFormat;
	NSString* romFormat;
}

- (IBAction)btnApply:(id)sender;
- (IBAction)btnSelectPatch:(id)sender;
- (IBAction)btnSelectOriginal:(id)sender;
- (IBAction)btnSelectOutput:(id)sender;
+ (PatchFormat)detectPatchFormat:(NSString*)patchPath;
- (IBAction)btnCreatePatch:(id)sender;
+ (mbFlipWindow*)flipper;

@end
