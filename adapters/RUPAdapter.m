//
//  RUPAdapter.m
//  MultiPatcher
//
//  Created by Paul Kratt on 12/9/18.
//

#import "RUPAdapter.h"
#include "librup.h"

@implementation RUPAdapter
+(MPPatchResult*)ApplyPatch:(NSString*)patch toFile:(NSString*)input andCreate:(NSString*)output{
    if(![input isEqualToString:output]){
        NSFileManager* fileMan = [NSFileManager defaultManager];
        NSError* error;
        if(![fileMan copyItemAtPath:input toPath:output error:&error])
        {
            return [MPPatchResult newMessage:@"Unable to open original file or write to output file." isWarning:NO];
        }
    }
    //Need to be in temp directory for creating ninja.src temp files on macOS 10.7. 
    chdir([NSTemporaryDirectory() cStringUsingEncoding:[NSString defaultCStringEncoding]]);
    
    int result = rup2_apply([patch cStringUsingEncoding:[NSString defaultCStringEncoding]], [output cStringUsingEncoding:[NSString defaultCStringEncoding]]);
    if(result != 0){
        switch(result){
            case RUP_WRONG_FORMAT:
                return [MPPatchResult newMessage:@"The patch provided is not in a supported format. Only Ninja 2 RUP patches can be applied." isWarning:NO];
            case RUP_UNREADABLE_FILE:
                return [MPPatchResult newMessage:@"The patch provided was not readable." isWarning:NO];
            case RUP_MD5_MISMATCH:
                return [MPPatchResult newMessage:@"File mismatch. This means the file that you tried to patch is the wrong file or wrong version of that file. It is not possible to override this error, you must patch the correct file." isWarning:NO];
            case RUP_BAD_PATCH:
                return [MPPatchResult newMessage:@"The patch you tried to apply contains an unrecognised command. The patch could be invalid, or this patcher didn't do something correctly." isWarning:NO];
            default:
                return [MPPatchResult newMessage:@"Something went so wrong that I don't even know what the error message for it is." isWarning:NO];
        }
    }
    return nil; //Success!
}

+(MPPatchResult*)CreatePatch:(NSString*)orig withMod:(NSString*)modify andCreate:(NSString*)output{
    return [MPPatchResult newMessage:@"Oops, RUP creation not supported." isWarning:NO]; //Success! :-(
}

@end
