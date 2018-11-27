//
//  XDeltaAdapter.h
//  MultiPatch
//
//  Created by Paul Kratt on 7/4/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MPPatchResult.h"

@interface XDeltaAdapter : NSObject {}
+(MPPatchResult*)ApplyPatch:(NSString*)patch toFile:(NSString*)input andCreate:(NSString*)output;
int code (int encode, FILE* InFile, FILE* SrcFile, FILE* OutFile, int BufSize);
+(MPPatchResult*)CreatePatch:(NSString*)orig withMod:(NSString*)modify andCreate:(NSString*)output;
@end
