//
//  MPSettings.m
//  MultiPatch
//
//  Created by Paul Kratt on 11/24/20.
//

#import "MPSettings.h"

@implementation MPSettings

static BOOL _ignoreXDeltaChecksum;
+(BOOL)IgnoreXDeltaChecksum{
    return _ignoreXDeltaChecksum;
}
+(void)setIgnoreXDeltaChecksum:(BOOL)value{
    _ignoreXDeltaChecksum = value;
}

@end
