//
//  BPSAdapter.m
//  MultiPatch
//

#import "BPSAdapter.h"
#include "flips/flips.h"

@implementation BPSAdapter
+(MPPatchResult*)ApplyPatch:(NSString*)patch toFile:(NSString*)input andCreate:(NSString*)output{
    struct manifestinfo manifestinfo={false, false, NULL};
    errorinfo result = ApplyPatch([patch fileSystemRepresentation],
                                  [input fileSystemRepresentation], NO, //<-- Do not verify input param
                                  [output fileSystemRepresentation], &manifestinfo, NO);
    
    if(result.level == el_warning){
        return [MPPatchResult newMessage:[@"Warning: " stringByAppendingFormat:@"%s", result.description] isWarning:YES];
    }
    else if(result.level != el_ok){
        return [MPPatchResult newMessage:[@"Failed to apply BPS patch: " stringByAppendingFormat:@"%s", result.description] isWarning:NO];
    }
    return nil;
}

+(MPPatchResult*)CreatePatchLinear:(NSString*)orig withMod:(NSString*)modify andCreate:(NSString*)output{
    struct manifestinfo manifestinfo={false, false, NULL};
    errorinfo result = CreatePatch([orig fileSystemRepresentation], [modify fileSystemRepresentation], patchtype::ty_bps_linear, &manifestinfo, [output fileSystemRepresentation]);
    
    if(result.level == el_warning){
        return [MPPatchResult newMessage:[@"Warning: " stringByAppendingFormat:@"%s", result.description] isWarning:YES];
    }
    else if(result.level != el_ok){
        return [MPPatchResult newMessage:[@"Failed to create BPS patch: " stringByAppendingFormat:@"%s", result.description] isWarning:NO];
    }
    return nil;
}

+(MPPatchResult*)CreatePatchDelta:(NSString*)orig withMod:(NSString*)modify andCreate:(NSString*)output{
    struct manifestinfo manifestinfo={false, false, NULL};
    errorinfo result = CreatePatch([orig fileSystemRepresentation], [modify fileSystemRepresentation], patchtype::ty_bps, &manifestinfo, [output fileSystemRepresentation]);
    
    if(result.level == el_warning){
        return [MPPatchResult newMessage:[@"Warning: " stringByAppendingFormat:@"%s", result.description] isWarning:YES];
    }
    else if(result.level != el_ok){
        return [MPPatchResult newMessage:[@"Failed to create BPS patch: " stringByAppendingFormat:@"%s", result.description] isWarning:NO];
    }
    return nil;
}
@end
