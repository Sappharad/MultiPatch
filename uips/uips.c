/*
** Universal IPS patch create/apply utility
** Written by Neill Corlett - Copyright 1999
** See UIPS.TXT for terms of use and disclaimer.
**
** To compile this, if you have gcc installed:
**
**    gcc uips.c -o uips
**
** (Add optimization options to taste.)
**
** If you don't have gcc, figure something else out.
*/

#include <stdio.h>
#include <stdlib.h>

/* Define truncate(2) for systems that don't have it */

#if defined(__MSDOS__) && defined(__TURBOC__)

#include <dos.h>
#include <io.h>
#include <fcntl.h>
static void truncate(const char *filename, long size) {
  int handle;
  unsigned nwritten;
  if(_dos_open(filename, O_WRONLY, &handle)) return;
  if(lseek(handle, size, SEEK_SET) != -1L) {
    _dos_write(handle, (void far*)(&handle), 0, &nwritten);
  }
  _dos_close(handle);
}

#elif defined(__WIN32__)

#include <windows.h>
static void truncate(const char *filename, long size) {
  HANDLE f = CreateFile(
    filename,
    GENERIC_WRITE,
    0,
    NULL,
    OPEN_EXISTING,
    FILE_ATTRIBUTE_NORMAL,
    NULL
  );
  if(f == INVALID_HANDLE_VALUE) return;
  SetFilePointer(f, size, NULL, FILE_BEGIN);
  if(GetLastError() == NO_ERROR) SetEndOfFile(f);
  CloseHandle(f);
}

#else

#include <unistd.h>

#endif

#define IPS_EOF   (0x00454F46l)
#define IPS_LIMIT (0x01000000l)

/* Show program banner */
static void banner(void) {
  fprintf(stderr,
    "Universal IPS create/apply utility\n"
    "Written by Neill Corlett - Copyright 1999\n"
  );
}

/* Show usage info */
static void usage(const char *prgname) {
  fprintf(stderr,
    "Usage:\n"
    "To create an IPS patch:\n"
    "  %s c patch_file source_file(s) target_file\n"
    "To apply an IPS patch:\n"
    "  %s a patch_file target_file\n",
    prgname, prgname
  );
}

/* Wrapper for fopen that does various things */
static FILE *my_fopen(const char *filename, const char *mode, long *size) {
  FILE *f = fopen(filename, mode);
  if(!f) {
    perror(filename);
    return NULL;
  }
  if(size) {
    fseek(f, 0, SEEK_END);
    *size = ftell(f);
    fseek(f, 0, SEEK_SET);
  }
  return f;
}

/* Read a number from a file, MSB first */
static long readvalue(FILE *f, unsigned nbytes) {
  long v = 0;
  while(nbytes--) {
    int c = fgetc(f);
    if(c == EOF) return -1;
    v = (v << 8) | (c & 0xFF);
  }
  return v;
}

/* Write a number to a file, MSB first */
static void writevalue(long value, FILE *f, unsigned nbytes) {
  unsigned i = nbytes << 3;
  while(nbytes--) {
    i -= 8;
    fputc(value >> i, f);
  }
}

/* Search for the next difference between the target file and a number of
** source files */
static long get_next_difference(
        long       ofs,
        FILE     **source_file,
  const long      *source_size,
        unsigned   source_nfiles,
        FILE      *target_file,
        long       target_size
) {
  unsigned i;
  if(ofs >= target_size) return target_size;
  fseek(target_file, ofs, SEEK_SET);
  for(i = 0; i < source_nfiles; i++) {
    if(ofs >= source_size[i]) return ofs;
  }
  for(i = 0; i < source_nfiles; i++) {
    fseek(source_file[i], ofs, SEEK_SET);
  }
  for(;;) {
    int tc = fgetc(target_file);
    if(tc == EOF) return target_size;
    for(i = 0; i < source_nfiles; i++) {
      if(fgetc(source_file[i]) != tc) return ofs;
    }
    ofs++;
  }
}

/* Search for the end of a difference block */
static long get_difference_end(
        long       ofs,
        int        similar_limit,
        FILE     **source_file,
  const long      *source_size,
        unsigned   source_nfiles,
        FILE      *target_file,
        long       target_size
) {
  unsigned i;
  int      similar_rl = 0;
  if(ofs >= target_size) return target_size;
  fseek(target_file, ofs, SEEK_SET);
  for(i = 0; i < source_nfiles; i++) {
    if(ofs >= source_size[i]) return target_size;
  }
  for(i = 0; i < source_nfiles; i++) {
    fseek(source_file[i], ofs, SEEK_SET);
  }
  for(;;) {
    char is_different = 0;
    int tc = fgetc(target_file);
    if(tc == EOF) return target_size;
    for(i = 0; i < source_nfiles; i++) {
      int fc = fgetc(source_file[i]);
      if(fc == EOF) return target_size;
      if(fc != tc) is_different = 1;
    }
    ofs++;
    if(is_different) {
      similar_rl = 0;
    } else {
      similar_rl++;
      if(similar_rl == similar_limit) break;
    }
  }
  return ofs - similar_limit;
}

