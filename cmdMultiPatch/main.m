//
//  main.m
//  cmdMultiPatch
//
//  Created by Paul Kratt on 11/24/20.
//

#import <Foundation/Foundation.h>
#import "XDeltaAdapter.h"
#import "IPSAdapter.h"
#import "PPFAdapter.h"
#import "BSdiffAdapter.h"
#import "BPSAdapter.h"
#import "UPSAdapter.h"
#import "RUPAdapter.h"

int applyPatch(NSString* patch, NSString* input, NSString* output);
int createPatch(NSString* oldPath, NSString* newPath, NSString* output);

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        printf("MultiPatch Command Line\n");
        if(argc != 5){
            printf("Call this with one of the following sets of arguments:\n");
            printf("  --apply [patchFile] [inputFile] [outFile]\n");
            printf("  --create [oldFile] [newFile] [patchFile]\n");
            return 1;
        }
        NSMutableArray<NSString*>* strArgs = [NSMutableArray<NSString*> new];
        for (int i=0; i<argc; i++) {
            [strArgs addObject:[NSString stringWithCString:argv[i] encoding:NSUTF8StringEncoding]];
        }
        if(!([[strArgs objectAtIndex:1] isEqualToString:@"--apply"] || [[strArgs objectAtIndex:1] isEqualToString:@"--create"])){
            printf("Unexpected argument: %s\n",[[strArgs objectAtIndex:1] UTF8String]);
            return 1;
        }
        NSFileManager* fman = [NSFileManager new];
        if(![fman fileExistsAtPath:[strArgs objectAtIndex:2]]){
            printf("File not found: %s\n", [[strArgs objectAtIndex:2] UTF8String]);
            return 1;
        }
        if(![fman fileExistsAtPath:[strArgs objectAtIndex:3]]){
            printf("File not found: %s\n", [[strArgs objectAtIndex:3] UTF8String]);
            return 1;
        }
        NSString* folder = [[strArgs objectAtIndex:4] stringByDeletingLastPathComponent];
        if(folder.length > 1 && ![fman fileExistsAtPath:folder]){
            printf("The folder where the output file should be created does not exist: %s\n", [[strArgs objectAtIndex:4] UTF8String]);
            return 1;
        }
        //Files are good, let's get started
        if([[strArgs objectAtIndex:1] isEqualToString:@"--apply"]){
            return applyPatch([strArgs objectAtIndex:2], [strArgs objectAtIndex:3], [strArgs objectAtIndex:4]);
        }
        else if([[strArgs objectAtIndex:1] isEqualToString:@"--create"]){
            return createPatch([strArgs objectAtIndex:2], [strArgs objectAtIndex:3], [strArgs objectAtIndex:4]);
        }
    }
    return 0;
}

int applyPatch(NSString* patch, NSString* input, NSString* output){
    MPPatchResult* retval = nil;
    NSString* lowerPath = [patch lowercaseString];
    if([lowerPath hasSuffix:@".ups"]){
        retval = [UPSAdapter ApplyPatch:patch toFile:input andCreate:output];
    }
    else if([lowerPath hasSuffix:@".ips"]){
        retval = [IPSAdapter ApplyPatch:patch toFile:input andCreate:output];
    }
    else if([lowerPath hasSuffix:@".ppf"]){
        retval = [PPFAdapter ApplyPatch:patch toFile:input andCreate:output];
    }
    else if([lowerPath hasSuffix:@".dat"] || [lowerPath hasSuffix:@"delta"]){
        retval = [XDeltaAdapter ApplyPatch:patch toFile:input andCreate:output];
    }
    else if([lowerPath hasSuffix:@".bdf"] || [lowerPath hasSuffix:@".bsdiff"]){
        retval = [BSdiffAdapter ApplyPatch:patch toFile:input andCreate:output];
    }
    else if([lowerPath hasSuffix:@".bps"]){
        retval = [BPSAdapter ApplyPatch:patch toFile:input andCreate:output];
    }
    else if([lowerPath hasSuffix:@".rup"]){
        retval = [RUPAdapter ApplyPatch:patch toFile:input andCreate:output];
    }
    if(retval != nil){
        printf("%s\n",[retval.Message UTF8String]);
        if(!retval.IsWarning){
            return 1;
        }
    }
    printf("Done patching!\n");
    return 0;
}

int createPatch(NSString* oldPath, NSString* newPath, NSString* output){
    MPPatchResult* retval = nil;
    NSString* lowerPath = [output lowercaseString];
    if([lowerPath hasSuffix:@".ips"]){
        retval = [IPSAdapter CreatePatch:oldPath withMod:newPath andCreate:output];
    }
    else if([lowerPath hasSuffix:@".dat"] || [lowerPath hasSuffix:@"delta"]){
        retval = [XDeltaAdapter CreatePatch:oldPath withMod:newPath andCreate:output];
    }
    else if([lowerPath hasSuffix:@".bdf"] || [lowerPath hasSuffix:@".bsdiff"]){
        retval = [BSdiffAdapter CreatePatch:oldPath withMod:newPath andCreate:output];
    }
    else if([lowerPath hasSuffix:@".bps"]){
        retval = [BPSAdapter CreatePatchDelta:oldPath withMod:newPath andCreate:output];
    }
    else if([lowerPath hasSuffix:@".ppf"]){
        retval = [PPFAdapter CreatePatch:oldPath withMod:newPath andCreate:output];
    }
    else{
        printf("Cannot create patch for unsupported file type: %s\n", [output UTF8String]);
        return 1;
    }
    if(retval != nil){
        printf("%s\n",[retval.Message UTF8String]);
        if(!retval.IsWarning){
            return 1;
        }
    }
    printf("Patch created!\n");
    return 0;
}
