//
//  ecmult_gen_impl.swift
//  secp256k1
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2018 pebble8888. All rights reserved.
//
/**********************************************************************
 * Copyright (c) 2013, 2014, 2015 Pieter Wuille, Gregory Maxwell      *
 * Distributed under the MIT software license, see the accompanying   *
 * file COPYING or http://www.opensource.org/licenses/mit-license.php.*
 **********************************************************************/

import Foundation

//#ifdef USE_ECMULT_STATIC_PRECOMPUTATION
//#include "ecmult_static_context.h"
//#endif

func secp256k1_ecmult_gen_context_init(_ ctx: inout secp256k1_ecmult_gen_context) {
    ctx.prec.removeAll()
}

func secp256k1_ecmult_gen_context_build(_ ctx: inout secp256k1_ecmult_gen_context, _ cb: secp256k1_callback?) {
    #if USE_ECMULT_STATIC_PRECOMPUTATION
    #else
        var prec: [secp256k1_ge] = [secp256k1_ge](repeating: secp256k1_ge(), count: 1024)
        var gj = secp256k1_gej()
        var nums_gej = secp256k1_gej()
    #endif

    if (ctx.prec.count > 0) {
        return;
    }
    #if USE_ECMULT_STATIC_PRECOMPUTATION
        ctx.prec = secp256k1_ecmult_static_context
    #else
        ctx.prec = [[secp256k1_ge_storage]](repeating: [secp256k1_ge_storage](repeating: secp256k1_ge_storage(), count: 16), count: 64)

        /* get the generator */
        secp256k1_gej_set_ge(&gj, secp256k1_ge_const_g);

        /* Construct a group element with no known corresponding scalar (nothing up my sleeve). */
        //static const unsigned char nums_b32[33] = "The scalar for this x is unknown";
        let nums_b32: [UInt8] = Array("The scalar for this x is unknown".utf8)
        var nums_x = secp256k1_fe()
        var nums_ge = secp256k1_ge()
        var r = secp256k1_fe_set_b32(&nums_x, nums_b32);
        VERIFY_CHECK(r);
        r = secp256k1_ge_set_xo_var(&nums_ge, nums_x, false);
        VERIFY_CHECK(r);
        secp256k1_gej_set_ge(&nums_gej, nums_ge);
        /* Add G to make the bits in x uniformly distributed. */
        var dummy = secp256k1_fe()
        secp256k1_gej_add_ge_var(&nums_gej, nums_gej, secp256k1_ge_const_g, &dummy);

        /* compute prec. */
        var precj = [secp256k1_gej](repeating: secp256k1_gej(), count:1024) /* Jacobian versions of prec. */
        var gbase: secp256k1_gej
        var numsbase: secp256k1_gej
        gbase = gj; /* 16^j * G */
        numsbase = nums_gej; /* 2^j * nums. */
        for j in 0..<64 {
            /* Set precj[j*16 .. j*16+15] to (numsbase, numsbase + gbase, ..., numsbase + 15*gbase). */
            precj[j*16] = numsbase;
            for i in 1..<16 {
                var dummy = secp256k1_fe()
                secp256k1_gej_add_var(&precj[j*16 + i], precj[j*16 + i - 1], gbase, &dummy);
            }
            /* Multiply gbase by 16. */
            for _ in 0..<4 {
                var dummy = secp256k1_fe()
                secp256k1_gej_double_var(&gbase, gbase, &dummy);
            }
            /* Multiply numbase by 2. */
            var dummy = secp256k1_fe()
            secp256k1_gej_double_var(&numsbase, numsbase, &dummy);
            if (j == 62) {
                /* In the last iteration, numsbase is (1 - 2^j) * nums instead. */
                secp256k1_gej_neg(&numsbase, numsbase);
                var dummy = secp256k1_fe()
                secp256k1_gej_add_var(&numsbase, numsbase, nums_gej, &dummy);
            }
        }
        secp256k1_ge_set_all_gej_var(&prec, precj, 1024, cb);
        
        for j in 0 ..< 64 {
            for i in 0 ..< 16 {
                secp256k1_ge_to_storage(&ctx.prec[j][i], prec[j*16 + i])
            }
        }
    #endif
    secp256k1_ecmult_gen_blind(&ctx, nil)
}

func secp256k1_ecmult_gen_context_is_built(_ ctx: secp256k1_ecmult_gen_context) -> Bool {
    //return ctx.prec != nil
    return ctx.prec.count > 0
}

func secp256k1_ecmult_gen_context_clone(_ dst: inout secp256k1_ecmult_gen_context,
                                        _ src: secp256k1_ecmult_gen_context,
                                        _ cb: secp256k1_callback)
{
    if src.prec.count == 0 {
        //dst.prec = nil
        dst.prec.removeAll()
    } else {
        #if USE_ECMULT_STATIC_PRECOMPUTATION
            //(void)cb;
            dst.prec = src.prec;
        #else
            //dst.prec = (secp256k1_ge_storage (*)[64][16])checked_malloc(cb, sizeof(*dst->prec));
            dst.prec = [[secp256k1_ge_storage]](repeating:[secp256k1_ge_storage](repeating: secp256k1_ge_storage(), count: 16), count: 64)
            //memcpy(dst->prec, src->prec, sizeof(*dst->prec));
            dst.prec = src.prec
        #endif
        dst.initial = src.initial;
        dst.blind = src.blind;
    }
}

