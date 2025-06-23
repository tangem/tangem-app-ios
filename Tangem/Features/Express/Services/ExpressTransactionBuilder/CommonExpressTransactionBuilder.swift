//
//  CommonExpressTransactionBuilder.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import TangemExpress

struct CommonExpressTransactionBuilder: ExpressTransactionBuilder {
    private let tokenItem: TokenItem
    private let feeTokenItem: TokenItem
    private let transactionCreator: TransactionCreator
    private let ethereumNetworkProvider: EthereumNetworkProvider?

    init(
        tokenItem: TokenItem,
        feeTokenItem: TokenItem,
        transactionCreator: TransactionCreator,
        ethereumNetworkProvider: EthereumNetworkProvider?
    ) {
        self.tokenItem = tokenItem
        self.feeTokenItem = feeTokenItem
        self.transactionCreator = transactionCreator
        self.ethereumNetworkProvider = ethereumNetworkProvider
    }

    func makeTransaction(data: ExpressTransactionData, fee: Fee) async throws -> BlockchainSdk.Transaction {
        var transactionParams: TransactionParams?

        if let extraDestinationId = data.extraDestinationId, !extraDestinationId.isEmpty {
            // If we received a extraId then try to map it to specific TransactionParams
            let builder = TransactionParamsBuilder(blockchain: tokenItem.blockchain)
            transactionParams = try builder.transactionParameters(value: extraDestinationId)
        }

        let destination: TransactionCreatorDestination = try {
            switch data.transactionType {
            case .send:
                return .send(destination: data.destinationAddress, transactionParams: transactionParams)
            case .swap:
                if let txData = data.txData {
                    return .contractCall(contract: data.destinationAddress, data: Data(hexString: txData))
                }

                throw ExpressTransactionBuilderError.transactionDataForSwapOperationNotFound
            }
        }()

        let transaction = try await buildTransaction(
            amount: data.txValue,
            fee: fee,
            destination: destination
        )

        return transaction
    }

    func makeApproveTransaction(data: ApproveTransactionData, fee: Fee) async throws -> BlockchainSdk.Transaction {
        guard ethereumNetworkProvider != nil else {
            throw ExpressTransactionBuilderError.approveImpossibleInNotEvmBlockchain
        }

        let transaction = try await buildTransaction(
            amount: 0, // For approve value isn't needed
            fee: fee,
            destination: .contractCall(contract: data.toContractAddress, data: data.txData)
        )

        return transaction
    }
}

private extension CommonExpressTransactionBuilder {
    func buildTransaction(
        amount: Decimal,
        fee: Fee,
        destination: TransactionCreatorDestination
    ) async throws -> BSDKTransaction {
        try await transactionCreator.buildTransaction(
            tokenItem: tokenItem,
            feeTokenItem: feeTokenItem,
            amount: amount,
            fee: fee,
            destination: destination
        )
    }
}

enum ExpressTransactionBuilderError: LocalizedError {
    case approveImpossibleInNotEvmBlockchain
    case transactionDataForSwapOperationNotFound
}
