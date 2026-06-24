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

final class CommonSendYieldModuleHelper: SendYieldModuleHelper {
    let yieldContractAddress: String?

    private let currency: ExpressWalletCurrency
    private let swapExecutionRegistryProvider: YieldModuleSwapExecutionRegistryProvider?
    private let yieldModuleUpgradeHandler: YieldModuleUpgradeHandler?

    init(
        yieldContractAddress: String,
        currency: ExpressWalletCurrency,
        swapExecutionRegistryProvider: YieldModuleSwapExecutionRegistryProvider?,
        yieldModuleUpgradeHandler: YieldModuleUpgradeHandler?
    ) {
        self.yieldContractAddress = yieldContractAddress
        self.currency = currency
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

    func yieldModuleDEXSwapData(data: ExpressTransactionData, provider: ExpressProvider, spender: String) async throws -> ExpressTransactionData {
        guard isYieldModuleDEXSwap(provider: provider) else {
            return data
        }

        guard let yieldContractAddress else {
            return data
        }

        guard let swapExecutionRegistryProvider else {
            throw ExpressProviderError.yieldModuleSwapUnavailable(.swapExecutionRegistryUnavailable)
        }

        guard let txData = data.txData else {
            throw ExpressProviderError.yieldModuleSwapUnavailable(.transactionDataNotFound)
        }

        guard try await swapExecutionRegistryProvider.isAllowedSpender(spender) else {
            throw ExpressProviderError.yieldModuleSwapUnavailable(.spenderNotAllowed)
        }

        guard try await swapExecutionRegistryProvider.isAllowedTarget(data.destinationAddress) else {
            throw ExpressProviderError.yieldModuleSwapUnavailable(.targetNotAllowed)
        }

        guard let amountIn = BigUInt(currency.convertToWEI(value: data.fromAmount).roundedDownDecimalNumber.stringValue) else {
            throw ExpressProviderError.yieldModuleSwapUnavailable(.amountInInvalid)
        }

        let method = YieldModuleSwapMethod(
            tokenIn: currency.contractAddress,
            amountIn: amountIn,
            target: data.destinationAddress,
            spender: spender,
            swapData: Data(hexString: txData)
        )

        let yieldSwapData = ExpressTransactionData(
            requestId: data.requestId,
            fromAmount: data.fromAmount,
            toAmount: data.toAmount,
            expressTransactionId: data.expressTransactionId,
            transactionType: data.transactionType,
            sourceAddress: data.sourceAddress,
            destinationAddress: yieldContractAddress,
            extraDestinationId: data.extraDestinationId,
            txValue: data.txValue,
            txData: method.encodedData,
            otherNativeFee: data.otherNativeFee,
            estimatedGasLimit: data.estimatedGasLimit,
            externalTxId: data.externalTxId,
            externalTxURL: data.externalTxURL,
            payInAddress: data.payInAddress
        )

        guard let yieldModuleUpgradeHandler else {
            return yieldSwapData
        }

        return try await yieldModuleUpgradeHandler.upgradeWrappedDataIfNeeded(yieldSwapData)
    }

    func refreshVersionAfterUpgrade() async throws {
        try await yieldModuleUpgradeHandler?.refreshVersionAfterUpgrade()
    }

    func isUpgradeWrapped(_ data: ExpressTransactionData) -> Bool {
        yieldModuleUpgradeHandler?.isUpgradeWrapped(data) == true
    }

    private func isYieldModuleDEXSwap(provider: ExpressProvider) -> Bool {
        guard yieldContractAddress != nil else {
            return false
        }

        switch provider.type {
        case .dex, .dexBridge:
            return true
        case .cex, .onramp, .unknown:
            return false
        }
    }
}
