//
//  flips-support.cpp
//  MultiPatcher
//

#include "flips.h"

file* file::create(const char * filename) { return file::create_libc(filename); }
filewrite* filewrite::create(const char * filename) { return filewrite::create_libc(filename); }
filemap* filemap::create(const char * filename) { return filemap::create_fallback(filename); }
