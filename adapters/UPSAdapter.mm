//
//  UPSAdapter.m
//  MultiPatcher
//

#import "UPSAdapter.h"
#include "flips/flips.h"

@implementation UPSAdapter
+(MPPatchResult*)ApplyPatch:(NSString*)patch toFile:(NSString*)input andCreate:(NSString*)output{
    struct manifestinfo manifestinfo={false, false, NULL};
    errorinfo result = ApplyPatch([patch cStringUsingEncoding:[NSString defaultCStringEncoding]],
                                  [input cStringUsingEncoding:[NSString defaultCStringEncoding]], NO, //<-- Do not verify input param
                                  [output cStringUsingEncoding:[NSString defaultCStringEncoding]], &manifestinfo, NO);
    
    if(result.level == el_warning){
        return [MPPatchResult newMessage:[@"Warning: " stringByAppendingFormat:@"%s", result.description] isWarning:YES];
    }
    else if(result.level != el_ok){
        return [MPPatchResult newMessage:[@"Failed to apply UPS patch: " stringByAppendingFormat:@"%s", result.description] isWarning:NO];
    }
    return nil;
}

+(MPPatchResult*)CreatePatch:(NSString*)orig withMod:(NSString*)modify andCreate:(NSString*)output{
    struct manifestinfo manifestinfo={false, false, NULL};
    errorinfo result = CreatePatch([orig cStringUsingEncoding:[NSString defaultCStringEncoding]], [modify cStringUsingEncoding:[NSString defaultCStringEncoding]], patchtype::ty_ups, &manifestinfo, [output cStringUsingEncoding:[NSString defaultCStringEncoding]]);
    
    if(result.level == el_warning){
        return [MPPatchResult newMessage:[@"Warning: " stringByAppendingFormat:@"%s", result.description] isWarning:YES];
    }
    else if(result.level != el_ok){
        return [MPPatchResult newMessage:[@"Failed to create UPS patch: " stringByAppendingFormat:@"%s", result.description] isWarning:NO];
    }
    return nil;
}
@end
