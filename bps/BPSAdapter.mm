//
//  BPSAdapter.m
//  MultiPatch
//

#import "BPSAdapter.h"
#import "patch.hpp"
#import "linear.hpp"
#import "delta.hpp"

@implementation BPSAdapter
+ (NSString*)TranslateBPSresult:(nall::bpspatch::result)result{
    NSString* retval = nil;
    switch (result) {
        case nall::bpspatch::result::patch_checksum_invalid:
            retval = @"The patch checksum is invalid!";
            break;
        case nall::bpspatch::result::patch_invalid_header:
            retval = @"The patch has an invalid header!";
            break;
        case nall::bpspatch::result::patch_too_small:
            retval = @"The patch is too small!";
            break;
        case nall::bpspatch::result::source_checksum_invalid:
            retval = @"The source file checksum is invalid. This usually means that the file you picked to patch is not the correct file.";
            break;
        case nall::bpspatch::result::source_too_small:
            retval = @"The source file is too small!";
            break;
        case nall::bpspatch::result::target_checksum_invalid:
            retval = @"The target (output file) checksum is invalid.";
            break;
        case nall::bpspatch::result::target_too_small:
            retval = @"The target (output file) is too small.";
            break;
        case nall::bpspatch::result::unknown:
        default:
            retval = @"Unknown BPS error!";
            break;
    }
    return retval;
}

+(NSString*)ApplyPatch:(NSString*)patch toFile:(NSString*)input andCreate:(NSString*)output{
    NSString* retval = nil;
    nall::bpspatch bps;
    bps.modify([patch cStringUsingEncoding:[NSString defaultCStringEncoding]]);
    bps.source([input cStringUsingEncoding:[NSString defaultCStringEncoding]]);
    bps.target([output cStringUsingEncoding:[NSString defaultCStringEncoding]]);
    nall::bpspatch::result bpsResult = bps.apply();
    if(bpsResult != nall::bpspatch::result::success){
        retval = [BPSAdapter TranslateBPSresult:bpsResult];
    }
    return retval;
}

+(NSString*)CreatePatchLinear:(NSString*)orig withMod:(NSString*)modify andCreate:(NSString*)output{
    NSString* retval = nil;
    nall::bpslinear bps;
    bps.source([orig cStringUsingEncoding:[NSString defaultCStringEncoding]]);
    bps.target([modify cStringUsingEncoding:[NSString defaultCStringEncoding]]);
    if(bps.create([output cStringUsingEncoding:[NSString defaultCStringEncoding]])==false){
        retval = @"BPS patch creation failed due to an unknown error!";
    }
    return nil;
}

+(NSString*)CreatePatchDelta:(NSString*)orig withMod:(NSString*)modify andCreate:(NSString*)output{
    NSString* retval = nil;
    nall::bpsdelta bps;
    bps.source([orig cStringUsingEncoding:[NSString defaultCStringEncoding]]);
    bps.target([modify cStringUsingEncoding:[NSString defaultCStringEncoding]]);
    if(bps.create([output cStringUsingEncoding:[NSString defaultCStringEncoding]])==false){
        retval = @"BPS patch creation failed due to an unknown error!";
    }
    return nil;
}
@end
