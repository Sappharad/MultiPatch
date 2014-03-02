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

#include "ppf.hh"

namespace lppf {
   PPF::PPF() {
      offset = 0;
      size = 0;
   }

  /*
   * Copy given data to data char array
   */
   void PPF::addData(unsigned char *buf, int size) {
      this->size = size;

      // If size is 2, the first byte in buffer is the data and the second
      // is number of repetitions of this data
      if (size == 2) {
         for (int i = 0; i < buf[1]; i++)
            data[i] = buf[0];
      } else {
         // Copy buffer
         for (int i = 0; i < size; i++)
            data[i] = buf[i];
      }
   }

  /*
   * Copy given undo data to undo data char array
   */
   void PPF::addUndo(unsigned char *buf, int size) {
      // Size of undo data should be the same as the size of the data
      if (this->size != size)
         cerr << "PPF::addUndo - Warning: Invalid size of undo data!\n";
      this->size = size;

      // Copy buffer
      for (int i = 0; i < size; i++)
         undo[i] = buf[i];
   }

  /*
   * Takes a user defined size char array of data creates a long integer
   * representing the data offset in big endian order
   */
   void PPF::setOffset(unsigned char *buf, int bytes) {
      bool start = false;

      // Reset current data offset value
      offset = 0;

      // Go through array to calculate
      for (int i = bytes - 1; i > -1; i--) {
         // Make sure that the leading zeroes won't be used
         if (start == false && buf[i] != 0)
            start = true;
         if (start)
            offset += (long)(buf[i] * pow(256.0, i));
      }
   }
}
