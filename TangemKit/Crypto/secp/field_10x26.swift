//
//  field_10x26.swift
//  secp256k1
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2017 pebble8888. All rights reserved.
//
/**********************************************************************
 * Copyright (c) 2013, 2014 Pieter Wuille                             *
 * Distributed under the MIT software license, see the accompanying   *
 * file COPYING or http://www.opensource.org/licenses/mit-license.php.*
 **********************************************************************/

import Foundation

//
// field 26bit limb
//
struct secp256k1_fe : CustomDebugStringConvertible {
    /* X = sum(i=0..9, elem[i]*2^26) mod n */
    // first is lower
    public var n: [UInt32] // size:10
#if VERIFY
    public var magnitude: Int  //
    public var normalized: Bool // 1:normalized, 0:not
#endif

    static func VERIFY_CHECK(_ a:Bool){
        assert(a);
    }
    init() {
        n = [UInt32](repeating: 0, count: 10)
        #if VERIFY
            magnitude = 0
            normalized = true
        #endif
    }
    
    init(_ n0:UInt32, _ n1:UInt32, _ n2:UInt32, _ n3:UInt32,
         _ n4:UInt32, _ n5:UInt32, _ n6:UInt32, _ n7:UInt32,
         _ n8:UInt32, _ n9:UInt32)
    {
        n = [UInt32](repeating: 0, count: 10)
        n[0] = n0
        n[1] = n1
        n[2] = n2
        n[3] = n3
        n[4] = n4
        n[5] = n5
        n[6] = n6
        n[7] = n7
        n[8] = n8
        n[9] = n9
        #if VERIFY
            magnitude = 0
            normalized = true
        #endif
    }
    
    func equal(_ a: secp256k1_fe) -> Bool {
        for i in 0 ..< 10 {
            if self.n[i] != a.n[i] {
                return false
            }
        }
        return true
    }
    
    var debugDescription: String {
        return n.hexDescription(separator: " ")
    }
}

/* Unpacks a constant into a overlapping multi-limbed FE element. */
func SECP256K1_FE_CONST_INNER(_ d7:UInt32, _ d6:UInt32, _ d5:UInt32, _ d4:UInt32,
                              _ d3:UInt32, _ d2:UInt32, _ d1:UInt32, _ d0:UInt32) -> secp256k1_fe
{
    let n0 = (d0) & 0x3FFFFFF
    let n1 = (d0 >> 26) | ((d1 & 0xFFFFF) << 6)
    let n2 = (d1 >> 20) | ((d2 & 0x3FFF) << 12)
    let n3 = (d2 >> 14) | ((d3 & 0xFF) << 18)
    let n4 = (d3 >> 8) | ((d4 & 0x3) << 24)
    let n5 = (d4 >> 2) & 0x3FFFFFF
    let n6 = (d4 >> 28) | ((d5 & 0x3FFFFF) << 4)
    let n7 = (d5 >> 22) | ((d6 & 0xFFFF) << 10)
    let n8 = (d6 >> 16) | ((d7 & 0x3FF) << 16)
    let n9 = (d7 >> 10)
    return secp256k1_fe(n0, n1, n2, n3, n4, n5, n6, n7, n8, n9)
}

func SECP256K1_FE_CONST(_ d7:UInt32, _ d6:UInt32, _ d5:UInt32, _ d4:UInt32,
                        _ d3:UInt32, _ d2:UInt32, _ d1:UInt32, _ d0:UInt32) -> secp256k1_fe
{
    return SECP256K1_FE_CONST_INNER(d7, d6, d5, d4, d3, d2, d1, d0)
}

func SECP256K1_FE_STORAGE_CONST(_ d7:UInt32, _ d6:UInt32, _ d5:UInt32, _ d4:UInt32,
                                _ d3:UInt32, _ d2:UInt32, _ d1:UInt32, _ d0:UInt32) -> secp256k1_fe_storage
{
    return secp256k1_fe_storage(d0, d1, d2, d3, d4, d5, d6, d7)
}
    
struct secp256k1_fe_storage : CustomDebugStringConvertible {
    var n:[UInt32] // size:8
    init(){
        n = [UInt32](repeating: 0, count: 8)
    }
    init(_ n0:UInt32, _ n1:UInt32, _ n2:UInt32, _ n3:UInt32,
         _ n4:UInt32, _ n5:UInt32, _ n6:UInt32, _ n7:UInt32) {
        n = [UInt32](repeating:0, count:8)
        n[0] = n0
        n[1] = n1
        n[2] = n2
        n[3] = n3
        n[4] = n4
        n[5] = n5
        n[6] = n6
        n[7] = n7
    }
    mutating func clear(){
        for i in 0..<8 {
            n[i] = 0
        }
    }
    func equal(_ a: secp256k1_fe_storage) -> Bool {
        for i in 0..<8 {
            if self.n[i] != a.n[i] {
                return false
            }
        }
        return true
    }
    var debugDescription: String {
        return n.hexDescription(separator: " ")
    }
}
