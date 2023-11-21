//
//  CommonExpressTransactionBuilder.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import TangemSwapping

struct CommonExpressTransactionBuilder: ExpressTransactionBuilder {
    func makeTransaction(wallet: WalletModel, data: ExpressTransactionData, fee: Fee) async throws -> BlockchainSdk.Transaction {
        let amount = Amount(with: wallet.tokenItem.blockchain, type: wallet.amountType, value: data.value)

        var transaction = BlockchainSdk.Transaction(
            amount: amount,
            fee: fee,
            sourceAddress: data.sourceAddress,
            destinationAddress: data.destinationAddress,
            changeAddress: data.sourceAddress,
            contractAddress: data.destinationAddress
        )

        // In EVM-like blockchains we should add the txData to the transaction
        if let ethereumNetworkProvider = wallet.ethereumNetworkProvider {
            let nonce = try await ethereumNetworkProvider.getTxCount(data.sourceAddress).async()
            transaction.params = EthereumTransactionParams(
                data: data.txData.map { Data(hexString: $0) },
                nonce: nonce
            )
        }

        return transaction
    }
}
