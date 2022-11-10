//
//  CreationController.h
//  MultiPatch
//

#import <Cocoa/Cocoa.h>
#import "MPPatchWindow.h"

@interface MPCreationWindow : NSWindow {
    IBOutlet MPFileTextField *txtOrigFile;
    IBOutlet MPFileTextField *txtModFile;
    IBOutlet NSTextField *txtPatchFile;
    IBOutlet NSTextFieldCell *lblPatchFormat;
    IBOutlet NSButton *btnCreatePatch;
    PatchFormat currentFormat;
    IBOutlet NSWindow *wndApplyPatch;
    IBOutlet NSPanel *pnlPatching;
    IBOutlet NSTextField *lblStatus;
    IBOutlet NSProgressIndicator *barProgress;
    IBOutlet NSView *vwFormatPicker;
    IBOutlet NSPopUpButton *ddFormats;
}
- (IBAction)btnPickOrig:(id)sender;
- (IBAction)btnPickModified:(id)sender;
- (IBAction)btnPickOutput:(id)sender;
- (IBAction)btnCreatePatch:(id)sender;
- (IBAction)btnApplyMode:(id)sender;
@end
