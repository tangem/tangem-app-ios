
//
//  util.swift
//  secp256k1
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2018 pebble8888. All rights reserved.
//
/**********************************************************************
 * Copyright (c) 2013, 2014 Pieter Wuille                             *
 * Distributed under the MIT software license, see the accompanying   *
 * file COPYING or http://www.opensource.org/licenses/mit-license.php.*
 **********************************************************************/

import Foundation

struct secp256k1_callback {
    //void (*fn)(const char *text, void* data);
    var fn: (_ text: String, _ data: UnsafeMutableRawPointer? /*[UInt8] */) -> Void
    // const void* data;
    var data: UnsafeMutableRawPointer? // [UInt8]?
}

func secp256k1_callback_call(_ cb: secp256k1_callback, _ text: String) {
    cb.fn(text, cb.data)
}

 /*
#ifdef DETERMINISTIC
#define TEST_FAILURE(msg) do { \
    fprintf(stderr, "%s\n", msg); \
        abort(); \
} while(0);
#else
#define TEST_FAILURE(msg) do { \
fprintf(stderr, "%s:%d: %s\n", __FILE__, __LINE__, msg); \
abort(); \
} while(0)
#endif

#ifdef HAVE_BUILTIN_EXPECT
#define EXPECT(x,c) __builtin_expect((x),(c))
#else
#define EXPECT(x,c) (x)
#endif
 */

//#ifdef DETERMINISTIC
func CHECK(_ cond: Bool) {
    assert(cond, "test condition failed")
}
//#endif

/* Like assert(), but when VERIFY is defined, and side-effect safe. */
//#if defined(COVERAGE)
    //#define VERIFY_CHECK(check)
    //#elif defined(VERIFY)
    func VERIFY_CHECK(_ cond: Bool) {
        CHECK(cond)
    }
    //#define VERIFY_SETUP(stmt) do { stmt; } while(0)
    //#else
    //#define VERIFY_CHECK(cond) do { (void)(cond); } while(0)
    //#define VERIFY_SETUP(stmt)
    //#endif

    /*
    static SECP256K1_INLINE void *checked_malloc(const secp256k1_callback* cb, size_t size) {
        void *ret = malloc(size);
        if (ret == NULL) {
            secp256k1_callback_call(cb, "Out of memory");
        }
        return ret;
    }
     */
    
    /*
    
    /* Macro for restrict, when available and not in a VERIFY build. */
#if defined(SECP256K1_BUILD) && defined(VERIFY)
    # define SECP256K1_RESTRICT
    #else
    # if (!defined(__STDC_VERSION__) || (__STDC_VERSION__ < 199901L) )
    #  if SECP256K1_GNUC_PREREQ(3,0)
    #   define SECP256K1_RESTRICT __restrict__
    #  elif (defined(_MSC_VER) && _MSC_VER >= 1400)
    #   define SECP256K1_RESTRICT __restrict
    #  else
    #   define SECP256K1_RESTRICT
    #  endif
    # else
    #  define SECP256K1_RESTRICT restrict
    # endif
    #endif
    
#if defined(_WIN32)
    # define I64FORMAT "I64d"
    # define I64uFORMAT "I64u"
    #else
    # define I64FORMAT "lld"
    # define I64uFORMAT "llu"
    #endif
    
#if defined(HAVE___INT128)
    # if defined(__GNUC__)
    #  define SECP256K1_GNUC_EXT __extension__
    # else
    #  define SECP256K1_GNUC_EXT
    # endif
    SECP256K1_GNUC_EXT typedef unsigned __int128 uint128_t;
#endif

*/


