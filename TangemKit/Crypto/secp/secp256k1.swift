//
//  secp256k1.swift
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

/* These rules specify the order of arguments in API calls:
 *
 * 1. Context pointers go first, followed by output arguments, combined
 *    output/input arguments, and finally input-only arguments.
 * 2. Array lengths always immediately the follow the argument whose length
 *    they describe, even if this violates rule 1.
 * 3. Within the OUT/OUTIN/IN groups, pointers to data that is typically generated
 *    later go first. This means: signatures, public nonces, private nonces,
 *    messages, public keys, secret keys, tweaks.
 * 4. Arguments that are not data pointers go last, from more complex to less
 *    complex: function pointers, algorithm names, messages, void pointers,
 *    counts, flags, booleans.
 * 5. Opaque data pointers follow the function pointer they are to be passed to.
 */

/** Opaque data structure that holds context information (precomputed tables etc.).
 *
 *  The purpose of context structures is to cache large precomputed data tables
 *  that are expensive to construct, and also to maintain the randomization data
 *  for blinding.
 *
 *  Do not create a new context object for each operation, as construction is
 *  far slower than all other API calls (~100 times slower than an ECDSA
 *  verification).
 *
 *  A constructed context can safely be used from multiple threads
 *  simultaneously, but API call that take a non-const pointer to a context
 *  need exclusive access to it. In particular this is the case for
 *  secp256k1_context_destroy and secp256k1_context_randomize.
 *
 *  Regarding randomization, either do it once at creation time (in which case
 *  you do not need any locking for the other calls), or use a read-write lock.
 */

/** Opaque data structure that holds a parsed and valid public key.
 *
 *  The exact representation of data inside is implementation defined and not
 *  guaranteed to be portable between different platforms or versions. It is
 *  however guaranteed to be 64 bytes in size, and can be safely copied/moved.
 *  If you need to convert to a format suitable for storage, transmission, or
 *  comparison, use secp256k1_ec_pubkey_serialize and secp256k1_ec_pubkey_parse.
 */
public struct secp256k1_pubkey : CustomDebugStringConvertible {
    public var data:[UInt8] // size:64
    public mutating func clear(){
        data = [UInt8](repeating: 0, count: 64)
    }
    public init()
    {
        data = [UInt8](repeating: 0, count: 64)
    }
    
    public func is_valid_len() -> Bool {
        return data.count == 64
    }
    
    public func equal(_ rhs:secp256k1_pubkey) -> Bool
    {
        if !is_valid_len() { return false }
        if !rhs.is_valid_len() { return false }
        for i in 0..<64 {
            if self.data[i] != rhs.data[i] {
                return false
            }
        }
        return true
    }
    public var debugDescription: String {
        return data.hexDescription(separator: " ")
    }
    func is_zero() -> Bool {
        if !is_valid_len() { return false }
        for i in 0 ..< 64 {
            if data[i] != 0 {
                return false
            }
        }
        return true
    }
    func is_zero_first_half() -> Bool {
        if !is_valid_len() { return false }
        for i in 0 ..< 32 {
            if data[i] != 0 {
                return false
            }
        }
        return true
    }
    func is_zero_second_half() -> Bool {
        if !is_valid_len() { return false }
        for i in 32 ..< 64 {
            if data[i] != 0 {
                return false
            }
        }
        return true
    }
}

extension secp256k1_pubkey : Equatable {
    public static func ==(lhs: secp256k1_pubkey, rhs: secp256k1_pubkey) -> Bool {
        return lhs.equal(rhs)
    }
}

/** Opaque data structured that holds a parsed ECDSA signature.
 *
 *  The exact representation of data inside is implementation defined and not
 *  guaranteed to be portable between different platforms or versions. It is
 *  however guaranteed to be 64 bytes in size, and can be safely copied/moved.
 *  If you need to convert to a format suitable for storage, transmission, or
 *  comparison, use the secp256k1_ecdsa_signature_serialize_* and
 *  secp256k1_ecdsa_signature_parse_* functions.
 */
public struct secp256k1_ecdsa_signature : CustomDebugStringConvertible {
    public var data:[UInt8] // size:64
    public mutating func clear() {
        data = [UInt8](repeating: 0, count: 64)
    }
    public init()
    {
        data = [UInt8](repeating: 0, count: 64)
    }
    public func is_valid_len() -> Bool {
        return data.count == 64
    }
    public var debugDescription: String {
        return data.hexDescription(separator: " ")
    }
    public func equal(_ lhs: secp256k1_ecdsa_signature) -> Bool {
        if !is_valid_len() { return false }
        if !lhs.is_valid_len() { return false }
        for i in 0 ..< 64 {
            if data[i] != lhs.data[i] {
                return false
            }
        }
        return true
    }
    public func is_zero() -> Bool {
        if !is_valid_len() { return false }
        for i in 0 ..< 64 {
            if data[i] != 0 {
                return false
            }
        }
        return true
    }
}

extension secp256k1_ecdsa_signature : Equatable {
    public static func ==(lhs: secp256k1_ecdsa_signature, rhs: secp256k1_ecdsa_signature) -> Bool {
        return lhs.equal(rhs)
    }
}

/** A pointer to a function to deterministically generate a nonce.
 *
 * Returns: 1 if a nonce was successfully generated. 0 will cause signing to fail.
 * Out:     nonce32:   pointer to a 32-byte array to be filled by the function.
 * In:      msg32:     the 32-byte message hash being verified (will not be NULL)
 *          key32:     pointer to a 32-byte secret key (will not be NULL)
 *          algo16:    pointer to a 16-byte array describing the signature
 *                     algorithm (will be NULL for ECDSA for compatibility).
 *          data:      Arbitrary data pointer that is passed through.
 *          attempt:   how many iterations we have tried to find a nonce.
 *                     This will almost always be 0, but different attempt values
 *                     are required to result in a different nonce.
 *
 * Except for test cases, this function should compute some cryptographic hash of
 * the message, the algorithm, the key and the attempt.
 */
public typealias secp256k1_nonce_function = (
    _ nonce32: inout [UInt8],
    _ msg32: [UInt8],
    _ key32:[UInt8],
    _ algo16:[UInt8]?,
    _ data: [UInt8]?,
    _ counter: UInt
) -> Bool

