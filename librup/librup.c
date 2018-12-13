//
//  librup.c
//  Created by Paul Kratt on 12/1/18.
//
//  Based on the original PHP implementation of Ninja2 written by Derrick Sobodash in 2006.

#include "librup.h"
#include <string.h>
#include <stdbool.h>
#include <stdlib.h>
#include <unistd.h>
#include "md5.h"

struct romPlusHeader{
    char* romData;
    long romDataSize;
    char* headerData;
    long headerDataSize;
};

long punpack(char* buffer, unsigned char length);
void smd_deint(char* romData);
struct romPlusHeader nes_read(char* infile);
struct romPlusHeader sfam_read(char* infile);
struct romPlusHeader n64_read(char* infile);
struct romPlusHeader gb_read(char* infile);
struct romPlusHeader sms_read(char* infile);
struct romPlusHeader mega_read(char* infile);
struct romPlusHeader pce_read(char* infile);
struct romPlusHeader lynx_read(char* infile);
bool md5Equals(unsigned char* m1, unsigned char* m2);
void rebuild_unif(char* infile, unsigned char* data);

int rup2_apply (const char* rup_file, const char* targetPath){
    char buffer[4096];
    bool revert = false;
    long ssize = 0, msize = 0;
    char* overflow = NULL, *header = NULL, *name = NULL;
    long overflowSize = 0, headerSize = 0;
    unsigned char smd5[16], mmd5[16], targetMD5[16];
    
    FILE* rup = fopen(rup_file, "rb");
    FILE* fo = NULL;
    int r = fseek(rup, 0, SEEK_SET);
    if(r){
        if(rup){
            fclose(rup);
            rup = NULL;
        }
        return RUP_UNREADABLE_FILE;
    }
    fread(buffer, 1, 6, rup);
    buffer[6] = 0;
    if(strncmp(buffer, "NINJA2", 6) != 0){
        fclose(rup);
        return RUP_WRONG_FORMAT;
    }
    
    //Skip over patch information block. Not needed to apply patch.
    fseek(rup, 2048, SEEK_SET);
    fread(buffer, 1, 1, rup);
    
    char controlCode = buffer[0];
    while(controlCode != 0){
        if(controlCode == 1){
            if(fo != NULL){
                // Append the original source data if reverting a shrunken modified file
                if(overflow != NULL){
                    if(ssize > msize && revert){
                        fseek(fo, msize, SEEK_SET);
                    }
                    else{
                        //PHP reference code had SEEK_SET && !revert, but SEEK_SET is 0 so that doesn't make sense.
                        fseek(fo, ssize, SEEK_SET);
                    }
                    fwrite(overflow, 1, overflowSize, fo);
                    free(overflow);
                    overflow = NULL;
                }
                // Truncate the file if creating a shrunken modified file
                if(ssize > msize && !revert){
                    ftruncate(fileno(fo), msize);
                }
                else if(ssize < msize && revert){
                    ftruncate(fileno(fo), ssize);
                }
                // Restore the header if necessary.
                // The original PHP code was missing a check for UINF here, so I will inherit this bug.
                if(header != NULL){
                    fseek(fo, 0, SEEK_END);
                    long tfsize = ftell(fo);
                    fseek(fo, 0, SEEK_SET);
                    char* tempFile = malloc(tfsize);
                    fread(tempFile, 1, tfsize, fo);
                    fseek(fo, 0, SEEK_SET);
                    fwrite(header, 1, headerSize, fo);
                    fwrite(tempFile, 1, tfsize, fo);
                    free(tempFile);
                    free(header);
                    header = NULL;
                }
                fclose(fo);
                fo = NULL;
                // If ninja.src exists, we're working on a temp file. Overwrite the original.
                if(access("ninja.src", F_OK) != -1){
                    unsigned long pathLen = strlen(targetPath) + strlen(name) + 1;
                    char* targetName = malloc(pathLen);
                    strcpy(targetName, targetPath);
                    targetName = strcat(targetName, name);
                    remove(targetName);
                    rename("ninja.src", targetName);
                    free(targetName);
                }
                name = NULL;
                revert = false;
                ssize = 0;
                msize = 0;
            }
            //Read file properties
            fread(buffer, 1, 1, rup);
            unsigned char temp = buffer[0];
            if(temp > 0){
                fread(buffer, 1, temp, rup);
                name = malloc(temp+2);
                name[0] = '/';
                strncpy(name+1, buffer, temp);
            }
            else{
                //Empty string
                name = malloc(1);
                name[0] = 0;
            }
            fread(buffer, 1, 1, rup);
            int type = buffer[0];
            fread(buffer, 1, 1, rup);
            temp = buffer[0];
            fread(buffer, 1, temp, rup);
            ssize = punpack(buffer, temp);
            fread(buffer, 1, 1, rup);
            temp = buffer[0];
            fread(buffer, 1, temp, rup);
            msize = punpack(buffer, temp);
            fread(smd5, 1, 16, rup);
            fread(mmd5, 1, 16, rup);
            //Patching target name
            size_t currentFNlen = strlen(targetPath) + strlen(name) + 1;
            char* currentFileName = malloc(currentFNlen);
            strcpy(currentFileName, targetPath);
            currentFileName = strcat(currentFileName, name);
            
            //Perform conversion if needed depending on file type
            switch(type){
                case 1: //NES
                {
                    struct romPlusHeader rph = nes_read(currentFileName);
                    header = rph.headerData;
                    headerSize = rph.headerDataSize;
                    fo = fopen("ninja.src", "wb");
                    fwrite(rph.romData, 1, rph.romDataSize, fo);
                    fclose(fo);
                    fo = NULL;
                    free(rph.romData);
                    break;
                }
                case 3: //SuperNES
                {
                    struct romPlusHeader rph = sfam_read(currentFileName);
                    header = rph.headerData;
                    headerSize = rph.headerDataSize;
                    fo = fopen("ninja.src", "wb");
                    fwrite(rph.romData, 1, rph.romDataSize, fo);
                    fclose(fo);
                    fo = NULL;
                    free(rph.romData);
                    break;
                }
                case 4: //N64
                {
                    struct romPlusHeader rph = n64_read(currentFileName);
                    fo = fopen("ninja.src", "wb");
                    fwrite(rph.romData, 1, rph.romDataSize, fo);
                    fclose(fo);
                    fo = NULL;
                    free(rph.romData);
                    break;
                }
                case 5: //Gameboy
                {
                    struct romPlusHeader rph = gb_read(currentFileName);
                    fo = fopen("ninja.src", "wb");
                    fwrite(rph.romData, 1, rph.romDataSize, fo);
                    fclose(fo);
                    fo = NULL;
                    free(rph.romData);
                    break;
                }
                case 6: //Sega Master System
                {
                    struct romPlusHeader rph = sms_read(currentFileName);
                    fo = fopen("ninja.src", "wb");
                    fwrite(rph.romData, 1, rph.romDataSize, fo);
                    fclose(fo);
                    fo = NULL;
                    free(rph.romData);
                    break;
                }
                case 7: //Sega Genesis / MegaDrive
                {
                    struct romPlusHeader rph = mega_read(currentFileName);
                    fo = fopen("ninja.src", "wb");
                    fwrite(rph.romData, 1, rph.romDataSize, fo);
                    fclose(fo);
                    fo = NULL;
                    free(rph.romData);
                    break;
                }
                case 8: //PC Engine / TurboGrafix 16
                {
                    struct romPlusHeader rph = pce_read(currentFileName);
                    fo = fopen("ninja.src", "wb");
                    fwrite(rph.romData, 1, rph.romDataSize, fo);
                    fclose(fo);
                    fo = NULL;
                    free(rph.romData);
                    break;
                }
                case 9: //Atari Lynx
                {
                    struct romPlusHeader rph = lynx_read(currentFileName);
                    header = rph.headerData;
                    headerSize = rph.headerDataSize;
                    fo = fopen("ninja.src", "wb");
                    fwrite(rph.romData, 1, rph.romDataSize, fo);
                    fclose(fo);
                    fo = NULL;
                    free(rph.romData);
                    break;
                }
            }
            
            MD5_CTX myMd5er;
            MD5_Init(&myMd5er);
            if(access("ninja.src", F_OK) != -1){
                fo = fopen("ninja.src", "rb");
                long amountRead = 0;
                do{
                    amountRead = fread(buffer, 1, 4096, fo);
                    if(amountRead > 0){
                        MD5_Update(&myMd5er, buffer, amountRead);
                    }
                } while(amountRead > 0);
                fclose(fo);
                fo = NULL;
            }
            else{
                fo = fopen(currentFileName, "rb");
                long amountRead = 0;
                do{
                    amountRead = fread(buffer, 1, 4096, fo);
                    if(amountRead > 0){
                        MD5_Update(&myMd5er, buffer, amountRead);
                    }
                } while(amountRead > 0);
                fclose(fo);
                fo = NULL;
            }
            MD5_Final(&targetMD5[0], &myMd5er);
            if(md5Equals(&targetMD5[0], &smd5[0])){
                revert = false;
            }
            else if(md5Equals(&targetMD5[0], &mmd5[0])){
                revert = true;
                //Reverting to pre-patched file.
            }
            else{
                fclose(rup);
                rup = NULL;
                return RUP_MD5_MISMATCH; //Bad input file, can't patch
            }
            if(access("ninja.src", F_OK) != -1){
                fo = fopen("ninja.src", "r+b");
            }
            else{
                fo = fopen(currentFileName, "r+b");
            }
            if(currentFileName){
                free(currentFileName);
                currentFileName = NULL;
            }
        }
        else if(controlCode == 'M' || controlCode == 'A'){
            // Read the source overflow to a our file properties
            // or... (Code in PHP version is identical for these two codes)
            // Append end of modified file
            unsigned char temp = fgetc(rup);
            fread(buffer, 1, temp, rup);
            overflowSize = punpack(buffer, temp);
            overflow = malloc(overflowSize);
            fread(overflow, 1, overflowSize, rup);
            for(long i = 0; i < overflowSize; i++){
                overflow[i] ^= 0xFF;
            }
        }
        else if(controlCode == 2){
            // Get the offset and seek it
            unsigned char temp = fgetc(rup);
            fread(buffer, 1, temp, rup);
            unsigned long offset = punpack(buffer, temp);
            fseek(fo, offset, SEEK_SET);
            
            // Get the patch length
            temp = fgetc(rup);
            fread(buffer, 1, temp, rup);
            unsigned long patchlen = punpack(buffer, temp);
            
            // Get the patch
            char* thisPatch = malloc(patchlen);
            char* sourceBytes = malloc(patchlen);
            fread(thisPatch, 1, patchlen, rup);
            fread(sourceBytes, 1, patchlen, fo);
            for(unsigned long i = 0; i<patchlen; i++){
                thisPatch[i] = sourceBytes[i] ^ thisPatch[i];
            }
            // Insert the patched bytes
            fseek(fo, offset, SEEK_SET);
            fwrite(thisPatch, 1, patchlen, fo);
            
            free(thisPatch);
            free(sourceBytes);
        }
        else{
            if(fo){
                fclose(fo);
                fo = NULL;
            }
            if(rup){
                fclose(rup);
                rup = NULL;
            }
            return RUP_BAD_PATCH; //Bad control code
        }
        if(fread(buffer, 1, 1, rup) == 0){
            controlCode = 0; //No bytes read, execute bail condition.
        }
        else{
            controlCode = buffer[0];
        }
    }
    //End of patch file, but it's not over yet!
    
    // Append the original source data if reverting a shrunken modified file
    if(overflow){
        if(ssize > msize && revert){
            fseek(fo, msize, SEEK_SET);
        }
        else{
            //PHP reference code had SEEK_SET && !revert, but SEEK_SET is 0 so that doesn't make sense.
            fseek(fo, ssize, SEEK_SET);
        }
        fwrite(overflow, 1, overflowSize, fo);
        free(overflow);
        overflow = NULL;
    }
    // Truncate the file if creating a shrunken modified file
    if(ssize > msize && !revert){
        ftruncate(fileno(fo), msize);
    }
    else if(ssize < msize && revert){
        ftruncate(fileno(fo), ssize);
    }
    // Restore the header if necessary
    if(header && strncmp(header, "UNIF", 4) == 0){
        //If we made it here, fo is most certainly ninja.src so I'm not going to check that
        unsigned long pathLen = strlen(targetPath) + strlen(name) + 1;
        char* targetName = malloc(pathLen);
        strcpy(targetName, targetPath);
        targetName = strcat(targetName, name);
        
        fseek(fo, 0, SEEK_END);
        long tfsize = ftell(fo);
        unsigned char* data = malloc(tfsize);
        fseek(fo, 0, SEEK_SET);
        fread(data, 1, tfsize, fo);
        rebuild_unif(targetName, data);
        free(data);
        free(targetName);
        free(header);
        header = NULL;
        fclose(fo);
        fo = NULL;
        remove("ninja.src"); //Rebuild_unif wrote into the original already.
    }
    else if(header){
        fseek(fo, 0, SEEK_END);
        long tfsize = ftell(fo);
        fseek(fo, 0, SEEK_SET);
        char* tempFile = malloc(tfsize);
        fread(tempFile, 1, tfsize, fo);
        fseek(fo, 0, SEEK_SET);
        fwrite(header, 1, headerSize, fo);
        fwrite(tempFile, 1, tfsize, fo);
        free(tempFile);
        free(header);
        header = NULL;
    }
    if(fo){
        fclose(fo);
        fo = NULL;
    }
    if(access("ninja.src", F_OK) != -1){
        unsigned long pathLen = strlen(targetPath) + strlen(name) + 1;
        char* targetName = malloc(pathLen);
        strcpy(targetName, targetPath);
        targetName = strcat(targetName, name);
        remove(targetName);
        rename("ninja.src", targetName);
        free(targetName);
    }
    if(rup){
        fclose(rup);
        rup = NULL;
    }
    if(name){
        free(name);
        name = NULL;
    }
    return 0;
}

