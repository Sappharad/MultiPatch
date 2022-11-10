#import "MPPatchWindow.h"
#if defined(HAVE_XDELTA)
#import "XDeltaAdapter.h"
#endif
#import "IPSAdapter.h"
#import "PPFAdapter.h"
#import "BSdiffAdapter.h"
#import "BPSAdapter.h"
#import "UPSAdapter.h"
#import "RUPAdapter.h"
#import "MPPatchResult.h"

@implementation MPPatchWindow
static mbFlipWindow* _flipper;

-(void)awakeFromNib{
    [super awakeFromNib];
    _flipper = [mbFlipWindow new];
}

-(void)close{
    [super close];
    [[NSApplication sharedApplication] terminate:nil];
}

-(void)makeKeyAndOrderFront:(id)sender{
    [super makeKeyAndOrderFront:sender]; //This one gets called when mbFlipWindow flips back to this window
    [self onOrderFront];
}

-(void)orderFront:(id)sender{
    [super orderFront:sender]; //This one gets called when the app starts
    [self onOrderFront];
}

-(void)onOrderFront{
    txtRomPath.acceptFileDrop = ^BOOL(NSURL * target) {
        [self setTargetFile:target];
        return YES;
    };
    txtPatchPath.acceptFileDrop = ^BOOL(NSURL * target) {
        [self setPatchFile:target];
        return YES;
    };
}

-(void)orderOut:(id)sender{
    [super orderOut:sender];
    txtRomPath.acceptFileDrop = nil;
    txtPatchPath.acceptFileDrop = nil;
}

- (IBAction)btnApply:(id)sender {
    NSFileManager *fileManager = [NSFileManager defaultManager];
	NSString *romPath = [txtRomPath stringValue];
	NSString *outputPath = [txtOutputPath stringValue];
	NSString *patchPath = [txtPatchPath stringValue];

	if([fileManager fileExistsAtPath:patchPath]){
		if([romPath length] > 0 && [outputPath length] > 0 && [patchPath length] > 0){
			[lblStatus setStringValue:@"Now patching..."];
            [NSApp beginSheet:pnlPatching modalForWindow:self modalDelegate:nil didEndSelector:nil contextInfo:nil]; //Make a sheet
			[barProgress setUsesThreadedAnimation:YES]; //Make sure it animates.
			[barProgress startAnimation:self];
			MPPatchResult* errMsg = [self ApplyPatch:patchPath :romPath :outputPath];
			[barProgress stopAnimation:self];
			[NSApp endSheet:pnlPatching]; //Tell the sheet we're done.
			[pnlPatching orderOut:self]; //Lets hide the sheet.

			if(errMsg == nil){
                NSRunAlertPanel(@"Finished!", @"The file was patched successfully.", @"Okay", nil, nil);
			}
            else if(errMsg.IsWarning){
                NSRunAlertPanel(@"Patching finished with warning", errMsg.Message, @"Okay", nil, nil);
                #if !__has_feature(objc_arc)
                [errMsg release];
                #endif
                errMsg = nil;
            }
            else{
				NSRunAlertPanel(@"Patching failed", errMsg.Message, @"Okay", nil, nil);
                #if !__has_feature(objc_arc)
				[errMsg release];
                #endif
				errMsg = nil;
			}
		}
		else{
			NSRunAlertPanel(@"Not ready yet",@"All of the files above must be chosen before patching is possible.",@"Okay",nil,nil);
		}
	}
	else{
		NSRunAlertPanel(@"Patch not found", @"The patch file selected does not exist anymore.\nWhy did you do that?", @"Okay", nil, nil);
	}
}

-(void)setPatchFile:(NSURL*)patch{
    NSString* selfile = [patch path];
    [txtPatchPath setStringValue:selfile];
    currentFormat = [MPPatchWindow detectPatchFormat:selfile];
    [btnApply setEnabled:currentFormat!=UNKNOWNPAT];
    switch (currentFormat) {
        case UPSPAT:
            [lblPatchFormat setStringValue:@"UPS"];
            break;
        #if defined(HAVE_XDELTA)
        case XDELTAPAT:
            [lblPatchFormat setStringValue:@"XDelta"];
            break;
        #endif
        case IPSPAT:
            [lblPatchFormat setStringValue:@"IPS"];
            break;
        case PPFPAT:
            [lblPatchFormat setStringValue:@"PPF"];
            break;
        case BSDIFFPAT:
            [lblPatchFormat setStringValue:@"BSDiff"];
            break;
        case BPSPAT:
            [lblPatchFormat setStringValue:@"BPS"];
            break;
        case RUPPAT:
            [lblPatchFormat setStringValue:@"Ninja (RUP)"];
            break;
        default:
            [lblPatchFormat setStringValue:@"Not supported"];
            break;
    }
}

