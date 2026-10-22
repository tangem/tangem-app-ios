//
//  OP_SHA1.swift
//  BitcoinKit
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2018 BitcoinKit developers. All rights reserved.
//

import Foundation
import CryptoSwift

/// The input is hashed using SHA-1.
struct OpSha1: OpCodeProtocol {
    var value: UInt8 { return 0xa7 }
}
