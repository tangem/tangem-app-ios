//
//  scalar_8x32.swift
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

/** A scalar modulo the group order of the secp256k1 curve. */
struct secp256k1_scalar : CustomDebugStringConvertible
{
    // d[0] is lowest digit
    // d[7] is highest digit
    var d: [UInt32] // size: 8
    init(){
        d = [UInt32](repeating: 0, count: 8)
    }
    var debugDescription: String {
        return d.hexDescription()
    }
    
    // for debug only
    #if DEBUG
    // basepoint order
    static let L: secp256k1_scalar
        = SECP256K1_SCALAR_CONST(SECP256K1_N_7,
                                 SECP256K1_N_6,
                                 SECP256K1_N_5,
                                 SECP256K1_N_4,
                                 SECP256K1_N_3,
                                 SECP256K1_N_2,
                                 SECP256K1_N_1,
                                 SECP256K1_N_0)
    #endif
}

func SECP256K1_SCALAR_CONST(_ d7:UInt32,
                            _ d6:UInt32,
                            _ d5:UInt32,
                            _ d4:UInt32,
                            _ d3:UInt32,
                            _ d2:UInt32,
                            _ d1:UInt32,
                            _ d0:UInt32) -> secp256k1_scalar
{
    var s = secp256k1_scalar()
    s.d[0] = d0
    s.d[1] = d1
    s.d[2] = d2
    s.d[3] = d3
    s.d[4] = d4
    s.d[5] = d5
    s.d[6] = d6
    s.d[7] = d7
    return s
}