bool md5Equals(unsigned char* m1, unsigned char* m2){
    for(int i=0; i<16; i++){
        if(m1[i] != m2[i]){
            return false;
        }
    }
    return true;
}

long punpack(char* buffer, unsigned char length){
    long retval = 0;
    for(int i = length-1; i>=0; i--){
        retval = retval << 8;
        retval += ((unsigned char)buffer[i]);
    }
    return retval;
}

struct romPlusHeader nes_read(char* infile){
    struct romPlusHeader retval;
    long romSize;
    FILE* fd = fopen(infile, "rb");
    unsigned char localBuffer[32];
    fread(localBuffer, 1, 10, fd);
    fseek(fd, 0, SEEK_END);
    romSize = ftell(fd);
    fseek(fd, 0, SEEK_SET);
    
    // Check for an iNES header.
    if(localBuffer[0] == 'N' && localBuffer[1] == 'E' && localBuffer[2] == 'S'){
        retval.headerDataSize = 0x10;
        retval.headerData = malloc(retval.headerDataSize);
        fread(retval.headerData, 1, retval.headerDataSize, fd);
        retval.romDataSize = romSize - 0x10;
        retval.romData = malloc(retval.romDataSize);
        fread(retval.romData, 1, retval.romDataSize, fd);
    }
    // Check for a Far Front East header.
    else if(localBuffer[8]==0xAA && localBuffer[9]==0xBB){
        retval.headerDataSize = 0x200;
        retval.headerData = malloc(retval.headerDataSize);
        fread(retval.headerData, 1, retval.headerDataSize, fd);
        retval.romDataSize = romSize - 0x200;
        retval.romData = malloc(retval.romDataSize);
        fread(retval.romData, 1, retval.romDataSize, fd);
    }
    // Check for a UNIF format ROM
    else if(localBuffer[0] == 'U' && localBuffer[1] == 'N' && localBuffer[2] == 'I' && localBuffer[3] == 'F'){
        retval.headerDataSize = 4;
        retval.headerData = malloc(retval.headerDataSize);
        strncpy(retval.headerData, "UNIF", 4);
        retval.romData = malloc(romSize);
        retval.romDataSize = 0;
        fseek(fd, 0x20, SEEK_SET);
        long srcLoc = 0x20;
        fread(localBuffer, 1, 4, fd);
        srcLoc += 4;
        while(srcLoc < romSize){
            if((strncmp("PRG", (char*)localBuffer, 3) == 0 ||
                strncmp("CHR", (char*)localBuffer, 3) == 0) &&
               ((localBuffer[3] >= '0' && localBuffer[3] <= '9') ||
                (localBuffer[3] >= 'A' && localBuffer[3] <= 'F')))
            {
                fread(localBuffer, 1, 4, fd);
                srcLoc += 4;
                long size = punpack((char*)localBuffer, 4);
                fread(retval.romData+retval.romDataSize, 1, size, fd);
                retval.romDataSize += size;
                srcLoc += size;
            }
            else{
                fread(localBuffer, 1, 4, fd);
                srcLoc += 4;
                long size = punpack((char*)localBuffer, 4);
                fseek(fd, size, SEEK_CUR);
                srcLoc += size;
            }
            if(srcLoc < romSize){
                fread(localBuffer, 1, 4, fd);
                srcLoc += 4;
            }
        }
    }
    else{
        //FAILED!!!
        retval.headerData = NULL;
        retval.romData = NULL;
        retval.headerDataSize = 0;
        retval.romDataSize = 0;
    }
    fclose(fd);
    return retval;
}

