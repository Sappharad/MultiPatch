/*****************************************************************************
   libppf v0.1-rc1 - A library for handling PPF patch files
  
   Copyright (C), Daniel Ekström <dv01dem@cs.umu.se>, 2007 - 2008
   More information can be found at http://oakstream.mine.nu

   This program is free software; you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation; either version 2 of the License, or
   (at your option) any later version.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program; if not, write to the Free Software
   Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
******************************************************************************/

// Unless specified, every function returns 0 for success or an error code

#include <math.h>
#include <stdio.h>
#include "libppf.hh"

namespace lppf {
   LibPPF::LibPPF() {
      // Set default options
      loaded = false;
      ppfDesc = string("");
      ppfName = string("");
      isoName = string("");
      totalSize = 0;
      type = TYPE_BIN;
      hasUndo = false;
      validation = false;
      version = 1;
   }

  /*
   * Load and parse the given PPF patch file
   */
   int LibPPF::loadPatch(string filename) {
      FILE *file;
      unsigned char buf[256];
      int chunkSize, offsetSize, size;

      // Save filename
      ppfName = string(filename);

      // Try to open the patch
      if ((file = fopen(filename.c_str(), "rb")) == NULL)
         return ERROR_PPF_OPEN;

      // Check if this really is a PPF file
      if (fread(buf, 1, 5, file) != 5)
         return ERROR_PPF_READ;

      if (buf[0] != 'P' || buf[1] != 'P' || buf[2] != 'F')
         return ERROR_PPF_FORMAT;

      // Get version number
      version = (int)fgetc(file) + 1;

      // Get patch description
      if (fread(buf, 1, 50, file) != 50)
         return ERROR_PPF_READ;

      // Add it as a string
      ppfDesc = string("");
      for (int i = 0; i < 50; i++)
         ppfDesc = string(ppfDesc + (char)buf[i]);

      // The following only applies to PPF v3.0
      if (version == 3) {
         // Get image type
         type = (int)fgetc(file);

         // Find out if validation is available
         if (fgetc(file) == 0x01)
            validation = true;

         // Find out if undo data is available
         if (fgetc(file) == 0x01)
            hasUndo = true;
      }

      // Set patch file pointer at the data position and set offset size,
      // which is 32-bit (4 bytes) for PPFv1 and 64-bit (8 bytes) for PPFv3
      if (version == 1) {
         offsetSize = 4;
         fseek(file, 56, SEEK_SET);
      } else if (version == 3) {
         offsetSize = 8;
         if (validation)
            fseek(file, 1084, SEEK_SET);
         else
            fseek(file, 60, SEEK_SET);
      } else {
         return ERROR_PPF_VERSION;
      }

      while ((size = fread(buf, 1, offsetSize, file)) != 0) {
         // Size must be 0, or offsetSize
         if (size != offsetSize)
            return ERROR_PPF_READ;
         
         // Create a new data chunk
         PPF chunk;
         // Get offset
         chunk.setOffset(buf, offsetSize);

         // Read chunk size and add it to the total chunk size
         if (fread(buf, 1, 1, file) != 1)
            return ERROR_PPF_READ;
         else
            chunkSize = buf[0];
         totalSize += chunkSize;

         // Read and add chunk data. If chunkSize is 0, the first byte is the
         // data and the second is number of repetitions. This is only valid
         // for PPFv1 patches
          if (chunkSize == 0){
              if (version == 1){
                  return ERROR_PPF_FORMAT;
              }
              else if (version == 3){
                  chunkSize = 2;
              }
          }

         if ((signed)fread(buf, 1, chunkSize, file) != chunkSize)
            return ERROR_PPF_READ;
         else
            chunk.addData(buf, chunkSize);
        
         // Read and add optional undo data
         if (version == 3 && hasUndo) {
            if ((signed)fread(buf, 1, chunkSize, file) != chunkSize)
               return ERROR_PPF_READ;
            else
               chunk.addUndo(buf, chunkSize);
         }

         // Add chunk to ppf vector
         chunks.push_back(chunk);
      }

      // Close file
      if (fclose(file) != 0)
         return ERROR_PPF_CLOSE;

      // Set patch as loaded
      loaded = true;

      return 0;
   }

  /*
   * Apply the loaded patch or undo data on the given file
   */
   int LibPPF::applyPatch(string filename, bool undo) {
      FILE *file;

      // Save filename
      isoName = filename;

      // Make sure that the patch has been loaded and that undo data is
      // available if specified
      if (!loaded)
         return ERROR_PPF_LOADED;
      if (undo && !hasUndo)
         return ERROR_PPF_UNDO;

      // Make sure that file exists by trying to open it in read mode first
      if ((file = fopen(filename.c_str(), "rb")) == NULL)
         return ERROR_ISO_EXISTS;
      else
         fclose(file);

      // Open the given file
      if ((file = fopen(filename.c_str(), "r+b")) == NULL)
         return ERROR_ISO_OPEN;

      // Go through patch chunks one by one
      for (unsigned i = 0; i < chunks.size(); i++) {
         
         // Position binary file pointer at this chunk's offset
         fseek(file, chunks[i].getOffset(), SEEK_SET);

         // Write chunk data or undo data to file
         unsigned chunkSize = chunks[i].getSize();
         if (undo) {
            if (fwrite(chunks[i].getData(), 1, chunkSize, file) !=
                  chunkSize)
               return ERROR_ISO_WRITE;
         } else {
            if (fwrite(chunks[i].getUndo(), 1, chunkSize, file) !=
                  chunkSize)
               return ERROR_ISO_WRITE;
         }
      }

      // Close files
      if (fclose(file) == -1)
         return ERROR_ISO_CLOSE;

      return 0;
   }

  /*
   * Print patch info / status
   */
   void LibPPF::dumpInfo() {
      cerr << "Linux PPF Patcher v0.1-rc1\n\n";
      cerr << "Patch info:\n";
      cerr << "   Name:       " << ppfName << "\n";
      cerr << "   Version:    " << version << ".0\n";
      cerr << "   Chunks:     " << chunks.size() << "\n";

      cerr << "   Image type: ";
      if (type == TYPE_BIN)
         cerr << "BIN\n";
      else if (type == TYPE_GI)
         cerr << "GI\n";
      else
         cerr << "Unknown\n";

      cerr << "   Validation: ";
      if (validation)
         cerr << "Available\n";
      else
         cerr << "Not available\n";

      cerr << "   Undo data:  ";
      if (hasUndo)
         cerr << "Available\n";
      else
         cerr << "Not available\n";

      // cerr << "   Description: " << desc << "\n";
   }
}
