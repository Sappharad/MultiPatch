/*****************************************************************************
   Linux PPF patcher v0.1-rc1
  
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

#include "lppf.hh"
#include "libppf.hh"

using namespace lppf;

/*
 * Returns a string representing the error code
 */
string errorCode(int error, LibPPF *ppf) {
   switch (error) {
      case 0x01:
         return string("File " + ppf->getPPF() + " is NOT a PPF file!");
      case 0x02:
         return string("PPF version not supported or unknown");
      case 0x03:
         return string("No such PPF file: " + ppf->getPPF());
      case 0x04:
         return string("Error opening PPF file: " + ppf->getPPF());
      case 0x05:
         return string("Error closing PPF file: " + ppf->getPPF());
      case 0x06:
         return string("Error reading from PPF file: " + ppf->getPPF());
      case 0x07:
         return string("PPF file hasn't been loaded");
      case 0x08:
         return string("No undo data available");
      case 0x11:
         return string("No such file: " + ppf->getISO());
      case 0x12:
         return string("Error opening file: " + ppf->getISO());
      case 0x13:
         return string("Error closing file: " + ppf->getISO());
      case 0x14:
         return string("Error reading from file: " + ppf->getISO());
      case 0x15:
         return string("Error writing to file: " + ppf->getISO());
      default:
         return string("Unknown error code!");
   }
}

/*
 * Print usage
 */
void usage() {
   cerr << "Linux PPF patcher " << VERSION << "\n\n" <<
      "Usage: lppf ppf-patch [action] [image]\n" <<
      "Actions:\n" <<
      "   -p image  patch the given image\n" <<
      "   -u image  undo the given image\n" <<
      "   -h        print this help\n" <<
      "   -v        print version number and exit\n\n" <<
      "The undo action only works on v3.0 patches " <<
      "with undo data available.\n" <<
      "If nothing except the patch is given, lppf will " <<
      "print patch info and exit.\n\n" <<
      "Copyright (C), 2007 - 2008 Daniel Ekström " <<
      "<dv01dem@cs.umu.se>\n";
}

int main(int argc, char **argv) {
   LibPPF ppf;
   int error, opt;
   string isoName;

   // First argument must be a patch file and dump it if no more options
   // are given
   if (argc == 1) {
      usage();
      return 0;
   }
   
   // Parse argument with getopt
   while ((opt = getopt(argc, argv, "hp:u:v")) != -1) {
      switch (opt) {
         case 'h':
            usage();
            return 0;

         case 'p':
            // Load PPF first
            if ((error = ppf.loadPatch(argv[1])) != 0) {
               cerr << errorCode(error, &ppf) << "\n";
               return 1;
            }

            // Apply PPF data to file
            isoName = string(argv[optind - 1]);
            cerr << "Applying PPF data from " << ppf.getPPF() << "...\n";
            if ((error = ppf.applyPatch(isoName, false)) != 0) {
               cerr << errorCode(error, &ppf) << "\n";
            } else {
               cerr << ppf.getBytes() << " bytes in " << ppf.getChunks() <<
                  " chunks successfully written to " << ppf.getISO() << "!\n";
            }
            return 0;

         case 'u':
            // Load PPF first
            if ((error = ppf.loadPatch(argv[1])) != 0) {
               cerr << errorCode(error, &ppf) << "\n";
               return 1;
            }

            // Apply PPF undo data to file
            isoName = string(argv[optind - 1]);
            cerr << "Applying PPF undo data from " << ppf.getPPF() << "...\n";
            if ((error = ppf.applyPatch(isoName, true)) != 0) {
               cerr << errorCode(error, &ppf) << "\n";
            } else {
               cerr << ppf.getBytes() << " bytes in " << ppf.getChunks() <<
                  " chunks successfully written to " << ppf.getISO() << "!\n";
            }
            return 0;

         case 'v':
            cerr << "lppf-" << VERSION << "\n";
            return 0;

         case ':':
            cerr << "Error: option '" << optopt << "' needs an argument," <<
               " aborting...\n";
            return 0;

         case '?':
            cerr << "Error: unknown option '" << optopt << "', aborting...\n";
            return 0;
      }
   }

   // If we've gotten this far without returning, no arguments was given
   ppf.dumpInfo();
    
   return 0;
}