void rebuild_unif(char* infile, unsigned char* data){
    FILE* fd = fopen(infile, "r+b");
    fseek(fd, 0, SEEK_END);
    long romSize = ftell(fd);
    fseek(fd, 0x20, SEEK_SET);
    long dataLoc = 0;
    long srcLoc = 0x20;
    unsigned char localBuffer[32];
    fread(localBuffer, 1, 4, fd);
    srcLoc += 4;
    while(srcLoc < romSize){
        if((strncmp("PRG", (char*)localBuffer, 3) == 0 ||
            strncmp("CHR", (char*)localBuffer, 3) == 0) &&
           ((localBuffer[3] >= '0' && localBuffer[3] <= '9') ||
            (localBuffer[3] >= 'A' && localBuffer[3] <= 'F')))
        {
            fread(localBuffer, 1, 4, fd);
            srcLoc += 4;
            long size = punpack((char*)localBuffer, 4);
            fwrite(data + dataLoc, 1, size, fd);
            dataLoc += size;
            srcLoc += size;
        }
        else{
            fread(localBuffer, 1, 4, fd);
            srcLoc += 4;
            long size = punpack((char*)localBuffer, 4);
            //Seek ahead by size, because we don't care about this bank
            fseek(fd, size, SEEK_CUR);
            srcLoc += size;
        }
        if(srcLoc < romSize){
            fread(localBuffer, 1, 4, fd);
            srcLoc += 4;
        }
    }
    fclose(fd);
}

