//
//  BPSAdapter.m
//  MultiPatch
//

#import "BPSAdapter.h"
#include "flips/flips.h"

@implementation BPSAdapter
+(NSString*)ApplyPatch:(NSString*)patch toFile:(NSString*)input andCreate:(NSString*)output{
    struct manifestinfo manifestinfo={false, false, NULL};
    errorinfo result = ApplyPatch([patch cStringUsingEncoding:[NSString defaultCStringEncoding]],
                                  [input cStringUsingEncoding:[NSString defaultCStringEncoding]], NO, //<-- Do not verify input param
                                  [output cStringUsingEncoding:[NSString defaultCStringEncoding]], &manifestinfo, NO);
    
    if(result.level != el_ok){
        return @"Failed to apply BPS patch!";
    }
    return nil;
}

+(NSString*)CreatePatchLinear:(NSString*)orig withMod:(NSString*)modify andCreate:(NSString*)output{
    struct manifestinfo manifestinfo={false, false, NULL};
    errorinfo result = CreatePatch([orig cStringUsingEncoding:[NSString defaultCStringEncoding]], [modify cStringUsingEncoding:[NSString defaultCStringEncoding]], patchtype::ty_bps_linear, &manifestinfo, [output cStringUsingEncoding:[NSString defaultCStringEncoding]]);
    
    if(result.level != el_ok){
        return @"Failed to create BPS patch!";
    }
    
    return nil;
}

+(NSString*)CreatePatchDelta:(NSString*)orig withMod:(NSString*)modify andCreate:(NSString*)output{
    struct manifestinfo manifestinfo={false, false, NULL};
    errorinfo result = CreatePatch([orig cStringUsingEncoding:[NSString defaultCStringEncoding]], [modify cStringUsingEncoding:[NSString defaultCStringEncoding]], patchtype::ty_bps, &manifestinfo, [output cStringUsingEncoding:[NSString defaultCStringEncoding]]);
    
    if(result.level != el_ok){
        return @"Failed to create BPS patch!";
    }
    
    return nil;
}
@end
