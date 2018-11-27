//
//  BPSAdapter.h
//  MultiPatch
//

#import <Foundation/Foundation.h>
#import "MPPatchResult.h"

@interface BPSAdapter : NSObject
+ (MPPatchResult*)ApplyPatch:(NSString*)patch toFile:(NSString*)input andCreate:(NSString*)output;
+ (MPPatchResult*)CreatePatchLinear:(NSString*)orig withMod:(NSString*)modify andCreate:(NSString*)output;
+ (MPPatchResult*)CreatePatchDelta:(NSString*)orig withMod:(NSString*)modify andCreate:(NSString*)output;
@end
