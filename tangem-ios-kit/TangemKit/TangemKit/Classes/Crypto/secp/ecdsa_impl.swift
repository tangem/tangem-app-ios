//
//  ecdsa_impl.swift
//  secp256k1
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2017 pebble8888. All rights reserved.
//
/**********************************************************************
 * Copyright (c) 2013-2015 Pieter Wuille                              *
 * Distributed under the MIT software license, see the accompanying   *
 * file COPYING or http://www.opensource.org/licenses/mit-license.php.*
 **********************************************************************/

import Foundation

/** Group order for secp256k1 defined as 'n' in "Standards for Efficient Cryptography" (SEC2) 2.7.1
 *  sage: for t in xrange(1023, -1, -1):
 *     ..   p = 2**256 - 2**32 - t
 *     ..   if p.is_prime():
 *     ..     print '%x'%p
 *     ..     break
 *   'fffffffffffffffffffffffffffffffffffffffffffffffffffffffefffffc2f'
 *  sage: a = 0
 *  sage: b = 7
 *  sage: F = FiniteField (p)
 *  sage: '%x' % (EllipticCurve ([F (a), F (b)]).order())
 *   'fffffffffffffffffffffffffffffffebaaedce6af48a03bbfd25e8cd0364141'
 */
// 群の位数(n)
let secp256k1_ecdsa_const_order_as_fe:secp256k1_fe = SECP256K1_FE_CONST(
    0xFFFFFFFF, 0xFFFFFFFF, 0xFFFFFFFF, 0xFFFFFFFE,
    0xBAAEDCE6, 0xAF48A03B, 0xBFD25E8C, 0xD0364141
);

/** Difference between field and order, values 'p' and 'n' values defined in
 *  "Standards for Efficient Cryptography" (SEC2) 2.7.1.
 *  sage: p = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFC2F
 *  sage: a = 0
 *  sage: b = 7
 *  sage: F = FiniteField (p)
 *  sage: '%x' % (p - EllipticCurve ([F (a), F (b)]).order())
 *   '14551231950b75fc4402da1722fc9baee'
 */
// module prime - group order
let secp256k1_ecdsa_const_p_minus_order:secp256k1_fe = SECP256K1_FE_CONST(
    0, 0, 0, 1, 0x45512319, 0x50B75FC4, 0x402DA172, 0x2FC9BAEE
);

fileprivate func secp256k1_der_read_len(_ sigp: [UInt8], _ sigp_idx: inout Int, _ sigend: UInt) -> Int
{
    var lenleft: Int
    var b1:Int
    var ret:Int = 0
    if sigp_idx >= sigend {
        return -1
    }
    b1 = Int(sigp[sigp_idx]); sigp_idx += 1
    
    if (b1 == 0xFF) {
        /* X.690-0207 8.1.3.5.c the value 0xFF shall not be used. */
        return -1
    }
    if ((b1 & 0x80) == 0) {
        /* X.690-0207 8.1.3.4 short form length octets */
        return b1
    }
    if (b1 == 0x80) {
        /* Indefinite length is not allowed in DER. */
        return -1
    }
    /* X.690-207 8.1.3.5 long form length octets */
    lenleft = b1 & 0x7F
    if (lenleft > Int(sigend) - sigp_idx) {
        return -1
    }
    if (sigp[sigp_idx] == 0) {
        /* Not the shortest possible length encoding. */
        return -1
    }
    if (lenleft > MemoryLayout<size_t>.size  /*sizeof(size_t) */) {
        /* The resulting length would exceed the range of a size_t, so
         * certainly longer than the passed array size.
         */
        return -1;
    }
    while (lenleft > 0) {
        ret = (ret << 8) | Int(sigp[sigp_idx])
        if ret + lenleft > Int(sigend) - sigp_idx {
            /* Result exceeds the length of the passed array. */
            return -1
        }
        sigp_idx += 1
        lenleft -= 1
    }
    if (ret < 128) {
        /* Not the shortest possible length encoding. */
        return -1;
    }
    return Int(ret);
}

func secp256k1_der_parse_integer(_ r:inout secp256k1_scalar, _ sig: [UInt8], _ sig_idx: inout Int, _ sigend: UInt) -> Bool
{
    var overflow:Bool = false
    var ra:[UInt8] = [UInt8](repeating:0, count:32)
    var rlen:Int
    if (sig_idx == sigend || sig[sig_idx] != 0x02) {
        /* Not a primitive integer (X.690-0207 8.3.1). */
        return false
    }
    sig_idx += 1
    rlen = secp256k1_der_read_len(sig, &sig_idx, sigend);
    if (rlen <= 0 || sig_idx + rlen > sigend) {
        /* Exceeds bounds or not at least length 1 (X.690-0207 8.3.1).  */
        return false
    }
    if (sig[sig_idx] == 0x00 && rlen > 1 && ((sig[sig_idx+1]) & 0x80) == 0x00) {
        /* Excessive 0x00 padding. */
        return false
    }
    if (sig[sig_idx] == 0xFF && rlen > 1 && ((sig[sig_idx+1]) & 0x80) == 0x80) {
        /* Excessive 0xFF padding. */
        return false
    }
    if ((sig[sig_idx] & 0x80) == 0x80) {
        /* Negative. */
        overflow = true
    }
    while (rlen > 0 && sig[sig_idx] == 0) {
        /* Skip leading zero bytes */
        rlen -= 1
        sig_idx += 1
    }
    if (rlen > 32) {
        overflow = true
    }
    if (!overflow) {
        for i in 0 ..< rlen {
            ra[32+i-rlen] = sig[i+sig_idx]
        }
        secp256k1_scalar_set_b32(&r, ra, &overflow);
    }
    if (overflow) {
        secp256k1_scalar_set_int(&r, 0);
    }
    sig_idx += rlen
    return true
}

