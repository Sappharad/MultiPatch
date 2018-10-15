//
//  UPSAdapter.h
//  MultiPatcher
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface UPSAdapter : NSObject
+(NSString*)ApplyPatch:(NSString*)patch toFile:(NSString*)input andCreate:(NSString*)output;
+(NSString*)CreatePatch:(NSString*)orig withMod:(NSString*)modify andCreate:(NSString*)output;
@end

NS_ASSUME_NONNULL_END
