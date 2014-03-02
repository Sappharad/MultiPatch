//
//  CreationController.mm
//  MultiPatch
//

#import "CreationController.h"
#include "libups.hpp"
#include "XDeltaAdapter.h"
#include "IPSAdapter.h"
#include "PPFAdapter.h"
#include "BSdiffAdapter.h"
#include "BPSAdapter.h"

@implementation CreationController

- (IBAction)btnPickOrig:(id)sender {
    NSOpenPanel *fbox = [NSOpenPanel openPanel];
	[fbox beginSheetForDirectory:nil file:nil modalForWindow:wndCreatePatch modalDelegate:self 
                  didEndSelector:@selector(pickOrgPanelDidEnd: returnCode: contextInfo:) contextInfo:nil];
}

- (void)pickOrgPanelDidEnd:(NSOpenPanel *)panel returnCode:(int)returnCode  contextInfo:(void  *)contextInfo{
	if(returnCode == NSOKButton){
		NSString* selfile = [[panel filenames] objectAtIndex:0];
		[txtOrigFile setStringValue:selfile];
	}
}

- (IBAction)btnPickModified:(id)sender{
    NSOpenPanel *fbox = [NSOpenPanel openPanel];
	[fbox beginSheetForDirectory:nil file:nil modalForWindow:wndCreatePatch modalDelegate:self 
                  didEndSelector:@selector(pickModPanelDidEnd: returnCode: contextInfo:) contextInfo:nil];
}

- (void)pickModPanelDidEnd:(NSOpenPanel *)panel returnCode:(int)returnCode  contextInfo:(void  *)contextInfo{
	if(returnCode == NSOKButton){
		NSString* selfile = [[panel filenames] objectAtIndex:0];
		[txtModFile setStringValue:selfile];
	}
}

- (IBAction)btnPickOutput:(id)sender{
    NSSavePanel *fbox = [NSSavePanel savePanel];
	[fbox setExtensionHidden:NO];
    [ddFormats removeAllItems];
    [ddFormats addItemWithTitle:@"UPS Patch (*.ups)"];
    [ddFormats addItemWithTitle:@"IPS Patch (*.ips)"];
    //[ddFormats addItemWithTitle:@"PPF Patch (*.ppf)"]; //No PPF creation in LibPPF. :-(
    [ddFormats addItemWithTitle:@"XDelta Patch (*.delta)"];
    [ddFormats addItemWithTitle:@"BSDiff Patch (*.bdf)"];
    [ddFormats addItemWithTitle:@"Linear BPS Patch (*.bps)"];
    [ddFormats addItemWithTitle:@"Delta BPS Patch (*.bps)"];
    [fbox setAccessoryView:vwFormatPicker];
	[fbox beginSheetForDirectory:nil file:nil modalForWindow:wndCreatePatch modalDelegate:self 
                  didEndSelector:@selector(selOutputPanelEnd: returnCode: contextInfo:) contextInfo:nil];
}

- (void)selOutputPanelEnd:(NSSavePanel*)panel returnCode:(int)returnCode contextInfo:(void*)contextInfo{
	if(returnCode == NSOKButton){
		NSString* selfile = [panel filename];
        bool bps_delta = false;
        if([[ddFormats titleOfSelectedItem] hasPrefix:@"UPS"] && ![selfile hasSuffix:@".ups"]){
            selfile = [selfile stringByAppendingString:@".ups"];
        }
        else if([[ddFormats titleOfSelectedItem] hasPrefix:@"Linear BPS"] && ![selfile hasSuffix:@".bps"]){
            selfile = [selfile stringByAppendingString:@".bps"];
        }
        else if([[ddFormats titleOfSelectedItem] hasPrefix:@"Delta BPS"] && ![selfile hasSuffix:@".bps"]){
            selfile = [selfile stringByAppendingString:@".bps"];
            bps_delta = true;
        }
        else if([[ddFormats titleOfSelectedItem] hasPrefix:@"IPS"] && ![selfile hasSuffix:@".ips"]){
            selfile = [selfile stringByAppendingString:@".ips"];
        }
        else if([[ddFormats titleOfSelectedItem] hasPrefix:@"XDelta"] && ![selfile hasSuffix:@".delta"]){
            selfile = [selfile stringByAppendingString:@".delta"];
        }
        else if([[ddFormats titleOfSelectedItem] hasPrefix:@"BSDiff"] && ![selfile hasSuffix:@".bdf"]){
            selfile = [selfile stringByAppendingString:@".bdf"];
        }
        [txtPatchFile setStringValue:selfile];
        currentFormat = [PatchController detectPatchFormat:selfile];
        if(currentFormat == UPSPAT){
            [lblPatchFormat setStringValue:@"UPS Patch"];
        }
        else if(currentFormat == IPSPAT){
            [lblPatchFormat setStringValue:@"IPS Patch"];
        }
        else if(currentFormat == XDELTAPAT){
            [lblPatchFormat setStringValue:@"XDelta Patch"];
        }
        /*else if(currentFormat == PPFPAT){
            [lblPatchFormat setStringValue:@"PPF Patch"];
        }*/
        else if(currentFormat == BSDIFFPAT){
            [lblPatchFormat setStringValue:@"BSDiff Patch"];
        }
        else if(currentFormat == BPSPAT){
            if(bps_delta){
                [lblPatchFormat setStringValue:@"BPS Patch (Delta)"];
                currentFormat = BPSDELTA;
            }
            else{
                [lblPatchFormat setStringValue:@"BPS Patch (Linear)"];
            }
        }
        else{
            [lblPatchFormat setStringValue:@"Unknown"];
        }
        [btnCreatePatch setEnabled:currentFormat!=UNKNOWNPAT];
	}
}

