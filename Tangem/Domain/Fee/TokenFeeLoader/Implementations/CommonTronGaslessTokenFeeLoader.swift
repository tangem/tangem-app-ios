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
    let tokenItem: TokenItem
    let feeToken: BSDKToken
    let sourceAddress: String

    private let networkManager: GaslessTransactionsNetworkManager

    init(
        tokenItem: TokenItem,
        feeToken: BSDKToken,
        sourceAddress: String,
        networkManager: GaslessTransactionsNetworkManager = InjectedValues[\.gaslessTransactionsNetworkManager]
    ) {
        self.tokenItem = tokenItem
        self.feeToken = feeToken
        self.sourceAddress = sourceAddress
        self.networkManager = networkManager
    }
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
        guard let tokenContract = tokenItem.contractAddress else {
            throw TokenFeeLoaderError.gaslessTronTokenFeeSupportOnlyTokenTransactions
        }

        let transactionAmount = BSDKAmount(with: tokenItem.blockchain, type: tokenItem.amountType, value: amount)
        guard let amountRaw = transactionAmount.bigUIntValue?.description else {
            throw TokenFeeLoaderError.gaslessTronTransactionAmountConversionFailed(amount)
        }

        let quoteRequest = TronGaslessQuoteRequest(
            sourceAddress: sourceAddress,
            destinationAddress: destination,
            tokenContractAddress: tokenContract,
            amountRaw: amountRaw,
            feeTokenContractAddress: feeToken.contractAddress
        )
        let request = GaslessTransactionsDTO.Request.TronEstimate(
            fromAddress: sourceAddress,
            toAddress: destination,
            tokenContract: tokenContract,
            amount: amountRaw,
            feeTokenContract: feeToken.contractAddress
        )

        let quote = try await networkManager.estimateTronGaslessTransaction(request)
        guard let compensationAmountRaw = Decimal(stringValue: quote.compensationAmountRaw) else {
            throw TokenFeeLoaderError.invalidGaslessTronCompensationAmount(quote.compensationAmountRaw)
        }

        let compensationAmount = compensationAmountRaw / pow(10, feeToken.decimalCount)
        let feeAmount = BSDKAmount(with: feeToken, value: compensationAmount)
        let parameters = TronGaslessFeeParameters(
            quoteId: quote.quoteId,
            request: quoteRequest,
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
