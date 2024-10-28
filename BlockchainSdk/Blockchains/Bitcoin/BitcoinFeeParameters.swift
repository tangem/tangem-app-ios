//
//  BitcoinFeeParameters.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

public struct BitcoinFeeParameters: FeeParameters {
    /// Fee rate per byte in satoshi
    public let rate: Int

    init(rate: Int) {
        self.rate = rate
    }
}
