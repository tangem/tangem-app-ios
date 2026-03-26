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
    let provider: ExpressProvider
    let pair: ExpressManagerSwappingPair
    let expressFeeProvider: ExpressFeeProvider
    let expressAPIProvider: ExpressAPIProvider
    let mapper: ExpressManagerMapper
    let providerTypeOverride: ExpressProviderType?

    init(
        provider: ExpressProvider,
        pair: ExpressManagerSwappingPair,
        expressFeeProvider: ExpressFeeProvider,
        expressAPIProvider: ExpressAPIProvider,
        mapper: ExpressManagerMapper,
        providerTypeOverride: ExpressProviderType? = nil
    ) {
        self.provider = provider
        self.pair = pair
        self.expressFeeProvider = expressFeeProvider
        self.expressAPIProvider = expressAPIProvider
        self.mapper = mapper
        self.providerTypeOverride = providerTypeOverride
    }

    // MARK: - Public

    /// Full flow including quote call. Used by the dedicated DEXExpressProviderManager.
    func getState(request: ExpressManagerSwappingPairRequest) async -> ExpressProviderManagerState {
        do {
            let item = mapper.makeExpressSwappableItem(pair: pair, request: request, providerId: provider.id, providerType: resolvedProviderType)
            let quote = try await expressAPIProvider.exchangeQuote(item: item)

            return await processAfterQuote(quote: quote, request: request)
        } catch {
            return mapError(error, quote: .none)
        }
    }

    /// Post-quote entry point. Used by CombinedExpressProviderManager after the flow type is resolved.
    /// Performs restriction checks, allowance, exchange-data (eager), txValue check, fee estimation.
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
                providerType: resolvedProviderType,
                quoteId: quote.quoteId
            )
            let data = try await expressAPIProvider.exchangeData(item: dataItem)
            try Task.checkCancellation()

            return try await proceed(sourceAmount: sourceAmount, request: request, quote: quote, data: data)
        } catch {
            return mapError(error, quote: quote)
        }
    }

    /// Reads transaction data from the cached `.ready` state. Used by both dedicated and Combined managers.
    func sendData(currentState: ExpressProviderManagerState) throws -> ExpressTransactionData {
        guard case .ready(let state) = currentState else {
            throw ExpressProviderError.transactionDataNotFound
        }

        return state.data
    }
}

// MARK: - Private

private extension DEXProviderFlowHelper {
    var resolvedProviderType: ExpressProviderType {
        providerTypeOverride ?? provider.type
    }

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
                    let fee = try await expressFeeProvider.transactionFee(txData: data.txData, toContractAddress: data.toContractAddress)
                    return .permissionRequired(
                        .init(provider: provider, policy: request.approvePolicy, data: data, fee: fee, quote: quote)
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
            return .ready(ready)
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

    func ready(request: ExpressManagerSwappingPairRequest, quote: ExpressQuote, data: ExpressTransactionData) async throws -> ExpressProviderManagerState.Ready {
        let fee = try await expressFeeProvider.transactionFee(data: .dex(data: data))

        try Task.checkCancellation()

        // better to make the quote from the data
        let quoteData = ExpressQuote(fromAmount: data.fromAmount, expectAmount: data.toAmount, allowanceContract: quote.allowanceContract, quoteId: quote.quoteId)
        return .init(provider: provider, data: data, fee: fee, quote: quoteData)
    }

    func mapError(_ error: Error, quote: ExpressQuote?) -> ExpressProviderManagerState {
        switch error {
        case let error as ExpressAPIError:
            guard let amount = error.value?.amount else {
                return .error(error, quote: quote)
            }

            switch error.errorCode {
            case .exchangeTooSmallAmountError:
                return .restriction(.tooSmallAmount(amount), quote: quote)
            case .exchangeTooBigAmountError:
                return .restriction(.tooBigAmount(amount), quote: quote)
            default:
                return .error(error, quote: quote)
            }
        default:
            return .error(error, quote: quote)
        }
    }
}

// MARK: - CustomStringConvertible

extension DEXProviderFlowHelper: CustomStringConvertible {
    var description: String {
        objectDescription("DEXProviderFlowHelper")
    }
}
