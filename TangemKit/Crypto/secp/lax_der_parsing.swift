//
//  lax_der_parsing.swift
//  secp256k1
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2018年 pebble8888. All rights reserved.
//
/**********************************************************************
 * Copyright (c) 2015 Pieter Wuille                                   *
 * Distributed under the MIT software license, see the accompanying   *
 * file COPYING or http://www.opensource.org/licenses/mit-license.php.*
 **********************************************************************/

import Foundation

func ecdsa_signature_parse_der_lax(_ ctx: inout secp256k1_context, _ sig: inout secp256k1_ecdsa_signature, _ input:[UInt8], _ inputlen: Int) -> Bool {
    var rpos, rlen, spos, slen:Int
    var pos: Int = 0
    var lenbyte: Int
    var tmpsig = [UInt8](repeating: 0, count: 64)
    var overflow: Bool = false
    
    /* Hack to initialize sig with a correctly-parsed but invalid signature. */
    let _ = secp256k1_ecdsa_signature_parse_compact(ctx, &sig, tmpsig);
    
    /* Sequence tag byte */
    if (pos == inputlen || input[pos] != 0x30) {
        return false
    }
    pos += 1
    
    /* Sequence length bytes */
    if (pos == inputlen) {
        return false
    }
    lenbyte = Int(input[pos]);
    pos += 1
    if (lenbyte & 0x80) != 0 {
        lenbyte -= 0x80;
        if (pos + lenbyte > inputlen) {
            return false
        }
        pos += lenbyte;
    }
    
    /* Integer tag byte for R */
    if (pos == inputlen || input[pos] != 0x02) {
        return false
    }
    pos += 1
    
    /* Integer length for R */
    if (pos == inputlen) {
        return false
    }
    lenbyte = Int(input[pos]);
    pos += 1
    if (lenbyte & 0x80) != 0 {
        lenbyte -= 0x80;
        if (pos + lenbyte > inputlen) {
            return false
        }
        while (lenbyte > 0 && input[pos] == 0) {
            pos += 1
            lenbyte -= 1
        }
        if lenbyte >= MemoryLayout<Int>.size {
            return false
        }
        rlen = 0;
        while (lenbyte > 0) {
            rlen = (rlen << 8) + Int(input[pos]);
            pos += 1
            lenbyte -= 1
        }
    } else {
        rlen = lenbyte;
    }
    if (rlen > inputlen - pos) {
        return false
    }
    rpos = pos;
    pos += rlen;
    
    /* Integer tag byte for S */
    if (pos == inputlen || input[pos] != 0x02) {
        return false
    }
    pos += 1
    
    /* Integer length for S */
    if (pos == inputlen) {
        return false
    }
    lenbyte = Int(input[pos]);
    pos += 1
    if (lenbyte & 0x80) != 0 {
        lenbyte -= 0x80;
        if (pos + lenbyte > inputlen) {
            return false
        }
        while (lenbyte > 0 && input[pos] == 0) {
            pos += 1
            lenbyte -= 1
        }
        if lenbyte >= MemoryLayout<Int>.size {
            return false
        }
        slen = 0;
        while (lenbyte > 0) {
            slen = (slen << 8) + Int(input[pos]);
            pos += 1
            lenbyte -= 1
        }
    } else {
        slen = lenbyte;
    }
    if (slen > inputlen - pos) {
        return false
    }
    spos = pos;
    pos += slen;
    
    /* Ignore leading zeroes in R */
    while (rlen > 0 && input[rpos] == 0) {
        rlen -= 1
        rpos += 1
    }
    /* Copy R value */
    if (rlen > 32) {
        overflow = true
    } else {
        //memcpy(tmpsig + 32 - rlen, input + rpos, rlen);
        for i in 0 ..< rlen {
            tmpsig[32 - rlen + i] = input[rpos + i]
        }
    }
    
    /* Ignore leading zeroes in S */
    while (slen > 0 && input[spos] == 0) {
        slen -= 1
        spos += 1
    }
    /* Copy S value */
    if (slen > 32) {
        overflow = true
    } else {
        //memcpy(tmpsig + 64 - slen, input + spos, slen);
        for i in 0 ..< slen {
            tmpsig[64 - slen + i] = input[spos + i]
        }
    }
    
    if (!overflow) {
        overflow = !secp256k1_ecdsa_signature_parse_compact(ctx, &sig, tmpsig);
    }
    if (overflow) {
        //memset(tmpsig, 0, 64);
        for i in 0..<64 {
            tmpsig[i] = 0
        }
        let _ = secp256k1_ecdsa_signature_parse_compact(ctx, &sig, tmpsig);
    }
    return true
}
