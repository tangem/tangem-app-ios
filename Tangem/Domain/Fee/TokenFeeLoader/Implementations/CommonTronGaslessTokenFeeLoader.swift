//
//  CommonTronGaslessTokenFeeLoader.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BigInt
import BlockchainSdk
import TangemFoundation

struct CommonTronGaslessTokenFeeLoader {
    let tokenItem: TokenItem
    let feeToken: BSDKToken
    let sourceAddress: String
    let userWalletId: UserWalletId

    private let networkManager: GaslessTransactionsNetworkManager
    private let isDEXEnabled: Bool

    init(
        tokenItem: TokenItem,
        feeToken: BSDKToken,
        sourceAddress: String,
        userWalletId: UserWalletId,
        isDEXEnabled: Bool,
        networkManager: GaslessTransactionsNetworkManager = InjectedValues[\.gaslessTransactionsNetworkManager]
    ) {
        self.tokenItem = tokenItem
        self.feeToken = feeToken
        self.sourceAddress = sourceAddress
        self.userWalletId = userWalletId
        self.isDEXEnabled = isDEXEnabled
        self.networkManager = networkManager
    }
}

// MARK: - TokenFeeLoader

extension CommonTronGaslessTokenFeeLoader: TokenFeeLoader {
    var rejectsBridgeCoinFee: Bool { true }

    func estimatedFee(amount: Decimal) async throws -> [BSDKFee] {
        let destination = try tokenItem.blockchain.feeEstimationAddress
        return try await makeFee(amount: amount, destination: destination)
    }

    func getFee(amount: Decimal, destination: String) async throws -> [BSDKFee] {
        try await makeFee(amount: amount, destination: destination)
    }

    func supports(_ input: TokenFeeProviderInputData) -> Bool {
        switch input {
        case .common, .cex:
            return true
        case .dex(.tron):
            return isDEXEnabled
        case .approve(_, _, let spender, _, _):
            return isDEXEnabled && spender != nil
        case .dex(.ethereum), .dex(.ethereumEstimate), .dex(.solana), .dex(.bitcoinPsbt), .approveWithSwap:
            return false
        }
    }

    func loadFees(_ input: TokenFeeProviderInputData, feeBlockchain _: Blockchain) async throws -> [BSDKFee] {
        switch input {
        case .common(let amount, let destination):
            return try await getFee(amount: amount, destination: destination)
        case .cex(let amount):
            return try await estimatedFee(amount: amount)
        case .dex(.tron(let request, let sourceAmount, let spender)):
            guard isDEXEnabled, let callData = request.callData else {
                throw TokenFeeLoaderError.tokenFeeLoaderNotFound
            }

            return try await getSwapFee(
                amount: sourceAmount,
                contractAddress: request.destination,
                callData: callData,
                spender: spender
            )
        case .approve(let txData, let toContractAddress, let spender, let amountRaw, _):
            guard isDEXEnabled, let spender else {
                throw TokenFeeLoaderError.tokenFeeLoaderNotFound
            }

            return try await getApproveFee(
                amountRaw: amountRaw,
                tokenContract: toContractAddress,
                spender: spender,
                callData: txData
            )
        case .dex(.ethereum), .dex(.ethereumEstimate), .dex(.solana), .dex(.bitcoinPsbt), .approveWithSwap:
            throw TokenFeeLoaderError.tokenFeeLoaderNotFound
        }
    }
}

extension CommonTronGaslessTokenFeeLoader {
    func getApproveFee(
        amountRaw: BigUInt,
        tokenContract: String,
        spender: String,
        callData: Data
    ) async throws -> [BSDKFee] {
        let quoteRequest = TronGaslessQuoteRequest(
            sourceAddress: sourceAddress,
            tokenContractAddress: tokenContract,
            amountRaw: amountRaw,
            feeTokenContractAddress: feeToken.contractAddress,
            operation: .approve(contractAddress: tokenContract, spender: spender, callData: callData)
        )
        let request = GaslessTransactionsDTO.Request.TronEstimate(
            fromAddress: sourceAddress,
            tokenContract: tokenContract,
            amount: String(amountRaw, radix: 10),
            feeTokenContract: feeToken.contractAddress,
            approve: .init(spender: spender)
        )

        return try await makeFee(request: request, quoteRequest: quoteRequest)
    }

    func getSwapFee(
        amount: Decimal,
        contractAddress: String,
        callData: Data,
        spender: String?
    ) async throws -> [BSDKFee] {
        guard let tokenContract = tokenItem.contractAddress else {
            throw TokenFeeLoaderError.gaslessTronTokenFeeSupportOnlyTokenTransactions
        }

        let amountRaw = try rawAmount(amount)
        let quoteRequest = TronGaslessQuoteRequest(
            sourceAddress: sourceAddress,
            tokenContractAddress: tokenContract,
            amountRaw: amountRaw,
            feeTokenContractAddress: feeToken.contractAddress,
            operation: .swap(contractAddress: contractAddress, callData: callData, spender: spender)
        )
        let request = GaslessTransactionsDTO.Request.TronEstimate(
            fromAddress: sourceAddress,
            tokenContract: tokenContract,
            amount: String(amountRaw, radix: 10),
            feeTokenContract: feeToken.contractAddress,
            swap: .init(
                contractAddress: contractAddress,
                data: callData.hexString,
                spender: spender
            )
        )

        return try await makeFee(request: request, quoteRequest: quoteRequest)
    }
}

// MARK: - Private

private extension CommonTronGaslessTokenFeeLoader {
    func makeFee(amount: Decimal, destination: String) async throws -> [BSDKFee] {
        guard let tokenContract = tokenItem.contractAddress else {
            throw TokenFeeLoaderError.gaslessTronTokenFeeSupportOnlyTokenTransactions
        }

        let amountRaw = try rawAmount(amount)
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
            amount: String(amountRaw, radix: 10),
            feeTokenContract: feeToken.contractAddress
        )

        return try await makeFee(request: request, quoteRequest: quoteRequest)
    }

    func makeFee(
        request: GaslessTransactionsDTO.Request.TronEstimate,
        quoteRequest: TronGaslessQuoteRequest
    ) async throws -> [BSDKFee] {
        let quote = try await networkManager.estimateTronGaslessTransaction(request, userWalletId: userWalletId)
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

    func rawAmount(_ amount: Decimal) throws -> BigUInt {
        let transactionAmount = BSDKAmount(with: tokenItem.blockchain, type: tokenItem.amountType, value: amount)
        guard let amountRaw = transactionAmount.bigUIntValue else {
            throw TokenFeeLoaderError.gaslessTronTransactionAmountConversionFailed(amount)
        }

        return amountRaw
    }
}
