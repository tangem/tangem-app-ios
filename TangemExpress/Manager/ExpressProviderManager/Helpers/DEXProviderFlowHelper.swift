//
//  DEXProviderFlowHelper.swift
//  TangemExpress
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation
import enum BlockchainSdk.ApprovePolicy
import struct BlockchainSdk.ApproveTransactionData

struct DEXProviderFlowHelper {
    private let context: ExpressProviderFlowContext

    private var provider: ExpressProvider { context.provider }
    private var pair: ExpressManagerSwappingPair { context.pair }
    private var expressFeeProvider: ExpressFeeProvider { context.expressFeeProvider }
    private var expressAPIProvider: ExpressAPIProvider { context.expressAPIProvider }
    private var mapper: ExpressManagerMapper { context.mapper }

    init(context: ExpressProviderFlowContext) {
        self.context = context
    }

    // MARK: - Public

    /// Post-quote entry point. Performs restriction checks, allowance, exchange-data (eager), txValue check, and fee estimation.
    func processAfterQuote(quote: ExpressQuote, request: ExpressManagerSwappingPairRequest) async -> ExpressProviderManagerState {
        // For .to flow, the actual source amount comes from the quote, not the request
        let sourceAmount: Decimal
        switch request.amountType {
        case .from:
            sourceAmount = request.amount
        case .to:
            sourceAmount = quote.fromAmount
        }

        switch await checkRestriction(sourceAmount: sourceAmount, request: request, quote: quote) {
        case .dexApproveFlowState(let approveData):
            return await fetchExchangeDataAndProceedWithApprove(
                sourceAmount: sourceAmount,
                request: request,
                quote: quote,
                approveData: approveData
            )

        case .terminalState(.some(.permissionRequired(let permissionRequired))):
            return .permissionRequired(permissionRequired)

        case .terminalState(.some(let state)):
            return state

        case .terminalState(.none):
            return await fetchExchangeDataAndProceed(sourceAmount: sourceAmount, request: request, quote: quote)
        }
    }

    /// Reads transaction data from the cached DEX preview state.
    func sendData(currentState: ExpressProviderManagerState) throws -> ExpressTransactionData {
        guard case .dexPreview(let state) = currentState else {
            throw ExpressProviderError.transactionDataNotFound
        }

        return state.data
    }
}

// MARK: - Private

private extension DEXProviderFlowHelper {
    enum RestrictionCheckResult {
        case terminalState(ExpressProviderManagerState?)
        case dexApproveFlowState(ApproveData)

        struct ApproveData {
            let provider: ExpressProvider
            let approvePolicy: ApprovePolicy
            let approveTransactionData: ApproveTransactionData
            let approvalFlow: ExpressProviderManagerState.ApprovalFlow
            let owner: String
        }
    }

    func checkRestriction(
        sourceAmount: Decimal,
        request: ExpressManagerSwappingPairRequest,
        quote: ExpressQuote
    ) async -> RestrictionCheckResult {
        do {
            let sourceBalance = try pair.source.balanceProvider.getBalance()
            let isNotEnoughBalanceForSwapping = sourceAmount > sourceBalance

            if isNotEnoughBalanceForSwapping {
                return .terminalState(.restriction(.insufficientBalance(sourceAmount), quote: quote))
            }

            // Check fee currency balance at least more then zero
            guard try expressFeeProvider.feeCurrencyHasPositiveBalance() else {
                let isFeeCurrency = expressFeeProvider.isFeeCurrency(source: pair.source.currency)
                return .terminalState(.restriction(.feeCurrencyHasZeroBalance(isFeeCurrency: isFeeCurrency), quote: quote))
            }

        } catch {
            return .terminalState(.error(error, quote: quote))
        }

        // Check Permission
        if let spender = quote.allowanceContract, !isYieldModuleDEXSwap {
            do {
                let allowanceState = try await pair.source.allowanceProvider?.allowanceState(
                    request: request,
                    contractAddress: pair.source.currency.contractAddress,
                    spender: spender
                )

                switch allowanceState {
                case .none:
                    throw ExpressProviderError.allowanceProviderNotFound
                case .enoughAllowance:
                    break
                case .permissionRequired(let data):
                    if context.featureFlags.isApproveWithSwapEnabled, let owner = pair.source.address {
                        return .dexApproveFlowState(
                            .init(
                                provider: provider,
                                approvePolicy: request.approvePolicy,
                                approveTransactionData: data,
                                approvalFlow: .approve,
                                owner: owner
                            )
                        )
                    } else {
                        let approveFee = try await expressFeeProvider.transactionFee(approveData: data)
                        return .terminalState(.permissionRequired(
                            .init(
                                provider: provider,
                                policy: request.approvePolicy,
                                data: data,
                                approvalFlow: .approve,
                                fee: approveFee,
                                quote: quote
                            )
                        ))
                    }
                case .revokeAndPermissionRequired(let revoke, let approve):
                    ExpressLogger.info("Revoke+approve allowance state for provider: \(provider.id)")
                    let revokeAndApproveFee = try await expressFeeProvider.revokeAndApproveTransactionFee(revokeData: revoke)
                    return .terminalState(.revokeAndPermissionRequired(
                        .init(provider: provider, policy: request.approvePolicy, data: approve, approvalFlow: .revokeAndApprove(revokeData: revoke, feeUnit: revokeAndApproveFee.unit), fee: revokeAndApproveFee.total, quote: quote)
                    ))
                case .approveTransactionInProgress:
                    return .terminalState(.restriction(.approveTransactionInProgress(spender: spender), quote: quote))
                }
            } catch {
                return .terminalState(.error(error, quote: quote))
            }
        }

        return .terminalState(nil)
    }

