//
//  hash_impl.swift
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

func Ch(_ x: UInt32, _ y: UInt32, _ z: UInt32) -> UInt32 { return ((z) ^ ((x) & ((y) ^ (z)))) }
func Maj(_ x: UInt32, _ y: UInt32, _ z: UInt32) -> UInt32 { return  (((x) & (y)) | ((z) & ((x) | (y)))) }
func Sigma0(_ x: UInt32) -> UInt32 {
    let a = ((x) >> 2 | (x) << 30)
    let b = ((x) >> 13 | (x) << 19)
    let c = ((x) >> 22 | (x) << 10)
    return a ^ b ^ c
}
func Sigma1(_ x: UInt32) -> UInt32 {
    let a = ((x) >> 6 | (x) << 26)
    let b = ((x) >> 11 | (x) << 21)
    let c = ((x) >> 25 | (x) << 7)
    return a ^ b ^ c

}
func sigma0(_ x: UInt32) -> UInt32 {
    let a = ((x) >> 7 | (x) << 25)
    let b = ((x) >> 18 | (x) << 14)
    let c = ((x) >> 3)
    return a ^ b ^ c
}
func sigma1(_ x: UInt32) -> UInt32 {
    let a = ((x) >> 17 | (x) << 15)
    let b = ((x) >> 19 | (x) << 13)
    let c = ((x) >> 10)
    return a ^ b ^ c
}

func Round(_ a: UInt32,
           _ b: UInt32,
           _ c: UInt32,
           _ d: inout UInt32,
           _ e: UInt32,
           _ f: UInt32,
           _ g: UInt32,
           _ h: inout UInt32,
           _ k: UInt32,
           _ w: UInt32)
{
    repeat {
        let t1: UInt32 = h &+ Sigma1(e) &+ Ch(e, f, g) &+ k &+ w
        let t2: UInt32 = Sigma0(a) &+ Maj(a, b, c)
        d = d &+ t1
        h = t1 &+ t2
    } while false
}

func BE32(_ p: UInt32) -> UInt32 {
    let a = ((p) & 0xff) << 24
    let b = ((p) & 0xff00) << 8
    let c = ((p) & 0xff0000) >> 8
    let d = ((p) & 0xff000000) >> 24
    return a | b | c | d

}

func secp256k1_sha256_initialize(_ hash: inout secp256k1_sha256_t) {
    hash.s[0] = 0x6a09e667;
    hash.s[1] = 0xbb67ae85;
    hash.s[2] = 0x3c6ef372;
    hash.s[3] = 0xa54ff53a;
    hash.s[4] = 0x510e527f;
    hash.s[5] = 0x9b05688c;
    hash.s[6] = 0x1f83d9ab;
    hash.s[7] = 0x5be0cd19;
    hash.bytes = 0;
}

