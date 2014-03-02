//
//  PPFAdapter.h
//  MultiPatch
//

#import <Cocoa/Cocoa.h>

@interface PPFAdapter : NSObject {}
+(NSString*)errorMsg:(int)error;
+(NSString*)ApplyPatch:(NSString*)patch toFile:(NSString*)input andCreate:(NSString*)output;
+(NSString*)CreatePatch:(NSString*)orig withMod:(NSString*)modify andCreate:(NSString*)output;
@end
