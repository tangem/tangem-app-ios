//
//  SolanaFeeParameters.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct SolanaFeeParameters: FeeParameters {
    let computeUnitLimit: UInt32?
    let computeUnitPrice: UInt64?

    /// for network request optimization purpose
    let destinationAccountExists: Bool

    init(destinationAccountExists: Bool, computeUnitLimit: UInt32?, computeUnitPrice: UInt64?) {
        self.destinationAccountExists = destinationAccountExists
        self.computeUnitLimit = computeUnitLimit
        self.computeUnitPrice = computeUnitPrice
    }
}
