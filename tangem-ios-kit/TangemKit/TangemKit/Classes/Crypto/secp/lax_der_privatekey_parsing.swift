//
//  lax_der_privatekey_parsing.swift
//  secp256k1
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2018年 pebble8888. All rights reserved.
//
/**********************************************************************
 * Copyright (c) 2014, 2015 Pieter Wuille                             *
 * Distributed under the MIT software license, see the accompanying   *
 * file COPYING or http://www.opensource.org/licenses/mit-license.php.*
 **********************************************************************/

import Foundation

func ec_privkey_import_der(_ ctx: secp256k1_context, _ out32: inout [UInt8], _ privkey: [UInt8], _ privkeylen: Int) -> Bool
{
    var privkey_idx: Int = 0
    let end: Int = privkeylen
    var lenb: Int = 0
    var len: Int = 0
    //memset(out32, 0, 32);
    for i in 0 ..< 32 {
        out32[i] = 0
    }
    /* sequence header */
    if (end < privkey_idx+1 || privkey[privkey_idx] != 0x30) {
        return false
    }
    privkey_idx += 1
    /* sequence length constructor */
    if (end < privkey_idx+1 || !((privkey[privkey_idx] & 0x80) != 0)) {
        return false
    }
    lenb = Int(privkey[privkey_idx] & ~UInt8(0x80));
    privkey_idx += 1
    if (lenb < 1 || lenb > 2) {
        return false
    }
    if (end < privkey_idx+lenb) {
        return false
    }
    
    /* sequence length */
    len = Int(privkey[privkey_idx+lenb-1] | UInt8(lenb > 1 ? privkey[privkey_idx+lenb-2] << 8 : 0))
    privkey_idx += lenb;
    if (end < privkey_idx+len) {
        return false
    }
    /* sequence element 0: version number (=1) */
    if (end < privkey_idx+3 || privkey[privkey_idx+0] != 0x02 || privkey[privkey_idx+1] != 0x01 || privkey[privkey_idx+2] != 0x01) {
        return false
    }
    privkey_idx += 3
    /* sequence element 1: octet string, up to 32 bytes */
    if end < privkey_idx+2 || privkey[privkey_idx+0] != 0x04 || privkey[privkey_idx+1] > 0x20 || end < privkey_idx+2+Int(privkey[privkey_idx+1]) {
        return false
    }
    //memcpy(out32 + 32 - privkey[1], privkey + 2, privkey[1]);
    for i in 0 ..< privkey[privkey_idx+1] {
        out32[Int(i)+32-Int(privkey[privkey_idx+1])] = privkey[Int(privkey_idx)+2+Int(i)]
    }
    
    if (!secp256k1_ec_seckey_verify(ctx, out32)) {
        //memset(out32, 0, 32);
        for i in 0 ..< 32 {
            out32[i] = 0
        }
        return false
    }
    return true
}

