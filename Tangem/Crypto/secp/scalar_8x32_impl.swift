//
//  scalar_8x32_impl.swift
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

/* Limbs of the secp256k1 order. */
/* order of base point */
let SECP256K1_N_0: UInt32 = 0xD0364141
let SECP256K1_N_1: UInt32 = 0xBFD25E8C
let SECP256K1_N_2: UInt32 = 0xAF48A03B
let SECP256K1_N_3: UInt32 = 0xBAAEDCE6
let SECP256K1_N_4: UInt32 = 0xFFFFFFFE
let SECP256K1_N_5: UInt32 = 0xFFFFFFFF
let SECP256K1_N_6: UInt32 = 0xFFFFFFFF
let SECP256K1_N_7: UInt32 = 0xFFFFFFFF

/* Limbs of 2^256 minus the secp256k1 order. */
let SECP256K1_N_C_0 = (~SECP256K1_N_0 + 1)
let SECP256K1_N_C_1 = (~SECP256K1_N_1)
let SECP256K1_N_C_2 = (~SECP256K1_N_2)
let SECP256K1_N_C_3 = (~SECP256K1_N_3)
let SECP256K1_N_C_4 = (1)

/* Limbs of half the secp256k1 order. */
let SECP256K1_N_H_0: UInt32 = 0x681B20A0
let SECP256K1_N_H_1: UInt32 = 0xDFE92F46
let SECP256K1_N_H_2: UInt32 = 0x57A4501D
let SECP256K1_N_H_3: UInt32 = 0x5D576E73
let SECP256K1_N_H_4: UInt32 = 0xFFFFFFFF
let SECP256K1_N_H_5: UInt32 = 0xFFFFFFFF
let SECP256K1_N_H_6: UInt32 = 0xFFFFFFFF
let SECP256K1_N_H_7: UInt32 = 0x7FFFFFFF

func secp256k1_scalar_clear(_ r: inout secp256k1_scalar) {
    r.d[0] = 0;
    r.d[1] = 0;
    r.d[2] = 0;
    r.d[3] = 0;
    r.d[4] = 0;
    r.d[5] = 0;
    r.d[6] = 0;
    r.d[7] = 0;
}

func secp256k1_scalar_set_int(_ r: inout secp256k1_scalar, _ v: UInt) {
    r.d[0] = UInt32(v)
    r.d[1] = 0;
    r.d[2] = 0;
    r.d[3] = 0;
    r.d[4] = 0;
    r.d[5] = 0;
    r.d[6] = 0;
    r.d[7] = 0;
}

func secp256k1_scalar_get_bits(_ a: secp256k1_scalar, _ offset: UInt, _ count: UInt) -> UInt {
    VERIFY_CHECK((offset + count - 1) >> 5 == offset >> 5);
    let b:UInt32 = a.d[Int(offset >> 5)] >> (offset & 0x1F)
    let c:UInt32 = (1 << count) - 1
    return UInt(b & c)
}

func secp256k1_scalar_get_bits_var(_ a: secp256k1_scalar, _ offset: UInt, _ count: UInt) -> UInt {
    VERIFY_CHECK(count < 32);
    VERIFY_CHECK(offset + count <= 256);
    if ((offset + count - 1) >> 5 == offset >> 5) {
        return secp256k1_scalar_get_bits(a, offset, count);
    } else {
        VERIFY_CHECK((offset >> 5) + 1 < 8);
        let v0 = a.d[Int(offset >> 5)] >> (offset & 0x1F)
        let v1 = a.d[Int((offset >> 5) + 1)] << (32 - (offset & 0x1F))
        let r1 = (v0 | v1)
        let r2 = (((UInt32(1)) << count) - 1)
        return UInt(r1 & r2)
    }
}

// ベースポイントのorderを越えているかどうか
func secp256k1_scalar_check_overflow(_ a: secp256k1_scalar) -> Bool {
    // 条件文の実行数を減らすため、上位から判断を開始する
    var yes: Bool = false
    var no: Bool = false
    no = no || (a.d[7] < SECP256K1_N_7); /* No need for a > check. */
    no = no || (a.d[6] < SECP256K1_N_6); /* No need for a > check. */
    no = no || (a.d[5] < SECP256K1_N_5); /* No need for a > check. */
    no = no || (a.d[4] < SECP256K1_N_4);
    yes = yes || ((a.d[4] > SECP256K1_N_4) && !no)
    no = no || ((a.d[3] < SECP256K1_N_3) && !yes)
    yes = yes || ((a.d[3] > SECP256K1_N_3) && !no)
    no = no || ((a.d[2] < SECP256K1_N_2) && !yes)
    yes = yes || ((a.d[2] > SECP256K1_N_2) && !no)
    no = no || ((a.d[1] < SECP256K1_N_1) && !yes)
    yes = yes || ((a.d[1] > SECP256K1_N_1) && !no)
    yes = yes || ((a.d[0] >= SECP256K1_N_0) && !no)
    return yes
}

func secp256k1_scalar_reduce(_ r: inout secp256k1_scalar, _ overflow: Bool) -> Bool {
    var t: UInt64
    let v_overflow: UInt64 = overflow ? 1 : 0
    VERIFY_CHECK(v_overflow <= 1);
    t = UInt64(r.d[0]) + v_overflow * UInt64(SECP256K1_N_C_0)
    r.d[0] = t.lo; t >>= 32;
    t += UInt64(r.d[1]) + v_overflow * UInt64(SECP256K1_N_C_1)
    r.d[1] = t.lo; t >>= 32
    t += UInt64(r.d[2]) + v_overflow * UInt64(SECP256K1_N_C_2)
    r.d[2] = t.lo; t >>= 32
    t += UInt64(r.d[3]) + v_overflow * UInt64(SECP256K1_N_C_3)
    r.d[3] = t.lo; t >>= 32
    t += UInt64(r.d[4]) + v_overflow * UInt64(SECP256K1_N_C_4)
    r.d[4] = t.lo; t >>= 32
    t += UInt64(r.d[5])
    r.d[5] = t.lo; t >>= 32
    t += UInt64(r.d[6])
    r.d[6] = t.lo; t >>= 32
    t += UInt64(r.d[7])
    r.d[7] = t.lo
    return overflow
}

