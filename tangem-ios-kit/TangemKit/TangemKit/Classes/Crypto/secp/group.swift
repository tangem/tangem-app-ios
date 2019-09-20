//
//  group.swift
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

/** A group element of the secp256k1 curve, in affine coordinates. */
// affine point
struct secp256k1_ge : CustomDebugStringConvertible {
    var x: secp256k1_fe
    var y: secp256k1_fe
    var infinity: Bool /* whether this represents the point at infinity */
    init(){
        self = SECP256K1_GE_CONST_INFINITY
    }
    init(x: secp256k1_fe, y: secp256k1_fe, infinity: Bool)
    {
        self.x = x
        self.y = y
        self.infinity = infinity
    }
    var debugDescription: String {
        return "\(x)\n\(y)\n"
    }
    
    #if DEBUG
    // for only Debug
    // base point
    static let G = secp256k1_ge_const_g
    #endif
}

func SECP256K1_GE_CONST(_ a: UInt32,
                        _ b: UInt32,
                        _ c: UInt32,
                        _ d: UInt32,
                        _ e: UInt32,
                        _ f: UInt32,
                        _ g: UInt32,
                        _ h: UInt32,
                        _ i: UInt32,
                        _ j: UInt32,
                        _ k: UInt32,
                        _ l: UInt32,
                        _ m: UInt32,
                        _ n: UInt32,
                        _ o: UInt32,
                        _ p: UInt32) -> secp256k1_ge
{
    return secp256k1_ge(x: SECP256K1_FE_CONST(a, b, c, d, e, f, g, h),
                        y: SECP256K1_FE_CONST(i, j, k, l, m, n, o, p),
                        infinity: false)
}

let SECP256K1_GE_CONST_INFINITY: secp256k1_ge =
    secp256k1_ge(x: SECP256K1_FE_CONST(0, 0, 0, 0, 0, 0, 0, 0),
                        y: SECP256K1_FE_CONST(0, 0, 0, 0, 0, 0, 0, 0),
                        infinity: true)

/** A group element of the secp256k1 curve, in jacobian coordinates. */
// yacobian point
struct secp256k1_gej: CustomDebugStringConvertible {
    var x: secp256k1_fe /* actual X: x/z^2 */
    var y: secp256k1_fe /* actual Y: y/z^3 */
    var z: secp256k1_fe
    var infinity: Bool /* whether this represents the point at infinity */
    init() {
        self = SECP256K1_GEJ_CONST_INFINITY
    }
    init(x: secp256k1_fe,
         y: secp256k1_fe,
         z: secp256k1_fe,
         infinity: Bool)
    {
        self.x = x
        self.y = y
        self.z = z
        self.infinity = infinity
    }
    var debugDescription: String {
        return "\(x)"
    }
}

func SECP256K1_GEJ_CONST(_ a: UInt32,
                         _ b: UInt32,
                         _ c: UInt32,
                         _ d: UInt32,
                         _ e: UInt32,
                         _ f: UInt32,
                         _ g: UInt32,
                         _ h: UInt32,
                         _ i: UInt32,
                         _ j: UInt32,
                         _ k: UInt32,
                         _ l: UInt32,
                         _ m: UInt32,
                         _ n: UInt32,
                         _ o: UInt32,
                         _ p: UInt32) -> secp256k1_gej
{
    return secp256k1_gej(
        x: SECP256K1_FE_CONST((a),(b),(c),(d),(e),(f),(g),(h)),
        y: SECP256K1_FE_CONST((i),(j),(k),(l),(m),(n),(o),(p)),
        z: SECP256K1_FE_CONST(0, 0, 0, 0, 0, 0, 0, 1),
        infinity: false)
}

let SECP256K1_GEJ_CONST_INFINITY: secp256k1_gej =
    secp256k1_gej(
        x: SECP256K1_FE_CONST(0, 0, 0, 0, 0, 0, 0, 0),
        y: SECP256K1_FE_CONST(0, 0, 0, 0, 0, 0, 0, 0),
        z: SECP256K1_FE_CONST(0, 0, 0, 0, 0, 0, 0, 0),
        infinity: true)

struct secp256k1_ge_storage : CustomDebugStringConvertible {
    var x: secp256k1_fe_storage
    var y: secp256k1_fe_storage
    init(){
        x = secp256k1_fe_storage()
        y = secp256k1_fe_storage()
    }
    init(x: secp256k1_fe_storage, y: secp256k1_fe_storage){
        self.x = x
        self.y = y
    }
    mutating func clear(){
        x.clear()
        y.clear()
    }
    var debugDescription: String {
        return "\(x)\n\(y)\n"
    }
}

func SECP256K1_GE_STORAGE_CONST(
    _ a: UInt32,
    _ b: UInt32,
    _ c: UInt32,
    _ d: UInt32,
    _ e: UInt32,
    _ f: UInt32,
    _ g: UInt32,
    _ h: UInt32,
    _ i: UInt32,
    _ j: UInt32,
    _ k: UInt32,
    _ l: UInt32,
    _ m: UInt32,
    _ n: UInt32,
    _ o: UInt32,
    _ p: UInt32) -> secp256k1_ge_storage
{
    return secp256k1_ge_storage(
      x: SECP256K1_FE_STORAGE_CONST((a),(b),(c),(d),(e),(f),(g),(h)),
      y: SECP256K1_FE_STORAGE_CONST((i),(j),(k),(l),(m),(n),(o),(p))
    )
}

//#define SECP256K1_GE_STORAGE_CONST_GET(t) SECP256K1_FE_STORAGE_CONST_GET(t.x), SECP256K1_FE_STORAGE_CONST_GET(t.y)