const int SNES_HEADER = 0x200;
const int KBYTE = 0x400;

struct romPlusHeader sfam_read(char* infile){
    struct romPlusHeader retval;
    retval.headerData = NULL;
    retval.headerDataSize = 0;
    //Intialize defaults in case of no header
    long romSize;
    FILE* fd = fopen(infile, "rb");
    char* fddump;
    fseek(fd, 0, SEEK_END);
    romSize = ftell(fd);
    fseek(fd, 0, SEEK_SET);
    fddump = malloc(romSize);
    fread(fddump, 1, romSize, fd);
    fclose(fd);
    
    // "SUPERUFO"
    char ufotest[8];
    memcpy(ufotest, fddump+0x8, 8);
    // "GAME DOCTOR SF 3"
    char gd3test[0x10];
    memcpy(gd3test, fddump, 0x10);
    
    if(strncmp((const char*)(fddump+0x1e8), "NSRT", 4) == 0){
        retval.headerDataSize = SNES_HEADER;
        retval.headerData = malloc(SNES_HEADER);
        memcpy(retval.headerData, fddump, SNES_HEADER);
    }
    if(romSize % (32 * KBYTE) != 0){
        //Remove header
        romSize = romSize - SNES_HEADER;
        char *tempDump = malloc(romSize);
        memcpy(tempDump, fddump + SNES_HEADER, romSize);
        free(fddump);
        fddump = tempDump;
    }
    long inverse = punpack((fddump+0x7fdc), 2);
    long checksum = punpack((fddump+0x7fde), 2);
    int romstate = fddump[0x7fd5] % 0x10;
    
