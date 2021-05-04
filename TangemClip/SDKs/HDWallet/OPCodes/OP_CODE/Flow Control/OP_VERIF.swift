//
//  OP_VERIF.swift
//  BitcoinKit
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2018 BitcoinKit developers. All rights reserved.
//

import Foundation

// Transaction is invalid unless occuring in an unexecuted OP_IF branch
public struct OpVerIf: OpCodeProtocol {
    public var value: UInt8 { return 0x65 }
    public var name: String { return "OP_VERIF" }
 
}
