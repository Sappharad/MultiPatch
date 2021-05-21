//
//  ppf3.h
//  MultiPatch
//

#ifndef ppf3_h
#define ppf3_h

int applyPPF(const char* binFile, const char* patchFile);
int makePPF(const char* originalFile, const char* modifiedFile, const char* ppfPath);

#define PPFERROR_FAILED_TO_OPEN -1
#define PPFERROR_WRONG_INPUT_SIZE -2
#define PPFERROR_PATCH_VALIDATION_FAILED -3
#define PPFERROR_NO_UNDO_DATA -4
#define PPFERROR_VERSION_UNSUPPORTED -5
#define PPFERROR_FAILED_TO_CREATE -6
#define PPFERROR_HEADER_FAILED -7
#define PPFERROR_OUT_OF_MEMORY -8

#endif /* ppf3_h */