    if((inverse + checksum) == 0xFFFF && (romstate % 2) == 0){
        //Type loROM detected
        retval.romData = fddump;
        retval.romDataSize = romSize;
        return retval;
    }
    else if(inverse + checksum == 0xFFFF && (romstate % 2) != 0){
        short chart_20mbit[] = {
                              1,   3,   5,   7,   9,  11,  13,  15,  17,  19,  21,  23,  25,  27,  29,
                              31,  33,  35,  37,  39,  41,  43,  45,  47,  49,  51,  53,  55,  57,  59,
                              61,  63,  65,  67,  69,  71,  73,  75,  77,  79,  64,  66,  68,  70,  72,
                              74,  76,  78,  32,  34,  36,  38,  40,  42,  44,  46,  48,  50,  52,  54,
                              56,  58,  60,  62,   0,   2,   4,   6,   8,  10,  12,  14,  16,  18,  20,
                              22,  24,  26,  28,  30
        };
        short chart_24mbit[] = {
                              1,   3,   5,   7,   9,  11,  13,  15,  17,  19,  21,  23,  25,  27,  29,
                              31,  33,  35,  37,  39,  41,  43,  45,  47,  49,  51,  53,  55,  57,  59,
                              61,  63,  65,  67,  69,  71,  73,  75,  77,  79,  81,  83,  85,  87,  89,
                              91,  93,  95,  64,  66,  68,  70,  72,  74,  76,  78,  80,  82,  84,  86,
                              88,  90,  92,  94,   0,   2,   4,   6,   8,  10,  12,  14,  16,  18,  20,
                              22,  24,  26,  28,  30,  32,  34,  36,  38,  40,  42,  44,  46,  48,  50,
                              52,  54,  56,  58,  60,  62
        };
        short chart_48mbit[] = {
                              129, 131, 133, 135, 137, 139, 141, 143, 145, 147, 149, 151, 153, 155, 157,
                              159, 161, 163, 165, 167, 169, 171, 173, 175, 177, 179, 181, 183, 185, 187,
                              189, 191, 128, 130, 132, 134, 136, 138, 140, 142, 144, 146, 148, 150, 152,
                              154, 156, 158, 160, 162, 164, 166, 168, 170, 172, 174, 176, 178, 180, 182,
                              184, 186, 188, 190,   1,   3,   5,   7,   9,  11,  13,  15,  17,  19,  21,
                              23,  25,  27,  29,  31,  33,  35,  37,  39,  41,  43,  45,  47,  49,  51,
                              53,  55,  57,  59,  61,  63,  65,  67,  69,  71,  73,  75,  77,  79,  81,
                              83,  85,  87,  89,  91,  93,  95,  97,  99, 101, 103, 105, 107, 109, 111,
                              113, 115, 117, 119, 121, 123, 125, 127,   0,   2,   4,   6,   8,  10,  12,
                              14,  16,  18,  20,  22,  24,  26,  28,  30,  32,  34,  36,  38,  40,  42,
                              44,  46,  48,  50,  52,  54,  56,  58,  60,  62,  64,  66,  68,  70,  72,
                              74,  76,  78,  80,  82,  84,  86,  88,  90,  92,  94,  96,  98, 100, 102,
                              104, 106, 108, 110, 112, 114, 116, 118, 120, 122, 124, 126
        };
        if(romSize == 512 * KBYTE * 5 && strncmp(ufotest, "SUPERUFO", 8) != 0){
            char* deinterleave = malloc(romSize);
            for(int i=0; i<0x50; i++){
                int chunkSrc =  i * 32 * KBYTE;
                int chunkDst = chart_20mbit[i]*(i*32*KBYTE);
                memcpy(deinterleave + chunkDst, fddump + chunkSrc, 32*KBYTE);
            }
            free(fddump);
            retval.romData = deinterleave;
            retval.romDataSize = romSize;
            return retval;
        }
        else if(romSize == 512 * KBYTE * 6 && strncmp(ufotest, "SUPERUFO", 8) != 0){
            char* deinterleave = malloc(romSize);
            for(int i=0; i<0x60; i++){
                int chunkSrc =  i * 32 * KBYTE;
                int chunkDst = chart_24mbit[i]*(i*32*KBYTE);
                memcpy(deinterleave + chunkDst, fddump + chunkSrc, 32*KBYTE);
            }
            free(fddump);
            retval.romData = deinterleave;
            retval.romDataSize = romSize;
            return retval;
        }
        else if(romSize == 512 * KBYTE * 12 && strncmp(ufotest, "SUPERUFO", 8) != 0){
            char* deinterleave = malloc(romSize);
            for(int i=0; i<0xC0; i++){
                int chunkSrc =  i * 32 * KBYTE;
                int chunkDst = chart_48mbit[i]*(i*32*KBYTE);
                memcpy(deinterleave + chunkDst, fddump + chunkSrc, 32*KBYTE);
            }
            free(fddump);
            retval.romData = deinterleave;
            retval.romDataSize = romSize;
            return retval;
        }
        else{
            int chunks = (int)(romSize / (32*KBYTE));
            char* deinterleave = malloc(romSize);
            for(int i=0; i<chunks/2; i++){
                int chunkSrc = (i + (chunks/2)) * 32 * KBYTE;
                int chunkDst =  (i*2) * 32 * KBYTE;
                memcpy(deinterleave + chunkDst, fddump + chunkSrc, 32*KBYTE);
                chunkSrc = (i) * 32 * KBYTE;
                chunkDst =  ((i*2)+1) * 32 * KBYTE;
                memcpy(deinterleave + chunkDst, fddump + chunkSrc, 32*KBYTE);
            }
            free(fddump);
            retval.romData = deinterleave;
            retval.romDataSize = romSize;
            return retval;
        }
    }
    inverse = punpack((fddump+0xffdc), 2);
    checksum = punpack((fddump+0xffde), 2);
    romstate = fddump[0xffd5] % 0x10;
    if(inverse + checksum == 0xFFFF && romstate % 2 != 0){
        //ROM type HiROM deinterleaved detected
        retval.romData = fddump;
        retval.romDataSize = romSize;
        return retval;
    }
    else if(romstate % 2 != 0){
        //ROM type unknown
        retval.romData = fddump;
        retval.romDataSize = romSize;
        return retval;
    }
    //Bad data.
    return retval;
}