/**
 r = a + b
 uint32_t r[8] : scalar
 uint32_t a[8] : scalar
 uint32_t b[8] : scalar
 */
@discardableResult
func secp256k1_scalar_add(_ r: inout secp256k1_scalar, _ a: secp256k1_scalar, _ b: secp256k1_scalar) -> Bool {
    var t: UInt64 = UInt64(a.d[0]) + UInt64(b.d[0])
    r.d[0] = t.lo; t >>= 32;
    t += UInt64(a.d[1]) + UInt64(b.d[1])
    r.d[1] = t.lo; t >>= 32;
    t += UInt64(a.d[2]) + UInt64(b.d[2])
    r.d[2] = t.lo; t >>= 32;
    t += UInt64(a.d[3]) + UInt64(b.d[3])
    r.d[3] = t.lo; t >>= 32;
    t += UInt64(a.d[4]) + UInt64(b.d[4])
    r.d[4] = t.lo; t >>= 32;
    t += UInt64(a.d[5]) + UInt64(b.d[5])
    r.d[5] = t.lo; t >>= 32;
    t += UInt64(a.d[6]) + UInt64(b.d[6])
    r.d[6] = t.lo ; t >>= 32;
    t += UInt64(a.d[7]) + UInt64(b.d[7])
    r.d[7] = t.lo; t >>= 32;
    let v0:UInt64 = t
    let v1:UInt64 = secp256k1_scalar_check_overflow(r) ? 1 : 0
    let overflow = v0 + v1
    VERIFY_CHECK(overflow == 0 || overflow == 1);
    assert(overflow == 0 || overflow == 1)
    let _ = secp256k1_scalar_reduce(&r, overflow != 0)
    return overflow != 0
}

func secp256k1_scalar_cadd_bit(_ r: inout secp256k1_scalar, _ a_bit: UInt, _ flag: Int) {
    var t: UInt64
    VERIFY_CHECK(a_bit < 256);
    let bit: UInt32 = UInt32(a_bit) + UInt32((flag - 1) & 0x100)  /* forcing (bit >> 5) > 7 makes this a noop */
    
    let v0: UInt32 = ((bit >> 5) == 0 ? 1 : 0)
    t = UInt64(r.d[0]) + UInt64(v0 << (bit & 0x1F));
    r.d[0] = t.lo; t >>= 32;
    let v1: UInt32 = ((bit >> 5) == 1 ? 1 : 0)
    t += UInt64(r.d[1]) + UInt64(v1 << (bit & 0x1F));
    r.d[1] = t.lo; t >>= 32;
    let v2: UInt32 = ((bit >> 5) == 2 ? 1 : 0)
    t += UInt64(r.d[2]) + UInt64(v2 << (bit & 0x1F))
    r.d[2] = t.lo; t >>= 32;
    let v3: UInt32 = ((bit >> 5) == 3 ? 1 : 0)
    t += UInt64(r.d[3]) + UInt64(v3 << (bit & 0x1F))
    r.d[3] = t.lo; t >>= 32;
    let v4: UInt32 = ((bit >> 5) == 4 ? 1 : 0)
    t += UInt64(r.d[4]) + UInt64(v4 << (bit & 0x1F))
    r.d[4] = t.lo; t >>= 32;
    let v5: UInt32 = ((bit >> 5) == 5 ? 1 : 0)
    t += UInt64(r.d[5]) + UInt64(v5 << (bit & 0x1F))
    r.d[5] = t.lo; t >>= 32;
    let v6: UInt32 = ((bit >> 5) == 6 ? 1 : 0)
    t += UInt64(r.d[6]) + UInt64(v6 << (bit & 0x1F))
    r.d[6] = t.lo; t >>= 32;
    let v7: UInt32 = ((bit >> 5) == 7 ? 1 : 0)
    t += UInt64(r.d[7]) + UInt64(v7 << (bit & 0x1F))
    r.d[7] = t.lo;
    #if VERIFY
        VERIFY_CHECK((t >> 32) == 0);
        VERIFY_CHECK(!secp256k1_scalar_check_overflow(r));
    #endif
}

