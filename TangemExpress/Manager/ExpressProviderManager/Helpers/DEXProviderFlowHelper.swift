//
//  DEXProviderFlowHelper.swift
//  TangemExpress
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

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

        if let restriction = await checkRestriction(sourceAmount: sourceAmount, request: request, quote: quote) {
            return restriction
        }

        do {
            let dataItem = try mapper.makeExpressSwappableDataItem(
                pair: pair,
                request: request,
                providerId: provider.id,
                providerType: provider.type,
                quoteId: quote.quoteId
            )
            let data = try await expressAPIProvider.exchangeData(item: dataItem)
            try Task.checkCancellation()

            return try await proceed(sourceAmount: sourceAmount, request: request, quote: quote, data: data)
        } catch {
            return mapError(error, quote: quote, amountType: request.amountType)
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
    func checkRestriction(
        sourceAmount: Decimal,
        request: ExpressManagerSwappingPairRequest,
        quote: ExpressQuote
    ) async -> ExpressProviderManagerState? {
        do {
            let sourceBalance = try pair.source.balanceProvider.getBalance()
            let isNotEnoughBalanceForSwapping = sourceAmount > sourceBalance

            if isNotEnoughBalanceForSwapping {
                return .restriction(.insufficientBalance(sourceAmount), quote: quote)
            }

            // Check fee currency balance at least more then zero
            guard try expressFeeProvider.feeCurrencyHasPositiveBalance() else {
                let isFeeCurrency = expressFeeProvider.isFeeCurrency(source: pair.source.currency)
                return .restriction(.feeCurrencyHasZeroBalance(isFeeCurrency: isFeeCurrency), quote: quote)
            }

        } catch {
            return .error(error, quote: quote)
        }

        // Check Permission
        if let spender = quote.allowanceContract {
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
                    let fee = try await expressFeeProvider.transactionFee(approveData: data)
                    return .permissionRequired(
                        .init(provider: provider, policy: request.approvePolicy, data: data, approvalFlow: .approve, fee: fee, quote: quote)
                    )
                case .revokeAndPermissionRequired(let revoke, let approve):
                    ExpressLogger.info("Revoke+approve allowance state for provider: \(provider.id)")
                    let revokeAndApproveFee = try await expressFeeProvider.revokeAndApproveTransactionFee(revokeData: revoke)
                    return .revokeAndPermissionRequired(
                        .init(provider: provider, policy: request.approvePolicy, data: approve, approvalFlow: .revokeAndApprove(revokeData: revoke, feeUnit: revokeAndApproveFee.unit), fee: revokeAndApproveFee.total, quote: quote)
                    )
                case .approveTransactionInProgress:
                    return .restriction(.approveTransactionInProgress(spender: spender), quote: quote)
                }
            } catch {
                return .error(error, quote: quote)
            }
        }

        return nil
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
            let ready = try await ready(request: request, quote: quote, data: data)
            return .dexPreview(ready)
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

    func ready(request: ExpressManagerSwappingPairRequest, quote: ExpressQuote, data: ExpressTransactionData) async throws -> ExpressProviderManagerState.DEXPreview {
        let fee = try await expressFeeProvider.transactionFee(data: .dex(data: data))

        try Task.checkCancellation()

        // better to make the quote from the data
        let quoteData = ExpressQuote(fromAmount: data.fromAmount, expectAmount: data.toAmount, allowanceContract: quote.allowanceContract, quoteId: quote.quoteId, txType: quote.txType)
        return .init(provider: provider, data: data, fee: fee, quote: quoteData)
    }

    func mapError(_ error: Error, quote: ExpressQuote?, amountType: ExpressAmountType) -> ExpressProviderManagerState {
        let currencySymbol = pair.currencySymbol(for: amountType)
        if let apiError = error as? ExpressAPIError {
            return .mapError(apiError, quote: quote, currencySymbol: currencySymbol)
        }
        return .error(error, quote: quote)
    }
}

// MARK: - CustomStringConvertible

extension DEXProviderFlowHelper: CustomStringConvertible {
    var description: String {
        objectDescription("DEXProviderFlowHelper")
    }
}