/** Perform one SHA-256 transformation, processing 16 big endian 32-bit words. */
func secp256k1_sha256_transform(_ s: inout [UInt32], _ chunk: [UInt32]) {
    assert(s.count == 8)
    assert(chunk.count == 16)
    var a = s[0]
    var b = s[1]
    var c = s[2]
    var d = s[3]
    var e = s[4]
    var f = s[5]
    var g = s[6]
    var h = s[7]
    var w0: UInt32
    var w1: UInt32
    var w2: UInt32
    var w3: UInt32
    var w4: UInt32
    var w5: UInt32
    var w6: UInt32
    var w7: UInt32
    var w8: UInt32
    var w9: UInt32
    var w10: UInt32
    var w11: UInt32
    var w12: UInt32
    var w13: UInt32
    var w14: UInt32
    var w15: UInt32
    
    w0 = BE32(chunk[0]);   Round(a, b, c, &d, e, f, g, &h, 0x428a2f98, w0)
    w1 = BE32(chunk[1]);   Round(h, a, b, &c, d, e, f, &g, 0x71374491, w1)
    w2 = BE32(chunk[2]);   Round(g, h, a, &b, c, d, e, &f, 0xb5c0fbcf, w2)
    w3 = BE32(chunk[3]);   Round(f, g, h, &a, b, c, d, &e, 0xe9b5dba5, w3)
    w4 = BE32(chunk[4]);   Round(e, f, g, &h, a, b, c, &d, 0x3956c25b, w4)
    w5 = BE32(chunk[5]);   Round(d, e, f, &g, h, a, b, &c, 0x59f111f1, w5)
    w6 = BE32(chunk[6]);   Round(c, d, e, &f, g, h, a, &b, 0x923f82a4, w6)
    w7 = BE32(chunk[7]);   Round(b, c, d, &e, f, g, h, &a, 0xab1c5ed5, w7)
    w8 = BE32(chunk[8]);   Round(a, b, c, &d, e, f, g, &h, 0xd807aa98, w8)
    w9 = BE32(chunk[9]);   Round(h, a, b, &c, d, e, f, &g, 0x12835b01, w9)
    w10 = BE32(chunk[10]); Round(g, h, a, &b, c, d, e, &f, 0x243185be, w10)
    w11 = BE32(chunk[11]); Round(f, g, h, &a, b, c, d, &e, 0x550c7dc3, w11)
    w12 = BE32(chunk[12]); Round(e, f, g, &h, a, b, c, &d, 0x72be5d74, w12)
    w13 = BE32(chunk[13]); Round(d, e, f, &g, h, a, b, &c, 0x80deb1fe, w13)
    w14 = BE32(chunk[14]); Round(c, d, e, &f, g, h, a, &b, 0x9bdc06a7, w14)
    w15 = BE32(chunk[15]); Round(b, c, d, &e, f, g, h, &a, 0xc19bf174, w15)
    
    w0 = w0 &+ sigma1(w14) &+ w9 &+ sigma0(w1);  Round(a, b, c, &d, e, f, g, &h, 0xe49b69c1, w0)
    w1 = w1 &+ sigma1(w15) &+ w10 &+ sigma0(w2);    Round(h, a, b, &c, d, e, f, &g, 0xefbe4786, w1)
    w2 = w2 &+ sigma1(w0) &+ w11 &+ sigma0(w3);     Round(g, h, a, &b, c, d, e, &f, 0x0fc19dc6, w2)
    w3 = w3 &+ sigma1(w1) &+ w12 &+ sigma0(w4);     Round(f, g, h, &a, b, c, d, &e, 0x240ca1cc, w3)
    w4 = w4 &+ sigma1(w2) &+ w13 &+ sigma0(w5);     Round(e, f, g, &h, a, b, c, &d, 0x2de92c6f, w4)
    w5 = w5 &+ sigma1(w3) &+ w14 &+ sigma0(w6);     Round(d, e, f, &g, h, a, b, &c, 0x4a7484aa, w5)
    w6 = w6 &+ sigma1(w4) &+ w15 &+ sigma0(w7);     Round(c, d, e, &f, g, h, a, &b, 0x5cb0a9dc, w6)
    w7 = w7 &+ sigma1(w5) &+ w0 &+ sigma0(w8);      Round(b, c, d, &e, f, g, h, &a, 0x76f988da, w7)
    w8 = w8 &+ sigma1(w6) &+ w1 &+ sigma0(w9);      Round(a, b, c, &d, e, f, g, &h, 0x983e5152, w8)
    w9 = w9 &+ sigma1(w7) &+ w2 &+ sigma0(w10);     Round(h, a, b, &c, d, e, f, &g, 0xa831c66d, w9)
    w10 = w10 &+ sigma1(w8) &+ w3 &+ sigma0(w11);   Round(g, h, a, &b, c, d, e, &f, 0xb00327c8, w10)
    w11 = w11 &+ sigma1(w9) &+ w4 &+ sigma0(w12);   Round(f, g, h, &a, b, c, d, &e, 0xbf597fc7, w11)
    w12 = w12 &+ sigma1(w10) &+ w5 &+ sigma0(w13);  Round(e, f, g, &h, a, b, c, &d, 0xc6e00bf3, w12)
    w13 = w13 &+ sigma1(w11) &+ w6 &+ sigma0(w14);  Round(d, e, f, &g, h, a, b, &c, 0xd5a79147, w13)
    w14 = w14 &+ sigma1(w12) &+ w7 &+ sigma0(w15);  Round(c, d, e, &f, g, h, a, &b, 0x06ca6351, w14)
    w15 = w15 &+ sigma1(w13) &+ w8 &+ sigma0(w0);   Round(b, c, d, &e, f, g, h, &a, 0x14292967, w15)
    
    w0 = w0 &+ sigma1(w14) &+ w9 &+ sigma0(w1);     Round(a, b, c, &d, e, f, g, &h, 0x27b70a85, w0)
    w1 = w1 &+ sigma1(w15) &+ w10 &+ sigma0(w2);    Round(h, a, b, &c, d, e, f, &g, 0x2e1b2138, w1)
    w2 = w2 &+ sigma1(w0) &+ w11 &+ sigma0(w3);     Round(g, h, a, &b, c, d, e, &f, 0x4d2c6dfc, w2)
    w3 = w3 &+ sigma1(w1) &+ w12 &+ sigma0(w4);     Round(f, g, h, &a, b, c, d, &e, 0x53380d13, w3)
    w4 = w4 &+ sigma1(w2) &+ w13 &+ sigma0(w5);     Round(e, f, g, &h, a, b, c, &d, 0x650a7354, w4)
    w5 = w5 &+ sigma1(w3) &+ w14 &+ sigma0(w6);     Round(d, e, f, &g, h, a, b, &c, 0x766a0abb, w5)
    w6 = w6 &+ sigma1(w4) &+ w15 &+ sigma0(w7);     Round(c, d, e, &f, g, h, a, &b, 0x81c2c92e, w6)
    w7 = w7 &+ sigma1(w5) &+ w0 &+ sigma0(w8);      Round(b, c, d, &e, f, g, h, &a, 0x92722c85, w7)
    w8 = w8 &+ sigma1(w6) &+ w1 &+ sigma0(w9);      Round(a, b, c, &d, e, f, g, &h, 0xa2bfe8a1, w8)
    w9 = w9 &+ sigma1(w7) &+ w2 &+ sigma0(w10);     Round(h, a, b, &c, d, e, f, &g, 0xa81a664b, w9)
    w10 = w10 &+ sigma1(w8) &+ w3 &+ sigma0(w11);   Round(g, h, a, &b, c, d, e, &f, 0xc24b8b70, w10)
    w11 = w11 &+ sigma1(w9) &+ w4 &+ sigma0(w12);   Round(f, g, h, &a, b, c, d, &e, 0xc76c51a3, w11)
    w12 = w12 &+ sigma1(w10) &+ w5 &+ sigma0(w13);  Round(e, f, g, &h, a, b, c, &d, 0xd192e819, w12)
    w13 = w13 &+ sigma1(w11) &+ w6 &+ sigma0(w14);  Round(d, e, f, &g, h, a, b, &c, 0xd6990624, w13)
    w14 = w14 &+ sigma1(w12) &+ w7 &+ sigma0(w15);  Round(c, d, e, &f, g, h, a, &b, 0xf40e3585, w14)
    w15 = w15 &+ sigma1(w13) &+ w8 &+ sigma0(w0);   Round(b, c, d, &e, f, g, h, &a, 0x106aa070, w15)
    
    w0 = w0 &+ sigma1(w14) &+ w9 &+ sigma0(w1);     Round(a, b, c, &d, e, f, g, &h, 0x19a4c116, w0)
    w1 = w1 &+ sigma1(w15) &+ w10 &+ sigma0(w2);    Round(h, a, b, &c, d, e, f, &g, 0x1e376c08, w1)
    w2 = w2 &+ sigma1(w0) &+ w11 &+ sigma0(w3);     Round(g, h, a, &b, c, d, e, &f, 0x2748774c, w2)
    w3 = w3 &+ sigma1(w1) &+ w12 &+ sigma0(w4);     Round(f, g, h, &a, b, c, d, &e, 0x34b0bcb5, w3)
    w4 = w4 &+ sigma1(w2) &+ w13 &+ sigma0(w5);     Round(e, f, g, &h, a, b, c, &d, 0x391c0cb3, w4)
    w5 = w5 &+ sigma1(w3) &+ w14 &+ sigma0(w6);     Round(d, e, f, &g, h, a, b, &c, 0x4ed8aa4a, w5)
    w6 = w6 &+ sigma1(w4) &+ w15 &+ sigma0(w7);     Round(c, d, e, &f, g, h, a, &b, 0x5b9cca4f, w6)
    w7 = w7 &+ sigma1(w5) &+ w0 &+ sigma0(w8);      Round(b, c, d, &e, f, g, h, &a, 0x682e6ff3, w7)
    w8 = w8 &+ sigma1(w6) &+ w1 &+ sigma0(w9);      Round(a, b, c, &d, e, f, g, &h, 0x748f82ee, w8)
    w9 = w9 &+ sigma1(w7) &+ w2 &+ sigma0(w10);     Round(h, a, b, &c, d, e, f, &g, 0x78a5636f, w9)
    w10 = w10 &+ sigma1(w8) &+ w3 &+ sigma0(w11);   Round(g, h, a, &b, c, d, e, &f, 0x84c87814, w10)
    w11 = w11 &+ sigma1(w9) &+ w4 &+ sigma0(w12);   Round(f, g, h, &a, b, c, d, &e, 0x8cc70208, w11)
    w12 = w12 &+ sigma1(w10) &+ w5 &+ sigma0(w13);  Round(e, f, g, &h, a, b, c, &d, 0x90befffa, w12)
    w13 = w13 &+ sigma1(w11) &+ w6 &+ sigma0(w14);  Round(d, e, f, &g, h, a, b, &c, 0xa4506ceb, w13)
    w14 = w14 &+ sigma1(w12) &+ w7 &+ sigma0(w15);  Round(c, d, e, &f, g, h, a, &b, 0xbef9a3f7, w14)
    w15 = w15 &+ sigma1(w13) &+ w8 &+ sigma0(w0);   Round(b, c, d, &e, f, g, h, &a, 0xc67178f2, w15)
    
    s[0] = s[0] &+ a
    s[1] = s[1] &+ b
    s[2] = s[2] &+ c
    s[3] = s[3] &+ d
    s[4] = s[4] &+ e
    s[5] = s[5] &+ f
    s[6] = s[6] &+ g
    s[7] = s[7] &+ h
}

