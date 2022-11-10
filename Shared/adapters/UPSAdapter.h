//
//  UPSAdapter.h
//  MultiPatcher
//

#import <Foundation/Foundation.h>
#import "MPPatchResult.h"

NS_ASSUME_NONNULL_BEGIN

@interface UPSAdapter : NSObject
+(MPPatchResult*)ApplyPatch:(NSString*)patch toFile:(NSString*)input andCreate:(NSString*)output;
+(MPPatchResult*)CreatePatch:(NSString*)orig withMod:(NSString*)modify andCreate:(NSString*)output;
@end

NS_ASSUME_NONNULL_END
