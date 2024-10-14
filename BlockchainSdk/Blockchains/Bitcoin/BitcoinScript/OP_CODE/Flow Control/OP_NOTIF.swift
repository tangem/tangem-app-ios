//
//  OP_NOTIF.swift
//  BitcoinKit
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2018 BitcoinKit developers. All rights reserved.
//

import Foundation

public struct OpNotIf: OpCodeProtocol {
    public var value: UInt8 { return 0x64 }
    public var name: String { return "OP_NOTIF" }
}
