//
//  OP_VER.swift
//  BitcoinKit
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2018 BitcoinKit developers. All rights reserved.
//

import Foundation

struct OpVer: OpCodeProtocol {
    var value: UInt8 { return 0x62 }
    var name: String { return "OP_VER" }
}
