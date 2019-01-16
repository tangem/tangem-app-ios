//
//  field_impl.swift
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

// a mod q != b
func secp256k1_fe_equal(_ a: secp256k1_fe, _ b:secp256k1_fe) -> Bool {
    var na = secp256k1_fe()
    // 4*q -a
    secp256k1_fe_negate(&na, a, 1);
    // v = 4*q -a + b
    secp256k1_fe_add(&na, b);
    // v mod q is zero or not
    return secp256k1_fe_normalizes_to_zero(&na);
}
    
// a mod p != b
func secp256k1_fe_equal_var(_ a:secp256k1_fe, _ b:secp256k1_fe) -> Bool {
    var na = secp256k1_fe()
    // 4*p -a
    secp256k1_fe_negate(&na, a, 1);
    // v = 4*p -a + b
    secp256k1_fe_add(&na, b);
    // v mod p is 0 or not
    return secp256k1_fe_normalizes_to_zero_var(&na);
}
    
// quadratic redisue 
// http://pebble8888.hatenablog.com/entry/2017/07/30/222227
// case : p mod 4 = 3.
// p is defined as 2^256 - 2^32 - 2^9 - 2^8 - 2^7 - 2^6 - 2^4 - 1.
// if x exists that x^2 = a,
// solution is x = a ^ ((p+1)/4).
// (p+1)/4 = 2^252 - 2^30 - 2^7 - 2^6 - 2^5 - 2^4 - 2^2
//
func secp256k1_fe_sqrt(_ r: inout secp256k1_fe, _ a: secp256k1_fe) -> Bool {
    /** Given that p is congruent to 3 mod 4, we can compute the square root of
     *  a mod p as the (p+1)/4'th power of a.
     *
     *  As (p+1)/4 is an even number, it will have the same result for a and for
     *  (-a). Only one of these two numbers actually has a square root however,
     *  so we test at the end by squaring and comparing to the input.
     *  Also because (p+1)/4 is an even number, the computed square root is
     *  itself always a square (a ** ((p+1)/4) is the square of a ** ((p+1)/8)).
     */
    var x2 = secp256k1_fe()
    var x3 = secp256k1_fe()
    var x6:secp256k1_fe
    var x9:secp256k1_fe
    var x11:secp256k1_fe
    var x22:secp256k1_fe
    var x44:secp256k1_fe
    var x88:secp256k1_fe
    var x176:secp256k1_fe
    var x220:secp256k1_fe
    var x223:secp256k1_fe
    var t1:secp256k1_fe
    //var j:Int

    /** The binary representation of (p + 1)/4 has 3 blocks of 1s, with lengths in
     *  { 2, 22, 223 }. Use an addition chain to calculate 2^n - 1 for each block:
     *  1, [2], 3, 6, 9, 11, [22], 44, 88, 176, 220, [223]
     */

    secp256k1_fe_sqr(&x2, a);
    secp256k1_fe_mul(&x2, x2, a);

    secp256k1_fe_sqr(&x3, x2);
    secp256k1_fe_mul(&x3, x3, a);

    x6 = x3;
    for _ in 0..<3 {
        secp256k1_fe_sqr(&x6, x6);
    }
    secp256k1_fe_mul(&x6, x6, x3);

    x9 = x6;
    for _ in 0..<3 {
        secp256k1_fe_sqr(&x9, x9);
    }
    secp256k1_fe_mul(&x9, x9, x3);

    x11 = x9;
    for _ in 0..<2 {
        secp256k1_fe_sqr(&x11, x11);
    }
    secp256k1_fe_mul(&x11, x11, x2);

    x22 = x11;
    for _ in 0..<11 {
        secp256k1_fe_sqr(&x22, x22);
    }
    secp256k1_fe_mul(&x22, x22, x11);

    x44 = x22;
    for _ in 0..<22 {
        secp256k1_fe_sqr(&x44, x44);
    }
    secp256k1_fe_mul(&x44, x44, x22);

    x88 = x44;
    for _ in 0..<44 {
        secp256k1_fe_sqr(&x88, x88);
    }
    secp256k1_fe_mul(&x88, x88, x44);

    x176 = x88;
    for _ in 0..<88 {
        secp256k1_fe_sqr(&x176, x176);
    }
    secp256k1_fe_mul(&x176, x176, x88);

    x220 = x176;
    for _ in 0..<44 {
        secp256k1_fe_sqr(&x220, x220);
    }
    secp256k1_fe_mul(&x220, x220, x44);

    x223 = x220;
    for _ in 0..<3 {
        secp256k1_fe_sqr(&x223, x223);
    }
    secp256k1_fe_mul(&x223, x223, x3);

    /* The final result is then assembled using a sliding window over the blocks. */
    // x223を23回２乗しt1にセットする
    t1 = x223;
    for _ in 0..<23 {
        secp256k1_fe_sqr(&t1, t1);
    }
    // t1にx22を掛ける
    secp256k1_fe_mul(&t1, t1, x22);
    // t1を6回２乗する
    for _ in 0..<6 {
        secp256k1_fe_sqr(&t1, t1);
    }
    // t1にx2を掛ける
    secp256k1_fe_mul(&t1, t1, x2);
    // t1を2回２乗し答えとする
    secp256k1_fe_sqr(&t1, t1);
    secp256k1_fe_sqr(&r, t1);

    /* Check that a square root was actually calculated */
    // rを2乗したらaに等しいことを確認する
    secp256k1_fe_sqr(&t1, r);
    return secp256k1_fe_equal(t1, a);
}
    
