/*
  libups
  version 0.03 (2008-03-31)
  author: byuu
  license: public domain (*)

  (*) -
    under the one condition that no changes may be made to this file format
    spec, no matter how insignificant, unless the new format is renamed to
    something other than UPS, the file signature does not start with "UPS",
    and the file extension is not .ups.
    this clause is necessary to ensure the integrity of the file format.
*/

#ifndef LIBUPS_HPP
#define LIBUPS_HPP

#include "../nall/algorithm.hpp"
#include "../nall/crc32.hpp"
#include "../nall/file.hpp"
#include "../nall/sort.hpp"
#include "../nall/stdint.hpp"

/*****
 * file format:
 *****
 * [4] signature ("UPS1")
 * [V] X file size
 * [V] Y file size
 * [?] {
 *   [V] relative difference offset
 *   [?] X ^ Y
 *   [1] 0x00 terminator
 * }
 * [4] X file crc32
 * [4] Y file crc32
 * [4] Z file crc32
 *****/

class UPS {
public:
  bool create(const char *x, const char *y, const char *z);
  bool apply (const char *x, const char *y, const char *z);

  const char *error;

  UPS();
  ~UPS();

private:
  nall::file fx, fy, fz;
  uint32_t crcx, crcy, crcz;

  void encptr(uint64_t offset);
  uint64_t decptr();

  uint8_t xread();
  uint8_t yread();
  uint8_t zread();
  void xwrite(uint8_t);
  void ywrite(uint8_t);
  void zwrite(uint8_t);

  void close();
};

/*****
 * verbose file format:
 *****
 * [4] signature ("UPS1")
 * must be valid to apply patch.
 * [V] X file size
 * [V] Y file size
 * exact file sizes, variable-length encoded
 * [?] {
 * all patch blocks. blocks of changes are stored
 * consecutively until EOF - 12 is reached.
 * [V] relative difference offset
 * variable-length encoded pointer describing the distance
 * between the current X,Y file pointer and the next different
 * byte.
 * see encptr() / decptr() for method used to encode / decode.
 * [?] X ^ Y
 * XOR of X byte and Y byte.
 * data stored as XOR so that patch can be applied in both
 * directions. length is never specified, patching continues
 * linearly until 0x00 byte is read from patch.
 * if reading past the end of one file (eg second file is
 * larger), 0x00 must be used in its place
 * [1] 0x00 terminator
 * if X == Y, then X ^ Y == 0x00. it is possible to determine
 * when differences between X and Y end by looking at XOR
 * value, therefore store a one-byte terminator, rather than
 * an encoded length value.
 * [4] X file crc32
 * [4] Y file crc32
 * self explanatory. values should be verified when applying
 * patches to detect when patches are applied to the wrong file,
 * or when patch file itself is actually corrupt.
 * [4] Z file (patch) crc32
 * crc32 of entire patch, sans the patch crc32 itself. one can
 * calculate the crc32 while creating the patch, and then write
 * the computed value as the very last step of patch creation.
 *****/

#endif //ifndef LIBUPS_HPP
