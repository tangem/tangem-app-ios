//
//  ecmult.swift
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

//typealias Pre_G = () -> secp256k1_ge_storage

public struct secp256k1_ecmult_context : CustomDebugStringConvertible {
    /* For accelerating the computation of a*P + b*G: */
    var pre_g: [/*Pre_G*/ secp256k1_ge_storage]    /* odd multiples of the generator */
    init() {
        pre_g = [secp256k1_ge_storage](repeating: secp256k1_ge_storage(), count: 0)
    }
    public var debugDescription: String {
        var s = ""
        for i in 0 ..< min(pre_g.count, 4) {
            s += "\(pre_g[i])"
        }
        return s
    }
}
