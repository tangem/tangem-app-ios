//
//  OP_HASH256.swift
//  BitcoinKit
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2018 BitcoinKit developers. All rights reserved.
//

import Foundation

/// The input is hashed two times with SHA-256.
struct OpHash256: OpCodeProtocol {
    var value: UInt8 { return 0xaa }
}