// スカラー値をb32に設定して返す,
// overflow していた場合は範囲内の値にして返す
func secp256k1_scalar_set_b32(_ r: inout secp256k1_scalar, _ b32: [UInt8], _ overflow: inout Bool) {
    assert(b32.count >= 32)
    var over: Bool
    r.d[0] = UInt32(b32[31])
    r.d[0] = r.d[0] | UInt32(b32[30]) << 8
    r.d[0] = r.d[0] | UInt32(b32[29]) << 16
    r.d[0] = r.d[0] | UInt32(b32[28]) << 24
    r.d[1] = UInt32(b32[27])
    r.d[1] = r.d[1] | UInt32(b32[26]) << 8
    r.d[1] = r.d[1] | UInt32(b32[25]) << 16
    r.d[1] = r.d[1] | UInt32(b32[24]) << 24
    r.d[2] = UInt32(b32[23])
    r.d[2] = r.d[2] | UInt32(b32[22]) << 8
    r.d[2] = r.d[2] | UInt32(b32[21]) << 16
    r.d[2] = r.d[2] | UInt32(b32[20]) << 24
    r.d[3] = UInt32(b32[19])
    r.d[3] = r.d[3] | UInt32(b32[18]) << 8
    r.d[3] = r.d[3] | UInt32(b32[17]) << 16
    r.d[3] = r.d[3] | UInt32(b32[16]) << 24
    r.d[4] = UInt32(b32[15])
    r.d[4] = r.d[4] | UInt32(b32[14]) << 8
    r.d[4] = r.d[4] | UInt32(b32[13]) << 16
    r.d[4] = r.d[4] | UInt32(b32[12]) << 24
    r.d[5] = UInt32(b32[11])
    r.d[5] = r.d[5] | UInt32(b32[10]) << 8
    r.d[5] = r.d[5] | UInt32(b32[9]) << 16
    r.d[5] = r.d[5] | UInt32(b32[8]) << 24
    r.d[6] = UInt32(b32[7])
    r.d[6] = r.d[6] | UInt32(b32[6]) << 8
    r.d[6] = r.d[6] | UInt32(b32[5]) << 16
    r.d[6] = r.d[6] | UInt32(b32[4]) << 24
    r.d[7] = UInt32(b32[3])
    r.d[7] = r.d[7] | UInt32(b32[2]) << 8
    r.d[7] = r.d[7] | UInt32(b32[1]) << 16
    r.d[7] = r.d[7] | UInt32(b32[0]) << 24
    over = secp256k1_scalar_reduce(&r, secp256k1_scalar_check_overflow(r));
    //if overflow != nil {
    overflow = over
    //}
}

func secp256k1_scalar_get_b32(_ bin: inout [UInt8], _ a: secp256k1_scalar) {
    assert(bin.count >= 32)
    UInt32BEToUInt8(&bin, 0, a.d[7])
    UInt32BEToUInt8(&bin, 4, a.d[6])
    UInt32BEToUInt8(&bin, 8, a.d[5])
    UInt32BEToUInt8(&bin, 12, a.d[4])
    UInt32BEToUInt8(&bin, 16, a.d[3])
    UInt32BEToUInt8(&bin, 20, a.d[2])
    UInt32BEToUInt8(&bin, 24, a.d[1])
    UInt32BEToUInt8(&bin, 28, a.d[0])
}

func secp256k1_scalar_is_zero(_ a: secp256k1_scalar) -> Bool {
    return (a.d[0] | a.d[1] | a.d[2] | a.d[3] | a.d[4] | a.d[5] | a.d[6] | a.d[7]) == 0;
}

func secp256k1_scalar_negate(_ r: inout secp256k1_scalar, _ a: secp256k1_scalar) {
    let nonzero:UInt32 = 0xFFFFFFFF * (secp256k1_scalar_is_zero(a) ? 0 : 1)
    var t:UInt64 = UInt64(~a.d[0]) + UInt64(SECP256K1_N_0) + UInt64(1)
    r.d[0] = t.lo & nonzero; t >>= 32;
    t += UInt64(~a.d[1]) + UInt64(SECP256K1_N_1)
    r.d[1] = t.lo & nonzero; t >>= 32;
    t += UInt64(~a.d[2]) + UInt64(SECP256K1_N_2)
    r.d[2] = t.lo & nonzero; t >>= 32;
    t += UInt64(~a.d[3]) + UInt64(SECP256K1_N_3)
    r.d[3] = t.lo & nonzero; t >>= 32;
    t += UInt64(~a.d[4]) + UInt64(SECP256K1_N_4)
    r.d[4] = t.lo & nonzero; t >>= 32;
    t += UInt64(~a.d[5]) + UInt64(SECP256K1_N_5)
    r.d[5] = t.lo & nonzero; t >>= 32;
    t += UInt64(~a.d[6]) + UInt64(SECP256K1_N_6)
    r.d[6] = t.lo & nonzero; t >>= 32;
    t += UInt64(~a.d[7]) + UInt64(SECP256K1_N_7)
    r.d[7] = t.lo & nonzero;
}

func secp256k1_scalar_is_one(_ a: secp256k1_scalar) -> Bool {
    return ((a.d[0] ^ 1) | a.d[1] | a.d[2] | a.d[3] | a.d[4] | a.d[5] | a.d[6] | a.d[7]) == 0;
}

//
func secp256k1_scalar_is_high(_ a: secp256k1_scalar) -> Bool {
    var yes: Bool = false
    var no: Bool = false
    no = no || (a.d[7] < SECP256K1_N_H_7);
    yes = yes || ((a.d[7] > SECP256K1_N_H_7) && !no);
    no = no || ((a.d[6] < SECP256K1_N_H_6) && !yes); /* No need for a > check. */
    no = no || ((a.d[5] < SECP256K1_N_H_5) && !yes); /* No need for a > check. */
    no = no || ((a.d[4] < SECP256K1_N_H_4) && !yes); /* No need for a > check. */
    no = no || ((a.d[3] < SECP256K1_N_H_3) && !yes);
    yes = yes || ((a.d[3] > SECP256K1_N_H_3) && !no);
    no = no || ((a.d[2] < SECP256K1_N_H_2) && !yes);
    yes = yes || ((a.d[2] > SECP256K1_N_H_2) && !no);
    no = no || ((a.d[1] < SECP256K1_N_H_1) && !yes);
    yes = yes || ((a.d[1] > SECP256K1_N_H_1) && !no);
    yes = yes || ((a.d[0] > SECP256K1_N_H_0) && !no);
    return yes;
}

