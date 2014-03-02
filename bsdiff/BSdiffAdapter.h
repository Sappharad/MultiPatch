//
//  BSdiffAdapter.h
//  MultiPatch
//

#import <Cocoa/Cocoa.h>


@interface BSdiffAdapter : NSObject {}
    +(NSString*)ApplyPatch:(NSString*)patch toFile:(NSString*)input andCreate:(NSString*)output;
    +(NSString*)CreatePatch:(NSString*)orig withMod:(NSString*)modify andCreate:(NSString*)output;
@end
