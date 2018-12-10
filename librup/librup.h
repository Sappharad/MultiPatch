//
//  librup.h
//  MultiPatcher
//
//  Created by Paul Kratt on 12/1/18.
//

#ifndef librup_h
#define librup_h

#include <stdio.h>

//Apply RUP patch.
int rup2_apply (const char* rup_file, const char* target_File);
//No create functionality, because nobody should use this format anymore.
//Even the creator of the format doesn't use it anymore. Use BPS instead.
static const int RUP_WRONG_FORMAT = -1;
static const int RUP_UNREADABLE_FILE = -2;
static const int RUP_MD5_MISMATCH = -3;
static const int RUP_BAD_PATCH = -4; //Wrong control code.

#endif /* librup_h */
