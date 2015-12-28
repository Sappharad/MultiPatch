//
//  PPFAdapter.m
//  MultiPatch
//

#import "PPFAdapter.h"
#include "libppf.hh"

@implementation PPFAdapter

+(NSString*)errorMsg:(int)error{
	switch (error) {
		case 0x01:
			return @"Selected patch file is NOT a PPF file!";
		case 0x02:
			return @"PPF version not supported or unknown.";
		case 0x03:
			return @"PPF file not found!";
		case 0x04:
			return @"Error opening PPF file.";
		case 0x05:
			return @"Error closing PPF file.";
		case 0x06:
			return @"Error reading from PPF file.";
		case 0x07:
			return @"PPF file hasn't been loaded";
		case 0x08:
			return @"No undo data available";
		case 0x11:
			return @"Input file not found.";
		case 0x12:
			return @"Error opening file.";
		case 0x13:
			return @"Error closing output file.";
		case 0x14:
			return @"Error reading from input!";
		case 0x15:
			return @"Error writing to output file!";
		default:
			return @"Unknown error code!";
	}
}

+(NSString*)ApplyPatch:(NSString*)patch toFile:(NSString*)input andCreate:(NSString*)output{
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
			return @"Unable to open original file or write to output file.";
		}
	}
	
	// Apply PPF data to file
	if ((error = ppf.applyPatch([output cStringUsingEncoding:[NSString defaultCStringEncoding]], false)) != 0) {
		return [self errorMsg:error];
	}
	return nil; //Success!
}

+(NSString*)CreatePatch:(NSString*)orig withMod:(NSString*)modify andCreate:(NSString*)output{
    return @"Oops, PPF creation not supported."; //Success! :-(
}
@end
