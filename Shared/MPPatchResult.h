//
//  MPPatchResult.h
//  MultiPatcher
//
//  Created by Paul Kratt on 11/26/18.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MPPatchResult : NSObject
+(MPPatchResult*)newMessage:(NSString*)message isWarning:(BOOL)warning;
@property BOOL IsWarning;
@property (assign) NSString* Message;

@end

NS_ASSUME_NONNULL_END
