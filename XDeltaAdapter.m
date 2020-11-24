//
//  XDeltaAdapter.m
//  MultiPatch
//

#import "XDeltaAdapter.h"
#import "MPSettings.h"
#include "xdelta3.h"

@implementation XDeltaAdapter
+(MPPatchResult*)ApplyPatch:(NSString*)patch toFile:(NSString*)input andCreate:(NSString*)output{
	FILE*  InFile = fopen([patch cStringUsingEncoding:[NSString defaultCStringEncoding]], "rb");
	FILE*  SrcFile = fopen([input cStringUsingEncoding:[NSString defaultCStringEncoding]], "rb");
	FILE* OutFile = fopen([output cStringUsingEncoding:[NSString defaultCStringEncoding]], "wb");
	int r = code (0, InFile, SrcFile, OutFile, 0x1000);
	
	fclose(OutFile);
	fclose(SrcFile);
	fclose(InFile);
	
	if (r != 0) {
        if(r == -17712){
            return [MPPatchResult newMessage:@"Invalid input. This typically means that the file you selected to patch is not the file your patch is intended for." isWarning:NO];
        }
		return [MPPatchResult newMessage:[NSString stringWithFormat:@"Decode error: %d",r] isWarning:NO];
	}
    if(MPSettings.IgnoreXDeltaChecksum){
        return [MPPatchResult newMessage:@"Patching was completed. Remember that you ignored the checksum so the output file might not work if the input was bad." isWarning:YES];
    }
	
	return nil;
}

+(MPPatchResult*)CreatePatch:(NSString*)orig withMod:(NSString*)modify andCreate:(NSString*)output{
    FILE* oldFile = fopen([orig cStringUsingEncoding:[NSString defaultCStringEncoding]], "rb");
	FILE* newFile = fopen([modify cStringUsingEncoding:[NSString defaultCStringEncoding]], "rb");
	FILE* deltaFile = fopen([output cStringUsingEncoding:[NSString defaultCStringEncoding]], "wb");
	int r = code (1, newFile, oldFile, deltaFile, 0x1000);
	
	fclose(deltaFile);
	fclose(oldFile);
	fclose(newFile);
	
	if (r != 0) {
        return [MPPatchResult newMessage:[NSString stringWithFormat:@"Encode error: %d",r] isWarning:NO];
	}
	
	return nil;
}

int code (int encode, FILE* InFile, FILE* SrcFile, FILE* OutFile, int BufSize)
{
    int ret;
    size_t r;
    xd3_stream stream;
    xd3_config config;
    xd3_source source;
    void* Input_Buf;
    usize_t Input_Buf_Read;
    
    if (BufSize < XD3_ALLOCSIZE)
        BufSize = XD3_ALLOCSIZE;
    
    memset (&stream, 0, sizeof (stream));
    memset (&source, 0, sizeof (source));
    
    if(MPSettings.IgnoreXDeltaChecksum){
        //We still want to generate a checksum either way, but this disables checking it for the apply operation.
        xd3_init_config(&config, XD3_ADLER32 | XD3_ADLER32_NOVER);
    }
    else{
        xd3_init_config(&config, XD3_ADLER32);
    }
    config.winsize = BufSize;
    xd3_config_stream(&stream, &config);
    
    if (SrcFile)
    {
        source.blksize = BufSize;
        source.curblk = malloc(source.blksize);
        
        /* Load 1st block of stream. */
        r = fseek(SrcFile, 0, SEEK_SET);
        if (r)
            return (int)r;
        source.onblk = (usize_t)fread((void*)source.curblk, 1, source.blksize, SrcFile);
        source.curblkno = 0;
        /* Set the stream. */
        xd3_set_source(&stream, &source);
    }
    
    Input_Buf = malloc(BufSize);
    
    fseek(InFile, 0, SEEK_SET);
    do
    {
        Input_Buf_Read = (usize_t)fread(Input_Buf, 1, BufSize, InFile);
        if (Input_Buf_Read < BufSize)
        {
            xd3_set_flags(&stream, XD3_FLUSH | stream.flags);
        }
        xd3_avail_input(&stream, Input_Buf, Input_Buf_Read);
        
    process:
        if (encode)
            ret = xd3_encode_input(&stream);
        else
            ret = xd3_decode_input(&stream);
        
        switch (ret)
        {
            case XD3_INPUT:
            {
                fprintf (stderr,"XD3_INPUT\n");
                continue;
            }
                
            case XD3_OUTPUT:
            {
                fprintf (stderr,"XD3_OUTPUT\n");
                r = fwrite(stream.next_out, 1, stream.avail_out, OutFile);
                if (r != (int)stream.avail_out)
                    return (int)r;
                xd3_consume_output(&stream);
                goto process;
            }
                
            case XD3_GETSRCBLK:
            {
                fprintf (stderr,"XD3_GETSRCBLK %qd\n", source.getblkno);
                if (SrcFile)
                {
                    r = fseek(SrcFile, source.blksize * source.getblkno, SEEK_SET);
                    if (r)
                        return (int)r;
                    source.onblk = (usize_t)fread((void*)source.curblk, 1, source.blksize, SrcFile);
                    source.curblkno = source.getblkno;
                }
                goto process;
            }
                
            case XD3_GOTHEADER:
            {
                fprintf (stderr,"XD3_GOTHEADER\n");
                goto process;
            }
                
            case XD3_WINSTART:
            {
                fprintf (stderr,"XD3_WINSTART\n");
                goto process;
            }
                
            case XD3_WINFINISH:
            {
                fprintf (stderr,"XD3_WINFINISH\n");
                goto process;
            }
                
            default:
            {
                fprintf (stderr,"!!! INVALID %s %d !!!\n",
                         stream.msg, ret);
                return ret;
            }
                
        }
        
    }
    while (Input_Buf_Read == BufSize);
    
    free(Input_Buf);
    
    free((void*)source.curblk);
    xd3_close_stream(&stream);
    xd3_free_stream(&stream);
    
    return 0;
};
@end
