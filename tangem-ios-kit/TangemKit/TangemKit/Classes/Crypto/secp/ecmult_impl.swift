//
//  ecmult_impl.swift
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

#if EXHAUSTIVE_TEST_ORDER
#else
    /* optimal for 128-bit and 256-bit exponents. */
    let WINDOW_A: Int = 5
    /** larger numbers may result in slightly better performance, at the cost of
     exponentially larger precomputed tables. */
    /** One table for window size 16: 1.375 MiB. */
    let WINDOW_G: Int = 16
#endif

/** The number of entries a table with precomputed multiples needs to have. */
func ECMULT_TABLE_SIZE(_ w: Int) -> Int { return (1 << ((w)-2)) }

/** Fill a table 'prej' with precomputed odd multiples of a. Prej will contain
 *  the values [1*a,3*a,...,(2*n-1)*a], so it space for n values. zr[0] will
 *  contain prej[0].z / a.z. The other zr[i] values = prej[i].z / prej[i-1].z.
 *  Prej's Z values are undefined, except for the last value.
 */
func secp256k1_ecmult_odd_multiples_table(_ n: Int, _ prej: inout [secp256k1_gej], _ zr: inout [secp256k1_fe], _ a: secp256k1_gej) {
    var d = secp256k1_gej()
    var a_ge = secp256k1_ge()
    var d_ge = secp256k1_ge()

    VERIFY_CHECK(!a.infinity);
    
    var dummy = secp256k1_fe()
    secp256k1_gej_double_var(&d, a, &dummy)
    
    /*
     * Perform the additions on an isomorphism where 'd' is affine: drop the z coordinate
     * of 'd', and scale the 1P starting value's x/y coordinates without changing its z.
     */
    d_ge.x = d.x;
    d_ge.y = d.y;
    d_ge.infinity = false
    
    secp256k1_ge_set_gej_zinv(&a_ge, a, d.z);
    prej[0].x = a_ge.x;
    prej[0].y = a_ge.y;
    prej[0].z = a.z;
    prej[0].infinity = false
    
    zr[0] = d.z;
    for i in 1..<n {
        secp256k1_gej_add_ge_var(&prej[i], prej[i-1], d_ge, &zr[i]);
    }
    
    /*
     * Each point in 'prej' has a z coordinate too small by a factor of 'd.z'. Only
     * the final point's z coordinate is actually used though, so just update that.
     */
    secp256k1_fe_mul(&prej[n-1].z, prej[n-1].z, d.z);
}

/** Fill a table 'pre' with precomputed odd multiples of a.
 *
 *  There are two versions of this function:
 *  - secp256k1_ecmult_odd_multiples_table_globalz_windowa which brings its
 *    resulting point set to a single constant Z denominator, stores the X and Y
 *    coordinates as ge_storage points in pre, and stores the global Z in rz.
 *    It only operates on tables sized for WINDOW_A wnaf multiples.
 *  - secp256k1_ecmult_odd_multiples_table_storage_var, which converts its
 *    resulting point set to actually affine points, and stores those in pre.
 *    It operates on tables of any size, but uses heap-allocated temporaries.
 *
 *  To compute a*P + b*G, we compute a table for P using the first function,
 *  and for G using the second (which requires an inverse, but it only needs to
 *  happen once).
 */
func secp256k1_ecmult_odd_multiples_table_globalz_windowa(_ pre: inout [secp256k1_ge], _ globalz: inout secp256k1_fe, _ a: secp256k1_gej) {
    var prej: [secp256k1_gej] = [secp256k1_gej](repeating: secp256k1_gej(), count: ECMULT_TABLE_SIZE(WINDOW_A))
    var zr: [secp256k1_fe] = [secp256k1_fe](repeating: secp256k1_fe(), count: ECMULT_TABLE_SIZE(WINDOW_A))
    
    /* Compute the odd multiples in Jacobian form. */
    secp256k1_ecmult_odd_multiples_table(ECMULT_TABLE_SIZE(WINDOW_A), &prej, &zr, a);
    /* Bring them to the same Z denominator. */
    secp256k1_ge_globalz_set_table_gej(UInt(ECMULT_TABLE_SIZE(WINDOW_A)), &pre, &globalz, prej, zr);
}

