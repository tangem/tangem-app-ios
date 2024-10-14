//
//  OP_ELSE.swift
//  BitcoinKit
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2018 BitcoinKit developers. All rights reserved.
//

import Foundation

public struct OpElse: OpCodeProtocol {
    public var value: UInt8 { return 0x67 }
    public var name: String { return "OP_ELSE" }
}