    func fetchExchangeDataAndProceed(
        sourceAmount: Decimal,
        request: ExpressManagerSwappingPairRequest,
        quote: ExpressQuote
    ) async -> ExpressProviderManagerState {
        do {
            try await yieldModuleTransactionHelper?.prepareForYieldModuleDEXSwap(provider: provider)

            let dataItem = try mapper.makeExpressSwappableDataItem(
                pair: pair,
                request: request,
                providerId: provider.id,
                providerType: provider.type,
                quoteId: quote.quoteId
            )

            let data = try await expressAPIProvider.exchangeData(item: dataItem)
            try Task.checkCancellation()

            let yieldModuleData = try await makeYieldModuleDEXSwapDataIfNeeded(data: data, quote: quote)

            return try await proceed(
                sourceAmount: sourceAmount,
                request: request,
                quote: quote,
                data: yieldModuleData
            )
        } catch {
            return mapError(error, quote: quote, amountType: request.amountType)
        }
    }

    func makeYieldModuleDEXSwapDataIfNeeded(data: ExpressTransactionData, quote: ExpressQuote) async throws -> ExpressTransactionData {
        guard isYieldModuleDEXSwap else {
            return data
        }

        guard let spender = quote.allowanceContract else {
            throw ExpressProviderError.yieldModuleSwapUnavailable(.spenderNotFound)
        }

        guard let yieldModuleTransactionHelper else {
            return data
        }

        return try await yieldModuleTransactionHelper.yieldModuleDEXSwapData(data: data, provider: provider, spender: spender)
    }

    func proceed(
        sourceAmount: Decimal,
        request: ExpressManagerSwappingPairRequest,
        quote: ExpressQuote,
        data: ExpressTransactionData
    ) async throws -> ExpressProviderManagerState {
        let coinBalance = try pair.source.balanceProvider.getCoinBalance()

        if data.txValue > coinBalance {
            let estimateFee = try await estimateFee(sourceAmount: sourceAmount, data: data)
            return .restriction(estimateFee, quote: quote)
        }

        if let txData = data.txData, !pair.source.providerTransactionValidator.validateTransactionSize(data: txData) {
            throw ExpressProviderError.transactionSizeNotSupported
        }

        do {
            return try await ready(request: request, quote: quote, data: data)
        } catch {
            return .error(error, quote: quote)
        }
    }

    func estimateFee(sourceAmount: Decimal, data: ExpressTransactionData) async throws -> ExpressRestriction {
        let otherNativeFee = data.otherNativeFee ?? 0

        if let estimatedGasLimit = data.estimatedGasLimit {
            let estimateFee = try await expressFeeProvider.estimatedFee(
                estimatedGasLimit: estimatedGasLimit,
                otherNativeFee: otherNativeFee
            )

            let isFeeCurrency = expressFeeProvider.isFeeCurrency(source: pair.source.currency)
            return .feeCurrencyInsufficientBalanceForTxValue(estimateFee.amount.value, isFeeCurrency: isFeeCurrency)
        }

        let estimatedAmount = sourceAmount + otherNativeFee
        return .insufficientBalance(estimatedAmount)
    }

    func ready(
        request: ExpressManagerSwappingPairRequest,
        quote: ExpressQuote,
        data: ExpressTransactionData
    ) async throws -> ExpressProviderManagerState {
        let fee = try await expressFeeProvider.transactionFee(data: .dex(data: data))
        try Task.checkCancellation()

        // better to make the quote from the data
        let quoteData = ExpressQuote(
            fromAmount: data.fromAmount,
            expectAmount: data.toAmount,
            allowanceContract: quote.allowanceContract,
            quoteId: quote.quoteId,
            txType: quote.txType
        )

        return .dexPreview(.init(provider: provider, data: data, fee: fee, quote: quoteData))
    }

    func mapError(_ error: Error, quote: ExpressQuote?, amountType: ExpressAmountType) -> ExpressProviderManagerState {
        let currencySymbol = pair.currencySymbol(for: amountType)
        if let apiError = error as? ExpressAPIError {
            return .mapError(apiError, quote: quote, currencySymbol: currencySymbol)
        }
        return .error(error, quote: quote)
    }