func secp256k1_ecdsa_sig_parse(
    _ rr:inout secp256k1_scalar,
    _ rs:inout secp256k1_scalar,
    _ sig:[UInt8],
    _ size:UInt) -> Bool
{
    let sigend = size
    var rlen: Int
    var sig_idx: Int = 0
    if sig_idx == sigend {
        // size is zero
        return false
    }
    if sig[sig_idx] != 0x30 {
        /* The encoding doesn't start with a constructed sequence (X.690-0207 8.9.1). */
        return false
    }
    sig_idx += 1
    rlen = secp256k1_der_read_len(sig, &sig_idx, sigend)
    if rlen < 0 || sig_idx + rlen > sigend {
        /* Tuple exceeds bounds */
        return false
    }
    if sig_idx + rlen != sigend {
        /* Garbage after tuple. */
        return false
    }
    
    if (!secp256k1_der_parse_integer(&rr, sig, &sig_idx, UInt(sigend))) {
        return false
    }
    if (!secp256k1_der_parse_integer(&rs, sig, &sig_idx, UInt(sigend))) {
        return false
    }
    
    if sig_idx != sigend {
        /* Trailing garbage inside tuple. */
        return false
    }
    
    return true
}

func secp256k1_ecdsa_sig_serialize(
    _ sig: inout [UInt8], // size 32
    _ size: inout UInt,
    _ a_ar: secp256k1_scalar,
    _ a_as: secp256k1_scalar) -> Bool
{
    var r:[UInt8] = [UInt8](repeating:0, count:32)
    var s:[UInt8] = [UInt8](repeating:0, count:32)
    var rp_idx: Int = 0
    var sp_idx: Int = 0
    var lenR:Int = 33
    var lenS:Int = 33
    secp256k1_scalar_get_b32(&r, a_ar);
    secp256k1_scalar_get_b32(&s, a_as);
    r.insert(0, at: 0)
    s.insert(0, at: 0)
    while (lenR > 1 && r[rp_idx] == 0 && r[1+rp_idx] < 0x80) {
        lenR -= 1
        rp_idx += 1
    }
    while (lenS > 1 && s[sp_idx] == 0 && s[1+sp_idx] < 0x80) {
        lenS -= 1
        sp_idx += 1
    }
    if (size < 6 + lenS + lenR) {
        size = 6 + UInt(lenS) + UInt(lenR)
        return false
    }
    size = 6 + UInt(lenS) + UInt(lenR)
    sig[0] = 0x30
    sig[1] = 4 + UInt8(lenS) + UInt8(lenR)
    sig[2] = 0x02
    sig[3] = UInt8(lenR)
    for i in 0 ..< lenR {
        sig[4+i] = r[rp_idx+i]
    }
    //memcpy(sig+4, rp, lenR)
        
    sig[4+lenR] = 0x02
    sig[5+lenR] = UInt8(lenS)
    //memcpy(sig+lenR+6, sp, lenS)
    for i in 0 ..< lenS {
        sig[lenR+6+i] = s[sp_idx+i]
    }
    return true
}