struct romPlusHeader n64_read(char* infile){
    struct romPlusHeader retval;
    retval.headerData = NULL;
    retval.headerDataSize = 0;
    //No header on N64
    long romSize;
    FILE* fd = fopen(infile, "rb");
    fseek(fd, 0, SEEK_END);
    romSize = ftell(fd);
    fseek(fd, 0, SEEK_SET);
    unsigned char* romData = malloc(romSize);
    fread(romData, 1, romSize, fd);
    fclose(fd);
    if(romData[0]==0x37 && romData[1]==0x80 && romData[2]==0x40 && romData[3]==0x12){
        //Interleaved - Well, they call it interleaved but it's really just byte swapped.
        unsigned char temp;
        for(int i = 0; i < romSize; i+=2){
            temp = romData[i];
            romData[i] = romData[i+1];
            romData[i+1] = temp;
        }
    }
    retval.romData = (char*)romData;
    retval.romDataSize = romSize;
    return retval;
}

struct romPlusHeader gb_read(char* infile){
    struct romPlusHeader retval;
    retval.headerData = NULL;
    retval.headerDataSize = 0;
    long romSize;
    FILE* fd = fopen(infile, "rb");
    fseek(fd, 0, SEEK_END);
    romSize = ftell(fd);
    fseek(fd, 0, SEEK_SET);
    // Test for an 0x200 SmartCard header
    if((romSize % 0x4000) != 0){
        fseek(fd, 0x200, SEEK_SET);
        romSize -= 0x200;
    }
    unsigned char* romData = malloc(romSize);
    fread(romData, 1, romSize, fd);
    fclose(fd);
    retval.romData = (char*)romData;
    retval.romDataSize = romSize;
    //Note: omitted file type check because we don't need it for patching since MD5 is checked.
    return retval;
}

