//
//  PPFAdapter.m
//  MultiPatch
//

#import "PPFAdapter.h"
#include "libppf.hh"

@implementation PPFAdapter

+(MPPatchResult*)errorMsg:(int)error{
	switch (error) {
		case 0x01:
            return [MPPatchResult newMessage:@"Selected patch file is NOT a PPF file!" isWarning:NO];
		case 0x02:
            return [MPPatchResult newMessage:@"PPF version not supported or unknown." isWarning:NO];
		case 0x03:
            return [MPPatchResult newMessage:@"PPF file not found!" isWarning:NO];
		case 0x04:
            return [MPPatchResult newMessage:@"Error opening PPF file." isWarning:NO];
		case 0x05:
			return [MPPatchResult newMessage:@"Error closing PPF file." isWarning:NO];
		case 0x06:
			return [MPPatchResult newMessage:@"Error reading from PPF file." isWarning:NO];
		case 0x07:
			return [MPPatchResult newMessage:@"PPF file hasn't been loaded" isWarning:NO];
		case 0x08:
			return [MPPatchResult newMessage:@"No undo data available" isWarning:NO];
		case 0x11:
			return [MPPatchResult newMessage:@"Input file not found." isWarning:NO];
		case 0x12:
			return [MPPatchResult newMessage:@"Error opening file." isWarning:NO];
		case 0x13:
			return [MPPatchResult newMessage:@"Error closing output file. Patching may have finished, but this is not certain." isWarning:YES];
		case 0x14:
			return [MPPatchResult newMessage:@"Error reading from input!" isWarning:NO];
		case 0x15:
			return [MPPatchResult newMessage:@"Error writing to output file!" isWarning:NO];
		default:
            return [MPPatchResult newMessage:@"Unknown error code!" isWarning:NO];
	}
}

+(MPPatchResult*)ApplyPatch:(NSString*)patch toFile:(NSString*)input andCreate:(NSString*)output{
	lppf::LibPPF ppf;
	int error;
	
	if ((error = ppf.loadPatch([patch cStringUsingEncoding:[NSString defaultCStringEncoding]])) != 0) {
		return [self errorMsg:error];
	}
	
	if(![input isEqualToString:output]){
		NSFileManager* fileMan = [NSFileManager defaultManager];
        NSError* error;
        if(![fileMan copyItemAtPath:input toPath:output error:&error])
		{
            return [MPPatchResult newMessage:@"Unable to open original file or write to output file." isWarning:NO];
		}
	}
	
	// Apply PPF data to file
	if ((error = ppf.applyPatch([output cStringUsingEncoding:[NSString defaultCStringEncoding]], false)) != 0) {
		return [self errorMsg:error];
	}
	return nil; //Success!
}

+(MPPatchResult*)CreatePatch:(NSString*)orig withMod:(NSString*)modify andCreate:(NSString*)output{
    return [MPPatchResult newMessage:@"Oops, PPF creation not supported." isWarning:NO]; //Success! :-(
}
@end