func secp256k1_ecmult_odd_multiples_table_storage_var(_ n: Int, _ pre: inout [secp256k1_ge_storage], _ a: secp256k1_gej, _ cb: secp256k1_callback?) {
    var prej: [secp256k1_gej] = [secp256k1_gej](repeating: secp256k1_gej(), count: n)
    var prea: [secp256k1_ge] = [secp256k1_ge](repeating: secp256k1_ge(), count: n)
    var zr: [secp256k1_fe] = [secp256k1_fe](repeating: secp256k1_fe(), count: n)

    /* Compute the odd multiples in Jacobian form. */
    secp256k1_ecmult_odd_multiples_table(n, &prej, &zr, a);
    /* Convert them in batch to affine coordinates. */
    secp256k1_ge_set_table_gej_var(&prea, prej, zr, UInt(n));
    /* Convert them to compact storage form. */
    for i in 0..<n {
        secp256k1_ge_to_storage(&pre[i], prea[i]);
    }
}

/** The following two macro retrieves a particular odd multiple from a table
 *  of precomputed multiples. */
func ECMULT_TABLE_GET_GE(_ r: inout secp256k1_ge, _ pre: [secp256k1_ge], _ n: Int, _ w: Int){
    VERIFY_CHECK(((n) & 1) == 1);
    VERIFY_CHECK((n) >= -((1 << ((w)-1)) - 1));
    VERIFY_CHECK((n) <=  ((1 << ((w)-1)) - 1));
    if (n > 0) {
        r = pre[(n-1)/2]
    } else {
        secp256k1_ge_neg(&r, pre[(-n-1)/2])
    }
}

func ECMULT_TABLE_GET_GE_STORAGE(_ r: inout secp256k1_ge, _ pre: [secp256k1_ge_storage], _ n: Int, _ w: Int) {
    VERIFY_CHECK(((n) & 1) == 1);
    VERIFY_CHECK((n) >= -((1 << ((w)-1)) - 1));
    VERIFY_CHECK((n) <=  ((1 << ((w)-1)) - 1));
    if ((n) > 0) {
        secp256k1_ge_from_storage(&r, pre[(n-1)/2])
    } else {
        secp256k1_ge_from_storage(&r, pre[(-n-1)/2])
        secp256k1_ge_neg(&r, r);
    }
}

func secp256k1_ecmult_context_init(_ ctx: inout secp256k1_ecmult_context) {
    ctx.pre_g.removeAll() //= nil
}

func secp256k1_ecmult_context_build(_ ctx: inout secp256k1_ecmult_context, _ cb: secp256k1_callback?) {
    var gj = secp256k1_gej()
    
    if (ctx.pre_g.count > 0 /* != nil */ ) {
        return;
    }
    
    /* get the generator */
    secp256k1_gej_set_ge(&gj, secp256k1_ge_const_g);
    
    ctx.pre_g = [/*Pre_G */ secp256k1_ge_storage](repeating: /*Pre_G */ secp256k1_ge_storage(), count: ECMULT_TABLE_SIZE(WINDOW_G))

    /* precompute the tables with odd multiples */
    secp256k1_ecmult_odd_multiples_table_storage_var(ECMULT_TABLE_SIZE(WINDOW_G), &ctx.pre_g, gj, cb);
}

func secp256k1_ecmult_context_clone(_ dst: inout secp256k1_ecmult_context,
    _ src: secp256k1_ecmult_context,
    _ cb: secp256k1_callback) {
    if (src.pre_g.count == 0 /*== nil */) {
        dst.pre_g.removeAll() // = nil
    } else {
        let count = ECMULT_TABLE_SIZE(WINDOW_G)
        //let size = sizeof((dst.pre_g)[0]) * ECMULT_TABLE_SIZE(WINDOW_G);
        dst.pre_g = [/*Pre_G */ secp256k1_ge_storage](repeating: /*Pre_G*/ secp256k1_ge_storage(), count: count) // (secp256k1_ge_storage (*)[])checked_malloc(cb, size);
        //memcpy(dst.pre_g, src.pre_g, size);
        dst.pre_g = src.pre_g
    }
}

func secp256k1_ecmult_context_is_built(_ ctx: secp256k1_ecmult_context) -> Bool {
    return ctx.pre_g.count > 0 // != nil
}

func secp256k1_ecmult_context_clear(_ ctx: inout secp256k1_ecmult_context) {
    //free(ctx.pre_g);
    ctx.pre_g.removeAll()
    secp256k1_ecmult_context_init(&ctx);
}

/** Convert a number to WNAF notation. The number becomes represented by sum(2^i * wnaf[i], i=0..bits),
 *  with the following guarantees:
 *  - each wnaf[i] is either 0, or an odd integer between -(1<<(w-1) - 1) and (1<<(w-1) - 1)
 *  - two non-zero entries in wnaf are separated by at least w-1 zeroes.
 *  - the number of set values in wnaf is returned. This number is at most 256, and at most one more
 *    than the number of bits in the (absolute value) of the input.
 */