public struct SECP256K1_FLAGS: OptionSet {
    public let rawValue: UInt
    public init(rawValue: UInt){
        self.rawValue = rawValue
    }
    /** All flags' lower 8 bits indicate what they're for. Do not use directly. */
    static let SECP256K1_FLAGS_TYPE_MASK: SECP256K1_FLAGS
        = [.SECP256K1_FLAGS_TYPE_CONTEXT, .SECP256K1_FLAGS_TYPE_COMPRESSION]
    static let SECP256K1_FLAGS_TYPE_CONTEXT = SECP256K1_FLAGS(rawValue: 1 << 0)
    static let SECP256K1_FLAGS_TYPE_COMPRESSION = SECP256K1_FLAGS(rawValue: 1 << 1)
    /** The higher bits contain the actual data. Do not use directly. */
    static let SECP256K1_FLAGS_BIT_CONTEXT_VERIFY = SECP256K1_FLAGS(rawValue: 1 << 8)
    static let SECP256K1_FLAGS_BIT_CONTEXT_SIGN = SECP256K1_FLAGS(rawValue: 1 << 9)
    static let SECP256K1_FLAGS_BIT_COMPRESSION = SECP256K1_FLAGS(rawValue: 1 << 8)
    /** Flags to pass to secp256k1_context_create. */
    public static let SECP256K1_CONTEXT_VERIFY: SECP256K1_FLAGS = [SECP256K1_FLAGS_TYPE_CONTEXT, SECP256K1_FLAGS_BIT_CONTEXT_VERIFY]
    public static let SECP256K1_CONTEXT_SIGN: SECP256K1_FLAGS = [SECP256K1_FLAGS_TYPE_CONTEXT, SECP256K1_FLAGS_BIT_CONTEXT_SIGN]
    public static let SECP256K1_CONTEXT_NONE: SECP256K1_FLAGS = [SECP256K1_FLAGS_TYPE_CONTEXT]
    /** Flag to pass to secp256k1_ec_pubkey_serialize and secp256k1_ec_privkey_export. */
    public static let SECP256K1_EC_COMPRESSED: SECP256K1_FLAGS = [SECP256K1_FLAGS_TYPE_COMPRESSION, SECP256K1_FLAGS_BIT_COMPRESSION]
    public static let SECP256K1_EC_UNCOMPRESSED: SECP256K1_FLAGS = [SECP256K1_FLAGS_TYPE_COMPRESSION]
    public static let ALL: SECP256K1_FLAGS = [
        SECP256K1_FLAGS_TYPE_CONTEXT,
        SECP256K1_FLAGS_TYPE_COMPRESSION,
        SECP256K1_FLAGS_BIT_CONTEXT_VERIFY,
        SECP256K1_FLAGS_BIT_CONTEXT_SIGN,
        SECP256K1_FLAGS_BIT_COMPRESSION
    ]
}

/** Prefix byte used to tag various encoded curvepoints for specific purposes */
let SECP256K1_TAG_PUBKEY_EVEN: UInt8 = 0x02
let SECP256K1_TAG_PUBKEY_ODD: UInt8 = 0x03
let SECP256K1_TAG_PUBKEY_UNCOMPRESSED: UInt8 = 0x04
let SECP256K1_TAG_PUBKEY_HYBRID_EVEN: UInt8 = 0x06
let SECP256K1_TAG_PUBKEY_HYBRID_ODD: UInt8 = 0x07

extension secp256k1_context {
    func ARG_CHECK(_ cond: Bool, _ text: String) -> Bool {
        if !cond {
            secp256k1_callback_call(self.illegal_callback, text)
            return false
        }
        return true
    }
}

func default_illegal_callback_fn(_ str: String, _ data: UnsafeMutableRawPointer?) {
    fatalError("[libsecp256k1] illegal argument: \(str)\n")
}

let default_illegal_callback = secp256k1_callback(
    fn: default_illegal_callback_fn,
    data: nil
)

func default_error_callback_fn(_ str: String, _ data: UnsafeMutableRawPointer?) {
    fatalError("[libsecp256k1] internal consistency check failed: \(str)\n");
}

fileprivate let default_error_callback = secp256k1_callback(
    fn: default_error_callback_fn,
    data: nil
)

public struct secp256k1_context : CustomDebugStringConvertible {
    var ecmult_ctx:         secp256k1_ecmult_context
    var ecmult_gen_ctx:     secp256k1_ecmult_gen_context
    var illegal_callback:   secp256k1_callback
    var error_callback:     secp256k1_callback
    init(){
        ecmult_ctx = secp256k1_ecmult_context()
        ecmult_gen_ctx = secp256k1_ecmult_gen_context()
        illegal_callback = default_illegal_callback
        error_callback = default_error_callback
    }
    public var debugDescription: String {
        return "\(ecmult_ctx)\n\(ecmult_gen_ctx)"
    }
}

/** Create a secp256k1 context object.
 *
 *  Returns: a newly created context object.
 *  In:      flags: which parts of the context to initialize.
 *
 *  See also secp256k1_context_randomize.
 */
public func secp256k1_context_create(_ flags: SECP256K1_FLAGS) -> secp256k1_context? {
    var ret: secp256k1_context = secp256k1_context()
    
    if !flags.contains(.SECP256K1_FLAGS_TYPE_CONTEXT) {
        secp256k1_callback_call(ret.illegal_callback, "Invalid flags");
        return nil
    }
    
    secp256k1_ecmult_context_init(&ret.ecmult_ctx);
    secp256k1_ecmult_gen_context_init(&ret.ecmult_gen_ctx);
    
    if flags.contains(.SECP256K1_FLAGS_BIT_CONTEXT_SIGN) {
        secp256k1_ecmult_gen_context_build(&ret.ecmult_gen_ctx, ret.error_callback);
    }
    if flags.contains(.SECP256K1_FLAGS_BIT_CONTEXT_VERIFY) {
        secp256k1_ecmult_context_build(&ret.ecmult_ctx, ret.error_callback);
    }
    
    return ret
}

/** Copies a secp256k1 context object.
 *
 *  Returns: a newly created context object.
 *  Args:    ctx: an existing context to copy (cannot be NULL)
 */
public func secp256k1_context_clone(_ ctx: secp256k1_context) -> secp256k1_context {
    var ret: secp256k1_context = secp256k1_context()
    ret.illegal_callback = ctx.illegal_callback
    ret.error_callback = ctx.error_callback
    secp256k1_ecmult_context_clone(&ret.ecmult_ctx, ctx.ecmult_ctx, ctx.error_callback)
    secp256k1_ecmult_gen_context_clone(&ret.ecmult_gen_ctx, ctx.ecmult_gen_ctx, ctx.error_callback)
    return ret
}

/** Destroy a secp256k1 context object.
 *
 *  The context pointer may not be used afterwards.
 *  Args:   ctx: an existing context to destroy (cannot be NULL)
 */