/* Encode a difference block into a patch file */
static void encode_patch_block(
  FILE *patch_file,
  FILE *target_file,
  long  ofs,
  long  ofs_end
) {
  while(ofs < ofs_end) {
    long ofs_block_end, rl;
    int c;
    /* Avoid accidental "EOF" marker */
    if(ofs == IPS_EOF) ofs--;
    /* Write the offset to the patch file */
    writevalue(ofs, patch_file, 3);
    fseek(target_file, ofs, SEEK_SET);
    /* If there is a beginning run of at least 9 bytes, use it */
    c = fgetc(target_file);
    rl = 1;
    while(
      (fgetc(target_file) == c) &&
      (rl < 0xFFFF) &&
      ((ofs + rl) < ofs_end)
    ) rl++;
    /* Encode a run, if the run was long enough */
    if(rl >= 9) {
      writevalue( 0, patch_file, 2);
      writevalue(rl, patch_file, 2);
      writevalue( c, patch_file, 1);
      ofs += rl;
      continue;
    }
    /* Search for the end of the block.
    ** The block ends if there's an internal run of at least 14, or an ending
    ** run of at least 9, or the block length == 0xFFFF, or the block reaches
    ** ofs_end. */
    fseek(target_file, ofs, SEEK_SET);
    ofs_block_end = ofs;
    c = -1;
    while(
      (ofs_block_end < ofs_end) &&
      ((ofs_block_end - ofs) < 0xFFFF)
    ) {
      int c2 = fgetc(target_file);
      ofs_block_end++;
      if(c == c2) {
        rl++;
        if(rl == 14) {
          ofs_block_end -= 14;
          break;
        }
      } else {
        rl = 1;
        c = c2;
      }
    }
    /* Look for a sufficiently long ending run */
    if((ofs_block_end == ofs_end) && (rl >= 9)) {
      ofs_block_end -= rl;
      if(ofs_block_end == IPS_EOF) ofs_block_end++;
    }
    /* Encode a regular patch block */
    writevalue(ofs_block_end - ofs, patch_file, 2);
    fseek(target_file, ofs, SEEK_SET);
    while(ofs < ofs_block_end) {
      fputc(fgetc(target_file), patch_file);
      ofs++;
    }
  }
}

/* Create a patch given a list of source filenames and a target filename.
** Returns 0 on success. */
static int create_patch(
  const char  *patch_filename,
  unsigned     source_nfiles,
  const char **source_filename,
  const char  *target_filename
) {
  FILE    *patch_file  = NULL;
  FILE   **source_file = NULL;
  long    *source_size = NULL;
  FILE    *target_file = NULL;
  long     target_size;
  long     ofs;
  int      e = 0;
  unsigned i;
  char     will_truncate = 0;
  /* Allocate memory for list of source file streams and sizes */
  if(
    (!(source_file = malloc(sizeof(FILE*) * source_nfiles))) ||
    (!(source_size = malloc(sizeof(long)  * source_nfiles)))
  ) {
    fprintf(stderr, "Out of memory\n");
    goto err;
  }
  for(i = 0; i < source_nfiles; i++) source_file[i] = NULL;
  /* Open target file */
  target_file = my_fopen(target_filename, "rb", &target_size);
  if(!target_file) goto err;
  /* Open source files */
  for(i = 0; i < source_nfiles; i++) {
    source_file[i] = my_fopen(source_filename[i], "rb", source_size + i);
    if(!source_file[i]) goto err;
    if(source_size[i] > target_size) will_truncate = 1;
  }
  /* Create patch file */
  patch_file = my_fopen(patch_filename, "wb", NULL);
  if(!patch_file) goto err;
  fprintf(stderr, "Creating %s...\n", patch_filename);
  /* Write "PATCH" signature */
  if(fwrite("PATCH", 1, 5, patch_file) != 5) {
    perror(patch_filename);
    goto err;
  }
  /* Main patch creation loop */
  ofs = 0;
  for(;;) {
    long ofs_end;
    /* Search for next difference */
    ofs = get_next_difference(
      ofs,
      source_file,
      source_size,
      source_nfiles,
      target_file,
      target_size
    );
    if(ofs == target_size) break;
    if(ofs >= IPS_LIMIT) {
      fprintf(stderr, "Warning: Differences beyond 16MB were ignored\n");
      break;
    }
    /* Determine the length of the difference block */
    ofs_end = get_difference_end(
      ofs,
      6,
      source_file,
      source_size,
      source_nfiles,
      target_file,
      target_size
    );
    /* Progress indicator */
    fprintf(stderr, "%06lX %06lX\r", ofs, ofs_end - ofs);
    /* Encode the difference block into the patch file */
    encode_patch_block(patch_file, target_file, ofs, ofs_end);
    ofs = ofs_end;
  }
  /* Write EOF marker */
  writevalue(IPS_EOF, patch_file, 3);
  if(will_truncate) {
    if(target_size >= IPS_LIMIT) {
      fprintf(stderr, "Warning: Can't truncate beyond 16MB\n");
    } else {
      writevalue(target_size, patch_file, 3);
    }
  }
  /* Finished */
  fprintf(stderr, "\nDone\n");
  goto no_err;
  err:
  e = 1;
  no_err:
  if(patch_file) fclose(patch_file);
  for(i = 0; i < source_nfiles; i++) {
    if(source_file[i]) fclose(source_file[i]);
  }
  if(target_file) fclose(target_file);
  if(source_file) free(source_file);
  if(source_size) free(source_size);
  return e;
}

