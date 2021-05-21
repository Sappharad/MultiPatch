# MultiPatch
MultiPatch is an all-in-one file patching utility for macOS. 

## Supported formats
Supported patch formats are automatically detected based on the file extension of the patch. Please ensure the patches you wish to use have the proper extension.  
IPS: .ips  
UPS: .ups  
PPF: .ppf  
XDelta: .delta; .dat  
BSDiff: .bdf; .bsdiff  
BPS: .bps  
Ninja2: .rup  

## License
MultiPatch is built using open source code taken from various sources. The code for each patching algorithm used falls under different licenses, and any changes made will need to adhere to the specific license for that code. The MultiPatch application itself is released under the GPL in an effort to be compatible with the licenses of the patching libraries contained within. The licenses employed by each patching library used are listed below:

**UPS, BPS and IPS use Floating IPS (FLIPS) by Alcaro.**  
\- Released under the GPLv3.  
**PPF uses ApplyPPF and MakePPF by Icarus.**  
\- Released under a "feel free to use this source" clause.
**XDelta uses XDelta3 by Josh MacDonald and others.**  
\- Released under the GPL.  
**BSDiff uses BSDiff by Colin Percival**  
\- Released under custom license. See source code for details.  
**Ninja2 uses LibRUP by Paul Kratt, translated from code by Derrick Sobodash**  
\- Released under the GPLv2.  

## More Information
The ReadMe.rtf file included with the application (which is checked into this repository) contains more information such as version history and usage instructions.
