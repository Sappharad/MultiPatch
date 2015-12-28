#import "PatchController.h"
#include "libups.hpp"
#include "XDeltaAdapter.h"
#include "IPSAdapter.h"
#include "PPFAdapter.h"
#include "BSdiffAdapter.h"
#include "BPSAdapter.h"

@implementation PatchController
static mbFlipWindow* _flipper;

-(id)init{
    if(self=[super init]){
        _flipper = [mbFlipWindow new];
    }
    return self;
}

- (IBAction)btnApply:(id)sender {
    NSFileManager *fileManager = [NSFileManager defaultManager];
	NSString *romPath = [txtRomPath stringValue];
	NSString *outputPath = [txtOutputPath stringValue];
	NSString *patchPath = [txtPatchPath stringValue];
	//NSRange lastSlash = [patchPath rangeOfString:@"/" options:NSBackwardsSearch];
	
	if([fileManager fileExistsAtPath:patchPath]){
		if([romPath length] > 0 && [outputPath length] > 0 && [patchPath length] > 0){
			[lblStatus setStringValue:@"Now patching..."];
            [NSApp beginSheet:pnlPatching modalForWindow:wndPatcher modalDelegate:nil didEndSelector:nil contextInfo:nil]; //Make a sheet
			[barProgress setUsesThreadedAnimation:YES]; //Make sure it animates.
			[barProgress startAnimation:self];
			NSString* errMsg = [self ApplyPatch:patchPath :romPath :outputPath];
			[barProgress stopAnimation:self];
			[NSApp endSheet:pnlPatching]; //Tell the sheet we're done.
			[pnlPatching orderOut:self]; //Lets hide the sheet.
			
			if(errMsg == nil){
				NSRunAlertPanel(@"Finished!",@"The file was patched sucessfully.",@"Okay",nil,nil);
			}
			else{
				NSRunAlertPanel(@"Patching failed", errMsg, @"Okay", nil, nil);
				[errMsg release];
				errMsg = nil;
			}
		}
		else{
			NSRunAlertPanel(@"Not ready yet",@"All of the files above must be chosen before patching is possible.",@"Okay",nil,nil);
		}
	}
	else{
		NSRunAlertPanel(@"Patch not found",@"The patch file selected does not exist.\nWhy did you do that?",@"Okay",nil,nil);	
	}
}

- (IBAction)btnBrowse:(id)sender {
    NSOpenPanel *fbox = [NSOpenPanel openPanel];
    [fbox beginSheetModalForWindow:wndPatcher completionHandler:^(NSInteger result) {
        if(result == NSOKButton){
            NSString* selfile = [[[fbox URLs] objectAtIndex:0] path];
            [txtRomPath setStringValue:selfile];
            if(romFormat != nil){
                [romFormat release];
            }
            romFormat = [selfile pathExtension];
            [romFormat retain];
        }
    }];
}

- (IBAction)btnSelectPatch:(id)sender{
	NSOpenPanel *fbox = [NSOpenPanel openPanel];
    [fbox beginSheetModalForWindow:wndPatcher completionHandler:^(NSInteger result) {
        if(result == NSOKButton){
            NSString* selfile = [[[fbox URLs] objectAtIndex:0] path];
            [txtPatchPath setStringValue:selfile];
            currentFormat = [PatchController detectPatchFormat:selfile];
            [btnApply setEnabled:currentFormat!=UNKNOWNPAT];
            switch (currentFormat) {
                case UPSPAT:
                    [lblPatchFormat setStringValue:@"UPS"];
                    break;
                case XDELTAPAT:
                    [lblPatchFormat setStringValue:@"XDelta"];
                    break;
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
                default:
                    [lblPatchFormat setStringValue:@"Not supported"];
                    break;
            }
        }
    }];
}

- (IBAction)btnSelectOutput:(id)sender{
	NSSavePanel *fbox = [NSSavePanel savePanel];
	if(romFormat != nil && [romFormat length]>0){
		[fbox setAllowedFileTypes:[NSArray arrayWithObject:romFormat]];
	}
    [fbox beginSheetModalForWindow:wndPatcher completionHandler:^(NSInteger result) {
        if(result == NSOKButton){
            NSString* selfile = [[fbox URL] path];
            [txtOutputPath setStringValue:selfile];
        }
    }];
}

+ (PatchFormat)detectPatchFormat:(NSString*)patchPath{
	//I'm just going to look at the file extensions for now.
	//In the future, I might wish to actually look at the contents of the file.
	if([patchPath hasSuffix:@".ups"]){
		return UPSPAT;
	}
	else if([patchPath hasSuffix:@".ips"]){
		return IPSPAT;
	}
	else if([patchPath hasSuffix:@".ppf"]){
		return PPFPAT;
	}
	else if([patchPath hasSuffix:@".dat"] || [patchPath hasSuffix:@"delta"]){
		return XDELTAPAT;
	}
    else if([patchPath hasSuffix:@".bdf"] || [patchPath hasSuffix:@".bsdiff"]){
        return BSDIFFPAT;
    }
    else if([patchPath hasSuffix:@".bps"]){
        return BPSPAT;
    }
	return UNKNOWNPAT;
}

- (NSString*)ApplyPatch:(NSString*)patchPath :(NSString*)sourceFile :(NSString*)destFile{
	NSString* retval = nil;
	if(currentFormat == UPSPAT){
		UPS ups; //UPS Patcher
		bool result = ups.apply([sourceFile cStringUsingEncoding:[NSString defaultCStringEncoding]], [destFile cStringUsingEncoding:[NSString defaultCStringEncoding]], [patchPath cStringUsingEncoding:[NSString defaultCStringEncoding]]);
		if(result == false){
			retval = [NSString stringWithCString:ups.error encoding:NSASCIIStringEncoding];
			[retval retain];
		}
	}
	else if(currentFormat == IPSPAT){
		retval = [IPSAdapter ApplyPatch:patchPath toFile:sourceFile andCreate:destFile];
	}
	else if(currentFormat == XDELTAPAT){
		retval = [XDeltaAdapter ApplyPatch:patchPath toFile:sourceFile andCreate:destFile];
	}
	else if(currentFormat == PPFPAT){
		retval = [PPFAdapter ApplyPatch:patchPath toFile:sourceFile andCreate:destFile];
	}
    else if(currentFormat == BSDIFFPAT){
        retval = [BSdiffAdapter ApplyPatch:patchPath toFile:sourceFile andCreate:destFile];
    }
    else if(currentFormat == BPSPAT){
        retval = [BPSAdapter ApplyPatch:patchPath toFile:sourceFile andCreate:destFile];
    }
	return retval;
}

- (IBAction)btnCreatePatch:(id)sender {
    _flipper.flipRight = YES;
    [_flipper flip:wndPatcher to:wndCreator];
}

+ (mbFlipWindow*)flipper{
    return _flipper;
}

@end