func secp256k1_scalar_cond_negate(_ r: inout secp256k1_scalar, _ flag: Int) -> Int {
    /* If we are flag = 0, mask = 00...00 and this is a no-op;
     * if we are flag = 1, mask = 11...11 and this is identical to secp256k1_scalar_negate */
    let mask:UInt32 = (flag == 0 ? 0 : 0xFFFFFFFF) //  !flag - 1;
    let nonzero:UInt32 = UInt32(0xFFFFFFFF * (!secp256k1_scalar_is_zero(r) ? 1 : 0))
    var t:UInt64 = UInt64(r.d[0] ^ mask) + UInt64((SECP256K1_N_0 + 1) & mask);
    r.d[0] = t.lo & nonzero; t >>= 32;
    t += UInt64(r.d[1] ^ mask) + UInt64(SECP256K1_N_1 & mask);
    r.d[1] = t.lo & nonzero; t >>= 32;
    t += UInt64(r.d[2] ^ mask) + UInt64(SECP256K1_N_2 & mask);
    r.d[2] = t.lo & nonzero; t >>= 32;
    t += UInt64(r.d[3] ^ mask) + UInt64(SECP256K1_N_3 & mask);
    r.d[3] = t.lo & nonzero; t >>= 32;
    t += UInt64(r.d[4] ^ mask) + UInt64(SECP256K1_N_4 & mask);
    r.d[4] = t.lo & nonzero; t >>= 32;
    t += UInt64(r.d[5] ^ mask) + UInt64(SECP256K1_N_5 & mask);
    r.d[5] = t.lo & nonzero; t >>= 32;
    t += UInt64(r.d[6] ^ mask) + UInt64(SECP256K1_N_6 & mask);
    r.d[6] = t.lo & nonzero; t >>= 32;
    t += UInt64(r.d[7] ^ mask) + UInt64(SECP256K1_N_7 & mask);
    r.d[7] = t.lo & nonzero;
    // mask == 0 -> 1
    // mask == 1 -> -1
    //return 2 * (mask == 0) - 1;
    return mask == 0 ? 1 : -1
}


/* Inspired by the macros in OpenSSL's crypto/bn/asm/x86_64-gcc.c. */
fileprivate struct CA {
    public var c0: UInt32
    public var c1: UInt32
    public var c2: UInt32
    init(){
        c0 = 0
        c1 = 0
        c2 = 0
    }
    
    func VERIFY_CHECK(_ cond:Bool){
        assert(cond)
    }

    /** Add a*b to the number defined by (c0,c1,c2). c2 must never overflow. */
    mutating func muladd(_ a: UInt32, _ b: UInt32) {
        var tl:UInt32
        var th:UInt32
        let t: UInt64 = UInt64(a) * UInt64(b)
        th = t.hi /* >> 32 */         /* at most 0xFFFFFFFE */
        tl = t.lo
        c0 = c0 &+ tl                 /* overflow is handled on the next line */
        th += (c0 < tl) ? 1 : 0;  /* at most 0xFFFFFFFF */
        c1 = c1 &+ th;                 /* overflow is handled on the next line */
        c2 += (c1 < th) ? 1 : 0;  /* never overflows by contract (verified in the next line) */
        VERIFY_CHECK((c1 >= th) || (c2 != 0));
    }

    /** Add a*b to the number defined by (c0,c1). c1 must never overflow. */
    mutating func muladd_fast(_ a: UInt32, _ b: UInt32) {
        var tl: UInt32
        var th: UInt32
        let t: UInt64 = UInt64(a) * UInt64(b)
        th = t.hi /* t >> 32 */         /* at most 0xFFFFFFFE */
        tl = t.lo
        c0 = c0 &+ tl                  /* overflow is handled on the next line */
        th += (c0 < tl) ? 1 : 0   /* at most 0xFFFFFFFF */
        c1 += th                  /* never overflows by contract (verified in the next line) */
        VERIFY_CHECK(c1 >= th)
    }

    /** Add 2*a*b to the number defined by (c0,c1,c2). c2 must never overflow. */
    mutating func muladd2(_ a: UInt32, _ b: UInt32) {
        var tl: UInt32
        var th: UInt32
        var th2: UInt32
        var tl2: UInt32
        let t: UInt64 = UInt64(a) * UInt64(b)
        th = t.hi /* UInt32(t >> 32) */               /* at most 0xFFFFFFFE */
        tl = t.lo;
        th2 = th &+ th;                  /* at most 0xFFFFFFFE (in case th was 0x7FFFFFFF) overflow is handled on the next line */
        c2 += (th2 < th) ? 1 : 0;       /* never overflows by contract (verified the next line) */
        VERIFY_CHECK((th2 >= th) || (c2 != 0));
        tl2 = tl &+ tl;                  /* at most 0xFFFFFFFE (in case the lowest 63 bits of tl were 0x7FFFFFFF)  overflow is handled on next line */
        th2 += (tl2 < tl) ? 1 : 0;      /* at most 0xFFFFFFFF */
        c0 = c0 &+ tl2;                      /* overflow is handled on the next line */
        th2 = th2 &+ ((c0 < tl2) ? 1 : 0)      /* second overflow is handled on the next line */
        c2 = c2 + UInt32(((c0 < tl2) ? 1 : 0) & (th2 == 0 ? 1 : 0)) /* never overflows by contract (verified the next line) */
        VERIFY_CHECK((c0 >= tl2) || (th2 != 0) || (c2 != 0));
        c1 = c1 &+ th2;                      /* overflow is handled on the next line */
        c2 += (c1 < th2) ? 1 : 0;       /* never overflows by contract (verified the next line) */
        VERIFY_CHECK((c1 >= th2) || (c2 != 0));
    }

    /** Add a to the number defined by (c0,c1,c2). c2 must never overflow. */
    mutating func sumadd(_ a: UInt32) {
        var over: UInt32
        c0 = c0 &+ a                /* overflow is handled on the next line */
        over = (c0 < (a)) ? 1 : 0;
        c1 = c1 &+ over;                 /* overflow is handled on the next line */
        c2 += (c1 < over) ? 1 : 0;  /* never overflows by contract */
    }

    /** Add a to the number defined by (c0,c1). c1 must never overflow, c2 must be zero. */
    mutating func sumadd_fast(_ a: UInt32) {
        c0 = c0 &+ a               /* overflow is handled on the next line */
        c1 += (c0 < (a)) ? 1 : 0   /* never overflows by contract (verified the next line) */
        VERIFY_CHECK((c1 != 0) || (c0 >= (a)))
        VERIFY_CHECK(c2 == 0)
    }

    /** Extract the lowest 32 bits of (c0,c1,c2) into n, and left shift the number 32 bits. */
    mutating func extract(_ n: inout UInt32) {
        n = c0;
        c0 = c1;
        c1 = c2;
        c2 = 0;
    }

    /** Extract the lowest 32 bits of (c0,c1,c2) into n, and left shift the number 32 bits. c2 is required to be zero. */
    mutating func extract_fast(_ n: inout UInt32) {
        n = c0;
        c0 = c1;
        c1 = 0;
        VERIFY_CHECK(c2 == 0);
    }
}