public func secp256k1_context_destroy(_ ctx: inout secp256k1_context) {
    secp256k1_ecmult_context_clear(&ctx.ecmult_ctx);
    secp256k1_ecmult_gen_context_clear(&ctx.ecmult_gen_ctx);
}

/** Set a callback function to be called when an illegal argument is passed to
 *  an API call. It will only trigger for violations that are mentioned
 *  explicitly in the header.
 *
 *  The philosophy is that these shouldn't be dealt with through a
 *  specific return value, as calling code should not have branches to deal with
 *  the case that this code itself is broken.
 *
 *  On the other hand, during debug stage, one would want to be informed about
 *  such mistakes, and the default (crashing) may be inadvisable.
 *  When this callback is triggered, the API function called is guaranteed not
 *  to cause a crash, though its return value and output arguments are
 *  undefined.
 *
 *  Args: ctx:  an existing context object (cannot be NULL)
 *  In:   fun:  a pointer to a function to call when an illegal argument is
 *              passed to the API, taking a message and an opaque pointer
 *              (NULL restores a default handler that calls abort).
 *        data: the opaque pointer to pass to fun above.
 */
public func secp256k1_context_set_illegal_callback(_ ctx: inout secp256k1_context,
    _ fn: ((_ message: String, _ data: UnsafeMutableRawPointer?) -> Void)?,
    _ data: UnsafeMutableRawPointer?)
{
    if let fn = fn {
        ctx.illegal_callback.fn = fn
    } else {
        ctx.illegal_callback.fn = default_illegal_callback_fn
    }
    ctx.illegal_callback.data = data
}

/** Set a callback function to be called when an internal consistency check
 *  fails. The default is crashing.
 *
 *  This can only trigger in case of a hardware failure, miscompilation,
 *  memory corruption, serious bug in the library, or other error would can
 *  otherwise result in undefined behaviour. It will not trigger due to mere
 *  incorrect usage of the API (see secp256k1_context_set_illegal_callback
 *  for that). After this callback returns, anything may happen, including
 *  crashing.
 *
 *  Args: ctx:  an existing context object (cannot be NULL)
 *  In:   fun:  a pointer to a function to call when an internal error occurs,
 *              taking a message and an opaque pointer (NULL restores a default
 *              handler that calls abort).
 *        data: the opaque pointer to pass to fun above.
 */
public func secp256k1_context_set_error_callback(_ ctx: inout secp256k1_context,
    _ fn: ((_ message: String, _ data: UnsafeMutableRawPointer?) -> Void)?,
    _ data: UnsafeMutableRawPointer?)
{
    if let fn = fn {
        ctx.error_callback.fn = fn
    } else {
        ctx.error_callback.fn = default_error_callback_fn
    }
    ctx.error_callback.data = data
}

func secp256k1_pubkey_load(_ ctx: secp256k1_context, _ ge: inout secp256k1_ge, _ pubkey: secp256k1_pubkey) -> Bool
{
    assert(pubkey.is_valid_len())
    /*
    if (sizeof(secp256k1_ge_storage) == 64) {
     */
        /* When the secp256k1_ge_storage type is exactly 64 byte, use its
         * representation inside secp256k1_pubkey, as conversion is very fast.
         * Note that secp256k1_pubkey_save must use the same representation. */
        var s = secp256k1_ge_storage()
        //memcpy(&s, &pubkey.data[0], 64);
        UInt8ToUInt32LE(&s.x.n, 0, pubkey.data, 0, 32)
        UInt8ToUInt32LE(&s.y.n, 0, pubkey.data, 32, 32)
        secp256k1_ge_from_storage(&ge, s);
    /*
    } else {
        /* Otherwise, fall back to 32-byte big endian for X and Y. */
        var x = secp256k1_fe()
        var y = secp256k1_fe()
        let _ = secp256k1_fe_set_b32(&x, Array(pubkey.data[0..<32]))
        let _ = secp256k1_fe_set_b32(&y, Array(pubkey.data[32..<64]))
        secp256k1_ge_set_xy(&ge, x, y);
    }
     */
    if !ctx.ARG_CHECK(!secp256k1_fe_is_zero(ge.x), "invalid ge") { return false }
    return true
}

func secp256k1_pubkey_save(_ pubkey: inout secp256k1_pubkey, _ ge: inout secp256k1_ge) {
    /*
    if (sizeof(secp256k1_ge_storage) == 64) {
     */
        var s = secp256k1_ge_storage()
        secp256k1_ge_to_storage(&s, ge);
        //memcpy(&pubkey.data[0], &s, 64);
        for i in 0 ..< 8 {
            UInt32LEToUInt8(&pubkey.data, 4*i, s.x.n[i])
        }
        for i in 0 ..< 8 {
            UInt32LEToUInt8(&pubkey.data, 32 + 4*i, s.y.n[i])
        }
    /*
    } else {
    //VERIFY_CHECK(!secp256k1_ge_is_infinity(ge));
    secp256k1_fe_normalize_var(&ge.x);
    secp256k1_fe_normalize_var(&ge.y);
    var v1 = [UInt8](repeating: 0, count: 32)
    var v2 = [UInt8](repeating: 0, count: 32)
    secp256k1_fe_get_b32(&v1, ge.x)
    secp256k1_fe_get_b32(&v2, ge.y)
    for i in 0..<32 {
        pubkey.data[i] = v1[i]
        pubkey.data[32+i] = v2[i]
    }
    }
     */
}

/** Parse a variable-length public key into the pubkey object.
 *
 *  Returns: 1 if the public key was fully valid.
 *           0 if the public key could not be parsed or is invalid.
 *  Args: ctx:      a secp256k1 context object.
 *  Out:  pubkey:   pointer to a pubkey object. If 1 is returned, it is set to a
 *                  parsed version of input. If not, its value is undefined.
 *  In:   input:    pointer to a serialized public key
 *        inputlen: length of the array pointed to by input
 *
 *  This function supports parsing compressed (33 bytes, header byte 0x02 or
 *  0x03), uncompressed (65 bytes, header byte 0x04), or hybrid (65 bytes, header
 *  byte 0x06 or 0x07) format public keys.
 */
public func secp256k1_ec_pubkey_parse(_ ctx: secp256k1_context, _ pubkey: inout secp256k1_pubkey, _ input: [UInt8], _ inputlen: UInt) -> Bool
{
    var Q = secp256k1_ge()
    let _ = ctx.ARG_CHECK(input.count != 0, "")
    pubkey.clear()
    if (!secp256k1_eckey_pubkey_parse(&Q, input, inputlen)) {
        return false
    }
    secp256k1_pubkey_save(&pubkey, &Q);
    secp256k1_ge_clear(&Q);
    return true
}

