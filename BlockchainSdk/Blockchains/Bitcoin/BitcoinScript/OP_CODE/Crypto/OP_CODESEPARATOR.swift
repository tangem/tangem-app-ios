//
//  OP_CODESEPARATOR.swift
//  BitcoinKit
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2018 BitcoinKit developers. All rights reserved.
//

import Foundation

// All of the signature checking words will only match signatures to the data after the most recently-executed OP_CODESEPARATOR.
struct OpCodeSeparator: OpCodeProtocol {
    var value: UInt8 { return 0xab }
    var name: String { return "OP_CODESEPARATOR" }
}