func secp256k1_scalar_reduce_512(_ r: inout secp256k1_scalar, _ l: [UInt32]) {
   
    var c: UInt64
    let n0 = l[8]
    let n1 = l[9]
    let n2 = l[10]
    let n3 = l[11]
    let n4 = l[12]
    let n5 = l[13]
    let n6 = l[14]
    let n7 = l[15]
    var m0: UInt32 = 0
    var m1: UInt32 = 0
    var m2: UInt32 = 0
    var m3: UInt32 = 0
    var m4: UInt32 = 0
    var m5: UInt32 = 0
    var m6: UInt32 = 0
    var m7: UInt32 = 0
    var m8: UInt32 = 0
    var m9: UInt32 = 0
    var m10: UInt32 = 0
    var m11: UInt32 = 0
    var m12: UInt32 = 0
    var p0: UInt32 = 0
    var p1: UInt32 = 0
    var p2: UInt32 = 0
    var p3: UInt32 = 0
    var p4: UInt32 = 0
    var p5: UInt32 = 0
    var p6: UInt32 = 0
    var p7: UInt32 = 0
    var p8: UInt32 = 0
    
    /* 96 bit accumulator. */
    //var c0: UInt32
    //var c1: UInt32
    //var c2: UInt32
    
    /* Reduce 512 bits into 385. */
    /* m[0..12] = l[0..7] + n[0..7] * SECP256K1_N_C. */
    //c0 = l[0]; c1 = 0; c2 = 0;
    var ca = CA()
    ca.c0 = l[0]; ca.c1 = 0; ca.c2 = 0
    ca.muladd_fast(n0, SECP256K1_N_C_0)
    ca.extract_fast(&m0);
    ca.sumadd_fast(l[1]);
    ca.muladd(n1, SECP256K1_N_C_0);
    ca.muladd(n0, SECP256K1_N_C_1);
    ca.extract(&m1);
    ca.sumadd(l[2]);
    ca.muladd(n2, SECP256K1_N_C_0);
    ca.muladd(n1, SECP256K1_N_C_1);
    ca.muladd(n0, SECP256K1_N_C_2);
    ca.extract(&m2);
    ca.sumadd(l[3]);
    ca.muladd(n3, SECP256K1_N_C_0);
    ca.muladd(n2, SECP256K1_N_C_1);
    ca.muladd(n1, SECP256K1_N_C_2);
    ca.muladd(n0, SECP256K1_N_C_3);
    ca.extract(&m3);
    ca.sumadd(l[4]);
    ca.muladd(n4, SECP256K1_N_C_0);
    ca.muladd(n3, SECP256K1_N_C_1);
    ca.muladd(n2, SECP256K1_N_C_2);
    ca.muladd(n1, SECP256K1_N_C_3);
    ca.sumadd(n0);
    ca.extract(&m4);
    ca.sumadd(l[5]);
    ca.muladd(n5, SECP256K1_N_C_0);
    ca.muladd(n4, SECP256K1_N_C_1);
    ca.muladd(n3, SECP256K1_N_C_2);
    ca.muladd(n2, SECP256K1_N_C_3);
    ca.sumadd(n1);
    ca.extract(&m5);
    ca.sumadd(l[6]);
    ca.muladd(n6, SECP256K1_N_C_0);
    ca.muladd(n5, SECP256K1_N_C_1);
    ca.muladd(n4, SECP256K1_N_C_2);
    ca.muladd(n3, SECP256K1_N_C_3);
    ca.sumadd(n2);
    ca.extract(&m6);
    ca.sumadd(l[7]);
    ca.muladd(n7, SECP256K1_N_C_0);
    ca.muladd(n6, SECP256K1_N_C_1);
    ca.muladd(n5, SECP256K1_N_C_2);
    ca.muladd(n4, SECP256K1_N_C_3);
    ca.sumadd(n3);
    ca.extract(&m7);
    ca.muladd(n7, SECP256K1_N_C_1);
    ca.muladd(n6, SECP256K1_N_C_2);
    ca.muladd(n5, SECP256K1_N_C_3);
    ca.sumadd(n4);
    ca.extract(&m8);
    ca.muladd(n7, SECP256K1_N_C_2);
    ca.muladd(n6, SECP256K1_N_C_3);
    ca.sumadd(n5);
    ca.extract(&m9);
    ca.muladd(n7, SECP256K1_N_C_3);
    ca.sumadd(n6);
    ca.extract(&m10);
    ca.sumadd_fast(n7);
    ca.extract_fast(&m11);
    VERIFY_CHECK(ca.c0 <= 1);
    m12 = ca.c0;
    
    /* Reduce 385 bits into 258. */
    /* p[0..8] = m[0..7] + m[8..12] * SECP256K1_N_C. */
    ca.c0 = m0; ca.c1 = 0; ca.c2 = 0;
    ca.muladd_fast(m8, SECP256K1_N_C_0);
    ca.extract_fast(&p0);
    ca.sumadd_fast(m1);
    ca.muladd(m9, SECP256K1_N_C_0);
    ca.muladd(m8, SECP256K1_N_C_1);
    ca.extract(&p1);
    ca.sumadd(m2);
    ca.muladd(m10, SECP256K1_N_C_0);
    ca.muladd(m9, SECP256K1_N_C_1);
    ca.muladd(m8, SECP256K1_N_C_2);
    ca.extract(&p2);
    ca.sumadd(m3);
    ca.muladd(m11, SECP256K1_N_C_0);
    ca.muladd(m10, SECP256K1_N_C_1);
    ca.muladd(m9, SECP256K1_N_C_2);
    ca.muladd(m8, SECP256K1_N_C_3);
    ca.extract(&p3);
    ca.sumadd(m4);
    ca.muladd(m12, SECP256K1_N_C_0);
    ca.muladd(m11, SECP256K1_N_C_1);
    ca.muladd(m10, SECP256K1_N_C_2);
    ca.muladd(m9, SECP256K1_N_C_3);
    ca.sumadd(m8);
    ca.extract(&p4);
    ca.sumadd(m5);
    ca.muladd(m12, SECP256K1_N_C_1);
    ca.muladd(m11, SECP256K1_N_C_2);
    ca.muladd(m10, SECP256K1_N_C_3);
    ca.sumadd(m9);
    ca.extract(&p5);
    ca.sumadd(m6);
    ca.muladd(m12, SECP256K1_N_C_2);
    ca.muladd(m11, SECP256K1_N_C_3);
    ca.sumadd(m10);
    ca.extract(&p6);
    ca.sumadd_fast(m7);
    ca.muladd_fast(m12, SECP256K1_N_C_3);
    ca.sumadd_fast(m11);
    ca.extract_fast(&p7);
    p8 = ca.c0 + m12;
    VERIFY_CHECK(p8 <= 2);
    
    /* Reduce 258 bits into 256. */
    /* r[0..7] = p[0..7] + p[8] * SECP256K1_N_C. */
    c = UInt64(p0) + UInt64(SECP256K1_N_C_0) * UInt64(p8)
    r.d[0] = c.lo; c >>= 32;
    c += UInt64(p1) + UInt64(SECP256K1_N_C_1) * UInt64(p8)
    r.d[1] = c.lo; c >>= 32;
    c += UInt64(p2) + UInt64(SECP256K1_N_C_2) * UInt64(p8)
    r.d[2] = c.lo; c >>= 32;
    c += UInt64(p3) + UInt64(SECP256K1_N_C_3) * UInt64(p8)
    r.d[3] = c.lo; c >>= 32;
    c += UInt64(p4) + UInt64(p8)
    r.d[4] = c.lo; c >>= 32;
    c += UInt64(p5)
    r.d[5] = c.lo; c >>= 32;
    c += UInt64(p6)
    r.d[6] = c.lo; c >>= 32;
    c += UInt64(p7)
    r.d[7] = c.lo; c >>= 32;
    
    /* Final reduction of r. */
    let v0 = c > 0 ? 1 : 0
    let v1 = secp256k1_scalar_check_overflow(r) ? 1 : 0
    let _ = secp256k1_scalar_reduce(&r, (v0 + v1) != 0)
}