/** Serialize a pubkey object into a serialized byte sequence.
 *
 *  Returns: 1 always.
 *  Args:   ctx:        a secp256k1 context object.
 *  Out:    output:     a pointer to a 65-byte (if compressed==0) or 33-byte (if
 *                      compressed==1) byte array to place the serialized key
 *                      in.
 *  In/Out: outputlen:  a pointer to an integer which is initially set to the
 *                      size of output, and is overwritten with the written
 *                      size.
 *  In:     pubkey:     a pointer to a secp256k1_pubkey containing an
 *                      initialized public key.
 *          flags:      SECP256K1_EC_COMPRESSED if serialization should be in
 *                      compressed format, otherwise SECP256K1_EC_UNCOMPRESSED.
 */
public func secp256k1_ec_pubkey_serialize(_ ctx: secp256k1_context, _ output: inout [UInt8], _ outputlen: inout UInt, _ pubkey: secp256k1_pubkey, _ flags: SECP256K1_FLAGS) -> Bool
{
    var Q = secp256k1_ge()
    var len: UInt
    var ret: Bool = false
    
    if !ctx.ARG_CHECK(outputlen >= (flags.contains(.SECP256K1_FLAGS_BIT_COMPRESSION) ? 33 : 65), "invalid outputlen and flags") { return false }
    len = outputlen
    outputlen = 0
    if !ctx.ARG_CHECK(output.count >= len, "insufficient output length") { return false }
    for i in 0 ..< output.count {
        output[i] = 0
    }
    if !ctx.ARG_CHECK(pubkey.is_valid_len(), "invalid pubkey") { return false }
    let val: Bool = (flags.intersection(.SECP256K1_FLAGS_TYPE_MASK) == SECP256K1_FLAGS.SECP256K1_FLAGS_TYPE_COMPRESSION)
    if !ctx.ARG_CHECK(val, "invalid flags") { return false }
    if (secp256k1_pubkey_load(ctx, &Q, pubkey)) {
        ret = secp256k1_eckey_pubkey_serialize(&Q, &output, &len, flags.contains(.SECP256K1_FLAGS_BIT_COMPRESSION))
        if (ret) {
            outputlen = len;
        }
    }
    return ret;
}

func secp256k1_ecdsa_signature_load(_ ctx: secp256k1_context, _ r: inout secp256k1_scalar, _ s: inout secp256k1_scalar, _ sig: secp256k1_ecdsa_signature)
{
    //(void)ctx;
    /*
    if (sizeof(secp256k1_scalar) == 32) {
        /* When the secp256k1_scalar type is exactly 32 byte, use its
         * representation inside secp256k1_ecdsa_signature, as conversion is very fast.
         * Note that secp256k1_ecdsa_signature_save must use the same representation. */
        memcpy(r, &sig->data[0], 32);
        memcpy(s, &sig->data[32], 32);
    } else {
     */
        var dummy: Bool = false
        secp256k1_scalar_set_b32(&r, sig.data, &dummy)
        secp256k1_scalar_set_b32(&s, Array(sig.data[32..<64]), &dummy)
    /*
    }
     */
}

func secp256k1_ecdsa_signature_save(_ sig: inout secp256k1_ecdsa_signature, _ r: secp256k1_scalar, _ s: secp256k1_scalar)
{
    /*
    if (sizeof(secp256k1_scalar) == 32) {
        memcpy(&sig->data[0], r, 32);
        memcpy(&sig->data[32], s, 32);
    } else {
     */
        var v1 = [UInt8](repeating: 0, count: 32)
        var v2 = [UInt8](repeating: 0, count: 32)
        secp256k1_scalar_get_b32(&v1, r);
        secp256k1_scalar_get_b32(&v2, s);
        for i in 0..<32 {
            sig.data[i] = v1[i]
            sig.data[32+i] = v2[i]
        }
    /*
    }
    */
}

/** Parse a DER ECDSA signature.
 *
 *  Returns: 1 when the signature could be parsed, 0 otherwise.
 *  Args: ctx:      a secp256k1 context object
 *  Out:  sig:      a pointer to a signature object
 *  In:   input:    a pointer to the signature to be parsed
 *        inputlen: the length of the array pointed to be input
 *
 *  This function will accept any valid DER encoded signature, even if the
 *  encoded numbers are out of range.
 *
 *  After the call, sig will always be initialized. If parsing failed or the
 *  encoded numbers are out of range, signature validation with it is
 *  guaranteed to fail for every message and public key.
 */
public func secp256k1_ecdsa_signature_parse_der(_ ctx: secp256k1_context, _ sig: inout secp256k1_ecdsa_signature, _ input: [UInt8], _ inputlen: UInt) -> Bool
{
    var r: secp256k1_scalar = secp256k1_scalar()
    var s: secp256k1_scalar = secp256k1_scalar()
    if !ctx.ARG_CHECK(sig.is_valid_len(), "invalid sig") { return false }
    if !ctx.ARG_CHECK(input.count >= inputlen, "invalid input") { return false }
    
    if secp256k1_ecdsa_sig_parse(&r, &s, input, inputlen) {
        secp256k1_ecdsa_signature_save(&sig, r, s)
        return true
    } else {
        //memset(sig, 0, sizeof(*sig));
        sig.clear()
        return false
    }
}

/** Parse an ECDSA signature in compact (64 bytes) format.
 *
 *  Returns: 1 when the signature could be parsed, 0 otherwise.
 *  Args: ctx:      a secp256k1 context object
 *  Out:  sig:      a pointer to a signature object
 *  In:   input64:  a pointer to the 64-byte array to parse
 *
 *  The signature must consist of a 32-byte big endian R value, followed by a
 *  32-byte big endian S value. If R or S fall outside of [0..order-1], the
 *  encoding is invalid. R and S with value 0 are allowed in the encoding.
 *
 *  After the call, sig will always be initialized. If parsing failed or R or
 *  S are zero, the resulting sig value is guaranteed to fail validation for any
 *  message and public key.
 */
public func secp256k1_ecdsa_signature_parse_compact(_ ctx: secp256k1_context, _ sig: inout secp256k1_ecdsa_signature, _ input64: [UInt8]) -> Bool
{
    var r = secp256k1_scalar()
    var s = secp256k1_scalar()
    var ret: Bool = true
    var overflow: Bool = false
    
    if !ctx.ARG_CHECK(sig.is_valid_len(), "invalid sig") { return false }
    if !ctx.ARG_CHECK(input64.count >= 64, "invalid input64") { return false }
    
    secp256k1_scalar_set_b32(&r, input64, &overflow);
    ret = ret && !overflow
    secp256k1_scalar_set_b32(&s, Array(input64[32..<64]), &overflow);
    ret = ret && !overflow
    if (ret) {
        secp256k1_ecdsa_signature_save(&sig, r, s)
    } else {
        sig.clear()
    }
    return ret;
}

