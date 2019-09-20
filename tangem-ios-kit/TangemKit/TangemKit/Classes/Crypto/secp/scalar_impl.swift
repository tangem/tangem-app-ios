//
//  scalar_impl.swift
//  secp256k1
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2018 pebble8888. All rights reserved.
//
/**********************************************************************
 * Copyright (c) 2014 Pieter Wuille                                   *
 * Distributed under the MIT software license, see the accompanying   *
 * file COPYING or http://www.opensource.org/licenses/mit-license.php.*
 **********************************************************************/

import Foundation

#if USE_NUM_NONE
func secp256k1_scalar_get_num(_ r: inout secp256k1_num, _ a: secp256k1_scalar) {
    var c:[UInt8] //[32]
    secp256k1_scalar_get_b32(&c, a);
    secp256k1_num_set_bin(r, c, 32);
}
    
/** secp256k1 curve order, see secp256k1_ecdsa_const_order_as_fe in ecdsa_impl.h */
func secp256k1_scalar_order_get_num(_ r: inout secp256k1_num) {
    let order:[UInt8] /*[32] */ = [
        0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,
        0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFE,
        0xBA,0xAE,0xDC,0xE6,0xAF,0x48,0xA0,0x3B,
        0xBF,0xD2,0x5E,0x8C,0xD0,0x36,0x41,0x41
    ]
    secp256k1_num_set_bin(r, order, 32);
}
#endif

