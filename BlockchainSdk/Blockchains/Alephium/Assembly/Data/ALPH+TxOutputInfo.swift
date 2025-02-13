//
//  ALPH+TxOutputInfo.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

extension ALPH {
    /// A struct representing the information about a transaction output in the Alephium blockchain
    /// It contains details about the lockup script, the amount of ALPH, the tokens included, and optional lock time and additional data
    struct TxOutputInfo {
        /// The lockup script that specifies the conditions for unlocking the output
        let lockupScript: LockupScript

        /// The amount of ALPH in the output, represented as a U256 (unsigned 256-bit integer)
        let attoAlphAmount: U256

        /// An array of tuples, each containing a TokenId and the amount of that token in the output
        let tokens: [(id: TokenId, amount: U256)]

        /// The optional lock time for the output, represented as a TimeStamp
        let lockTime: TimeStamp?

        /// The optional additional data for the output, represented as a Data object
        let additionalData: Data?

        init(
            lockupScript: LockupScript,
            attoAlphAmount: U256,
            tokens: [(TokenId, U256)] = [],
            lockTime: TimeStamp? = nil,
            additionalData: Data? = nil
        ) {
            self.lockupScript = lockupScript
            self.attoAlphAmount = attoAlphAmount
            self.tokens = tokens.map { (id: $0.0, amount: $0.1) }
            self.lockTime = lockTime
            self.additionalData = additionalData
        }
    }
}