/** Serialize an ECDSA signature in DER format.
 *
 *  Returns: 1 if enough space was available to serialize, 0 otherwise
 *  Args:   ctx:       a secp256k1 context object
 *  Out:    output:    a pointer to an array to store the DER serialization
 *  In/Out: outputlen: a pointer to a length integer. Initially, this integer
 *                     should be set to the length of output. After the call
 *                     it will be set to the length of the serialization (even
 *                     if 0 was returned).
 *  In:     sig:       a pointer to an initialized signature object
 */
public func secp256k1_ecdsa_signature_serialize_der(_ ctx: secp256k1_context, _ output: inout [UInt8], _ outputlen: inout UInt, _ sig: secp256k1_ecdsa_signature) -> Bool
{
    var r = secp256k1_scalar()
    var s = secp256k1_scalar()
    if !ctx.ARG_CHECK(output.count >= outputlen, "invalid output") { return false }
    if !ctx.ARG_CHECK(outputlen > 0, "invalid outputlen") { return false }
    if !ctx.ARG_CHECK(sig.is_valid_len(), "invalid sig") { return false }

    secp256k1_ecdsa_signature_load(ctx, &r, &s, sig);
    return secp256k1_ecdsa_sig_serialize(&output, &outputlen, r, s);
}

/** Serialize an ECDSA signature in compact (64 byte) format.
 *
 *  Returns: 1
 *  Args:   ctx:       a secp256k1 context object
 *  Out:    output64:  a pointer to a 64-byte array to store the compact serialization
 *  In:     sig:       a pointer to an initialized signature object
 *
 *  See secp256k1_ecdsa_signature_parse_compact for details about the encoding.
 */
public func secp256k1_ecdsa_signature_serialize_compact(_ ctx: secp256k1_context, _ output64: inout [UInt8], _ sig: secp256k1_ecdsa_signature) -> Bool
{
    var r = secp256k1_scalar()
    var s = secp256k1_scalar()
    
    if !ctx.ARG_CHECK(output64.count >= 64, "invalid output64") { return false }
    if !ctx.ARG_CHECK(sig.is_valid_len(), "invalid sig") { return false }
    
    secp256k1_ecdsa_signature_load(ctx, &r, &s, sig);
    var v1 = [UInt8](repeating: 0, count: 32)
    var v2 = [UInt8](repeating: 0, count: 32)
    secp256k1_scalar_get_b32(&v1, r);
    secp256k1_scalar_get_b32(&v2, s);
    for i in 0..<32 {
        output64[i] = v1[i]
        output64[32+i] = v2[i]
    }
    return true
}

/** Convert a signature to a normalized lower-S form.
 *
 *  Returns: 1 if sigin was not normalized, 0 if it already was.
 *  Args: ctx:    a secp256k1 context object
 *  Out:  sigout: a pointer to a signature to fill with the normalized form,
 *                or copy if the input was already normalized. (can be NULL if
 *                you're only interested in whether the input was already
 *                normalized).
 *  In:   sigin:  a pointer to a signature to check/normalize (cannot be NULL,
 *                can be identical to sigout)
 *
 *  With ECDSA a third-party can forge a second distinct signature of the same
 *  message, given a single initial signature, but without knowing the key. This
 *  is done by negating the S value modulo the order of the curve, 'flipping'
 *  the sign of the random point R which is not included in the signature.
 *
 *  Forgery of the same message isn't universally problematic, but in systems
 *  where message malleability or uniqueness of signatures is important this can
 *  cause issues. This forgery can be blocked by all verifiers forcing signers
 *  to use a normalized form.
 *
 *  The lower-S form reduces the size of signatures slightly on average when
 *  variable length encodings (such as DER) are used and is cheap to verify,
 *  making it a good choice. Security of always using lower-S is assured because
 *  anyone can trivially modify a signature after the fact to enforce this
 *  property anyway.
 *
 *  The lower S value is always between 0x1 and
 *  0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0,
 *  inclusive.
 *
 *  No other forms of ECDSA malleability are known and none seem likely, but
 *  there is no formal proof that ECDSA, even with this additional restriction,
 *  is free of other malleability. Commonly used serialization schemes will also
 *  accept various non-unique encodings, so care should be taken when this
 *  property is required for an application.
 *
 *  The secp256k1_ecdsa_sign function will by default create signatures in the
 *  lower-S form, and secp256k1_ecdsa_verify will not accept others. In case
 *  signatures come from a system that cannot enforce this property,
 *  secp256k1_ecdsa_signature_normalize must be called before verification.
 */
public func secp256k1_ecdsa_signature_normalize(_ ctx: secp256k1_context, _ sigout: inout secp256k1_ecdsa_signature , _ sigin: secp256k1_ecdsa_signature) -> Bool
{
    var r = secp256k1_scalar()
    var s = secp256k1_scalar()
    var ret: Bool = false
    
    if !ctx.ARG_CHECK(sigout.is_valid_len(), "invalid sigout") { return false }
    if !ctx.ARG_CHECK(sigin.is_valid_len(), "invalid sigin") { return false }

    secp256k1_ecdsa_signature_load(ctx, &r, &s, sigin);
    ret = secp256k1_scalar_is_high(s);
    //if (sigout != nil) {
        if (ret) {
            secp256k1_scalar_negate(&s, s);
        }
        secp256k1_ecdsa_signature_save(&sigout, r, s)
    //}
    
    return ret;
}

/** Verify an ECDSA signature.
 *
 *  Returns: 1: correct signature
 *           0: incorrect or unparseable signature
 *  Args:    ctx:       a secp256k1 context object, initialized for verification.
 *  In:      sig:       the signature being verified (cannot be NULL)
 *           msg32:     the 32-byte message hash being verified (cannot be NULL)
 *           pubkey:    pointer to an initialized public key to verify with (cannot be NULL)
 *
 * To avoid accepting malleable signatures, only ECDSA signatures in lower-S
 * form are accepted.
 *
 * If you need to accept ECDSA signatures from sources that do not obey this
 * rule, apply secp256k1_ecdsa_signature_normalize to the signature prior to
 * validation, but be aware that doing so results in malleable signatures.
 *
 * For details, see the comments for that function.
 */
