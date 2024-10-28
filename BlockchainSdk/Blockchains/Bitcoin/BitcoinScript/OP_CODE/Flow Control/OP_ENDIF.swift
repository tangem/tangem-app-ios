//
//  OP_ENDIF.swift
//  BitcoinKit
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2018 BitcoinKit developers. All rights reserved.
//

import Foundation

struct OpEndIf: OpCodeProtocol {
    var value: UInt8 { return 0x68 }
    var name: String { return "OP_ENDIF" }
}