- (IBAction)btnCreatePatch:(id)sender{
    NSFileManager *fileManager = [NSFileManager defaultManager];
	NSString *origPath = [txtOrigFile stringValue];
	NSString *modPath = [txtModFile stringValue];
	NSString *patchPath = [txtPatchFile stringValue];
	//NSRange lastSlash = [patchPath rangeOfString:@"/" options:NSBackwardsSearch];
	
	if([fileManager fileExistsAtPath:origPath] && [fileManager fileExistsAtPath:modPath]){
		if([origPath length] > 0 && [modPath length] > 0 && [patchPath length] > 0){
			[lblStatus setStringValue:@"Now creating patch..."];
			[NSApp beginSheet:pnlPatching modalForWindow:wndCreatePatch modalDelegate:nil didEndSelector:nil contextInfo:nil];
            //Make a sheet
            [barProgress setUsesThreadedAnimation:YES]; //Make sure it animates.
			[barProgress startAnimation:self];
			NSString* errMsg = [self CreatePatch:origPath :modPath :patchPath];
			[barProgress stopAnimation:self];
			[NSApp endSheet:pnlPatching]; //Tell the sheet we're done.
			[pnlPatching orderOut:self]; //Lets hide the sheet.
			
			if(errMsg == nil){
				NSRunAlertPanel(@"Finished!",@"The patch was created sucessfully!",@"Okay",nil,nil);
			}
			else{
				NSRunAlertPanel(@"Patch creation failed.", errMsg, @"Okay", nil, nil);
				[errMsg release];
				errMsg = nil;
			}
		}
		else{
			NSRunAlertPanel(@"Not ready yet",@"All of the files above must be chosen before patching is possible.",@"Okay",nil,nil);
		}
	}
	else{
		NSRunAlertPanel(@"Input file(s) not found",@"The input files must be selected and should exist.",@"Okay",nil,nil);	
	}

}

- (IBAction)btnApplyMode:(id)sender {
    [wndApplyPatch setFrameOrigin:[wndCreatePatch frame].origin];
    [wndApplyPatch makeKeyAndOrderFront:self];
    [wndCreatePatch orderOut:self];
}

- (NSString*)CreatePatch:(NSString*)origFile :(NSString*)modFile :(NSString*)createFile{
    NSString* retval = nil;
	if(currentFormat == UPSPAT){
		UPS ups; //UPS Patcher
		bool result = ups.create([origFile cStringUsingEncoding:[NSString defaultCStringEncoding]], [modFile cStringUsingEncoding:[NSString defaultCStringEncoding]], [createFile cStringUsingEncoding:[NSString defaultCStringEncoding]]);
		if(result == false){
			retval = [NSString stringWithCString:ups.error encoding:NSASCIIStringEncoding];
			[retval retain];
		}
	}
	else if(currentFormat == IPSPAT){
		retval = [IPSAdapter CreatePatch:origFile withMod:modFile andCreate:createFile];
	}
	else if(currentFormat == XDELTAPAT){
        retval = [XDeltaAdapter CreatePatch:origFile withMod:modFile andCreate:createFile];
	}
	else if(currentFormat == PPFPAT){
		retval = [PPFAdapter CreatePatch:origFile withMod:modFile andCreate:createFile];
	}
    else if(currentFormat == BSDIFFPAT){
        retval = [BSdiffAdapter CreatePatch:origFile withMod:modFile andCreate:createFile];
    }
    else if(currentFormat == BPSPAT){
        retval = [BPSAdapter CreatePatchLinear:origFile withMod:modFile andCreate:createFile];
    }
    else if(currentFormat == BPSDELTA){
        retval = [BPSAdapter CreatePatchDelta:origFile withMod:modFile andCreate:createFile];
    }
	return retval;
}
@end
