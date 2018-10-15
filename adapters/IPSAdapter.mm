//
//  IPSAdapter.m
//  MultiPatch
//

#import "IPSAdapter.h"
#include "flips/flips.h"

@implementation IPSAdapter
+(NSString*)ApplyPatch:(NSString*)patch toFile:(NSString*)input andCreate:(NSString*)output{
	struct manifestinfo manifestinfo={false, false, NULL};
    errorinfo result = ApplyPatch([patch cStringUsingEncoding:[NSString defaultCStringEncoding]],
               [input cStringUsingEncoding:[NSString defaultCStringEncoding]], NO, //<-- Do not verify input param
               [output cStringUsingEncoding:[NSString defaultCStringEncoding]], &manifestinfo, NO);
    
    if(result.level != el_ok){
        return @"Failed to apply IPS patch!";
    }
    return nil;
}

+(NSString*)CreatePatch:(NSString*)orig withMod:(NSString*)modify andCreate:(NSString*)output{
    struct manifestinfo manifestinfo={false, false, NULL};
    errorinfo result = CreatePatch([orig cStringUsingEncoding:[NSString defaultCStringEncoding]], [modify cStringUsingEncoding:[NSString defaultCStringEncoding]], patchtype::ty_ips, &manifestinfo, [output cStringUsingEncoding:[NSString defaultCStringEncoding]]);
    
    if(result.level != el_ok){
        return @"Failed to create IPS patch!";
    }
	
    return nil;
}
@end
