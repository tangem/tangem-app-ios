//
//  GaslessFeeEstimator.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BigInt

struct GaslessFeeEstimator {
    
    // MARK: - Dependencies
    
    private let walletManager: EthereumWalletManager
    
    // MARK: - Init

    init(walletManager: EthereumWalletManager) {
        self.walletManager = walletManager
    }
    
    // MARK: - Public Implementation
    
    /// Estimates the gasless fee for a token transfer.
    func estimateFee(
        feeToken: Token,
        amount: Amount,
        destination: String,
        feeRecipientAddress: String,
        nativeToFeeTokenRate: Decimal
    ) async throws -> Fee {
        let sanitizedAmount = EthereumWalletManager.sanitizeAmount(amount, wallet: walletManager.wallet)
        let innerFee = try await walletManager.getFee(amount: sanitizedAmount, destination: destination).async()

        return try await buildGaslessFee(
            feeToken: feeToken,
            innerOperationFee: innerFee,
            feeRecipientAddress: feeRecipientAddress,
            nativeToFeeTokenRate: nativeToFeeTokenRate
        )
    }

    /// Estimates the gasless fee for an arbitrary contract call (approve, etc.).
    func estimateFee(
        feeToken: Token,
        destination: String,
        value: String?,
        data: Data?,
        feeRecipientAddress: String,
        nativeToFeeTokenRate: Decimal
    ) async throws -> Fee {
        let innerFee = try await walletManager.getFee(destination: destination, value: value, data: data).async()

        return try await buildGaslessFee(
            feeToken: feeToken,
            innerOperationFee: innerFee,
            feeRecipientAddress: feeRecipientAddress,
            nativeToFeeTokenRate: nativeToFeeTokenRate
        )
    }
}

// MARK: - Private

private extension GaslessFeeEstimator {
    func buildGaslessFee(
        feeToken: Token,
        innerOperationFee: [Fee],
        feeRecipientAddress: String,
        nativeToFeeTokenRate: Decimal
    ) async throws -> Fee {
        // Addresses
        let ourAddress = walletManager.wallet.defaultAddress.value
        let convertedFeeRecipientAddress = try walletManager.addressConverter.convertToETHAddress(feeRecipientAddress)
        let convertedOurAddress = try walletManager.addressConverter.convertToETHAddress(ourAddress)

        // Fixed fee token amount (10000 minimal units)
        let baseTokenAmount = EthereumFeeParametersConstants.gaslessMinTokenAmount

        // 1) Build calldata for transferring fixed fee token amount to Gasless collector
        let tokenTransferData = TransferERC20TokenMethod(destination: convertedFeeRecipientAddress, amount: baseTokenAmount).encodedData

        // 2) Estimate gas limit for fee token transfer
        let feeTransferGasLimit = try await walletManager.getGasLimit(
            to: feeToken.contractAddress,
            from: convertedOurAddress,
            value: nil,
            data: tokenTransferData
        ).async()

        // 3) Add 10% buffer to fee token transfer gas limit (multiply by 1.1 using integer math)
        let feeTransferGasLimitBuffered = feeTransferGasLimit * BigUInt(11) / BigUInt(10)

        // 4) Pick the market fee (index 1) from the inner operation fees array.
        guard let params = innerOperationFee[safe: 1]?.parameters as? EthereumEIP1559FeeParameters else {
            throw BlockchainSdkError.failedToGetFee
        }

        // 5) Combine gas limits and add BASE_GAS buffer (60_000)
        let newGasLimit = params.gasLimit + feeTransferGasLimitBuffered + EthereumFeeParametersConstants.gaslessBaseGasBuffer

        // 6) Create updated fee params
        let newParams = EthereumGaslessTransactionFeeParameters(
            gasLimit: newGasLimit,
            maxFeePerGas: params.maxFeePerGas,
            priorityFee: params.priorityFee,
            nativeToFeeTokenRate: nativeToFeeTokenRate,
            feeTokenTransferGasLimit: feeTransferGasLimitBuffered
        )

        // 7) Compute the fee amount.
        // IMPORTANT: The fee is calculated in the token using the provided nativeToFeeTokenRate,
        // buffered by +1% (buffering is done by calculateFee).
        var fee = newParams.calculateFee(decimalValue: walletManager.wallet.blockchain.decimalValue)

        // 8) Round the fee to the fee token's decimal precision
        fee = fee.rounded(scale: feeToken.decimalCount)

        // 9) Return Fee with updated params and computed amount
        return Fee(.init(with: feeToken, value: fee), parameters: newParams)
    }
}
