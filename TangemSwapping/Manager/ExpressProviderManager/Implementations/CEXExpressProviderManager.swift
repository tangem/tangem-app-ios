//
//  CEXExpressProviderManager.swift
//  TangemSwapping
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

actor CEXExpressProviderManager {
    // MARK: - Dependencies

    private let provider: ExpressProvider
    private let expressAPIProvider: ExpressAPIProvider
    private let feeProvider: FeeProvider
    private let logger: SwappingLogger
    private let mapper: ExpressManagerMapper

    // MARK: - State

    private var _state: ExpressProviderManagerState = .idle

    init(
        provider: ExpressProvider,
        expressAPIProvider: ExpressAPIProvider,
        feeProvider: FeeProvider,
        logger: SwappingLogger,
        mapper: ExpressManagerMapper
    ) {
        self.provider = provider
        self.expressAPIProvider = expressAPIProvider
        self.feeProvider = feeProvider
        self.logger = logger
        self.mapper = mapper
    }
}

// MARK: - ExpressProviderManager

extension CEXExpressProviderManager: ExpressProviderManager {
    func getState() -> ExpressProviderManagerState {
        _state
    }

    func update(request: ExpressManagerSwappingPairRequest, approvePolicy _: SwappingApprovePolicy) async {
        let state = await getState(request: request)
        log("Update to \(state)")
        _state = state
    }

    func sendData(request: ExpressManagerSwappingPairRequest) async throws -> ExpressTransactionData {
        let item = mapper.makeExpressSwappableItem(request: request, providerId: provider.id)
        let data = try await expressAPIProvider.exchangeData(item: item)

        try Task.checkCancellation()

        return data
    }
}

// MARK: - Private

private extension CEXExpressProviderManager {
    func getState(request: ExpressManagerSwappingPairRequest) async -> ExpressProviderManagerState {
        var loadedQuote: ExpressQuote?

        do {
            let item = mapper.makeExpressSwappableItem(request: request, providerId: provider.id)
            let quote = try await expressAPIProvider.exchangeQuote(item: item)

            // Save the quote for use it in the next possible error case
            loadedQuote = quote

            if try await isNotEnoughBalanceForSwapping(request: request) {
                return .restriction(.insufficientBalance(request.amount), quote: quote)
            }

            var request = request
            let estimatedFee = try await feeProvider.estimatedFee(amount: request.amount)
            let subtractFee = try await subtractFee(request: request, fee: estimatedFee)

            if subtractFee > 0 {
                request = ExpressManagerSwappingPairRequest(pair: request.pair, amount: request.amount - subtractFee)
            }

            return .preview(.init(fee: estimatedFee, subtractFee: subtractFee, quote: quote))

        } catch let error as ExpressAPIError {
            if error.errorCode == .exchangeTooSmallAmountError, let minAmount = error.value?.amount {
                return .restriction(.tooSmallAmount(minAmount), quote: loadedQuote)
            }

            return .error(error, quote: loadedQuote)
        } catch {
            return .error(error, quote: loadedQuote)
        }
    }

    func isNotEnoughBalanceForSwapping(request: ExpressManagerSwappingPairRequest) async throws -> Bool {
        let sourceBalance = try await request.pair.source.getBalance()
        let isNotEnoughBalanceForSwapping = request.amount > sourceBalance

        return isNotEnoughBalanceForSwapping
    }

    func subtractFee(request: ExpressManagerSwappingPairRequest, fee: ExpressFee) async throws -> Decimal {
        // The fee's subtraction needed only for coin
        guard !request.pair.source.isToken else { return 0 }

        let balance = try await request.pair.source.getBalance()
        let fullAmount = request.amount + fee.fastest.amount.value
        // We have enough balance
        if fullAmount < balance {
            return 0
        }

        // We try to decrease on exceed amount
        let subtractFee = fullAmount - balance
        log("Subtract fee - \(subtractFee) from amount - \(request.amount)")
        return subtractFee
    }

    func log(_ args: Any) {
        logger.debug("[Express] \(self) \(args)")
    }
}