struct romPlusHeader sms_read(char* infile){
    struct romPlusHeader retval;
    retval.headerData = NULL;
    retval.headerDataSize = 0;
    long romSize;
    FILE* fd = fopen(infile, "rb");
    fseek(fd, 0, SEEK_END);
    romSize = ftell(fd);
    fseek(fd, 0x7ff4, SEEK_SET);
    char sega[4];
    fread(sega, 1, 4, fd);
    //Test if the file is in BIN format
    if(strncmp(sega, "SEGA", 4) != 0){
        //Not BIN. Check for SMD
        fseek(fd, 0x8, SEEK_SET);
        fread(sega, 1, 2, fd);
        if((unsigned char)(sega[0]) == 0xAA && (unsigned char)(sega[1]) == 0xBB){
            //This is SMD
            fseek(fd, 0x200, SEEK_SET);
            romSize -= 0x200;
            retval.romDataSize = romSize;
            retval.romData = malloc(romSize);
            fread(retval.romData, 1, romSize, fd);
            fclose(fd);
            long num_blocks = romSize / (16*KBYTE);
            for(int i = 0; i < num_blocks; i++){
                smd_deint(retval.romData+(i*16*KBYTE));
            }
            return retval;
        }
    }
    //Not SMD, just read it as binary
    fseek(fd, 0, SEEK_SET);
    unsigned char* romData = malloc(romSize);
    fread(romData, 1, romSize, fd);
    fclose(fd);
    retval.romData = (char*)romData;
    retval.romDataSize = romSize;
    return retval;
}

