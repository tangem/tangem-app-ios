//
//  UnspentTransaction.swift
//  TangemKit
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Smart Cash AG. All rights reserved.
//

import Foundation

struct UnspentTransaction {
    let amount: UInt64
    let outputIndex: Int
    let hash: [UInt8]
    let outputScript: [UInt8]
}