    var isYieldModuleDEXSwap: Bool {
        switch provider.type {
        case .dex, .dexBridge:
            return yieldModuleTransactionHelper?.yieldContractAddress != nil
        case .cex, .onramp, .unknown:
            return false
        }
    }

    var yieldModuleTransactionHelper: YieldModuleTransactionHelper? {
        pair.source.yieldModuleTransactionHelper
    }
}

// MARK: - Approve & swap flow

private extension DEXProviderFlowHelper {
    func fetchExchangeDataAndProceedWithApprove(
        sourceAmount: Decimal,
        request: ExpressManagerSwappingPairRequest,
        quote: ExpressQuote,
        approveData: RestrictionCheckResult.ApproveData
    ) async -> ExpressProviderManagerState {
        do {
            try await yieldModuleTransactionHelper?.prepareForYieldModuleDEXSwap(provider: provider)

            let dataItem = try mapper.makeExpressSwappableDataItem(
                pair: pair,
                request: request,
                providerId: provider.id,
                providerType: provider.type,
                quoteId: quote.quoteId
            )

            let data = try await expressAPIProvider.exchangeData(item: dataItem)
            try Task.checkCancellation()

            let yieldModuleData = try await makeYieldModuleDEXSwapDataIfNeeded(data: data, quote: quote)

            return try await proceedWithApprove(
                sourceAmount: sourceAmount,
                request: request,
                quote: quote,
                data: yieldModuleData,
                approveData: approveData
            )
        } catch {
            return mapError(error, quote: quote, amountType: request.amountType)
        }
    }

    func proceedWithApprove(
        sourceAmount: Decimal,
        request: ExpressManagerSwappingPairRequest,
        quote: ExpressQuote,
        data: ExpressTransactionData,
        approveData: RestrictionCheckResult.ApproveData
    ) async throws -> ExpressProviderManagerState {
        let coinBalance = try pair.source.balanceProvider.getCoinBalance()

        if data.txValue > coinBalance {
            let estimateFee = try await estimateFee(sourceAmount: sourceAmount, data: data)
            return .restriction(estimateFee, quote: quote)
        }

        if let txData = data.txData, !pair.source.providerTransactionValidator.validateTransactionSize(data: txData) {
            throw ExpressProviderError.transactionSizeNotSupported
        }

        do {
            return try await readyToApproveAndSwap(request: request, quote: quote, data: data, approveData: approveData)
        } catch {
            return .error(error, quote: quote)
        }
    }

    func readyToApproveAndSwap(
        request: ExpressManagerSwappingPairRequest,
        quote: ExpressQuote,
        data: ExpressTransactionData,
        approveData: RestrictionCheckResult.ApproveData
    ) async throws -> ExpressProviderManagerState {
        let combinedFee: ApproveWithSwapFee
        do {
            combinedFee = try await approveAndSwapFee(data: data, approveData: approveData)
        } catch {
            return try await fallbackToTwoStepApprove(approveData: approveData, quote: quote)
        }

        try Task.checkCancellation()

        let quoteData = ExpressQuote(
            fromAmount: data.fromAmount,
            expectAmount: data.toAmount,
            allowanceContract: quote.allowanceContract,
            quoteId: quote.quoteId,
            txType: quote.txType
        )

        let approveFlowData = ExpressProviderManagerState.DEXWithApprovePreview.DEXWithApproveFlowApproveData(
            provider: approveData.provider,
            approvePolicy: approveData.approvePolicy,
            approveTransactionData: approveData.approveTransactionData,
            approvalFlow: approveData.approvalFlow,
            approveFee: combinedFee.approve
        )

        return .dexWithApprovePreview(
            .init(
                provider: provider,
                expressTransactionData: data,
                quote: quoteData,
                approveData: approveFlowData,
                combinedFee: combinedFee.total
            )
        )
    }

    func approveAndSwapFee(
        data: ExpressTransactionData,
        approveData: RestrictionCheckResult.ApproveData
    ) async throws -> ApproveWithSwapFee {
        let allowanceOverride = AllowanceOverride(
            tokenContractAddress: pair.source.currency.contractAddress,
            owner: approveData.owner,
            spender: approveData.approveTransactionData.spender
        )

        return try await expressFeeProvider.transactionFee(
            data: .dex(data: data),
            allowanceOverride: allowanceOverride,
            approveData: approveData.approveTransactionData
        )
    }

    func fallbackToTwoStepApprove(
        approveData: RestrictionCheckResult.ApproveData,
        quote: ExpressQuote
    ) async throws -> ExpressProviderManagerState {
        let fee = try await expressFeeProvider.transactionFee(approveData: approveData.approveTransactionData)
        return .permissionRequired(
            .init(
                provider: approveData.provider,
                policy: approveData.approvePolicy,
                data: approveData.approveTransactionData,
                approvalFlow: approveData.approvalFlow,
                fee: fee,
                quote: quote
            )
        )
    }
}

// MARK: - CustomStringConvertible

extension DEXProviderFlowHelper: CustomStringConvertible {
    var description: String {
        objectDescription("DEXProviderFlowHelper")
    }
}
