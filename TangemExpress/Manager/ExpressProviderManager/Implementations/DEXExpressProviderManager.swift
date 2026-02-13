//
//  DEXExpressProviderManager.swift
//  TangemExpress
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

final class DEXExpressProviderManager {
    // MARK: - Dependencies

    private let provider: ExpressProvider
    private let swappingPair: ExpressManagerSwappingPair
    private let expressFeeProvider: ExpressFeeProvider // a.k.a TokenFeeProvidersManager
    private let expressAPIProvider: ExpressAPIProvider
    private let mapper: ExpressManagerMapper
    private let transactionValidator: ExpressProviderTransactionValidator

    // MARK: - State

    private var _state: ThreadSafeContainer<ExpressProviderManagerState> = .init(.idle)

    init(
        provider: ExpressProvider,
        swappingPair: ExpressManagerSwappingPair,
        expressFeeProvider: ExpressFeeProvider,
        expressAPIProvider: ExpressAPIProvider,
        mapper: ExpressManagerMapper,
        transactionValidator: ExpressProviderTransactionValidator
    ) {
        self.provider = provider
        self.swappingPair = swappingPair
        self.expressFeeProvider = expressFeeProvider
        self.expressAPIProvider = expressAPIProvider
        self.mapper = mapper
        self.transactionValidator = transactionValidator
    }
}

// MARK: - ExpressProviderManager

extension DEXExpressProviderManager: ExpressProviderManager {
    var pair: ExpressManagerSwappingPair { swappingPair }
    var feeProvider: any ExpressFeeProvider { expressFeeProvider }

    func getState() -> ExpressProviderManagerState {
        _state.read()
    }

    func update(request: ExpressManagerSwappingPairRequest) async {
        let state = await getState(request: request)
        ExpressLogger.info(self, "Update to \(state)")
        _state.mutate { $0 = state }
    }

    func sendData(request: ExpressManagerSwappingPairRequest) async throws -> ExpressTransactionData {
        guard case .ready(let state) = _state.read() else {
            throw ExpressProviderError.transactionDataNotFound
        }

        return state.data
    }
}

// MARK: - Private

private extension DEXExpressProviderManager {
    func getState(request: ExpressManagerSwappingPairRequest) async -> ExpressProviderManagerState {
        do {
            let item = mapper.makeExpressSwappableItem(pair: pair, request: request, providerId: provider.id, providerType: provider.type)
            let quote = try await expressAPIProvider.exchangeQuote(item: item)

            if let restriction = await checkRestriction(request: request, quote: quote) {
                return restriction
            }

            let dataItem = try mapper.makeExpressSwappableDataItem(pair: pair, request: request, providerId: provider.id, providerType: provider.type)
            let data = try await expressAPIProvider.exchangeData(item: dataItem)
            try Task.checkCancellation()

            return try await proceed(request: request, quote: quote, data: data)

        } catch let error as ExpressAPIError {
            guard let amount = error.value?.amount else {
                return .error(error, quote: .none)
            }

            switch error.errorCode {
            case .exchangeTooSmallAmountError:
                return .restriction(.tooSmallAmount(amount), quote: .none)
            case .exchangeTooBigAmountError:
                return .restriction(.tooBigAmount(amount), quote: .none)
            default:
                return .error(error, quote: .none)
            }
        } catch {
            return .error(error, quote: .none)
        }
    }

    func checkRestriction(request: ExpressManagerSwappingPairRequest, quote: ExpressQuote) async -> ExpressProviderManagerState? {
        // Check Balance
        do {
            let sourceBalance = try pair.source.balanceProvider.getBalance()
            let isNotEnoughBalanceForSwapping = request.amount > sourceBalance

            if isNotEnoughBalanceForSwapping {
                return .restriction(.insufficientBalance(request.amount), quote: quote)
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
                case .permissionRequired(let approveData):
                    return .permissionRequired(
                        .init(provider: provider, policy: request.approvePolicy, data: approveData, quote: quote)
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

    func proceed(request: ExpressManagerSwappingPairRequest, quote: ExpressQuote, data: ExpressTransactionData) async throws -> ExpressProviderManagerState {
        let coinBalance = try pair.source.balanceProvider.getCoinBalance()
        if data.txValue > coinBalance {
            let estimateFee = try await estimateFee(request: request, data: data)
            return .restriction(estimateFee, quote: quote)
        }

        if let txData = data.txData, !transactionValidator.validateTransactionSize(data: txData) {
            throw ExpressProviderError.transactionSizeNotSupported
        }

        do {
            let ready = try await ready(request: request, quote: quote, data: data)
            return .ready(ready)
        } catch {
            // [REDACTED_TODO_COMMENT]
            if error.universalErrorCode == 108000006 {
                return .error(error, quote: quote)
            }

            let estimateFee = try await estimateFee(request: request, data: data)
            return .restriction(estimateFee, quote: quote)
        }
    }

    func estimateFee(request: ExpressManagerSwappingPairRequest, data: ExpressTransactionData) async throws -> ExpressRestriction {
        let otherNativeFee = data.otherNativeFee ?? 0

        if let estimatedGasLimit = data.estimatedGasLimit {
            let estimateFee = try await expressFeeProvider.estimatedFee(
                estimatedGasLimit: estimatedGasLimit,
                otherNativeFee: otherNativeFee
            )

            let isFeeCurrency = expressFeeProvider.isFeeCurrency(source: pair.source.currency)
            return .feeCurrencyInsufficientBalanceForTxValue(estimateFee.amount.value, isFeeCurrency: isFeeCurrency)
        }

        let estimatedAmount = request.amount + otherNativeFee
        return .insufficientBalance(estimatedAmount)
    }

    func ready(request: ExpressManagerSwappingPairRequest, quote: ExpressQuote, data: ExpressTransactionData) async throws -> ExpressProviderManagerState.Ready {
        _ = try await expressFeeProvider.transactionFee(data: .dex(data: data))

        try Task.checkCancellation()

        // better to make the quote from the data
        let quoteData = ExpressQuote(fromAmount: data.fromAmount, expectAmount: data.toAmount, allowanceContract: quote.allowanceContract)
        return .init(provider: provider, data: data, quote: quoteData)
    }
}

// MARK: - CustomStringConvertible

extension DEXExpressProviderManager: CustomStringConvertible {
    var description: String {
        objectDescription(self)
    }
}