public func secp256k1_ecdsa_verify(_ ctx: secp256k1_context, _ sig: secp256k1_ecdsa_signature, _ msg32: [UInt8], _ pubkey: secp256k1_pubkey) -> Bool
{
    var q = secp256k1_ge()
    var r = secp256k1_scalar()
    var s = secp256k1_scalar()
    var m = secp256k1_scalar()
    if !ctx.ARG_CHECK(secp256k1_ecmult_context_is_built(ctx.ecmult_ctx), "invalid ctx") { return false }
    if !ctx.ARG_CHECK(msg32.count == 32, "invalid msg") { return false }
    if !ctx.ARG_CHECK(sig.is_valid_len(), "invalid sig") { return false }
    if !ctx.ARG_CHECK(pubkey.is_valid_len(), "invalid pubkey") { return false }
    
    var dummy: Bool = false
    secp256k1_scalar_set_b32(&m, msg32, &dummy)
    secp256k1_ecdsa_signature_load(ctx, &r, &s, sig)
    /*
    return (!secp256k1_scalar_is_high(s) &&
        secp256k1_pubkey_load(ctx, &q, pubkey) &&
        secp256k1_ecdsa_sig_verify(ctx.ecmult_ctx, r, s, q, m))
 */
    if secp256k1_scalar_is_high(s) {
        return false
    }
    if !secp256k1_pubkey_load(ctx, &q, pubkey) {
        return false
    }
    return secp256k1_ecdsa_sig_verify(ctx.ecmult_ctx, r, s, q, m)
}

func nonce_function_rfc6979(
    _ nonce32: inout [UInt8],
    _ msg32: [UInt8],
    _ key32: [UInt8],
    _ algo16: [UInt8]?,
    _ data: [UInt8]?,
    _ counter: UInt) -> Bool
{
    //unsigned char keydata[112];
    var keydata:[UInt8] = [UInt8](repeating: 0, count: 112)
    var keylen: Int = 64;
    var rng = secp256k1_rfc6979_hmac_sha256_t()
    /* We feed a byte array to the PRNG as input, consisting of:
     * - the private key (32 bytes) and message (32 bytes), see RFC 6979 3.2d.
     * - optionally 32 extra bytes of data, see RFC 6979 3.6 Additional Data.
     * - optionally 16 extra bytes with the algorithm name.
     * Because the arguments have distinct fixed lengths it is not possible for
     *  different argument mixtures to emulate each other and result in the same
     *  nonces.
     */
    for i in 0..<32 {
        keydata[i] = key32[i]
    }
    for i in 0..<32 {
        keydata[32+i] = msg32[i]
    }
    if let data = data {
        for i in 0..<32 {
            keydata[i + 64] = data[i]
        }
        keylen = 96;
    }
    if let algo16 = algo16 {
        for i in 0..<16 {
            keydata[keylen + i] = algo16[i]
        }
        keylen += 16;
    }
    secp256k1_rfc6979_hmac_sha256_initialize(&rng, keydata, UInt(keylen));
    keydata.clear(count: 112)
    for _ in 0 ... counter {
        secp256k1_rfc6979_hmac_sha256_generate(&rng, &nonce32, outlen: 32);
    }
    secp256k1_rfc6979_hmac_sha256_finalize(&rng);
    return true
}

/** An implementation of RFC6979 (using HMAC-SHA256) as nonce generation function.
 * If a data pointer is passed, it is assumed to be a pointer to 32 bytes of
 * extra entropy.
 */
let secp256k1_nonce_function_rfc6979: secp256k1_nonce_function = nonce_function_rfc6979

/** A default safe nonce generation function (currently equal to secp256k1_nonce_function_rfc6979). */
let secp256k1_nonce_function_default: secp256k1_nonce_function = nonce_function_rfc6979

/** Create an ECDSA signature.
 *
 *  Returns: 1: signature created
 *           0: the nonce generation function failed, or the private key was invalid.
 *  Args:    ctx:    pointer to a context object, initialized for signing (cannot be NULL)
 *  Out:     sig:    pointer to an array where the signature will be placed (cannot be NULL)
 *  In:      msg32:  the 32-byte message hash being signed (cannot be NULL)
 *           seckey: pointer to a 32-byte secret key (cannot be NULL)
 *           noncefp:pointer to a nonce generation function. If NULL, secp256k1_nonce_function_default is used
 *           ndata:  pointer to arbitrary data used by the nonce generation function (can be NULL)
 *
 * The created signature is always in lower-S form. See
 * secp256k1_ecdsa_signature_normalize for more details.
 */
public func secp256k1_ecdsa_sign(_ ctx: secp256k1_context,
                          _ signature: inout secp256k1_ecdsa_signature,
                          _ msg32: [UInt8],
                          _ seckey: [UInt8],
                          _ noncefp: secp256k1_nonce_function?,
                          _ noncedata: [UInt8]?) -> Bool {
    var r = secp256k1_scalar()
    var s = secp256k1_scalar()
    var sec = secp256k1_scalar()
    var non = secp256k1_scalar()
    var msg = secp256k1_scalar()
    var ret: Bool = false
    var overflow: Bool = false
    
    if !ctx.ARG_CHECK(secp256k1_ecmult_gen_context_is_built(ctx.ecmult_gen_ctx), "invalid gen ctx") { return false }
    if !ctx.ARG_CHECK(msg32.count == 32, "invalid msg") { return false }
    if !ctx.ARG_CHECK(signature.is_valid_len(), "invalid signature") { return false }
    if !ctx.ARG_CHECK(seckey.count == 32, "invalid seckey") { return false }

    var v_noncefp: secp256k1_nonce_function
    if let v = noncefp {
        v_noncefp = v
    } else {
        v_noncefp = secp256k1_nonce_function_default;
    }

    secp256k1_scalar_set_b32(&sec, seckey, &overflow);
    /* Fail if the secret key is invalid. */
    if (!overflow && !secp256k1_scalar_is_zero(sec)) {
        //unsigned char nonce32[32];
        var nonce32: [UInt8] = [UInt8](repeating: 0, count: 32)
        var count: UInt = 0;
        var dummy: Bool = false
        secp256k1_scalar_set_b32(&msg, msg32, &dummy);
        while (true) {
            ret = v_noncefp(&nonce32, msg32, seckey, nil, noncedata, count)
            if (!ret) {
                break;
            }
            secp256k1_scalar_set_b32(&non, nonce32, &overflow);
            if (!overflow && !secp256k1_scalar_is_zero(non)) {
                var dummy: Int = 0
                if (secp256k1_ecdsa_sig_sign(ctx.ecmult_gen_ctx, &r, &s, sec, msg, non, &dummy)) {
                    break;
                }
            }
            count += 1
        }
        nonce32 = [UInt8](repeating: 0, count: 32)
        secp256k1_scalar_clear(&msg);
        secp256k1_scalar_clear(&non);
        secp256k1_scalar_clear(&sec);
    }
    if (ret) {
        secp256k1_ecdsa_signature_save(&signature, r, s);
    } else {
        signature.clear()
    }
    return ret;
}

