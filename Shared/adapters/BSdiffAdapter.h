//
//  BSdiffAdapter.h
//  MultiPatch
//

#import <Foundation/Foundation.h>
#import "MPPatchResult.h"

@interface BSdiffAdapter : NSObject {}
    +(MPPatchResult*)ApplyPatch:(NSString*)patch toFile:(NSString*)input andCreate:(NSString*)output;
    +(MPPatchResult*)CreatePatch:(NSString*)orig withMod:(NSString*)modify andCreate:(NSString*)output;
@end
