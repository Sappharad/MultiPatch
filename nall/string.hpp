#ifndef NALL_STRING_HPP
#define NALL_STRING_HPP

#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include <algorithm>
#include <initializer_list>

#include "atoi.hpp"
#include "function.hpp"
#include "platform.hpp"
#include "sha256.hpp"
#include "stdint.hpp"
#include "utility.hpp"
#include "varint.hpp"
#include "vector.hpp"

#include "windows/utf8.hpp"

#define NALL_STRING_INTERNAL_HPP
#include "string/base.hpp"
#include "string/bml.hpp"
#include "string/bsv.hpp"
#include "string/cast.hpp"
#include "string/compare.hpp"
#include "string/convert.hpp"
#include "string/core.hpp"
#include "string/cstring.hpp"
#include "string/filename.hpp"
#include "string/math-fixed-point.hpp"
#include "string/math-floating-point.hpp"
#include "string/platform.hpp"
#include "string/strm.hpp"
#include "string/strpos.hpp"
#include "string/trim.hpp"
#include "string/replace.hpp"
#include "string/split.hpp"
#include "string/static.hpp"
#include "string/utf8.hpp"
#include "string/utility.hpp"
#include "string/variadic.hpp"
#include "string/wildcard.hpp"
#include "string/wrapper.hpp"
#include "string/xml.hpp"
#undef NALL_STRING_INTERNAL_HPP

#endif
