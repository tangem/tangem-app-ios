//
//  Alephium+GasPrice.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

extension ALPH {
    /// A struct representing the gas price in the Alephium blockchain
    /// Gas price is used to determine the cost of executing a transaction
    struct GasPrice: Comparable {
        /// The value of the gas price, represented as a U256 (unsigned 256-bit integer)
        let value: U256

        // MARK: - Comparable

        static func * (lhs: GasPrice, rhs: GasBox) -> U256 {
            return lhs.value.mulUnsafe(rhs.toU256())
        }

        static func == (lhs: GasPrice, rhs: GasPrice) -> Bool {
            return lhs.value == rhs.value
        }

        static func < (lhs: GasPrice, rhs: GasPrice) -> Bool {
            return lhs.value < rhs.value
        }
    }
}
