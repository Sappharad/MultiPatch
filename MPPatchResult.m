//
//  MPPatchResult.m
//  MultiPatcher
//
//  Created by Paul Kratt on 11/26/18.
//

#import "MPPatchResult.h"

@implementation MPPatchResult
+(MPPatchResult*)newMessage:(NSString*)message isWarning:(BOOL)warning{
    MPPatchResult* retval = [[MPPatchResult alloc] init];
    retval.IsWarning = warning;
    retval.Message = message;
    return retval;
}
@end
