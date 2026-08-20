//
//  CommonSendYieldModuleHelper.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BigInt
import BlockchainSdk
import TangemExpress
import TangemFoundation

final class CommonSendYieldModuleHelper: SendYieldModuleHelper {
    var yieldContractAddress: String? { yieldContract }

    private let yieldContract: String
    private let currency: ExpressWalletCurrency
    private let swapExecutionRegistryProvider: YieldModuleSwapExecutionRegistryProvider?
    private let yieldModuleUpgradeHandler: YieldModuleUpgradeHandler?
    private let isTransferDetectionAvailable: Bool

    init(
        yieldContractAddress: String,
        currency: ExpressWalletCurrency,
        swapExecutionRegistryProvider: YieldModuleSwapExecutionRegistryProvider?,
        yieldModuleUpgradeHandler: YieldModuleUpgradeHandler?,
        isTransferDetectionAvailable: Bool
    ) {
        yieldContract = yieldContractAddress
        self.currency = currency
        self.swapExecutionRegistryProvider = swapExecutionRegistryProvider
        self.yieldModuleUpgradeHandler = yieldModuleUpgradeHandler
        self.isTransferDetectionAvailable = isTransferDetectionAvailable
    }

    func prepareForYieldModuleDEXSwap(provider: ExpressProvider) async throws {
        guard isYieldModuleDEXSwap(provider: provider) else {
            return
        }

        guard let yieldModuleUpgradeHandler else {
            throw ExpressProviderError.yieldModuleSwapUnavailable(.moduleUpgradeUnavailable)
        }

        try await yieldModuleUpgradeHandler.checkSwapAvailability()
    }

    func yieldModuleTransactionData(
        data: ExpressTransactionData,
        provider: ExpressProvider,
        spender: String?
    ) async throws -> ExpressTransactionData {
        guard isYieldModuleDEXSwap(provider: provider) else {
            return data
        }

        guard let txData = data.txData else {
            throw ExpressProviderError.yieldModuleSwapUnavailable(.transactionDataNotFound)
        }

        // Legacy flow preserved as is. This check and flow will be removed
        // when the feature toggle for `isTransferDetectionAvailable` is removed
        guard isTransferDetectionAvailable else {
            return try await makeSwapCallData(data: data, txData: txData, spender: spender)
        }

        let isTransferCalldata = TransferERC20TokenMethod.isEncodedCall(txData)
        let sendsToSwappedTokenContract = data.destinationAddress.caseInsensitiveEquals(to: currency.contractAddress)

        switch (isTransferCalldata, sendsToSwappedTokenContract) {
        case (false, false):
            return try await makeSwapCallData(data: data, txData: txData, spender: spender)

        case (true, true):
            return try makeSendCallData(data: data, txData: txData)

        default:
            throw ExpressProviderError.yieldModuleSwapUnavailable(.transferAndSwapIndicatorsConflict)
        }
    }

    private func makeSwapCallData(
        data: ExpressTransactionData,
        txData: String,
        spender: String?
    ) async throws -> ExpressTransactionData {
        guard let spender else {
            throw ExpressProviderError.yieldModuleSwapUnavailable(.spenderNotFound)
        }

        guard let swapExecutionRegistryProvider else {
            throw ExpressProviderError.yieldModuleSwapUnavailable(.swapExecutionRegistryUnavailable)
        }

        guard try await swapExecutionRegistryProvider.isAllowedSpender(spender) else {
            throw ExpressProviderError.yieldModuleSwapUnavailable(.spenderNotAllowed)
        }

        guard try await swapExecutionRegistryProvider.isAllowedTarget(data.destinationAddress) else {
            throw ExpressProviderError.yieldModuleSwapUnavailable(.targetNotAllowed)
        }

        let amountIn = try makeAmountInWEI(from: data)
        let method = YieldModuleSwapMethod(
            tokenIn: currency.contractAddress,
            amountIn: amountIn,
            target: data.destinationAddress,
            spender: spender,
            swapData: Data(hexString: txData)
        )

        let yieldSwapData = makeYieldModuleCallData(from: data, method: method)

        guard let yieldModuleUpgradeHandler else {
            return yieldSwapData
        }

        return try await yieldModuleUpgradeHandler.upgradeWrappedDataIfNeeded(yieldSwapData)
    }

    private func makeSendCallData(
        data: ExpressTransactionData,
        txData: String
    ) throws -> ExpressTransactionData {
        guard let transfer = TransferERC20TokenMethod(calldata: Data(hexString: txData)) else {
            throw ExpressProviderError.yieldModuleSwapUnavailable(.transferCalldataMalformed)
        }

        guard !transfer.destination.caseInsensitiveEquals(to: Constants.zeroAddress) else {
            throw ExpressProviderError.yieldModuleSwapUnavailable(.transferToZeroAddress)
        }

        let expectedAmount = try makeAmountInWEI(from: data)

        guard transfer.amount == expectedAmount else {
            throw ExpressProviderError.yieldModuleSwapUnavailable(.transferAmountMismatch)
        }

        let method = try YieldSendMethod(
            tokenContractAddress: currency.contractAddress,
            destination: transfer.destination,
            amount: transfer.amount
        )

        return makeYieldModuleCallData(from: data, method: method)
    }

    private func makeAmountInWEI(from data: ExpressTransactionData) throws -> BigUInt {
        guard let amountIn = BigUInt(currency.convertToWEI(value: data.fromAmount).roundedDownDecimalNumber.stringValue) else {
            throw ExpressProviderError.yieldModuleSwapUnavailable(.amountInInvalid)
        }

        return amountIn
    }

    private func makeYieldModuleCallData(
        from data: ExpressTransactionData,
        method: SmartContractMethod
    ) -> ExpressTransactionData {
        ExpressTransactionData(
            requestId: data.requestId,
            fromAmount: data.fromAmount,
            toAmount: data.toAmount,
            expressTransactionId: data.expressTransactionId,
            transactionType: data.transactionType,
            sourceAddress: data.sourceAddress,
            destinationAddress: yieldContract,
            extraDestinationId: data.extraDestinationId,
            txValue: data.txValue,
            txData: method.encodedData,
            otherNativeFee: data.otherNativeFee,
            estimatedGasLimit: data.estimatedGasLimit,
            externalTxId: data.externalTxId,
            externalTxURL: data.externalTxURL,
            payInAddress: data.payInAddress
        )
    }

    func refreshVersionAfterUpgrade() async throws {
        try await yieldModuleUpgradeHandler?.refreshVersionAfterUpgrade()
    }

    func isUpgradeWrapped(_ data: ExpressTransactionData) -> Bool {
        yieldModuleUpgradeHandler?.isUpgradeWrapped(data) == true
    }

    private func isYieldModuleDEXSwap(provider: ExpressProvider) -> Bool {
        switch provider.type {
        case .dex, .dexBridge:
            return true
        case .cex, .onramp, .unknown:
            return false
        }
    }
}

// MARK: - Constants

private extension CommonSendYieldModuleHelper {
    enum Constants {
        static let zeroAddress = "0x" + String(repeating: "0", count: 40)
    }
}
