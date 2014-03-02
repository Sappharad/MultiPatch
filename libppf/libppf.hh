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

#ifndef _LIBPPF_
#define _LIBPPF_

// PPF error codes
#define ERROR_PPF_FORMAT  0x01
#define ERROR_PPF_VERSION 0x02
#define ERROR_PPF_EXISTS  0x03
#define ERROR_PPF_OPEN    0x04
#define ERROR_PPF_CLOSE   0x05
#define ERROR_PPF_READ    0x06
#define ERROR_PPF_LOADED  0x07
#define ERROR_PPF_UNDO    0x08

// ISO error codes
#define ERROR_ISO_EXISTS  0x11
#define ERROR_ISO_OPEN    0x12
#define ERROR_ISO_CLOSE   0x13
#define ERROR_ISO_READ    0x14
#define ERROR_ISO_WRITE   0x15

#define TYPE_BIN 0
#define TYPE_GI  1

#include <iostream>
#include <vector>
#include "ppf.hh"

namespace lppf {
   using namespace std;

   class LibPPF {
      public:
         LibPPF();
         int loadPatch(string filename);
         int applyPatch(string filename, bool undo);
         void dumpInfo();
         int getBytes() {return totalSize;}
         unsigned getChunks() {return chunks.size();}
         string getPPF() {return ppfName;}
         string getISO() {return isoName;}

      private:
         bool loaded, validation, hasUndo;
         string ppfDesc, ppfName, isoName;
         int totalSize, type, version;
         vector<PPF> chunks;
   };
}

#endif
