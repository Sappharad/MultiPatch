/*****************************************************************************
   A class for stroring ppf data in lppf v0.1-rc1

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

#ifndef _PPF_DATA_
#define _PPF_DATA_

#include <iostream>
#include <cmath>

namespace lppf {
   using namespace std;

   class PPF {
      public:
         PPF();
         int getSize() {return size;}
         long getOffset() {return offset;}
         void addData(unsigned char *buf, int size);
         void addUndo(unsigned char *buf, int size);
         void setOffset(unsigned char *buf, int bytes);
         unsigned char *getData() {return data;}
         unsigned char *getUndo() {return undo;}

      private:
         unsigned char data[256], undo[256];
         long offset;
         int size;
   };
}

#endif
