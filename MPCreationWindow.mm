//
//  CreationController.mm
//  MultiPatch
//

#import "MPCreationWindow.h"
#import "XDeltaAdapter.h"
#import "IPSAdapter.h"
#import "PPFAdapter.h"
#import "BSdiffAdapter.h"
#import "BPSAdapter.h"
#import "UPSAdapter.h"
#import "MPPatchResult.h"

@implementation MPCreationWindow

-(void)close{
    [super close];
    [[NSApplication sharedApplication] terminate:nil];
}

-(void)makeKeyAndOrderFront:(id)sender{
    [super makeKeyAndOrderFront:sender];
    txtOrigFile.acceptFileDrop = ^BOOL(NSURL * target) {
        [self setOriginalFile:target];
        return YES;
    };
    txtModFile.acceptFileDrop = ^BOOL(NSURL * target) {
        [self setModifiedFile:target];
        return YES;
    };
}

-(void)orderOut:(id)sender{
    [super orderOut:sender]; //This is what you do when you order a pizza
    txtOrigFile.acceptFileDrop = nil;
    txtModFile.acceptFileDrop = nil;
}

-(void)setOriginalFile:(NSURL*)original{
    NSString* selfile = [original path];
    [txtOrigFile setStringValue:selfile];
}

- (IBAction)btnPickOrig:(id)sender {
    NSOpenPanel *fbox = [NSOpenPanel openPanel];
    [fbox beginSheetModalForWindow:self completionHandler:^(NSInteger result) {
        if(result == NSOKButton){
            [self setOriginalFile:[[fbox URLs] objectAtIndex:0]];
        }
    }];
}

-(void)setModifiedFile:(NSURL*)modified{
    NSString* selfile = [modified path];
    [txtModFile setStringValue:selfile];
}

- (IBAction)btnPickModified:(id)sender{
    NSOpenPanel *fbox = [NSOpenPanel openPanel];
    [fbox beginSheetModalForWindow:self completionHandler:^(NSInteger result) {
        if(result == NSOKButton){
            [self setModifiedFile:[[fbox URLs] objectAtIndex:0]];
        }
    }];
}

- (IBAction)btnPickOutput:(id)sender{
    NSSavePanel *fbox = [NSSavePanel savePanel];
	[fbox setExtensionHidden:NO];
    [ddFormats removeAllItems];
    //Put Delta BPS on top because it's the preferred format.
    [ddFormats addItemWithTitle:@"Delta BPS Patch (*.bps)"];
    [ddFormats addItemWithTitle:@"Linear BPS Patch (*.bps)"];
    //[ddFormats addItemWithTitle:@"UPS Patch (*.ups)"];
    //FLIPS does not create UPS. It's deprecated anyway, so use BPS instead
    [ddFormats addItemWithTitle:@"IPS Patch (*.ips)"];
    [ddFormats addItemWithTitle:@"PPF Patch (*.ppf)"];
    [ddFormats addItemWithTitle:@"XDelta Patch (*.delta)"];
    [ddFormats addItemWithTitle:@"BSDiff Patch (*.bdf)"];
    [fbox setAccessoryView:vwFormatPicker];
    [fbox beginSheetModalForWindow:self completionHandler:^(NSInteger result) {
        [self selOutputPanelEnd:fbox returnCode:result];
    }];
}

- (void)selOutputPanelEnd:(NSSavePanel*)panel returnCode:(long)returnCode{
	if(returnCode == NSOKButton){
		NSString* selfile = [[panel URL] path];
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
        else if([[ddFormats titleOfSelectedItem] hasPrefix:@"PPF"] && ![selfile hasSuffix:@".ppf"]){
            selfile = [selfile stringByAppendingString:@".ppf"];
        }
        else if([[ddFormats titleOfSelectedItem] hasPrefix:@"XDelta"] && ![selfile hasSuffix:@".delta"]){
            selfile = [selfile stringByAppendingString:@".delta"];
        }
        else if([[ddFormats titleOfSelectedItem] hasPrefix:@"BSDiff"] && ![selfile hasSuffix:@".bdf"]){
            selfile = [selfile stringByAppendingString:@".bdf"];
        }
        [txtPatchFile setStringValue:selfile];
        currentFormat = [MPPatchWindow detectPatchFormat:selfile];
        if(currentFormat == IPSPAT){
            [lblPatchFormat setStringValue:@"IPS Patch"];
        }
        /*else if(currentFormat == UPSPAT){
            [lblPatchFormat setStringValue:@"UPS Patch"];
        }*/
        else if(currentFormat == XDELTAPAT){
            [lblPatchFormat setStringValue:@"XDelta Patch"];
        }
        else if(currentFormat == PPFPAT){
            [lblPatchFormat setStringValue:@"PPF Patch"];
        }
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
			[NSApp beginSheet:pnlPatching modalForWindow:self modalDelegate:nil didEndSelector:nil contextInfo:nil];
            //Make a sheet
            [barProgress setUsesThreadedAnimation:YES]; //Make sure it animates.
			[barProgress startAnimation:self];
			MPPatchResult* errMsg = [self CreatePatch:origPath :modPath :patchPath];
			[barProgress stopAnimation:self];
			[NSApp endSheet:pnlPatching]; //Tell the sheet we're done.
			[pnlPatching orderOut:self]; //Lets hide the sheet.
			
			if(errMsg == nil){
				NSRunAlertPanel(@"Finished!",@"The patch was created sucessfully!",@"Okay",nil,nil);
			}
            else if(errMsg.IsWarning){
                NSRunAlertPanel(@"Patch creation finished with warning.", errMsg.Message, @"Okay", nil, nil);
                [errMsg release];
                errMsg = nil;
            }
			else{
				NSRunAlertPanel(@"Patch creation failed.", errMsg.Message, @"Okay", nil, nil);
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
    mbFlipWindow* flipper = [MPPatchWindow flipper];
    flipper.flipRight = NO;
    [flipper flip:self to:wndApplyPatch];
}

- (MPPatchResult*)CreatePatch:(NSString*)origFile :(NSString*)modFile :(NSString*)createFile{
    MPPatchResult* retval = nil;
	if(currentFormat == UPSPAT){
		retval = [UPSAdapter CreatePatch:origFile withMod:modFile andCreate:createFile];
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
