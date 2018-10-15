//
//  BPSAdapter.h
//  MultiPatch
//

#import <Foundation/Foundation.h>

@interface BPSAdapter : NSObject
+ (NSString*)ApplyPatch:(NSString*)patch toFile:(NSString*)input andCreate:(NSString*)output;
+ (NSString*)CreatePatchLinear:(NSString*)orig withMod:(NSString*)modify andCreate:(NSString*)output;
+ (NSString*)CreatePatchDelta:(NSString*)orig withMod:(NSString*)modify andCreate:(NSString*)output;
@end
