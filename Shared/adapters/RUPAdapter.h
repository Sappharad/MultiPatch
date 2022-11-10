//
//  RUPAdapter.h
//  MultiPatcher
//
//  Created by Paul Kratt on 12/9/18.
//

#import <Foundation/Foundation.h>
#import "MPPatchResult.h"

NS_ASSUME_NONNULL_BEGIN

@interface RUPAdapter : NSObject
+(MPPatchResult*)ApplyPatch:(NSString*)patch toFile:(NSString*)input andCreate:(NSString*)output;
+(MPPatchResult*)CreatePatch:(NSString*)orig withMod:(NSString*)modify andCreate:(NSString*)output;
@end

NS_ASSUME_NONNULL_END
