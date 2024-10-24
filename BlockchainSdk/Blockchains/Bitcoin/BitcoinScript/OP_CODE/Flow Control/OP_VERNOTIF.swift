//
//  OP_VERNOTIF.swift
//  BitcoinKit
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2018 BitcoinKit developers. All rights reserved.
//

import Foundation

public struct OpVerNotIf: OpCodeProtocol {
    public var value: UInt8 { return 0x66 }
    public var name: String { return "OP_VERNOTIF" }
}
