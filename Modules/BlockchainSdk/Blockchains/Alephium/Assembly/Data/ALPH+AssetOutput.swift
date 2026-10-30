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
    }
}