// a^(-1) = a^(p-2)
func secp256k1_fe_inv(_ r: inout secp256k1_fe, _ a:secp256k1_fe) {
    var x2 = secp256k1_fe()
    var x3 = secp256k1_fe()
    var x6:secp256k1_fe
    var x9:secp256k1_fe
    var x11:secp256k1_fe
    var x22:secp256k1_fe
    var x44:secp256k1_fe
    var x88:secp256k1_fe
    var x176:secp256k1_fe
    var x220:secp256k1_fe
    var x223:secp256k1_fe
    var t1:secp256k1_fe
    //var j:Int

    /** The binary representation of (p - 2) has 5 blocks of 1s, with lengths in
     *  { 1, 2, 22, 223 }. Use an addition chain to calculate 2^n - 1 for each block:
     *  [1], [2], 3, 6, 9, 11, [22], 44, 88, 176, 220, [223]
     */

    secp256k1_fe_sqr(&x2, a);
    secp256k1_fe_mul(&x2, x2, a);

    secp256k1_fe_sqr(&x3, x2);
    secp256k1_fe_mul(&x3, x3, a);

    x6 = x3;
    for _ in 0..<3 {
        secp256k1_fe_sqr(&x6, x6);
    }
    secp256k1_fe_mul(&x6, x6, x3);

    x9 = x6;
    for _ in 0..<3 {
        secp256k1_fe_sqr(&x9, x9);
    }
    secp256k1_fe_mul(&x9, x9, x3);

    x11 = x9;
    for _ in 0..<2 {
        secp256k1_fe_sqr(&x11, x11);
    }
    secp256k1_fe_mul(&x11, x11, x2);

    x22 = x11;
    for _ in 0..<11 {
        secp256k1_fe_sqr(&x22, x22);
    }
    secp256k1_fe_mul(&x22, x22, x11);

    x44 = x22;
    for _ in 0..<22 {
        secp256k1_fe_sqr(&x44, x44);
    }
    secp256k1_fe_mul(&x44, x44, x22);

    x88 = x44;
    for _ in 0..<44 {
        secp256k1_fe_sqr(&x88, x88);
    }
    secp256k1_fe_mul(&x88, x88, x44);

    x176 = x88;
    for _ in 0..<88 {
        secp256k1_fe_sqr(&x176, x176);
    }
    secp256k1_fe_mul(&x176, x176, x88);

    x220 = x176;
    for _ in 0..<44 {
        secp256k1_fe_sqr(&x220, x220);
    }
    secp256k1_fe_mul(&x220, x220, x44);

    x223 = x220;
    for _ in 0..<3 {
        secp256k1_fe_sqr(&x223, x223);
    }
    secp256k1_fe_mul(&x223, x223, x3);

    /* The final result is then assembled using a sliding window over the blocks. */

    t1 = x223;
    for _ in 0..<23 {
        secp256k1_fe_sqr(&t1, t1);
    }
    secp256k1_fe_mul(&t1, t1, x22);
    for _ in 0..<5 {
        secp256k1_fe_sqr(&t1, t1);
    }
    secp256k1_fe_mul(&t1, t1, a);
    for _ in 0..<3 {
        secp256k1_fe_sqr(&t1, t1);
    }
    secp256k1_fe_mul(&t1, t1, x2);
    for _ in 0..<2 {
        secp256k1_fe_sqr(&t1, t1);
    }
    secp256k1_fe_mul(&r, a, t1);
}
    
// r = 1/a
func secp256k1_fe_inv_var(_ r: inout secp256k1_fe, _ a:secp256k1_fe) {
    secp256k1_fe_inv(&r, a);
}

// r = [ 1/a[0], 1/a[1], ..., 1/a[n] ]
func secp256k1_fe_inv_all_var(_ r: inout [secp256k1_fe], _ a:[secp256k1_fe], _ len: UInt) {
    var u = secp256k1_fe()
    var i: Int
    if len < 1 {
        return;
    }

    //VERIFY_CHECK((r + len <= a) || (a + len <= r));

    r[0] = a[0]

    i = 0;
    i += 1
    while i < len {
        secp256k1_fe_mul(&r[i], r[i - 1], a[i]);
        i += 1
    }

    i -= 1
    secp256k1_fe_inv_var(&u, r[i]);

    while i > 0 {
        let j:Int = i
        i -= 1
        secp256k1_fe_mul(&r[j], r[i], u);
        secp256k1_fe_mul(&u, u, a[j]);
    }

    r[0] = u;
}

// Is quadratic redisue
// Does x exist to meet x^2 = a mod q ?
func secp256k1_fe_is_quad_var(_ a:secp256k1_fe) -> Bool {
    var r = secp256k1_fe()
    return secp256k1_fe_sqrt(&r, a);
}
