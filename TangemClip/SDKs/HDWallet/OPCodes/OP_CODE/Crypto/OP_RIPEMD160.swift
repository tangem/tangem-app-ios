//
//  OP_RIPEMD160.swift
//  BitcoinKit
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2018 BitcoinKit developers. All rights reserved.
//

import Foundation

// The input is hashed using RIPEMD-160.
public struct OpRipemd160: OpCodeProtocol {
    public var value: UInt8 { return 0xa6 }
    public var name: String { return "OP_RIPEMD160" }

}