- (IBAction)btnSelectPatch:(id)sender{
	NSOpenPanel *fbox = [NSOpenPanel openPanel];
    [fbox beginSheetModalForWindow:self completionHandler:^(NSInteger result) {
        if(result == NSOKButton){
            [self setPatchFile:[[fbox URLs] objectAtIndex:0]];
        }
    }];
}

-(void)setTargetFile:(NSURL*)target{
    NSString* selfile = [target path];
    [txtRomPath setStringValue:selfile];
    #if !__has_feature(objc_arc)
    if(romFormat != nil){
        [romFormat release];
    }
    #endif
    romFormat = [selfile pathExtension];
    #if !__has_feature(objc_arc)
    [romFormat retain];
    #endif
}

- (IBAction)btnSelectOriginal:(id)sender {
    NSOpenPanel *fbox = [NSOpenPanel openPanel];
    [fbox beginSheetModalForWindow:self completionHandler:^(NSInteger result) {
        if(result == NSOKButton){
            [self setTargetFile:[[fbox URLs] objectAtIndex:0]];
        }
    }];
}

- (IBAction)btnSelectOutput:(id)sender{
	NSSavePanel *fbox = [NSSavePanel savePanel];
	if(romFormat != nil && [romFormat length]>0){
		[fbox setAllowedFileTypes:[NSArray arrayWithObject:romFormat]];
	}
    [fbox beginSheetModalForWindow:self completionHandler:^(NSInteger result) {
        if(result == NSOKButton){
            NSString* selfile = [[fbox URL] path];
            [txtOutputPath setStringValue:selfile];
        }
    }];
}

+ (PatchFormat)detectPatchFormat:(NSString*)patchPath{
	//I'm just going to look at the file extensions for now.
	//In the future, I might wish to actually look at the contents of the file.
    NSString* lowerPath = [patchPath lowercaseString];
	if([lowerPath hasSuffix:@".ups"]){
		return UPSPAT;
	}
	else if([lowerPath hasSuffix:@".ips"]){
		return IPSPAT;
	}
	else if([lowerPath hasSuffix:@".ppf"]){
		return PPFPAT;
	}
    #if defined(HAVE_XDELTA)
	else if([lowerPath hasSuffix:@".dat"] || [lowerPath hasSuffix:@"delta"]){
		return XDELTAPAT;
	}
    #endif
    else if([lowerPath hasSuffix:@".bdf"] || [lowerPath hasSuffix:@".bsdiff"]){
        return BSDIFFPAT;
    }
    else if([lowerPath hasSuffix:@".bps"]){
        return BPSPAT;
    }
    else if([lowerPath hasSuffix:@".rup"]){
        return RUPPAT;
    }
	return UNKNOWNPAT;
}

- (MPPatchResult*)ApplyPatch:(NSString*)patchPath :(NSString*)sourceFile :(NSString*)destFile{
	MPPatchResult* retval = nil;
	if(currentFormat == UPSPAT){
		retval = [UPSAdapter ApplyPatch:patchPath toFile:sourceFile andCreate:destFile];
	}
	else if(currentFormat == IPSPAT){
		retval = [IPSAdapter ApplyPatch:patchPath toFile:sourceFile andCreate:destFile];
	}
    #if defined(HAVE_XDELTA)
	else if(currentFormat == XDELTAPAT){
		retval = [XDeltaAdapter ApplyPatch:patchPath toFile:sourceFile andCreate:destFile];
	}
    #endif
	else if(currentFormat == PPFPAT){
		retval = [PPFAdapter ApplyPatch:patchPath toFile:sourceFile andCreate:destFile];
	}
    else if(currentFormat == BSDIFFPAT){
        retval = [BSdiffAdapter ApplyPatch:patchPath toFile:sourceFile andCreate:destFile];
    }
    else if(currentFormat == BPSPAT){
        retval = [BPSAdapter ApplyPatch:patchPath toFile:sourceFile andCreate:destFile];
    }
    else if(currentFormat == RUPPAT){
        retval = [RUPAdapter ApplyPatch:patchPath toFile:sourceFile andCreate:destFile];
    }
	return retval;
}

- (IBAction)btnCreatePatch:(id)sender {
    _flipper.flipRight = YES;
    [_flipper flip:self to:wndCreator];
}

+ (mbFlipWindow*)flipper{
    return _flipper;
}

@end
