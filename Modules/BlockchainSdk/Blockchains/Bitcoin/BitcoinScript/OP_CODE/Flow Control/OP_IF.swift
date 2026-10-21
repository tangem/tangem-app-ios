//
//  OP_IF.swift
//  BitcoinKit
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2018 BitcoinKit developers. All rights reserved.
//

import Foundation

struct OpIf: OpCodeProtocol {
    var value: UInt8 { return 0x63 }
}