/** Verify an ECDSA secret key.
 *
 *  Returns: 1: secret key is valid
 *           0: secret key is invalid
 *  Args:    ctx: pointer to a context object (cannot be NULL)
 *  In:      seckey: pointer to a 32-byte secret key (cannot be NULL)
 */
public func secp256k1_ec_seckey_verify(_ ctx: secp256k1_context, _ seckey: [UInt8]) -> Bool
{
    var sec = secp256k1_scalar()
    var ret: Bool
    var overflow: Bool = false
    if !ctx.ARG_CHECK(seckey.count >= 32, "insufficient seckey length") { return false }
    
    secp256k1_scalar_set_b32(&sec, seckey, &overflow);
    ret = !overflow && !secp256k1_scalar_is_zero(sec);
    secp256k1_scalar_clear(&sec);
    return ret;
}

/** Compute the public key for a secret key.
 *
 *  Returns: 1: secret was valid, public key stores
 *           0: secret was invalid, try again
 *  Args:   ctx:        pointer to a context object, initialized for signing (cannot be NULL)
 *  Out:    pubkey:     pointer to the created public key (cannot be NULL)
 *  In:     seckey:     pointer to a 32-byte private key (cannot be NULL)
 */
public func secp256k1_ec_pubkey_create(_ ctx: secp256k1_context, _ pubkey: inout secp256k1_pubkey, _ seckey: [UInt8]) -> Bool
{
    var pj = secp256k1_gej()
    var p = secp256k1_ge()
    var sec = secp256k1_scalar()
    var overflow: Bool = false
    var ret: Bool = false
    if !ctx.ARG_CHECK(pubkey.data.count >= 32, "insufficient pubkey length") { return false }
    pubkey.clear()
    if !ctx.ARG_CHECK(secp256k1_ecmult_gen_context_is_built(ctx.ecmult_gen_ctx), "invalid ctx") {
        return false
    }
    if !ctx.ARG_CHECK(seckey.count >= 32, "insufficient seckey length") { return false }
    
    secp256k1_scalar_set_b32(&sec, seckey, &overflow);
    ret = !overflow && !secp256k1_scalar_is_zero(sec)
    if (ret) {
        secp256k1_ecmult_gen(ctx.ecmult_gen_ctx, &pj, sec)
        secp256k1_ge_set_gej(&p, &pj);
        secp256k1_pubkey_save(&pubkey, &p);
    }
    secp256k1_scalar_clear(&sec);
    return ret;
}

/** Negates a private key in place.
 *
 *  Returns: 1 always
 *  Args:   ctx:        pointer to a context object
 *  In/Out: pubkey:     pointer to the public key to be negated (cannot be NULL)
 */
public func secp256k1_ec_privkey_negate(_ ctx: secp256k1_context, _ seckey: inout [UInt8]) -> Bool
{
    var sec = secp256k1_scalar()
    
    if !ctx.ARG_CHECK(seckey.count >= 32, "invalid seckey") { return false }
    
    var dummy: Bool = false
    secp256k1_scalar_set_b32(&sec, seckey, &dummy);
    secp256k1_scalar_negate(&sec, sec);
    secp256k1_scalar_get_b32(&seckey, sec);
    
    return true
}

/** Negates a public key in place.
 *
 *  Returns: 1 always
 *  Args:   ctx:        pointer to a context object
 *  In/Out: pubkey:     pointer to the public key to be negated (cannot be NULL)
 */
public func secp256k1_ec_pubkey_negate(_ ctx: secp256k1_context, _ pubkey: inout secp256k1_pubkey) -> Bool
{
    var ret: Bool = false
    var p = secp256k1_ge()
    
    if !ctx.ARG_CHECK(pubkey.is_valid_len(), "invalid pubkey") { return false }
    
    ret = secp256k1_pubkey_load(ctx, &p, pubkey);
    pubkey.clear()
    if (ret) {
        secp256k1_ge_neg(&p, p);
        secp256k1_pubkey_save(&pubkey, &p);
    }
    return ret;
}

/** Tweak a private key by adding tweak to it.
 * Returns: 0 if the tweak was out of range (chance of around 1 in 2^128 for
 *          uniformly random 32-byte arrays, or if the resulting private key
 *          would be invalid (only when the tweak is the complement of the
 *          private key). 1 otherwise.
 * Args:    ctx:    pointer to a context object (cannot be NULL).
 * In/Out:  seckey: pointer to a 32-byte private key.
 * In:      tweak:  pointer to a 32-byte tweak.
 */
public func secp256k1_ec_privkey_tweak_add(_ ctx: secp256k1_context, _ seckey: inout [UInt8], _ tweak: [UInt8]) -> Bool
{
    var term = secp256k1_scalar()
    var sec = secp256k1_scalar()
    var ret: Bool = false
    var overflow: Bool = false
    if !ctx.ARG_CHECK(seckey.count >= 32, "insufficient seckey length") { return false }
    if !ctx.ARG_CHECK(tweak.count >= 32, "insufficient tweak length") { return false }
    
    secp256k1_scalar_set_b32(&term, tweak, &overflow);
    var dummy: Bool = false
    secp256k1_scalar_set_b32(&sec, seckey, &dummy);
    
    ret = !overflow && secp256k1_eckey_privkey_tweak_add(&sec, term);
    seckey.clear(count:32)
    if (ret) {
        secp256k1_scalar_get_b32(&seckey, sec);
    }
    
    secp256k1_scalar_clear(&sec);
    secp256k1_scalar_clear(&term);
    return ret;
}

/** Tweak a public key by adding tweak times the generator to it.
 * Returns: 0 if the tweak was out of range (chance of around 1 in 2^128 for
 *          uniformly random 32-byte arrays, or if the resulting public key
 *          would be invalid (only when the tweak is the complement of the
 *          corresponding private key). 1 otherwise.
 * Args:    ctx:    pointer to a context object initialized for validation
 *                  (cannot be NULL).
 * In/Out:  pubkey: pointer to a public key object.
 * In:      tweak:  pointer to a 32-byte tweak.
 */
