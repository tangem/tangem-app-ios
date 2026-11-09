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
    private let newImplementationAddress: () async -> String?
    private let swapExecutionRegistryProvider: YieldModuleSwapExecutionRegistryProvider?
    private let yieldModuleUpgradeHandler: YieldModuleUpgradeHandler?

    init(
        yieldContractAddress: String,
        currency: ExpressWalletCurrency,
        newImplementationAddress: @escaping () async -> String?,
        swapExecutionRegistryProvider: YieldModuleSwapExecutionRegistryProvider?,
        yieldModuleUpgradeHandler: YieldModuleUpgradeHandler?
    ) {
        yieldContract = yieldContractAddress
        self.currency = currency
        self.newImplementationAddress = newImplementationAddress
        self.swapExecutionRegistryProvider = swapExecutionRegistryProvider
        self.yieldModuleUpgradeHandler = yieldModuleUpgradeHandler
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

        let isTransferCalldata = TransferERC20TokenMethod.isEncodedCall(txData)
        let sendsToSwappedTokenContract = data.destinationAddress.caseInsensitiveEquals(to: currency.contractAddress)

        switch (isTransferCalldata, sendsToSwappedTokenContract) {
        case (false, false):
            return try await makeSwapCallData(data: data, txData: txData, spender: spender)

        case (true, true):
            return try await makeSendCallData(data: data, txData: txData)

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
    ) async throws -> ExpressTransactionData {
        guard let transfer = TransferERC20TokenMethod(calldata: Data(hexString: txData)) else {
            throw ExpressProviderError.yieldModuleSwapUnavailable(.transferCalldataMalformed)
        }

        let expectedAmount = try makeAmountInWEI(from: data)

        guard transfer.amount == expectedAmount else {
            throw ExpressProviderError.yieldModuleSwapUnavailable(.transferAmountMismatch)
        }

        let sendMethod = try YieldSendMethod(
            tokenContractAddress: currency.contractAddress,
            destination: transfer.destination,
            amount: transfer.amount
        )

        guard let newImplementationAddress = await newImplementationAddress() else {
            return makeYieldModuleCallData(from: data, method: sendMethod)
        }

        let upgradingSendMethod = UpgradeToAndCallMethod(newImplementation: newImplementationAddress, callData: sendMethod.data)

        return makeYieldModuleCallData(from: data, method: upgradingSendMethod)
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
            payInAddress: data.payInAddress,
            slippage: data.slippage
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
