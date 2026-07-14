//
//  CommonTronGaslessTokenFeeLoader.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import TangemFoundation

struct CommonTronGaslessTokenFeeLoader {
    @Injected(\.gaslessTransactionsNetworkManager)
    private var networkManager: GaslessTransactionsNetworkManager

    let tokenItem: TokenItem
    let feeToken: BSDKToken
    let sourceAddress: String
    let tronGaslessTransactionsBuilder: any TronGaslessTransactionsBuilder
}

// MARK: - TokenFeeLoader

extension CommonTronGaslessTokenFeeLoader: TokenFeeLoader {
    func estimatedFee(amount: Decimal) async throws -> [BSDKFee] {
        try await makeFee(amount: amount, destination: sourceAddress)
    }

    func getFee(amount: Decimal, destination: String) async throws -> [BSDKFee] {
        try await makeFee(amount: amount, destination: destination)
    }
}

// MARK: - Private

private extension CommonTronGaslessTokenFeeLoader {
    func makeFee(amount: Decimal, destination: String) async throws -> [BSDKFee] {
        guard FeatureProvider.isAvailable(.tronGasless) else {
            return []
        }

        guard let tokenContract = tokenItem.contractAddress else {
            throw TokenFeeLoaderError.gaslessEthereumTokenFeeSupportOnlyTokenAsFeeTokenItem
        }

        let amount = BSDKAmount(with: tokenItem.blockchain, type: tokenItem.amountType, value: amount)
        guard let amountRaw = amount.bigUIntValue?.description else {
            throw TokenFeeLoaderError.notEnoughFeeBalance
        }

        let request = GaslessTransactionsDTO.Request.TronEstimate(
            fromAddress: sourceAddress,
            toAddress: destination,
            tokenContract: tokenContract,
            amount: amountRaw,
            feeTokenContract: feeToken.contractAddress
        )

        let quote = try await networkManager.estimateTronGaslessTransaction(request)
        guard let compensationAmount = Decimal(stringValue: quote.compensationAmount) else {
            throw TokenFeeLoaderError.notEnoughFeeBalance
        }

        let feeAmount = BSDKAmount(with: feeToken, value: compensationAmount)
        let parameters = TronGaslessFeeParameters(
            quoteId: quote.quoteId,
            feeRecipient: quote.feeRecipient,
            compensationToken: quote.compensationToken,
            compensationAmountRaw: quote.compensationAmountRaw,
            expiresAt: quote.expiresAt,
            energy: quote.estimate.energy,
            bandwidth: quote.estimate.bandwidth,
            trxCost: quote.estimate.trxCost
        )

        return [BSDKFee(feeAmount, parameters: parameters)]
    }
}