func secp256k1_sha256_write(_ hash: inout secp256k1_sha256_t, _ data: [UInt8], _ len: UInt) {
    var bufsize: UInt = hash.bytes & 0x3F
    hash.bytes += len
    var l_len = len
    var data_pos: UInt = 0
    while l_len >= 64 - bufsize {
        /* Fill the buffer, and process it. */
        //memcpy(((unsigned char*)hash.buf) + bufsize, data, 64 - bufsize);
        UInt8ToUInt32LE(&hash.buf, bufsize, data, Int(data_pos), 64 - bufsize)
        
        data_pos += (64 - bufsize)
        l_len -= (64 - bufsize)
        secp256k1_sha256_transform(&hash.s, hash.buf);
        
        bufsize = 0
    }
    if l_len > 0 {
        /* Fill the buffer with what remains. */
        //memcpy(((unsigned char*)hash.buf) + bufsize, data, len);
        UInt8ToUInt32LE(&hash.buf, bufsize, data, Int(data_pos), l_len)
    }
}

func secp256k1_sha256_finalize(_ hash: inout secp256k1_sha256_t, _ out32: inout [UInt8]) {
    // size: 64
    let pad: [UInt8] = [0x80, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
    var sizedesc = [UInt32](repeating: 0, count: 2)
    var out = [UInt32](repeating: 0, count: 8)
    sizedesc[0] = BE32(UInt32(hash.bytes >> 29))
    sizedesc[1] = BE32(UInt32(hash.bytes << 3))
    
    let sz = 1 + ((119 - (hash.bytes % 64)) % 64);
    secp256k1_sha256_write(&hash, pad, sz)
    var v = [UInt8](repeating: 0, count: 8)
    UInt32LEToUInt8(&v, 0, sizedesc[0])
    UInt32LEToUInt8(&v, 4, sizedesc[1])
    secp256k1_sha256_write(&hash, v, 8)
    for i in 0..<8 {
        out[i] = BE32(hash.s[i]);
        hash.s[i] = 0;
    }
    //memcpy(out32, (const unsigned char*)out, 32);
    for i in 0..<8 {
        UInt32LEToUInt8(&out32, i*4, out[i])
    }
}

func secp256k1_hmac_sha256_initialize(_ hash: inout secp256k1_hmac_sha256_t, _ key: [UInt8], _ keylen: UInt) {
    var rkey = [UInt8](repeating: 0, count: 64)
    if (keylen <= 64) {
        for i in 0 ..< Int(keylen) {
            rkey[i] = key[i]
        }
        for i in 0 ..< 64 - Int(keylen) {
            rkey[Int(keylen)+i] = 0
        }
    } else {
        var sha256 = secp256k1_sha256_t()
        secp256k1_sha256_initialize(&sha256);
        secp256k1_sha256_write(&sha256, key, keylen);
        secp256k1_sha256_finalize(&sha256, &rkey);
        for i in 0 ..< 32 {
            rkey[32+i] = 0
        }
    }
    
    secp256k1_sha256_initialize(&hash.outer);
    for n in 0 ..< 64 {
        rkey[n] ^= 0x5c;
    }
    secp256k1_sha256_write(&hash.outer, rkey, 64);
    
    secp256k1_sha256_initialize(&hash.inner);
    for n in 0 ..< 64 {
        rkey[n] ^= 0x5c ^ 0x36;
    }
    secp256k1_sha256_write(&hash.inner, rkey, 64);
    for i in 0 ..< 64 {
        rkey[i] = 0
    }
}

func secp256k1_hmac_sha256_write(_ hash: inout secp256k1_hmac_sha256_t, _ data: [UInt8], _ size: UInt) {
    secp256k1_sha256_write(&hash.inner, data, size);
}

func secp256k1_hmac_sha256_finalize(_ hash: inout secp256k1_hmac_sha256_t, _ out32: inout [UInt8]) {
    var temp = [UInt8](repeating: 0, count: 32)
    secp256k1_sha256_finalize(&hash.inner, &temp);
    secp256k1_sha256_write(&hash.outer, temp, 32);
    for i in 0 ..< 32 {
        temp[i] = 0
    }
    secp256k1_sha256_finalize(&hash.outer, &out32);
}

func secp256k1_rfc6979_hmac_sha256_initialize(_ rng: inout secp256k1_rfc6979_hmac_sha256_t, _ key: [UInt8], _ keylen: UInt) {
    var hmac = secp256k1_hmac_sha256_t()
    let zero: [UInt8] = [0x00]
    let one: [UInt8] = [0x01]
    
    for i in 0 ..< 32 { rng.v[i] = 0x01 } /* RFC6979 3.2.b. */
    for i in 0 ..< 32 { rng.k[i] = 0x00 } /* RFC6979 3.2.c. */
    
    /* RFC6979 3.2.d. */
    secp256k1_hmac_sha256_initialize(&hmac, rng.k, 32);
    secp256k1_hmac_sha256_write(&hmac, rng.v, 32);
    secp256k1_hmac_sha256_write(&hmac, zero, 1);
    secp256k1_hmac_sha256_write(&hmac, key, keylen);
    secp256k1_hmac_sha256_finalize(&hmac, &rng.k);
    secp256k1_hmac_sha256_initialize(&hmac, rng.k, 32);
    secp256k1_hmac_sha256_write(&hmac, rng.v, 32);
    secp256k1_hmac_sha256_finalize(&hmac, &rng.v);

    /* RFC6979 3.2.f. */
    secp256k1_hmac_sha256_initialize(&hmac, rng.k, 32);
    secp256k1_hmac_sha256_write(&hmac, rng.v, 32);
    secp256k1_hmac_sha256_write(&hmac, one, 1);
    secp256k1_hmac_sha256_write(&hmac, key, keylen);
    secp256k1_hmac_sha256_finalize(&hmac, &rng.k);
    secp256k1_hmac_sha256_initialize(&hmac, rng.k, 32);
    secp256k1_hmac_sha256_write(&hmac, rng.v, 32);
    secp256k1_hmac_sha256_finalize(&hmac, &rng.v);

    rng.retry = false
}

func secp256k1_rfc6979_hmac_sha256_generate(_ rng: inout secp256k1_rfc6979_hmac_sha256_t, _ out: inout [UInt8], from: Int = 0, outlen: UInt) {
    /* RFC6979 3.2.h. */
    let zero: [UInt8] = [0x00]
    if (rng.retry) {
        var hmac = secp256k1_hmac_sha256_t()
        secp256k1_hmac_sha256_initialize(&hmac, rng.k, 32);
        secp256k1_hmac_sha256_write(&hmac, rng.v, 32);
        secp256k1_hmac_sha256_write(&hmac, zero, 1);
        secp256k1_hmac_sha256_finalize(&hmac, &rng.k);
        secp256k1_hmac_sha256_initialize(&hmac, rng.k, 32);
        secp256k1_hmac_sha256_write(&hmac, rng.v, 32);
        secp256k1_hmac_sha256_finalize(&hmac, &rng.v);
    }
    
    var outlen = outlen
    var outidx: Int = from
    while outlen > 0 {
        var hmac = secp256k1_hmac_sha256_t()
        var now: Int = Int(outlen)
        secp256k1_hmac_sha256_initialize(&hmac, rng.k, 32);
        secp256k1_hmac_sha256_write(&hmac, rng.v, 32);
        secp256k1_hmac_sha256_finalize(&hmac, &rng.v);
        if (now > 32) {
            now = 32;
        }
        for i in 0..<now {
            out[i+outidx] = rng.v[i]
        }
        outidx += now
        outlen = outlen - UInt(now)
    }
    
    rng.retry = true
}

func secp256k1_rfc6979_hmac_sha256_finalize(_ rng: inout secp256k1_rfc6979_hmac_sha256_t) {
    for i in 0 ..< 32 { rng.k[i] = 0 }
    for i in 0 ..< 32 { rng.v[i] = 0 }
    rng.retry = false
}
