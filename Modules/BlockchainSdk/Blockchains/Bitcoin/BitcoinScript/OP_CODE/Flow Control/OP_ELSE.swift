//
//  OP_ELSE.swift
//  BitcoinKit
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2018 BitcoinKit developers. All rights reserved.
//

import Foundation

struct OpElse: OpCodeProtocol {
    var value: UInt8 { return 0x67 }
    var name: String { return "OP_ELSE" }
}
