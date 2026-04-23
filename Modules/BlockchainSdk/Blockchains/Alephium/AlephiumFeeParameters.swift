//
//  AlephiumFeeParameters.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

struct AlephiumFeeParameters: FeeParameters {
    let gasPrice: Decimal
    let gasAmount: Int
}
