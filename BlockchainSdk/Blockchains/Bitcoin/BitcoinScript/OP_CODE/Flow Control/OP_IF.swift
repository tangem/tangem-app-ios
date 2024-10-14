//
//  OP_IF.swift
//  BitcoinKit
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2018 BitcoinKit developers. All rights reserved.
//

import Foundation

public struct OpIf: OpCodeProtocol {
    public var value: UInt8 { return 0x63 }
    public var name: String { return "OP_IF" }
}
