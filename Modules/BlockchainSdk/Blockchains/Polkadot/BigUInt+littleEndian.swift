//
//  BigUInt+littleEndian.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import BigInt

extension BigUInt {
    init(littleEndian data: Data) {
        self = BigUInt(Data(data.reversed()))
    }
}