public func secp256k1_ec_pubkey_tweak_add(_ ctx: secp256k1_context, _ pubkey: inout secp256k1_pubkey, _ tweak: [UInt8]) -> Bool
{
    var p = secp256k1_ge()
    var term = secp256k1_scalar()
    var ret: Bool = false
    var overflow: Bool = false
    if !ctx.ARG_CHECK(secp256k1_ecmult_context_is_built(ctx.ecmult_ctx), "invalid ctx") { return false }
    if !ctx.ARG_CHECK(pubkey.is_valid_len(), "invalid pubkey") { return false }
    if !ctx.ARG_CHECK(tweak.count >= 32, "insufficient tweak length") { return false }
    
    secp256k1_scalar_set_b32(&term, tweak, &overflow);
    ret = !overflow && secp256k1_pubkey_load(ctx, &p, pubkey);
    pubkey.clear()
    if (ret) {
        if (secp256k1_eckey_pubkey_tweak_add(ctx.ecmult_ctx, &p, term)) {
            secp256k1_pubkey_save(&pubkey, &p);
        } else {
            ret = false
        }
    }
    return ret;
}

/** Tweak a private key by multiplying it by a tweak.
 * Returns: 0 if the tweak was out of range (chance of around 1 in 2^128 for
 *          uniformly random 32-byte arrays, or equal to zero. 1 otherwise.
 * Args:   ctx:    pointer to a context object (cannot be NULL).
 * In/Out: seckey: pointer to a 32-byte private key.
 * In:     tweak:  pointer to a 32-byte tweak.
 */
public func secp256k1_ec_privkey_tweak_mul(_ ctx: secp256k1_context, _ seckey: inout [UInt8], _ tweak: [UInt8]) -> Bool
{
    var factor = secp256k1_scalar()
    var sec = secp256k1_scalar()
    var ret: Bool = false
    var overflow: Bool = false
    if !ctx.ARG_CHECK(seckey.count >= 32, "insufficient seckey length") { return false }
    if !ctx.ARG_CHECK(tweak.count >= 32, "insufficient tweak length") { return false }
    
    secp256k1_scalar_set_b32(&factor, tweak, &overflow);
    var dummy: Bool = false
    secp256k1_scalar_set_b32(&sec, seckey, &dummy);
    ret = !overflow && secp256k1_eckey_privkey_tweak_mul(&sec, factor);
    seckey.clear(count: 32)
    if (ret) {
        secp256k1_scalar_get_b32(&seckey, sec);
    }
    
    secp256k1_scalar_clear(&sec);
    secp256k1_scalar_clear(&factor);
    return ret;
}

/** Tweak a public key by multiplying it by a tweak value.
 * Returns: 0 if the tweak was out of range (chance of around 1 in 2^128 for
 *          uniformly random 32-byte arrays, or equal to zero. 1 otherwise.
 * Args:    ctx:    pointer to a context object initialized for validation
 *                 (cannot be NULL).
 * In/Out:  pubkey: pointer to a public key obkect.
 * In:      tweak:  pointer to a 32-byte tweak.
 */
public func secp256k1_ec_pubkey_tweak_mul(_ ctx: secp256k1_context, _ pubkey: inout secp256k1_pubkey, _ tweak: [UInt8]) -> Bool
{
    var p = secp256k1_ge()
    var factor = secp256k1_scalar()
    var ret: Bool = false
    var overflow: Bool = false
    if !ctx.ARG_CHECK(secp256k1_ecmult_context_is_built(ctx.ecmult_ctx), "invalid ctx") { return false }
    if !ctx.ARG_CHECK(pubkey.is_valid_len(), "invalid pubkey") { return false }
    if !ctx.ARG_CHECK(tweak.count >= 32, "insufficient tweak length") { return false }
    
    secp256k1_scalar_set_b32(&factor, tweak, &overflow);
    ret = !overflow && secp256k1_pubkey_load(ctx, &p, pubkey);
    pubkey.clear()
    if (ret) {
        if (secp256k1_eckey_pubkey_tweak_mul(ctx.ecmult_ctx, &p, factor)) {
            secp256k1_pubkey_save(&pubkey, &p);
        } else {
            ret = false
        }
    }
    
    return ret
}

/** Updates the context randomization to protect against side-channel leakage.
 *  Returns: 1: randomization successfully updated
 *           0: error
 *  Args:    ctx:       pointer to a context object (cannot be NULL)
 *  In:      seed32:    pointer to a 32-byte random seed (NULL resets to initial state)
 *
 * While secp256k1 code is written to be constant-time no matter what secret
 * values are, it's possible that a future compiler may output code which isn't,
 * and also that the CPU may not emit the same radio frequencies or draw the same
 * amount power for all values.
 *
 * This function provides a seed which is combined into the blinding value: that
 * blinding value is added before each multiplication (and removed afterwards) so
 * that it does not affect function results, but shields against attacks which
 * rely on any input-dependent behaviour.
 *
 * You should call this after secp256k1_context_create or
 * secp256k1_context_clone, and may call this repeatedly afterwards.
 */
public func secp256k1_context_randomize(_ ctx: inout secp256k1_context, _ seed32: [UInt8]?) -> Bool {
    if !ctx.ARG_CHECK(secp256k1_ecmult_gen_context_is_built(ctx.ecmult_gen_ctx), "invalid ctx") { return false }
    secp256k1_ecmult_gen_blind(&ctx.ecmult_gen_ctx, seed32);
    return true
}

/** Add a number of public keys together.
 *  Returns: 1: the sum of the public keys is valid.
 *           0: the sum of the public keys is not valid.
 *  Args:   ctx:        pointer to a context object
 *  Out:    out:        pointer to a public key object for placing the resulting public key
 *                      (cannot be NULL)
 *  In:     ins:        pointer to array of pointers to public keys (cannot be NULL)
 *          n:          the number of public keys to add together (must be at least 1)
 */
public func secp256k1_ec_pubkey_combine(_ ctx: secp256k1_context, _ pubnonce: inout secp256k1_pubkey, _ pubnonces:[secp256k1_pubkey], _ n: UInt) -> Bool
{
    var Qj = secp256k1_gej()
    var Q = secp256k1_ge()
    
    if !ctx.ARG_CHECK(pubnonce.is_valid_len(), "invalid pubnonce") { return false }
    pubnonce.clear()
    if !ctx.ARG_CHECK(n >= 1, "invalid n") { return false }
    if !ctx.ARG_CHECK(pubnonces.count >= n, "insufficient pubnonces length") { return false }

    secp256k1_gej_set_infinity(&Qj);
    
    for i in 0 ..< Int(n) {
        let _ = secp256k1_pubkey_load(ctx, &Q, pubnonces[i]);
        secp256k1_gej_add_ge(&Qj, Qj, Q);
    }
    if (secp256k1_gej_is_infinity(Qj)) {
        return false
    }
    secp256k1_ge_set_gej(&Q, &Qj);
    secp256k1_pubkey_save(&pubnonce, &Q);
    return true
}