func secp256k1_ecmult_gen_context_clear(_ ctx: inout secp256k1_ecmult_gen_context) {
    #if USE_ECMULT_STATIC_PRECOMPUTATION
    #else
        //free(ctx.prec);
    #endif
    secp256k1_scalar_clear(&ctx.blind)
    secp256k1_gej_clear(&ctx.initial)
    ctx.prec.removeAll()
}

/**
 @brief get point gn * G, G: base point
 @param r : gej
 @param gn : scalar
 */
func secp256k1_ecmult_gen(_ ctx: secp256k1_ecmult_gen_context,
                          _ r: inout secp256k1_gej,
                          _ gn: secp256k1_scalar) {
    var add = secp256k1_ge()
    var adds = secp256k1_ge_storage()
    var gnb = secp256k1_scalar()
    var bits: UInt
    adds.clear()
    r = ctx.initial;

    /* Blind scalar/point multiplication by computing (n-b)G + bG instead of nG. */
    let _ = secp256k1_scalar_add(&gnb, gn, ctx.blind)

    add.infinity = false
    for j in 0..<64 {
        bits = secp256k1_scalar_get_bits(gnb, UInt(j * 4), UInt(4));
        for i in 0..<16 {
            /** This uses a conditional move to avoid any secret data in array indexes.
             *   _Any_ use of secret indexes has been demonstrated to result in timing
             *   sidechannels, even when the cache-line access patterns are uniform.
             *  See also:
             *   "A word of warning", CHES 2013 Rump Session, by Daniel J. Bernstein and Peter Schwabe
             *    (https://cryptojedi.org/peter/data/chesrump-20130822.pdf) and
             *   "Cache Attacks and Countermeasures: the Case of AES", RSA 2006,
             *    by Dag Arne Osvik, Adi Shamir, and Eran Tromer
             *    (http://www.tau.ac.il/~tromer/papers/cache.pdf)
             */
            secp256k1_ge_storage_cmov(&adds, ctx.prec[j][i], i == bits);
        }
        secp256k1_ge_from_storage(&add, adds);
        secp256k1_gej_add_ge(&r, r, add);
    }
    bits = 0;
    secp256k1_ge_clear(&add);
    secp256k1_scalar_clear(&gnb);
}

/* Setup blinding values for secp256k1_ecmult_gen. */
func secp256k1_ecmult_gen_blind(_ ctx: inout secp256k1_ecmult_gen_context, _ seed32:[UInt8]?)
{
    var b = secp256k1_scalar()
    var gb = secp256k1_gej()
    var s = secp256k1_fe()
    var nonce32 = [UInt8](repeating: 0, count: 32)
    var rng = secp256k1_rfc6979_hmac_sha256_t()
    var retry: Bool
    var keydata = [UInt8](repeating: 0, count: 64)
    if (seed32 == nil) {
        /* When seed is NULL, reset the initial point and blinding value. */
        secp256k1_gej_set_ge(&ctx.initial, secp256k1_ge_const_g);
        secp256k1_gej_neg(&ctx.initial, ctx.initial);
        secp256k1_scalar_set_int(&ctx.blind, 1);
    }
    /* The prior blinding value (if not reset) is chained forward by including it in the hash. */
    secp256k1_scalar_get_b32(&nonce32, ctx.blind);
    /** Using a CSPRNG allows a failure free interface, avoids needing large amounts of random data,
     *   and guards against weak or adversarial seeds.  This is a simpler and safer interface than
     *   asking the caller for blinding values directly and expecting them to retry on failure.
     */
    for i in 0..<32 {
        keydata[i] = nonce32[i]
    }
    if let seed32 = seed32 {
        for i in 0..<32 {
            keydata[32+i] = seed32[i]
        }
    }
    
    secp256k1_rfc6979_hmac_sha256_initialize(&rng, keydata, seed32 != nil ? 64 : 32);

    //memset(keydata, 0, sizeof(keydata));
    for i in 0 ..< keydata.count {
        keydata[i] = 0
    }
    /* Retry for out of range results to achieve uniformity. */
    repeat {
        secp256k1_rfc6979_hmac_sha256_generate(&rng, &nonce32, outlen: 32);
        retry = !secp256k1_fe_set_b32(&s, nonce32);
        retry =  retry || secp256k1_fe_is_zero(s);
    } while (retry); /* This branch true is cryptographically unreachable. Requires sha256_hmac output > Fp. */
    /* Randomize the projection to defend against multiplier sidechannels. */
    secp256k1_gej_rescale(&ctx.initial, s);
    secp256k1_fe_clear(&s);
    repeat {
        secp256k1_rfc6979_hmac_sha256_generate(&rng, &nonce32, outlen: 32);
        secp256k1_scalar_set_b32(&b, nonce32, &retry);
        /* A blinding value of 0 works, but would undermine the projection hardening. */
        retry = retry || secp256k1_scalar_is_zero(b);
    } while (retry); /* This branch true is cryptographically unreachable. Requires sha256_hmac output > order. */
    secp256k1_rfc6979_hmac_sha256_finalize(&rng);
    for i in 0..<32 {
        nonce32[i] = 0
    }
    
    secp256k1_ecmult_gen(ctx, &gb, b);
    secp256k1_scalar_negate(&b, b);
    ctx.blind = b;
    ctx.initial = gb;
    secp256k1_scalar_clear(&b);
    secp256k1_gej_clear(&gb);
}