/* Apply a patch to a given target.
** Returns 0 on success. */
static int apply_patch(
  const char *patch_filename,
  const char *target_filename
) {
  FILE *patch_file  = NULL;
  FILE *target_file = NULL;
  long  target_size;
  long  ofs;
  int   e = 0;
  /* Open patch file */
  patch_file = my_fopen(patch_filename, "rb", NULL);
  if(!patch_file) goto err;
  /* Verify first five characters */
  if(
    (fgetc(patch_file) != 'P') ||
    (fgetc(patch_file) != 'A') ||
    (fgetc(patch_file) != 'T') ||
    (fgetc(patch_file) != 'C') ||
    (fgetc(patch_file) != 'H')
  ) {
    fprintf(stderr, "%s: Invalid patch file format\n", patch_filename);
    goto err;
  }
  /* Open target file */
  target_file = my_fopen(target_filename, "r+b", &target_size);
  if(!target_file) goto err;
  fprintf(stderr, "Applying %s...\n", patch_filename);
  /* Main patch application loop */
  for(;;) {
    long ofs, len;
    long rlen  = 0;
    int  rchar = 0;
    /* Read the beginning of a patch record */
    ofs = readvalue(patch_file, 3);
    if(ofs == -1) goto err_eof;
    if(ofs == IPS_EOF) break;
    len = readvalue(patch_file, 2);
    if(len == -1) goto err_eof;
    if(!len) {
      rlen = readvalue(patch_file, 2);
      if(rlen == -1) goto err_eof;
      rchar = fgetc(patch_file);
      if(rchar == EOF) goto err_eof;
    }
    /* Seek to the appropriate position in the target file */
    if(ofs <= target_size) {
      fseek(target_file, ofs, SEEK_SET);
    } else {
      fseek(target_file, 0, SEEK_END);
      while(target_size < ofs) {
        fputc(0, target_file);
        target_size++;
      }
    }
    /* Apply patch block */
    if(len) {
      fprintf(stderr, "regular  %06lX %04lX\r", ofs, len);
      ofs += len;
      if(ofs > target_size) target_size = ofs;
      while(len--) {
        rchar = fgetc(patch_file);
        if(rchar == EOF) goto err_eof;
        fputc(rchar, target_file);
      }
    } else {
      fprintf(stderr, "run      %06lX %04lX\r", ofs, rlen);
      ofs += rlen;
      if(ofs > target_size) target_size = ofs;
      while(rlen--) fputc(rchar, target_file);
    }
  }
  /* Perform truncation if necessary */
  fclose(target_file);
  target_file = NULL;
  ofs = readvalue(patch_file, 3);
  if(ofs != -1) {
    fprintf(stderr, "truncate %06lX     ", ofs);
    truncate(target_filename, ofs);
  }
  /* Finished */
  fprintf(stderr, "\nDone\n");
  goto no_err;
  err_eof:
  fprintf(stderr,
    "%s: Unexpected end-of-file, patch incomplete\n",
    patch_filename
  );
  err:
  e = 1;
  no_err:
  if(target_file) fclose(target_file);
  if(patch_file) fclose(patch_file);
  return e;
}

/*int main(
  int argc,
  char **argv
) {
  char cmd;
  if(argc < 2) {
    banner();
    usage(argv[0]);
    return 1;
  }
  cmd = argv[1][0];
  if(cmd && argv[1][1]) cmd = 0;
  switch(cmd) {
  case 'c':
  case 'C':
    if(argc < 5) {
      fprintf(stderr, "Not enough parameters\n");
      usage(argv[0]);
      return 1;
    }
    if(create_patch(
      argv[2],
      argc - 4,
      (const char**)(argv + 3),
      argv[argc - 1]
    )) return 1;
    break;
  case 'a':
  case 'A':
    if(argc < 4) usage(argv[0]);
    if(apply_patch(argv[2], argv[3])) return 1;
    break;
  default:
    fprintf(stderr, "Unknown command: %s\n", argv[1]);
    usage(argv[0]);
    return 1;
  }
  return 0;
}*/

