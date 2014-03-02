//
//  XDeltaAdapter.h
//  MultiPatch
//
//  Created by Paul Kratt on 7/4/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface XDeltaAdapter : NSObject {}
+(NSString*)ApplyPatch:(NSString*)patch toFile:(NSString*)input andCreate:(NSString*)output;
int code (int encode, FILE* InFile, FILE* SrcFile, FILE* OutFile, int BufSize);
+(NSString*)CreatePatch:(NSString*)orig withMod:(NSString*)modify andCreate:(NSString*)output;
@end