func secp256k1_scalar_inverse(_ r: inout secp256k1_scalar, _ x: secp256k1_scalar) {
    /* First compute xN as x ^ (2^N - 1) for some values of N,
     * and uM as x ^ M for some values of M. */
    var x2 = secp256k1_scalar()
    var x3 = secp256k1_scalar()
    var x6 = secp256k1_scalar()
    var x8 = secp256k1_scalar()
    var x14 = secp256k1_scalar()
    var x28 = secp256k1_scalar()
    var x56 = secp256k1_scalar()
    var x112 = secp256k1_scalar()
    var x126 = secp256k1_scalar()
    var u2 = secp256k1_scalar()
    var u5 = secp256k1_scalar()
    var u9 = secp256k1_scalar()
    var u11 = secp256k1_scalar()
    var u13 = secp256k1_scalar()
    
    secp256k1_scalar_sqr(&u2, x);
    secp256k1_scalar_mul(&x2, u2,  x);
    secp256k1_scalar_mul(&u5, u2, x2);
    secp256k1_scalar_mul(&x3, u5,  u2);
    secp256k1_scalar_mul(&u9, x3, u2);
    secp256k1_scalar_mul(&u11, u9, u2);
    secp256k1_scalar_mul(&u13, u11, u2);
    
    secp256k1_scalar_sqr(&x6, u13);
    secp256k1_scalar_sqr(&x6, x6);
    secp256k1_scalar_mul(&x6, x6, u11);
    
    secp256k1_scalar_sqr(&x8, x6);
    secp256k1_scalar_sqr(&x8, x8);
    secp256k1_scalar_mul(&x8, x8, x2);
    
    secp256k1_scalar_sqr(&x14, x8);
    for _ in 0..<5 {
        secp256k1_scalar_sqr(&x14, x14);
    }
    secp256k1_scalar_mul(&x14, x14, x6);
    
    secp256k1_scalar_sqr(&x28, x14);
    for _ in 0..<13 {
        secp256k1_scalar_sqr(&x28, x28);
    }
    secp256k1_scalar_mul(&x28, x28, x14);
    
    secp256k1_scalar_sqr(&x56, x28);
    for _ in 0..<27 {
        secp256k1_scalar_sqr(&x56, x56);
    }
    secp256k1_scalar_mul(&x56, x56, x28);
    
    secp256k1_scalar_sqr(&x112, x56);
    for _ in 0..<55 {
        secp256k1_scalar_sqr(&x112, x112);
    }
    secp256k1_scalar_mul(&x112, x112, x56);
    
    secp256k1_scalar_sqr(&x126, x112);
    for _ in 0..<13 {
        secp256k1_scalar_sqr(&x126, x126);
    }
    secp256k1_scalar_mul(&x126, x126, x14);
    
    /* Then accumulate the final result (t starts at x126). */
    var t:secp256k1_scalar = x126
    for _ in 0..<3 {
        secp256k1_scalar_sqr(&t, t);
    }
    secp256k1_scalar_mul(&t, t, u5); /* 101 */
    for _ in 0..<4 { /* 0 */
        secp256k1_scalar_sqr(&t, t);
    }
    secp256k1_scalar_mul(&t, t, x3); /* 111 */
    for _ in 0..<4 { /* 0 */
        secp256k1_scalar_sqr(&t, t);
    }
    secp256k1_scalar_mul(&t, t, u5); /* 101 */
    for _ in 0..<5 { /* 0 */
        secp256k1_scalar_sqr(&t, t);
    }
    secp256k1_scalar_mul(&t, t, u11); /* 1011 */
    for _ in 0..<4 {
        secp256k1_scalar_sqr(&t, t);
    }
    secp256k1_scalar_mul(&t, t, u11); /* 1011 */
    for _ in 0..<4 { /* 0 */
        secp256k1_scalar_sqr(&t, t);
    }
    secp256k1_scalar_mul(&t, t, x3); /* 111 */
    for _ in 0..<5 { /* 00 */
        secp256k1_scalar_sqr(&t, t);
    }
    secp256k1_scalar_mul(&t, t, x3); /* 111 */
    for _ in 0..<6 { /* 00 */
        secp256k1_scalar_sqr(&t, t);
    }
    secp256k1_scalar_mul(&t, t, u13); /* 1101 */
    for _ in 0..<4 { /* 0 */
        secp256k1_scalar_sqr(&t, t);
    }
    secp256k1_scalar_mul(&t, t, u5); /* 101 */
    for _ in 0..<3 {
        secp256k1_scalar_sqr(&t, t);
    }
    secp256k1_scalar_mul(&t, t, x3); /* 111 */
    for _ in 0..<5 { /* 0 */
        secp256k1_scalar_sqr(&t, t);
    }
    secp256k1_scalar_mul(&t, t, u9); /* 1001 */
    for _ in 0..<6 { /* 000 */
        secp256k1_scalar_sqr(&t, t);
    }
    secp256k1_scalar_mul(&t, t, u5); /* 101 */
    for _ in 0..<10 { /* 0000000 */
        secp256k1_scalar_sqr(&t, t);
    }
    secp256k1_scalar_mul(&t, t, x3); /* 111 */
    for _ in 0..<4 { /* 0 */
        secp256k1_scalar_sqr(&t, t);
    }
    secp256k1_scalar_mul(&t, t, x3); /* 111 */
    for _ in 0..<9 { /* 0 */
        secp256k1_scalar_sqr(&t, t);
    }
    secp256k1_scalar_mul(&t, t, x8); /* 11111111 */
    for _ in 0..<5 { /* 0 */
        secp256k1_scalar_sqr(&t, t);
    }
    secp256k1_scalar_mul(&t, t, u9); /* 1001 */
    for _ in 0..<6 { /* 00 */
        secp256k1_scalar_sqr(&t, t);
    }
    secp256k1_scalar_mul(&t, t, u11); /* 1011 */
    for _ in 0..<4 {
        secp256k1_scalar_sqr(&t, t);
    }
    secp256k1_scalar_mul(&t, t, u13); /* 1101 */
    for _ in 0..<5 {
        secp256k1_scalar_sqr(&t, t);
    }
    secp256k1_scalar_mul(&t, t, x2); /* 11 */
    for _ in 0..<6 { /* 00 */
        secp256k1_scalar_sqr(&t, t);
    }
    secp256k1_scalar_mul(&t, t, u13); /* 1101 */
    for _ in 0..<10 { /* 000000 */
        secp256k1_scalar_sqr(&t, t);
    }
    secp256k1_scalar_mul(&t, t, u13); /* 1101 */
    for _ in 0..<4 {
        secp256k1_scalar_sqr(&t, t);
    }
    secp256k1_scalar_mul(&t, t, u9); /* 1001 */
    for _ in 0..<6 { /* 00000 */
        secp256k1_scalar_sqr(&t, t);
    }
    secp256k1_scalar_mul(&t, t, x); /* 1 */
    for _ in 0..<8 { /* 00 */
        secp256k1_scalar_sqr(&t, t);
    }
    secp256k1_scalar_mul(&r, t, x6); /* 111111 */
}

func secp256k1_scalar_is_even(_ a: secp256k1_scalar) -> Bool {
    return (a.d[0] & 1) == 0
}

func secp256k1_scalar_inverse_var(_ r: inout secp256k1_scalar, _ x: secp256k1_scalar) {
//#if USE_SCALAR_INV_BUILTIN
#if true
    secp256k1_scalar_inverse(&r, x);
#elseif USE_SCALAR_INV_NUM
    var b:[UInt8] //[32];
    var n: secp256k1_num
    var m: secp256k1_num
    var t: secp256k1_scalar = *x;
    secp256k1_scalar_get_b32(b, &t);
    secp256k1_num_set_bin(&n, b, 32);
    secp256k1_scalar_order_get_num(&m);
    secp256k1_num_mod_inverse(&n, &n, &m);
    secp256k1_num_get_bin(b, 32, &n);
    secp256k1_scalar_set_b32(r, b, NULL);
    /* Verify that the inverse was computed correctly, without GMP code. */
    secp256k1_scalar_mul(&t, &t, r);
    //CHECK(secp256k1_scalar_is_one(&t));
#else
    assert(false, "Please select scalar inverse implementation")
#endif
}
