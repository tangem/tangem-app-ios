//
//  OP_SHA256.swift
//  BitcoinKit
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2018 BitcoinKit developers. All rights reserved.
//

import Foundation

/// The input is hashed using SHA-256.
struct OpSha256: OpCodeProtocol {
    var value: UInt8 { return 0xa8 }
}
