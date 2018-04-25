//
//  eckey_impl.swift
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

func secp256k1_eckey_pubkey_parse(_ elem: inout secp256k1_ge, _ pub:[UInt8], _ size: UInt) -> Bool {
    guard size <= pub.count else {
        return false
    }
    if size == 33 && (pub[0] == SECP256K1_TAG_PUBKEY_EVEN || pub[0] == SECP256K1_TAG_PUBKEY_ODD) {
        var x = secp256k1_fe()
        return secp256k1_fe_set_b32(&x, Array(pub[1...])) &&
               secp256k1_ge_set_xo_var(&elem, x, pub[0] == SECP256K1_TAG_PUBKEY_ODD);
    } else if size == 65 && (pub[0] == 0x04 || pub[0] == 0x06 || pub[0] == 0x07) {
        var x = secp256k1_fe()
        var y = secp256k1_fe()
        if !secp256k1_fe_set_b32(&x, Array(pub[1..<33])) {
            return false
        }
        if !secp256k1_fe_set_b32(&y, Array(pub[33..<65])) {
            return false
        }
        secp256k1_ge_set_xy(&elem, x, y);
        if ((pub[0] == SECP256K1_TAG_PUBKEY_HYBRID_EVEN || pub[0] == SECP256K1_TAG_PUBKEY_HYBRID_ODD) &&
            secp256k1_fe_is_odd(y) != (pub[0] == SECP256K1_TAG_PUBKEY_HYBRID_ODD)) {
            return false
        }
        return secp256k1_ge_is_valid_var(elem);
    } else {
        return false
    }
}

func secp256k1_eckey_pubkey_serialize(_ elem: inout secp256k1_ge, _ pub: inout [UInt8], _ size: inout UInt, _ compressed: Bool) -> Bool {
    if (secp256k1_ge_is_infinity(elem)) {
        return false
    }
    secp256k1_fe_normalize_var(&elem.x);
    secp256k1_fe_normalize_var(&elem.y);
    var v = [UInt8](repeating: 0, count: 32)
    secp256k1_fe_get_b32(&v, elem.x)
    for i in 0..<32 {
        pub[1+i] = v[i]
    }
    if (compressed) {
        size = 33;
        pub[0] = secp256k1_fe_is_odd(elem.y) ? SECP256K1_TAG_PUBKEY_ODD : SECP256K1_TAG_PUBKEY_EVEN;
    } else {
        size = 65;
        pub[0] = SECP256K1_TAG_PUBKEY_UNCOMPRESSED;
        var w = [UInt8](repeating: 0, count: 32)
        secp256k1_fe_get_b32(&w, elem.y);
        for i in 0..<32 {
            pub[33+i] = w[i]
        }
    }
    return true
}

func secp256k1_eckey_privkey_tweak_add(_ key: inout secp256k1_scalar , _ tweak: secp256k1_scalar) -> Bool {
    let _ = secp256k1_scalar_add(&key, key, tweak);
    if (secp256k1_scalar_is_zero(key)) {
        return false
    }
    return true
}

func secp256k1_eckey_pubkey_tweak_add(_ ctx: secp256k1_ecmult_context, _ key: inout secp256k1_ge, _ tweak: secp256k1_scalar) -> Bool {
    var pt = secp256k1_gej()
    var one = secp256k1_scalar()
    secp256k1_gej_set_ge(&pt, key);
    secp256k1_scalar_set_int(&one, 1);
    secp256k1_ecmult(ctx, &pt, pt, one, tweak);
    
    if (secp256k1_gej_is_infinity(pt)) {
        return false
    }
    secp256k1_ge_set_gej(&key, &pt);
    return true
}

func secp256k1_eckey_privkey_tweak_mul(_ key: inout secp256k1_scalar, _ tweak: secp256k1_scalar) -> Bool {
    if (secp256k1_scalar_is_zero(tweak)) {
        return false
    }
    
    secp256k1_scalar_mul(&key, key, tweak);
    return true
}

func secp256k1_eckey_pubkey_tweak_mul(_ ctx: secp256k1_ecmult_context, _ key: inout secp256k1_ge, _ tweak: secp256k1_scalar) -> Bool {
    var zero = secp256k1_scalar()
    var pt = secp256k1_gej()
    if (secp256k1_scalar_is_zero(tweak)) {
        return false
    }
    
    secp256k1_scalar_set_int(&zero, 0);
    secp256k1_gej_set_ge(&pt, key);
    secp256k1_ecmult(ctx, &pt, pt, tweak, zero);
    secp256k1_ge_set_gej(&key, &pt);
    return true
}