func ec_privkey_export_der(_ ctx: secp256k1_context,
                           _ privkey: inout [UInt8],
                           _ privkeylen: inout UInt,
                           _ key32: [UInt8],
                           _ compressed: Bool) -> Bool
{
    var pubkey = secp256k1_pubkey()
    var pubkeylen: UInt = 0;
    if (!secp256k1_ec_pubkey_create(ctx, &pubkey, key32)) {
        privkeylen = 0;
        return false
    }
    if (compressed) {
        let begin: [UInt8] = [
            0x30,0x81,0xD3,0x02,0x01,0x01,0x04,0x20
        ]
        let middle: [UInt8] = [
            0xA0,0x81,0x85,0x30,0x81,0x82,0x02,0x01,0x01,0x30,0x2C,0x06,0x07,0x2A,0x86,0x48,
            0xCE,0x3D,0x01,0x01,0x02,0x21,0x00,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,
            0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,
            0xFF,0xFF,0xFE,0xFF,0xFF,0xFC,0x2F,0x30,0x06,0x04,0x01,0x00,0x04,0x01,0x07,0x04,
            0x21,0x02,0x79,0xBE,0x66,0x7E,0xF9,0xDC,0xBB,0xAC,0x55,0xA0,0x62,0x95,0xCE,0x87,
            0x0B,0x07,0x02,0x9B,0xFC,0xDB,0x2D,0xCE,0x28,0xD9,0x59,0xF2,0x81,0x5B,0x16,0xF8,
            0x17,0x98,0x02,0x21,0x00,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,
            0xFF,0xFF,0xFF,0xFF,0xFE,0xBA,0xAE,0xDC,0xE6,0xAF,0x48,0xA0,0x3B,0xBF,0xD2,0x5E,
            0x8C,0xD0,0x36,0x41,0x41,0x02,0x01,0x01,0xA1,0x24,0x03,0x22,0x00
        ]
        //unsigned char *ptr = privkey;
        var ptr: Int = 0
        //memcpy(ptr, begin, sizeof(begin));
        for i in 0 ..< begin.count {
            privkey[ptr+i] = begin[i]
        }
        //ptr += sizeof(begin);
        ptr += begin.count
        //memcpy(ptr, key32, 32);
        for i in 0 ..< 32 {
            privkey[ptr+i] = key32[i]
        }
        //ptr += 32;
        ptr += 32
        //memcpy(ptr, middle, sizeof(middle));
        for i in 0 ..< middle.count {
            privkey[ptr+i] = middle[i]
        }
        //ptr += sizeof(middle);
        ptr += middle.count
        pubkeylen = 33;
        
        var q = [UInt8](repeating: 0, count: 33)
        let _ = secp256k1_ec_pubkey_serialize(ctx, &q, &pubkeylen, pubkey, .SECP256K1_EC_COMPRESSED);
        for i in 0 ..< 33 {
            privkey[ptr+i] = q[i]
        }
        ptr += Int(pubkeylen)
        privkeylen = UInt(ptr) //ptr - privkey;
    } else {
        let begin: [UInt8] = [
            0x30,0x82,0x01,0x13,0x02,0x01,0x01,0x04,0x20
        ]
        let middle: [UInt8] = [
            0xA0,0x81,0xA5,0x30,0x81,0xA2,0x02,0x01,0x01,0x30,0x2C,0x06,0x07,0x2A,0x86,0x48,
            0xCE,0x3D,0x01,0x01,0x02,0x21,0x00,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,
            0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,
            0xFF,0xFF,0xFE,0xFF,0xFF,0xFC,0x2F,0x30,0x06,0x04,0x01,0x00,0x04,0x01,0x07,0x04,
            0x41,0x04,0x79,0xBE,0x66,0x7E,0xF9,0xDC,0xBB,0xAC,0x55,0xA0,0x62,0x95,0xCE,0x87,
            0x0B,0x07,0x02,0x9B,0xFC,0xDB,0x2D,0xCE,0x28,0xD9,0x59,0xF2,0x81,0x5B,0x16,0xF8,
            0x17,0x98,0x48,0x3A,0xDA,0x77,0x26,0xA3,0xC4,0x65,0x5D,0xA4,0xFB,0xFC,0x0E,0x11,
            0x08,0xA8,0xFD,0x17,0xB4,0x48,0xA6,0x85,0x54,0x19,0x9C,0x47,0xD0,0x8F,0xFB,0x10,
            0xD4,0xB8,0x02,0x21,0x00,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,
            0xFF,0xFF,0xFF,0xFF,0xFE,0xBA,0xAE,0xDC,0xE6,0xAF,0x48,0xA0,0x3B,0xBF,0xD2,0x5E,
            0x8C,0xD0,0x36,0x41,0x41,0x02,0x01,0x01,0xA1,0x44,0x03,0x42,0x00
        ]
        //unsigned char *ptr = privkey;
        var ptr: Int = 0
        //memcpy(ptr, begin, sizeof(begin));
        for i in 0 ..< begin.count {
            privkey[ptr+i] = begin[i]
        }
        //ptr += sizeof(begin);
        ptr += begin.count
        //memcpy(ptr, key32, 32);
        for i in 0 ..< 32 {
            privkey[ptr+i] = key32[i]
        }
        //ptr += 32;
        ptr += 32
        //memcpy(ptr, middle, sizeof(middle));
        for i in 0 ..< middle.count {
            privkey[ptr+i] = middle[i]
        }
        //ptr += sizeof(middle);
        ptr += middle.count
        pubkeylen = 65;
        var q = [UInt8](repeating: 0, count: 65)
        let _ = secp256k1_ec_pubkey_serialize(ctx, &q, &pubkeylen, pubkey, .SECP256K1_EC_UNCOMPRESSED);
        for i in 0 ..< 65 {
            privkey[ptr+i] = q[i]
        }
        ptr += Int(pubkeylen)
        privkeylen = UInt(ptr) // ptr - privkey;
    }
    return true
}