fileprivate func secp256k1_scalar_mul_512(_ l: inout [UInt32], _ a: secp256k1_scalar, _ b: secp256k1_scalar) {
    /* 96 bit accumulator. */
    //var c0: UInt32 = 0
    //var c1: UInt32 = 0
    //var c2: UInt32 = 0
    var ca = CA()
    
    /* l[0..15] = a[0..7] * b[0..7]. */
    ca.muladd_fast(a.d[0], b.d[0]);
    ca.extract_fast(&l[0]);
    ca.muladd(a.d[0], b.d[1]);
    ca.muladd(a.d[1], b.d[0]);
    ca.extract(&l[1]);
    ca.muladd(a.d[0], b.d[2]);
    ca.muladd(a.d[1], b.d[1]);
    ca.muladd(a.d[2], b.d[0]);
    ca.extract(&l[2]);
    ca.muladd(a.d[0], b.d[3]);
    ca.muladd(a.d[1], b.d[2]);
    ca.muladd(a.d[2], b.d[1]);
    ca.muladd(a.d[3], b.d[0]);
    ca.extract(&l[3]);
    ca.muladd(a.d[0], b.d[4]);
    ca.muladd(a.d[1], b.d[3]);
    ca.muladd(a.d[2], b.d[2]);
    ca.muladd(a.d[3], b.d[1]);
    ca.muladd(a.d[4], b.d[0]);
    ca.extract(&l[4]);
    ca.muladd(a.d[0], b.d[5]);
    ca.muladd(a.d[1], b.d[4]);
    ca.muladd(a.d[2], b.d[3]);
    ca.muladd(a.d[3], b.d[2]);
    ca.muladd(a.d[4], b.d[1]);
    ca.muladd(a.d[5], b.d[0]);
    ca.extract(&l[5]);
    ca.muladd(a.d[0], b.d[6]);
    ca.muladd(a.d[1], b.d[5]);
    ca.muladd(a.d[2], b.d[4]);
    ca.muladd(a.d[3], b.d[3]);
    ca.muladd(a.d[4], b.d[2]);
    ca.muladd(a.d[5], b.d[1]);
    ca.muladd(a.d[6], b.d[0]);
    ca.extract(&l[6]);
    ca.muladd(a.d[0], b.d[7]);
    ca.muladd(a.d[1], b.d[6]);
    ca.muladd(a.d[2], b.d[5]);
    ca.muladd(a.d[3], b.d[4]);
    ca.muladd(a.d[4], b.d[3]);
    ca.muladd(a.d[5], b.d[2]);
    ca.muladd(a.d[6], b.d[1]);
    ca.muladd(a.d[7], b.d[0]);
    ca.extract(&l[7]);
    ca.muladd(a.d[1], b.d[7]);
    ca.muladd(a.d[2], b.d[6]);
    ca.muladd(a.d[3], b.d[5]);
    ca.muladd(a.d[4], b.d[4]);
    ca.muladd(a.d[5], b.d[3]);
    ca.muladd(a.d[6], b.d[2]);
    ca.muladd(a.d[7], b.d[1]);
    ca.extract(&l[8]);
    ca.muladd(a.d[2], b.d[7]);
    ca.muladd(a.d[3], b.d[6]);
    ca.muladd(a.d[4], b.d[5]);
    ca.muladd(a.d[5], b.d[4]);
    ca.muladd(a.d[6], b.d[3]);
    ca.muladd(a.d[7], b.d[2]);
    ca.extract(&l[9]);
    ca.muladd(a.d[3], b.d[7]);
    ca.muladd(a.d[4], b.d[6]);
    ca.muladd(a.d[5], b.d[5]);
    ca.muladd(a.d[6], b.d[4]);
    ca.muladd(a.d[7], b.d[3]);
    ca.extract(&l[10]);
    ca.muladd(a.d[4], b.d[7]);
    ca.muladd(a.d[5], b.d[6]);
    ca.muladd(a.d[6], b.d[5]);
    ca.muladd(a.d[7], b.d[4]);
    ca.extract(&l[11]);
    ca.muladd(a.d[5], b.d[7]);
    ca.muladd(a.d[6], b.d[6]);
    ca.muladd(a.d[7], b.d[5]);
    ca.extract(&l[12]);
    ca.muladd(a.d[6], b.d[7]);
    ca.muladd(a.d[7], b.d[6]);
    ca.extract(&l[13]);
    ca.muladd_fast(a.d[7], b.d[7]);
    ca.extract_fast(&l[14]);
    VERIFY_CHECK(ca.c1 == 0);
    l[15] = ca.c0
}

