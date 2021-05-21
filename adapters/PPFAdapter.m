//
//  PPFAdapter.m
//  MultiPatch
//

#import "PPFAdapter.h"
#include "ppf3.h"

@implementation PPFAdapter
+(MPPatchResult*)ApplyPatch:(NSString*)patch toFile:(NSString*)input andCreate:(NSString*)output{
    if(![input isEqualToString:output]){
        NSFileManager* fileMan = [NSFileManager defaultManager];
        NSError* error;
        if(![fileMan copyItemAtPath:input toPath:output error:&error])
        {
            return [MPPatchResult newMessage:@"Unable to open original file or write to output file." isWarning:NO];
        }
    }
    
    int result = applyPPF([output cStringUsingEncoding:[NSString defaultCStringEncoding]], [patch cStringUsingEncoding:[NSString defaultCStringEncoding]]);
    if(result != 0){
        switch(result){
            case PPFERROR_VERSION_UNSUPPORTED:
                return [MPPatchResult newMessage:@"The version of this PPF file is unsupported." isWarning:NO];
            case PPFERROR_NO_UNDO_DATA:
                return [MPPatchResult newMessage:@"The PPF File has no Undo data." isWarning:NO];
            case PPFERROR_PATCH_VALIDATION_FAILED:
                return [MPPatchResult newMessage:@"The PPF Patch failed validation." isWarning:NO];
            case PPFERROR_WRONG_INPUT_SIZE:
                return [MPPatchResult newMessage:@"The file you want to patch is not correct file for this PPF patch." isWarning:NO];
            case PPFERROR_FAILED_TO_OPEN:
                return [MPPatchResult newMessage:@"Failed to open one of the files that you selected." isWarning:NO];
        }
        return [MPPatchResult newMessage:@"Unexpected error applying PPF Patch." isWarning:NO];
    }
    return nil; //Success!
}

+(MPPatchResult*)CreatePatch:(NSString*)orig withMod:(NSString*)modify andCreate:(NSString*)output{
    int result = makePPF([orig cStringUsingEncoding:NSString.defaultCStringEncoding], [modify cStringUsingEncoding:NSString.defaultCStringEncoding], [output cStringUsingEncoding:NSString.defaultCStringEncoding]);
    if(result != 0){
        switch(result){
            case PPFERROR_FAILED_TO_OPEN:
                return [MPPatchResult newMessage:@"Failed to open one of the files that you selected." isWarning:NO];
            case PPFERROR_WRONG_INPUT_SIZE:
                return [MPPatchResult newMessage:@"The size of the files you want to create a patch for are not the same, or are empty." isWarning:NO];
            case PPFERROR_FAILED_TO_CREATE:
                return [MPPatchResult newMessage:@"Failed to create a new file at the selected output location." isWarning:NO];
            case PPFERROR_HEADER_FAILED:
                return [MPPatchResult newMessage:@"Failed to create a header for the patch." isWarning:NO];
            case PPFERROR_OUT_OF_MEMORY:
                return [MPPatchResult newMessage:@"Not enough memory is available to create a patch for the selected input files." isWarning:NO];
        }
        return [MPPatchResult newMessage:@"Unexpected error creating PPF Patch." isWarning:NO];
    }
    return nil;
}
@end
