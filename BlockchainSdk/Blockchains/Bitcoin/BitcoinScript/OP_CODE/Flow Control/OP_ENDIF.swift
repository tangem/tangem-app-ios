//
//  OP_ENDIF.swift
//  BitcoinKit
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2018 BitcoinKit developers. All rights reserved.
//

import Foundation

public struct OpEndIf: OpCodeProtocol {
    public var value: UInt8 { return 0x68 }
    public var name: String { return "OP_ENDIF" }
}