fileprivate func secp256k1_scalar_sqr_512(_ l: inout [UInt32], _ a: secp256k1_scalar) {
    /* 96 bit accumulator. */
    //var c0: UInt32 = 0
    //var c1: UInt32 = 0
    //var c2: UInt32 = 0
    var ca = CA()
    
    /* l[0..15] = a[0..7]^2. */
    ca.muladd_fast(a.d[0], a.d[0]);
    ca.extract_fast(&l[0]);
    ca.muladd2(a.d[0], a.d[1]);
    ca.extract(&l[1]);
    ca.muladd2(a.d[0], a.d[2]);
    ca.muladd(a.d[1], a.d[1]);
    ca.extract(&l[2]);
    ca.muladd2(a.d[0], a.d[3]);
    ca.muladd2(a.d[1], a.d[2]);
    ca.extract(&l[3]);
    ca.muladd2(a.d[0], a.d[4]);
    ca.muladd2(a.d[1], a.d[3]);
    ca.muladd(a.d[2], a.d[2]);
    ca.extract(&l[4]);
    ca.muladd2(a.d[0], a.d[5]);
    ca.muladd2(a.d[1], a.d[4]);
    ca.muladd2(a.d[2], a.d[3]);
    ca.extract(&l[5]);
    ca.muladd2(a.d[0], a.d[6]);
    ca.muladd2(a.d[1], a.d[5]);
    ca.muladd2(a.d[2], a.d[4]);
    ca.muladd(a.d[3], a.d[3]);
    ca.extract(&l[6]);
    ca.muladd2(a.d[0], a.d[7]);
    ca.muladd2(a.d[1], a.d[6]);
    ca.muladd2(a.d[2], a.d[5]);
    ca.muladd2(a.d[3], a.d[4]);
    ca.extract(&l[7]);
    ca.muladd2(a.d[1], a.d[7]);
    ca.muladd2(a.d[2], a.d[6]);
    ca.muladd2(a.d[3], a.d[5]);
    ca.muladd(a.d[4], a.d[4]);
    ca.extract(&l[8]);
    ca.muladd2(a.d[2], a.d[7]);
    ca.muladd2(a.d[3], a.d[6]);
    ca.muladd2(a.d[4], a.d[5]);
    ca.extract(&l[9]);
    ca.muladd2(a.d[3], a.d[7]);
    ca.muladd2(a.d[4], a.d[6]);
    ca.muladd(a.d[5], a.d[5]);
    ca.extract(&l[10]);
    ca.muladd2(a.d[4], a.d[7]);
    ca.muladd2(a.d[5], a.d[6]);
    ca.extract(&l[11]);
    ca.muladd2(a.d[5], a.d[7]);
    ca.muladd(a.d[6], a.d[6]);
    ca.extract(&l[12]);
    ca.muladd2(a.d[6], a.d[7]);
    ca.extract(&l[13]);
    ca.muladd_fast(a.d[7], a.d[7]);
    ca.extract_fast(&l[14]);
    VERIFY_CHECK(ca.c1 == 0);
    l[15] = ca.c0
}

