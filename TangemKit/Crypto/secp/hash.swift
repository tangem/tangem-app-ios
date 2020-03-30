//
//  hash.swift
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


struct secp256k1_sha256_t : CustomDebugStringConvertible {
    var s: [UInt32] // size: 8
    var buf: [UInt32] /* size: 16, In big endian */
    var bytes: UInt
    init(){
        s = [UInt32](repeating: 0, count: 8)
        buf = [UInt32](repeating: 0, count: 16)
        bytes = 0
    }
    var debugDescription: String {
        return buf.hexDescription() + "\n" + s.hexDescription() + "\n"
    }
}

struct secp256k1_hmac_sha256_t : CustomDebugStringConvertible {
    var inner: secp256k1_sha256_t
    var outer: secp256k1_sha256_t
    init(){
        inner = secp256k1_sha256_t()
        outer = secp256k1_sha256_t()
    }
    var debugDescription: String {
        return "inner:\n\(inner)\nouter:\n\(outer)"
    }
}

struct secp256k1_rfc6979_hmac_sha256_t : CustomDebugStringConvertible {
    var v: [UInt8] // size: 32
    var k: [UInt8] // size: 32
    var retry: Bool
    public init() {
        v = [UInt8](repeating: 0, count: 32)
        k = [UInt8](repeating: 0, count: 32)
        retry = false
    }
    public var debugDescription: String {
        return "k: \n\(k.hexDescription())\nv: \n\(v.hexDescription())"
    }
}