func secp256k1_ecmult_wnaf(_ wnaf: inout [Int], _ len: Int, _ a: secp256k1_scalar, _ w: Int) -> Int {
    var s: secp256k1_scalar = a
    var last_set_bit: Int = -1;
    var bit: Int = 0;
    var sign: Int = 1;
    var carry: Int = 0;
    
    //VERIFY_CHECK(wnaf != NULL);
    VERIFY_CHECK(0 <= len && len <= 256);
    //VERIFY_CHECK(a != NULL);
    VERIFY_CHECK(2 <= w && w <= 31);
    
    for i in 0 ..< len {
        wnaf[i] = 0
    }
    
    if secp256k1_scalar_get_bits(s, 255, 1) != 0 {
        secp256k1_scalar_negate(&s, s);
        sign = -1;
    }
    
    while (bit < len) {
        var now:Int
        var word:Int
        if (secp256k1_scalar_get_bits(s, UInt(bit), 1) == /*(unsigned int)*/ carry) {
            bit += 1
            continue;
        }
        
        now = w;
        if (now > len - bit) {
            now = len - bit;
        }
        
        word = Int(secp256k1_scalar_get_bits_var(s, UInt(bit), UInt(now))) + carry;
        
        carry = (word >> (w-1)) & 1;
        word -= carry << w;
        
        wnaf[bit] = sign * word;
        last_set_bit = bit;
        
        bit += now;
    }
    #if VERIFY
        CHECK(carry == 0);
        while (bit < 256) {
            CHECK(secp256k1_scalar_get_bits(s, UInt(bit), 1) == 0)
            bit += 1
        }
    #endif
    return last_set_bit + 1;
}

/**
 @brief calc (x1, y1) = ng * G + na * A, get x1
 @param r : gej
 @param a : gej      jacobian cordinate of public piont A (pubkey)
 @param na : scalar  u2: coef of A(public point)
 @param ng : scalar  u1: coef of G(base point)
 */
func secp256k1_ecmult(_ ctx: secp256k1_ecmult_context,
    _ r: inout secp256k1_gej,
    _ a: secp256k1_gej,
    _ na: secp256k1_scalar,
    _ ng: secp256k1_scalar) {
    var pre_a:[secp256k1_ge] = [secp256k1_ge](repeating: secp256k1_ge(), count: ECMULT_TABLE_SIZE(WINDOW_A))
    var tmpa = secp256k1_ge()
    var Z = secp256k1_fe()
    var wnaf_na: [Int] = [Int](repeating: 0, count: 256)
    var bits_na: Int
    var wnaf_ng: [Int] = [Int](repeating: 0, count: 256)
    var bits_ng: Int
    var bits: Int
    
    /* build wnaf representation for na. */
    bits_na = secp256k1_ecmult_wnaf(&wnaf_na, 256, na, WINDOW_A);
    bits = bits_na;
    
    /* Calculate odd multiples of a.
     * All multiples are brought to the same Z 'denominator', which is stored
     * in Z. Due to secp256k1' isomorphism we can do all operations pretending
     * that the Z coordinate was 1, use affine addition formulae, and correct
     * the Z coordinate of the result once at the end.
     * The exception is the precomputed G table points, which are actually
     * affine. Compared to the base used for other points, they have a Z ratio
     * of 1/Z, so we can use secp256k1_gej_add_zinv_var, which uses the same
     * isomorphism to efficiently add with a known Z inverse.
     */
    secp256k1_ecmult_odd_multiples_table_globalz_windowa(&pre_a, &Z, a);
    
    bits_ng = secp256k1_ecmult_wnaf(&wnaf_ng, 256, ng, WINDOW_G);
    if (bits_ng > bits) {
        bits = bits_ng;
    }
    
    secp256k1_gej_set_infinity(&r);
    
    for i in stride(from: bits - 1, through: 0, by: -1){
        var n: Int
        var dummy = secp256k1_fe()
        secp256k1_gej_double_var(&r, r, &dummy);
        if (i < bits_na) {
            n = wnaf_na[i]
            if n != 0 {
                ECMULT_TABLE_GET_GE(&tmpa, pre_a, n, WINDOW_A);
                secp256k1_gej_add_ge_var(&r, r, tmpa, &dummy);
            }
        }
        if (i < bits_ng) {
            n = wnaf_ng[i]
            if n != 0 {
                ECMULT_TABLE_GET_GE_STORAGE(&tmpa, ctx.pre_g, n, WINDOW_G);
                secp256k1_gej_add_zinv_var(&r, r, tmpa, Z);
            }
        }
    }
    
    if (!r.infinity) {
        secp256k1_fe_mul(&r.z, r.z, Z);
    }
}
