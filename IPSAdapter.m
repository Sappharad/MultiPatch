//
//  IPSAdapter.m
//  MultiPatch
//

#import "IPSAdapter.h"
#include "uips/uips.c"


@implementation IPSAdapter
+(NSString*)ApplyPatch:(NSString*)patch toFile:(NSString*)input andCreate:(NSString*)output{
	if(![input isEqualToString:output]){
		NSFileManager* fileMan = [NSFileManager defaultManager];
		if(![fileMan copyPath:input toPath:output handler:nil])
		{
			//Note: copyPath:ToPath is deprecated in 10.5
			//Use if(![fileMan copyItemAtPath:input toPath:output error:NULL]) in 10.5
			return @"Unable to open original file or write to output file.";
		}
	}
    
    int err = apply_patch([patch cStringUsingEncoding:[NSString defaultCStringEncoding]], [output cStringUsingEncoding:[NSString defaultCStringEncoding]]);
    if(err == 1){
        return @"Failed to apply IPS patch!";
    }
	
    return nil;
}

+(NSString*)CreatePatch:(NSString*)orig withMod:(NSString*)modify andCreate:(NSString*)output{
    unsigned listOfOne[1];
    listOfOne[0] = (unsigned)[orig cStringUsingEncoding:[NSString defaultCStringEncoding]];
    int err = create_patch([output cStringUsingEncoding:[NSString defaultCStringEncoding]], 1, (const char**)listOfOne, [modify cStringUsingEncoding:[NSString defaultCStringEncoding]]);
    if(err == 1){
        return @"Failed to create IPS patch!";
    }
	
    return nil;
}
@end
