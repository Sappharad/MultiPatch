//
//  CreationController.h
//  MultiPatch
//

#import <Cocoa/Cocoa.h>
#import "PatchController.h"

@interface CreationController : NSObject {
    IBOutlet NSTextField *txtOrigFile;
    IBOutlet NSTextField *txtModFile;
    IBOutlet NSTextField *txtPatchFile;
    IBOutlet NSTextFieldCell *lblPatchFormat;
    IBOutlet NSButton *btnCreatePatch;
    PatchFormat currentFormat;
    IBOutlet NSWindow *wndApplyPatch;
    IBOutlet NSWindow *wndCreatePatch;
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
- (NSString*)CreatePatch:(NSString*)origFile :(NSString*)modFile :(NSString*)createFile;
@end
