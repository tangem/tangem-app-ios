//
//  recovery.swift
//  secp256k1
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2018年 pebble8888. All rights reserved.
//
/**********************************************************************
 * Copyright (c) 2013-2015 Pieter Wuille                              *
 * Distributed under the MIT software license, see the accompanying   *
 * file COPYING or http://www.opensource.org/licenses/mit-license.php.*
 **********************************************************************/

import Foundation

/** Opaque data structured that holds a parsed ECDSA signature,
 *  supporting pubkey recovery.
 *
 *  The exact representation of data inside is implementation defined and not
 *  guaranteed to be portable between different platforms or versions. It is
 *  however guaranteed to be 65 bytes in size, and can be safely copied/moved.
 *  If you need to convert to a format suitable for storage or transmission, use
 *  the secp256k1_ecdsa_signature_serialize_* and
 *  secp256k1_ecdsa_signature_parse_* functions.
 *
 *  Furthermore, it is guaranteed that identical signatures (including their
 *  recoverability) will have identical representation, so they can be
 *  memcmp'ed.
 */
public struct secp256k1_ecdsa_recoverable_signature
{
    var data: [UInt8] // 65
    public init(){
        data = [UInt8](repeating: 0, count: 65)
    }
    mutating func clear() {
        for i in 0 ..< 65 {
            data[i] = 0
        }
    }
    func is_valid_len() -> Bool {
        return data.count == 65
    }
}

func secp256k1_ecdsa_recoverable_signature_load(
    _ ctx: secp256k1_context,
    _ r: inout secp256k1_scalar,
    _ s: inout secp256k1_scalar,
    _ recid: inout Int,
    _ sig: secp256k1_ecdsa_recoverable_signature)
{
    
    /*
    if (sizeof(secp256k1_scalar) == 32) {
     */
        /* When the secp256k1_scalar type is exactly 32 byte, use its
         * representation inside secp256k1_ecdsa_signature, as conversion is very fast.
         * Note that secp256k1_ecdsa_signature_save must use the same representation. */
        //memcpy(r, &sig->data[0], 32);
        //memcpy(s, &sig->data[32], 32);
        UInt8ToUInt32LE(&r.d, 0, sig.data, 0, 32)
        UInt8ToUInt32LE(&s.d, 0, sig.data, 32, 32)
        /*
    } else {
    var dummy_overflow: Bool = false
    secp256k1_scalar_set_b32(&r, Array(sig.data[0..<32]), &dummy_overflow)
    secp256k1_scalar_set_b32(&s, Array(sig.data[32..<64]), &dummy_overflow)
    }
     */
    recid = Int(sig.data[64])
}

func secp256k1_ecdsa_recoverable_signature_save(
    _ sig: inout secp256k1_ecdsa_recoverable_signature,
    _ r: secp256k1_scalar,
    _ s: secp256k1_scalar,
    _ recid: Int)
{
    /*
    if (sizeof(secp256k1_scalar) == 32) {
     */
    //memcpy(&sig->data[0], r, 32);
    //memcpy(&sig->data[32], s, 32);
    for i in 0 ..< 8 {
        UInt32LEToUInt8(&sig.data, 4 * i, r.d[i])
    }
    for i in 0 ..< 8 {
        UInt32LEToUInt8(&sig.data, 32 + 4 * i, s.d[i])
    }
    /*
    } else {
        var v1 = [UInt8](repeating: 0, count: 32)
        var v2 = [UInt8](repeating: 0, count: 32)
        secp256k1_scalar_get_b32(&v1, r)
        secp256k1_scalar_get_b32(&v2, s)
        for i in 0 ..< 32 {
            sig.data[i] = v1[i]
            sig.data[32+i] = v2[i]
        }
     }
    */
    sig.data[64] = UInt8(recid)
}

/** Parse a compact ECDSA signature (64 bytes + recovery id).
 *
 *  Returns: 1 when the signature could be parsed, 0 otherwise
 *  Args: ctx:     a secp256k1 context object
 *  Out:  sig:     a pointer to a signature object
 *  In:   input64: a pointer to a 64-byte compact signature
 *        recid:   the recovery id (0, 1, 2 or 3)
 */
public func secp256k1_ecdsa_recoverable_signature_parse_compact(
    _ ctx: secp256k1_context,
    _ sig: inout secp256k1_ecdsa_recoverable_signature,
    _ input64: [UInt8],
    _ recid: Int) -> Bool
{
    var r = secp256k1_scalar()
    var s = secp256k1_scalar()
    var ret: Bool = true
    var overflow: Bool = false
    
    if !ctx.ARG_CHECK(sig.is_valid_len(), "invalid sig") { return false }
    if !ctx.ARG_CHECK(input64.count >= 64, "invalid input64") { return false }
    if !ctx.ARG_CHECK(recid >= 0 && recid <= 3, "invalid recid") { return false }
    
    secp256k1_scalar_set_b32(&r, Array(input64[0..<32]), &overflow);
    ret = ret && !overflow
    secp256k1_scalar_set_b32(&s, Array(input64[32..<64]), &overflow);
    ret = ret && !overflow
    if (ret) {
        secp256k1_ecdsa_recoverable_signature_save(&sig, r, s, recid);
    } else {
        sig.clear()
    }
    return ret;
}

