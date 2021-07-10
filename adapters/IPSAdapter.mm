//
//  IPSAdapter.m
//  MultiPatch
//

#import "IPSAdapter.h"
#include "flips/flips.h"

@implementation IPSAdapter
+(MPPatchResult*)ApplyPatch:(NSString*)patch toFile:(NSString*)input andCreate:(NSString*)output{
	struct manifestinfo manifestinfo={false, false, NULL};
    errorinfo result = ApplyPatch([patch fileSystemRepresentation],
               [input fileSystemRepresentation], NO, //<-- Do not verify input param
               [output fileSystemRepresentation], &manifestinfo, NO);
    
    if(result.level == el_warning){
        return [MPPatchResult newMessage:[@"Warning: " stringByAppendingFormat:@"%s", result.description] isWarning:YES];
    }
    else if(result.level != el_ok){
        return [MPPatchResult newMessage:[@"Failed to apply IPS patch: " stringByAppendingFormat:@"%s", result.description] isWarning:NO];
    }
    return nil;
}

+(MPPatchResult*)CreatePatch:(NSString*)orig withMod:(NSString*)modify andCreate:(NSString*)output{
    struct manifestinfo manifestinfo={false, false, NULL};
    errorinfo result = CreatePatch([orig fileSystemRepresentation], [modify fileSystemRepresentation], patchtype::ty_ips, &manifestinfo, [output fileSystemRepresentation]);
    
    if(result.level == el_warning){
        return [MPPatchResult newMessage:[@"Warning: " stringByAppendingFormat:@"%s", result.description] isWarning:YES];
    }
    else if(result.level != el_ok){
        return [MPPatchResult newMessage:[@"Failed to create IPS patch: " stringByAppendingFormat:@"%s", result.description] isWarning:NO];
    }
    return nil;
}
@end
