//
//  gen_context.swift
//  secp256k1
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2018 pebble8888. All rights reserved.
//
/**********************************************************************
 * Copyright (c) 2013, 2014, 2015 Thomas Daede, Cory Fields           *
 * Distributed under the MIT software license, see the accompanying   *
 * file COPYING or http://www.opensource.org/licenses/mit-license.php.*
 **********************************************************************/

import Foundation

func default_error_callback_fn(str: [UInt8], data: UnsafeRawPointer?){
    print("[libsecp256k1] internal consistency check failed: \(str)\n")
    fatalError()
}

fileprivate let default_error_callback: secp256k1_callback = secp256k1_callback(
    fn: default_error_callback_fn,
    data: nil
)