/** Serialize an ECDSA signature in compact format (64 bytes + recovery id).
 *
 *  Returns: 1
 *  Args: ctx:      a secp256k1 context object
 *  Out:  output64: a pointer to a 64-byte array of the compact signature (cannot be NULL)
 *        recid:    a pointer to an integer to hold the recovery id (can be NULL).
 *  In:   sig:      a pointer to an initialized signature object (cannot be NULL)
 */
public func secp256k1_ecdsa_recoverable_signature_serialize_compact(
    _ ctx: secp256k1_context,
    _ output64: inout [UInt8],
    _ recid: inout Int,
    _ sig: secp256k1_ecdsa_recoverable_signature) -> Bool
{
    var r = secp256k1_scalar()
    var s = secp256k1_scalar()
    
    if !ctx.ARG_CHECK(output64.count >= 64, "invalid output64") { return false }
    if !ctx.ARG_CHECK(sig.is_valid_len(), "invalid sig") { return false }
    //ARG_CHECK(recid != NULL);
    
    secp256k1_ecdsa_recoverable_signature_load(ctx, &r, &s, &recid, sig);
    var v1 = [UInt8](repeating: 0, count: 32)
    var v2 = [UInt8](repeating: 0, count: 32)
    secp256k1_scalar_get_b32(&v1, r)
    secp256k1_scalar_get_b32(&v2, s)
    for i in 0 ..< 32 {
        output64[i] = v1[i]
        output64[32+i] = v2[i]
    }
    return true
}

/** Convert a recoverable signature into a normal signature.
 *
 *  Returns: 1
 *  Out: sig:    a pointer to a normal signature (cannot be NULL).
 *  In:  sigin:  a pointer to a recoverable signature (cannot be NULL).
 */
public func secp256k1_ecdsa_recoverable_signature_convert(
    _ ctx: secp256k1_context,
    _ sig: inout secp256k1_ecdsa_signature,
    _ sigin: secp256k1_ecdsa_recoverable_signature) -> Bool
{
    var r = secp256k1_scalar()
    var s = secp256k1_scalar()
    var recid: Int = 0
    
    if !ctx.ARG_CHECK(sig.is_valid_len(), "invalid sig") { return false }
    if !ctx.ARG_CHECK(sigin.is_valid_len(), "invalid isgin") { return false }
    
    secp256k1_ecdsa_recoverable_signature_load(ctx, &r, &s, &recid, sigin);
    secp256k1_ecdsa_signature_save(&sig, r, s)
    return true
}

func secp256k1_ecdsa_sig_recover(
    _ ctx:  secp256k1_ecmult_context,
    _ sigr: secp256k1_scalar,
    _ sigs: secp256k1_scalar,
    _ pubkey: inout secp256k1_ge,
    _ message: secp256k1_scalar,
    _ recid: Int) -> Bool
{
    var brx = [UInt8](repeating: 0, count: 32)
    var fx = secp256k1_fe()
    var x = secp256k1_ge()
    var xj = secp256k1_gej()
    var rn = secp256k1_scalar()
    var u1 = secp256k1_scalar()
    var u2 = secp256k1_scalar()
    var qj = secp256k1_gej()
    var r:Bool
    
    if (secp256k1_scalar_is_zero(sigr) || secp256k1_scalar_is_zero(sigs)) {
        return false
    }
    
    secp256k1_scalar_get_b32(&brx, sigr);
    r = secp256k1_fe_set_b32(&fx, brx);
    VERIFY_CHECK(r) /* brx comes from a scalar, so is less than the order; certainly less than p */
    if (recid & 2) != 0 {
        if (secp256k1_fe_cmp_var(fx, secp256k1_ecdsa_const_p_minus_order) >= 0) {
            return false
        }
        secp256k1_fe_add(&fx, secp256k1_ecdsa_const_order_as_fe);
    }
    if (!secp256k1_ge_set_xo_var(&x, fx, (recid & 1) != 0)) {
        return false
    }
    secp256k1_gej_set_ge(&xj, x);
    secp256k1_scalar_inverse_var(&rn, sigr);
    secp256k1_scalar_mul(&u1, rn, message);
    secp256k1_scalar_negate(&u1, u1);
    secp256k1_scalar_mul(&u2, rn, sigs);
    secp256k1_ecmult(ctx, &qj, xj, u2, u1);
    secp256k1_ge_set_gej_var(&pubkey, &qj);
    return !secp256k1_gej_is_infinity(qj);
}

