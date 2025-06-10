//
//  AlephiumUTXO.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

struct AlephiumUTXO {
    let hint: Int
    let key: String
    let value: Decimal
    let lockTime: Int64
    let additionalData: String

    var isConfirmed: Bool {
        lockTime != 0
    }
}
