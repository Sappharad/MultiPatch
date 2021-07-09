//
//  BSdiffAdapter.m
//  MultiPatch
//

#import "BSdiffAdapter.h"

@implementation BSdiffAdapter

extern int bspatch_perform(char* oldfile, char* newfile, char* patchfile);
extern int bsdiff_perform(char* oldfile, char* newfile, char* patchfile);

+(MPPatchResult*)ApplyPatch:(NSString*)patch toFile:(NSString*)input andCreate:(NSString*)output{
    int err = bspatch_perform((char*)[input fileSystemRepresentation], (char*)[output fileSystemRepresentation], (char*)[patch fileSystemRepresentation]);
	if(err > 0){
		if(err==2)
			return [MPPatchResult newMessage:@"Failed to apply BSdiff patch. Your patch file appears to be corrupt." isWarning:NO];
        return [MPPatchResult newMessage:@"Failed to apply BSdiff patch!" isWarning:NO];
    }
	
    return nil;
}

+(MPPatchResult*)CreatePatch:(NSString*)orig withMod:(NSString*)modify andCreate:(NSString*)output{
    int err = bsdiff_perform((char*)[orig fileSystemRepresentation], (char*)[modify fileSystemRepresentation], (char*)[output fileSystemRepresentation]);
    if(err > 0){
		if(err == 5)
            return [MPPatchResult newMessage:@"Not enough memory to create BSDiff patch.\nInput files are probably too big." isWarning:NO];
        return [MPPatchResult newMessage:@"Failed to create BSdiff patch!" isWarning:NO];
    }
	
    return nil;
}
@end