/** Create a recoverable ECDSA signature.
 *
 *  Returns: 1: signature created
 *           0: the nonce generation function failed, or the private key was invalid.
 *  Args:    ctx:    pointer to a context object, initialized for signing (cannot be NULL)
 *  Out:     sig:    pointer to an array where the signature will be placed (cannot be NULL)
 *  In:      msg32:  the 32-byte message hash being signed (cannot be NULL)
 *           seckey: pointer to a 32-byte secret key (cannot be NULL)
 *           noncefp:pointer to a nonce generation function. If NULL, secp256k1_nonce_function_default is used
 *           ndata:  pointer to arbitrary data used by the nonce generation function (can be NULL)
 */
public func secp256k1_ecdsa_sign_recoverable(
    _ ctx: secp256k1_context,
    _ signature: inout secp256k1_ecdsa_recoverable_signature,
    _ msg32: [UInt8],
    _ seckey: [UInt8],
    _ noncefp: secp256k1_nonce_function?,
    _ noncedata:[UInt8]?) -> Bool
{
    var r = secp256k1_scalar()
    var s = secp256k1_scalar()
    var sec = secp256k1_scalar()
    var non = secp256k1_scalar()
    var msg = secp256k1_scalar()
    var recid: Int = 0
    var ret: Bool = false
    var overflow: Bool = false
    if !ctx.ARG_CHECK(secp256k1_ecmult_gen_context_is_built(ctx.ecmult_gen_ctx), "invalid context") { return false }
    if !ctx.ARG_CHECK(msg32.count == 32, "invalid msg32") { return false }
    if !ctx.ARG_CHECK(signature.is_valid_len(), "invalid signature") { return false }
    if !ctx.ARG_CHECK(seckey.count == 32, "invalid seckey") { return false }
    var v_noncefp: secp256k1_nonce_function
    if let v = noncefp {
        v_noncefp = v
    } else {
        v_noncefp = secp256k1_nonce_function_default
    }
    
    secp256k1_scalar_set_b32(&sec, seckey, &overflow)
    /* Fail if the secret key is invalid. */
    if !overflow && !secp256k1_scalar_is_zero(sec) {
        var nonce32 = [UInt8](repeating: 0, count: 32)
        var count: UInt = 0
        var dummy_overflow: Bool = false
        secp256k1_scalar_set_b32(&msg, msg32, &dummy_overflow)
        while true {
            ret = v_noncefp(&nonce32, msg32, seckey, nil, noncedata, count)
            if !ret {
                break
            }
            secp256k1_scalar_set_b32(&non, nonce32, &overflow)
            if !secp256k1_scalar_is_zero(non) && !overflow {
                if secp256k1_ecdsa_sig_sign(ctx.ecmult_gen_ctx, &r, &s, sec, msg, non, &recid) {
                    break
                }
            }
            count += 1
        }
        for i in 0 ..< 32 {
            nonce32[i] = 0
        }
        secp256k1_scalar_clear(&msg)
        secp256k1_scalar_clear(&non)
        secp256k1_scalar_clear(&sec)
    }
    if (ret) {
        secp256k1_ecdsa_recoverable_signature_save(&signature, r, s, recid)
    } else {
        signature.clear()
    }
    return ret
}

/** Recover an ECDSA public key from a signature.
 *
 *  Returns: 1: public key successfully recovered (which guarantees a correct signature).
 *           0: otherwise.
 *  Args:    ctx:        pointer to a context object, initialized for verification (cannot be NULL)
 *  Out:     pubkey:     pointer to the recovered public key (cannot be NULL)
 *  In:      sig:        pointer to initialized signature that supports pubkey recovery (cannot be NULL)
 *           msg32:      the 32-byte message hash assumed to be signed (cannot be NULL)
 */
public func secp256k1_ecdsa_recover(
    _ ctx: secp256k1_context,
    _ pubkey: inout secp256k1_pubkey,
    _ signature: secp256k1_ecdsa_recoverable_signature,
    _ msg32: [UInt8]) -> Bool
{
    var q = secp256k1_ge()
    var r = secp256k1_scalar()
    var s = secp256k1_scalar()
    var m = secp256k1_scalar()
    var recid:Int = 0
    if !ctx.ARG_CHECK(secp256k1_ecmult_context_is_built(ctx.ecmult_ctx), "invalid context") { return false }
    if !ctx.ARG_CHECK(msg32.count == 32, "invalid msg") { return false }
    if !ctx.ARG_CHECK(signature.is_valid_len(), "invalid signature") { return false }
    if !ctx.ARG_CHECK(pubkey.is_valid_len(), "invalid pubkey") { return false }
    
    secp256k1_ecdsa_recoverable_signature_load(ctx, &r, &s, &recid, signature);
    VERIFY_CHECK(recid >= 0 && recid < 4);  /* should have been caught in parse_compact */
    var dummy_overflow: Bool = false
    secp256k1_scalar_set_b32(&m, msg32, &dummy_overflow)
    if (secp256k1_ecdsa_sig_recover(ctx.ecmult_ctx, r, s, &q, m, recid)) {
        secp256k1_pubkey_save(&pubkey, &q)
        return true
    } else {
        pubkey.clear()
        return false
    }
}
