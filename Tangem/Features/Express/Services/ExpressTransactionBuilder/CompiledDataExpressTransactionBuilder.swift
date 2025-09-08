//
//  CompiledDataExpressTransactionBuilder.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import TangemExpress

struct CompiledDataExpressTransactionBuilder: ExpressTransactionBuilder {
    private let tokenItem: TokenItem
    private let feeTokenItem: TokenItem
    private let transactionCreator: TransactionCreator

    init(
        tokenItem: TokenItem,
        feeTokenItem: TokenItem,
        transactionCreator: TransactionCreator,
    ) {
        self.tokenItem = tokenItem
        self.feeTokenItem = feeTokenItem
        self.transactionCreator = transactionCreator
    }

    func makeTransaction(data: ExpressTransactionData, fee: Fee) async throws -> ExpressTransactionResult {
        let bsdkTransaction = try await makeTransaction(data, fee: fee)
        return .default(bsdkTransaction)
    }

    func makeApproveTransaction(data: ApproveTransactionData, fee: Fee) async throws -> ExpressTransactionResult {
        let bsdkTransaction = try await makeApproveTransaction(data, fee: fee)
        return .default(bsdkTransaction)
    }
}

private extension CompiledDataExpressTransactionBuilder {
    func makeTransaction(_ data: ExpressTransactionData, fee: Fee) async throws -> BlockchainSdk.Transaction {
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

    func makeApproveTransaction(_ data: ApproveTransactionData, fee: Fee) async throws -> BlockchainSdk.Transaction {
        throw ExpressTransactionBuilderError.approveImpossibleInNotEvmBlockchain
    }

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
