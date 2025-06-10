//
//  ALPH+AssetOutput.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

extension ALPH {
    /// A struct representing an asset output in the Alephium blockchain
    /// Contains information about the amount, lockup script, lock time, tokens, and additional data
    struct AssetOutput: TxOutput {
        /// The amount of the asset, represented as a U256 (unsigned 256-bit integer)
        let amount: U256

        /// The lockup script that specifies the conditions for unlocking the output
        let lockupScript: LockupScript

        /// The lock time for the output, represented as a TimeStamp
        let lockTime: TimeStamp

        /// An array of tuples, each containing a TokenId and the amount of that token in the output
        let tokens: AVector<(TokenId, U256)>

        /// The optional additional data for the output, represented as a Data object
        let additionalData: Data

        /// Returns true if the output is an asset
        var isAsset: Bool {
            return true
        }

        /// Returns a hint for the asset output
        var hint: Hint {
            Hint.from(self)
        }

        /// Returns true if the output is a contract
        var isContract: Bool {
            false
        }

        /// Deducts the gas fee from the output amount.
        /// - Parameter fee: The amount of gas to deduct
        /// - Returns: A new TxOutput with the deducted gas fee
        func payGasUnsafe(fee: U256) -> TxOutput {
            AssetOutput(
                amount: amount.sub(fee) ?? .zero,
                lockupScript: lockupScript,
                lockTime: lockTime,
                tokens: tokens,
                additionalData: additionalData
            )
        }
    }
}
