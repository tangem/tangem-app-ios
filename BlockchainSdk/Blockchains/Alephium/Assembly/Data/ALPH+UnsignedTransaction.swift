//
//  UnsignedTransaction.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

extension ALPH {
    /// A struct representing an unsigned transaction in the Alephium blockchain
    /// Contains all the necessary information to construct a valid transaction before signing
    struct UnsignedTransaction {
        /// The version number of the transaction format
        let version: Byte

        /// The network ID indicating which Alephium network this transaction is for (mainnet/testnet)
        let networkId: NetworkId

        /// The amount of gas allocated for executing this transaction
        let gasAmount: GasBox

        /// The price per unit of gas that will be paid for this transaction
        let gasPrice: GasPrice

        /// The inputs to be consumed by this transaction
        let inputs: AVector<TxInputInfo>

        /// The outputs to be created by [REDACTED_AUTHOR]
        let fixedOutputs: AVector<AssetOutput>

        // MARK: - TransactionId

        var transactionId: TransactionId {
            TransactionId.hash(bytes: UnsignedTransactionSerde().serialize(self))
        }
    }
}
