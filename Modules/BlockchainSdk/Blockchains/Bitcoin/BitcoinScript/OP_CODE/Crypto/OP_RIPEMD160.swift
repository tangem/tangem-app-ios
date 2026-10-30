//
//  OP_RIPEMD160.swift
//  BitcoinKit
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2018 BitcoinKit developers. All rights reserved.
//

import Foundation

/// The input is hashed using RIPEMD-160.
struct OpRipemd160: OpCodeProtocol {
    var value: UInt8 { return 0xa6 }
}