void smd_deint(char* romData){
    int low = 1;
    int high = 0;
    char chunk[16*KBYTE];
    memcpy(chunk, romData, 16*KBYTE);
    for(int i = 0; i < 8 * KBYTE; i++){
        romData[low] = chunk[((8*KBYTE) + i)];
        romData[high] = chunk[i];
        low += 2;
        high += 2;
    }
}

struct romPlusHeader mega_read(char* infile){
    struct romPlusHeader retval;
    retval.headerData = NULL;
    retval.headerDataSize = 0;
    long romSize;
    FILE* fd = fopen(infile, "rb");
    fseek(fd, 0, SEEK_END);
    romSize = ftell(fd);
    fseek(fd, 0x100, SEEK_SET);
    char sega[4];
    fread(sega, 1, 4, fd);
    //Test if the file is in BIN format
    if(strncmp(sega, "SEGA", 4) != 0){
        //Not BIN. Check for SMD
        fseek(fd, 0x8, SEEK_SET);
        fread(sega, 1, 2, fd);
        if((unsigned char)(sega[0]) == 0xAA && (unsigned char)(sega[1]) == 0xBB){
            //This is SMD
            fseek(fd, 0x200, SEEK_SET);
            romSize -= 0x200;
            retval.romDataSize = romSize;
            retval.romData = malloc(romSize);
            fread(retval.romData, 1, romSize, fd);
            fclose(fd);
            long num_blocks = romSize / (16*KBYTE);
            for(int i = 0; i < num_blocks; i++){
                smd_deint(retval.romData+(i*16*KBYTE));
            }
            return retval;
        }
    }
    //Not SMD, just read it as binary
    fseek(fd, 0, SEEK_SET);
    unsigned char* romData = malloc(romSize);
    fread(romData, 1, romSize, fd);
    fclose(fd);
    retval.romData = (char*)romData;
    retval.romDataSize = romSize;
    return retval;
}

struct romPlusHeader pce_read(char* infile){
    struct romPlusHeader retval;
    retval.headerData = NULL;
    retval.headerDataSize = 0;
    long romSize;
    FILE* fd = fopen(infile, "rb");
    fseek(fd, 0, SEEK_END);
    romSize = ftell(fd);
    fseek(fd, 0, SEEK_SET);
    // Test for an 0x200 SmartCard header
    if((romSize % 0x1000) != 0){
        fseek(fd, 0x200, SEEK_SET);
        romSize -= 0x200;
    }
    unsigned char* romData = malloc(romSize);
    fread(romData, 1, romSize, fd);
    fclose(fd);
    retval.romData = (char*)romData;
    retval.romDataSize = romSize;
    return retval;
}

struct romPlusHeader lynx_read(char* infile){
    struct romPlusHeader retval;
    retval.headerData = NULL;
    retval.headerDataSize = 0;
    long romSize;
    FILE* fd = fopen(infile, "rb");
    fseek(fd, 0, SEEK_END);
    romSize = ftell(fd);
    fseek(fd, 0, SEEK_SET);
    char lynx[4];
    fread(lynx, 1, 4, fd);
    fseek(fd, 0, SEEK_SET);
    //Check for a LYNX header
    if(strncmp(lynx, "LYNX", 4)==0){
        retval.headerDataSize = 0x40;
        retval.headerData = malloc(0x40);
        fread(retval.headerData, 1, 0x40, fd);
        romSize -= 0x40;
    }
    unsigned char* romData = malloc(romSize);
    fread(romData, 1, romSize, fd);
    fclose(fd);
    retval.romData = (char*)romData;
    retval.romDataSize = romSize;
    return retval;
}
