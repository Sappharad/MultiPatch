//
//  MultiPatchController.h
//  MultiPatcher
//
//  Created by Paul Kratt on 12/1/18.
//

#import <Cocoa/Cocoa.h>
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MultiPatchController : NSObject<NSApplicationDelegate>
@property (assign) IBOutlet NSWindow *wndPreferences;
@property (assign) IBOutlet NSButton *chkIgnoreXDelta;
@property (assign) IBOutlet NSButton *chkCheckForUpdates;

- (IBAction)showPreferences:(id)sender;
- (IBAction)chkIgnoreXdelta_Changed:(id)sender;
- (IBAction)chkCheckForUpdates_Changed:(id)sender;
@end

NS_ASSUME_NONNULL_END