// r = a * b
func secp256k1_scalar_mul(_ r: inout secp256k1_scalar, _ a: secp256k1_scalar, _ b: secp256k1_scalar) {
    var l:[UInt32] = [UInt32](repeating: 0, count: 16)
    secp256k1_scalar_mul_512(&l, a, b);
    secp256k1_scalar_reduce_512(&r, l);
}

func secp256k1_scalar_shr_int(_ r: inout secp256k1_scalar, _ n: Int) -> UInt32 {
    var ret:UInt32
    VERIFY_CHECK(n > 0);
    VERIFY_CHECK(n < 16);
    ret = r.d[0] & ((1 << n) - 1)
    r.d[0] = (r.d[0] >> n) + (r.d[1] << (32 - n));
    r.d[1] = (r.d[1] >> n) + (r.d[2] << (32 - n));
    r.d[2] = (r.d[2] >> n) + (r.d[3] << (32 - n));
    r.d[3] = (r.d[3] >> n) + (r.d[4] << (32 - n));
    r.d[4] = (r.d[4] >> n) + (r.d[5] << (32 - n));
    r.d[5] = (r.d[5] >> n) + (r.d[6] << (32 - n));
    r.d[6] = (r.d[6] >> n) + (r.d[7] << (32 - n));
    r.d[7] = (r.d[7] >> n);
    return ret
}

func secp256k1_scalar_sqr(_ r: inout secp256k1_scalar, _ a: secp256k1_scalar) {
    var l: [UInt32] = [UInt32](repeating: 0, count: 16)
    secp256k1_scalar_sqr_512(&l, a);
    secp256k1_scalar_reduce_512(&r, l);
}

#if USE_ENDOMORPHISM
func secp256k1_scalar_split_128(_ r1: inout secp256k1_scalar, _ r2: inout secp256k1_scalar, _ a: secp256k1_scalar) {
    r1->d[0] = a->d[0];
    r1->d[1] = a->d[1];
    r1->d[2] = a->d[2];
    r1->d[3] = a->d[3];
    r1->d[4] = 0;
    r1->d[5] = 0;
    r1->d[6] = 0;
    r1->d[7] = 0;
    r2->d[0] = a->d[4];
    r2->d[1] = a->d[5];
    r2->d[2] = a->d[6];
    r2->d[3] = a->d[7];
    r2->d[4] = 0;
    r2->d[5] = 0;
    r2->d[6] = 0;
    r2->d[7] = 0;
}
#endif

func secp256k1_scalar_eq(_ a: secp256k1_scalar, _ b: secp256k1_scalar) -> Bool {
    var r = (a.d[0] ^ b.d[0])
    r |= (a.d[1] ^ b.d[1])
    r |= (a.d[2] ^ b.d[2])
    r |= (a.d[3] ^ b.d[3])
    r |= (a.d[4] ^ b.d[4])
    r |= (a.d[5] ^ b.d[5])
    r |= (a.d[6] ^ b.d[6])
    r |= (a.d[7] ^ b.d[7])
    return r == 0
}

func secp256k1_scalar_mul_shift_var(_ r: inout secp256k1_scalar, _ a: secp256k1_scalar, _ b: secp256k1_scalar, _ shift: UInt) {
    var l: [UInt32] = [UInt32](repeating: 0, count: 16)
    var shiftlimbs: Int
    var shiftlow: UInt
    var shifthigh: UInt
    VERIFY_CHECK(shift >= 256);
    secp256k1_scalar_mul_512(&l, a, b);
    shiftlimbs = Int(shift >> 5)
    shiftlow = shift & 0x1F;
    shifthigh = 32 - shiftlow;
    r.d[0] = shift < 512 ? (l[0 + shiftlimbs] >> shiftlow | (shift < 480 && shiftlow != 0 ? (l[1 + shiftlimbs] << shifthigh) : 0)) : 0;
    r.d[1] = shift < 480 ? (l[1 + shiftlimbs] >> shiftlow | (shift < 448 && shiftlow != 0 ? (l[2 + shiftlimbs] << shifthigh) : 0)) : 0;
    r.d[2] = shift < 448 ? (l[2 + shiftlimbs] >> shiftlow | (shift < 416 && shiftlow != 0 ? (l[3 + shiftlimbs] << shifthigh) : 0)) : 0;
    r.d[3] = shift < 416 ? (l[3 + shiftlimbs] >> shiftlow | (shift < 384 && shiftlow != 0 ? (l[4 + shiftlimbs] << shifthigh) : 0)) : 0;
    r.d[4] = shift < 384 ? (l[4 + shiftlimbs] >> shiftlow | (shift < 352 && shiftlow != 0 ? (l[5 + shiftlimbs] << shifthigh) : 0)) : 0;
    r.d[5] = shift < 352 ? (l[5 + shiftlimbs] >> shiftlow | (shift < 320 && shiftlow != 0 ? (l[6 + shiftlimbs] << shifthigh) : 0)) : 0;
    r.d[6] = shift < 320 ? (l[6 + shiftlimbs] >> shiftlow | (shift < 288 && shiftlow != 0 ? (l[7 + shiftlimbs] << shifthigh) : 0)) : 0;
    r.d[7] = shift < 288 ? (l[7 + shiftlimbs] >> shiftlow) : 0
    let v: Int = (Int(shift) - 1) & 0x1f
    let u: UInt32 = (l[(Int(shift) - 1) >> 5] >> v) & 1
    secp256k1_scalar_cadd_bit(&r, 0, Int(u))
}