func secp256k1_ecdsa_sig_verify(
    _ ctx: secp256k1_ecmult_context,
    _ sigr: secp256k1_scalar,
    _ sigs: secp256k1_scalar,
    _ pubkey: secp256k1_ge,
    _ message: secp256k1_scalar) -> Bool
{
    var c:[UInt8] = [UInt8](repeating: 0, count: 32)
    var sn = secp256k1_scalar()
    var u1 = secp256k1_scalar()
    var u2 = secp256k1_scalar()
    var xr = secp256k1_fe()
    var pubkeyj = secp256k1_gej()
    var pr = secp256k1_gej()
    
    if (secp256k1_scalar_is_zero(sigr) || secp256k1_scalar_is_zero(sigs)) {
        return false
    }
    
    // sn = sigs ^ -1
    secp256k1_scalar_inverse_var(&sn, sigs);
    // u1 = message * (sigs ^ -1)
    secp256k1_scalar_mul(&u1, sn, message);
    // u2 = sigr * (sigs ^ -1)
    secp256k1_scalar_mul(&u2, sn, sigr);
    // affine to jacobian
    secp256k1_gej_set_ge(&pubkeyj, pubkey);
    // calc jacobian point
    // G: base point
    // A: public point
    // pr = u1 * G + u2 * A 
    secp256k1_ecmult(ctx, &pr, pubkeyj, u2, u1);
    if (secp256k1_gej_is_infinity(pr)) {
        return false
    }
    
    // transform sigr to BigEndian 32 bytes
    secp256k1_scalar_get_b32(&c, sigr);
    // transform BigEndian 32 bytes to x point
    let _ = secp256k1_fe_set_b32(&xr, c);
    
    /** We now have the recomputed R point in pr, and its claimed x coordinate (modulo n)
     *  in xr. Naively, we would extract the x coordinate from pr (requiring a inversion modulo p),
     *  compute the remainder modulo n, and compare it to xr. However:
     *
     *        xr == X(pr) mod n
     *    <=> exists h. (xr + h * n < p && xr + h * n == X(pr))
     *    [Since 2 * n > p, h can only be 0 or 1]
     *    <=> (xr == X(pr)) || (xr + n < p && xr + n == X(pr))
     *    [In Jacobian coordinates, X(pr) is pr.x / pr.z^2 mod p]
     *    <=> (xr == pr.x / pr.z^2 mod p) || (xr + n < p && xr + n == pr.x / pr.z^2 mod p)
     *    [Multiplying both sides of the equations by pr.z^2 mod p]
     *    <=> (xr * pr.z^2 mod p == pr.x) || (xr + n < p && (xr + n) * pr.z^2 mod p == pr.x)
     *
     *  Thus, we can avoid the inversion, but we have to check both cases separately.
     *  secp256k1_gej_eq_x implements the (xr * pr.z^2 mod p == pr.x) test.
     */
    // equal affine x point to jacobian pr
    if (secp256k1_gej_eq_x_var(xr, pr)) {
        /* xr * pr.z^2 mod p == pr.x, so the signature is valid. */
        return true
    }
    if (secp256k1_fe_cmp_var(xr, secp256k1_ecdsa_const_p_minus_order) >= 0) {
        /* xr + n >= p, so we can skip testing the second case. */
        return false
    }
    secp256k1_fe_add(&xr, secp256k1_ecdsa_const_order_as_fe);
    if (secp256k1_gej_eq_x_var(xr, pr)) {
        /* (xr + n) * pr.z^2 mod p == pr.x, so the signature is valid. */
        return true
    }
    return false
}

/*
 @param [out] recid   : int     recovery id (0, 1, 2, 3)
 */
func secp256k1_ecdsa_sig_sign(
    _ ctx: secp256k1_ecmult_gen_context,
    _ sigr:inout secp256k1_scalar,
    _ sigs:inout secp256k1_scalar,
    _ seckey: secp256k1_scalar,
    _ message: secp256k1_scalar,
    _ nonce: secp256k1_scalar,
    _ recid: inout Int) -> Bool
{
    var b: [UInt8] = [UInt8](repeating: 0, count: 32)
    var rp = secp256k1_gej()
    var r = secp256k1_ge()
    var n = secp256k1_scalar()
    var overflow:Bool = false
    
    // rp = nonce * G
    secp256k1_ecmult_gen(ctx, &rp, nonce)
    // transform jacobian to affine
    // r = rp
    secp256k1_ge_set_gej(&r, &rp)
    // normalize affine point by mod
    secp256k1_fe_normalize(&r.x)
    secp256k1_fe_normalize(&r.y)
    // x point to BigEndian 32 bytes
    secp256k1_fe_get_b32(&b, r.x)
    // BigEndian 32 bytes to scalar
    // sigr = r.x
    secp256k1_scalar_set_b32(&sigr, b, &overflow)
    /* These two conditions should be checked before calling */
    assert(!secp256k1_scalar_is_zero(sigr))
    assert(!overflow)
    
    /* The overflow condition is cryptographically unreachable as hitting it requires finding the discrete log
     * of some P where P.x >= order, and only 1 in about 2^127 points meet this criteria.
     */
    recid = (overflow ? 2 : 0) | (secp256k1_fe_is_odd(r.y) ? 1 : 0)

    // n = sigr * seckey 
    secp256k1_scalar_mul(&n, sigr, seckey)
    // n = message + sigr * seckey
    let _ = secp256k1_scalar_add(&n, n, message)
    // sigs = nonce ^ -1
    secp256k1_scalar_inverse(&sigs, nonce)
    // sigs = (nonce ^ -1) * (message + sigr * seckey)
    secp256k1_scalar_mul(&sigs, sigs, n)
    // clear 
    secp256k1_scalar_clear(&n)
    secp256k1_gej_clear(&rp)
    secp256k1_ge_clear(&r)

    if (secp256k1_scalar_is_zero(sigs)) {
        return false
    }
    if (secp256k1_scalar_is_high(sigs)) {
        // take near zero, minus is ok
        secp256k1_scalar_negate(&sigs, sigs)
        recid ^= 1
    }
    return true
}
