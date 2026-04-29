//
//  RegularSwapEventHandler.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemExpress

/// Event handler for the regular swap flow.
/// No fixed-rate estimation; always quotes in float (`.from`) direction.
final class RegularSwapEventHandler: SwapEventHandler {
    private let expressManager: ExpressManager
    private let expressPairsRepository: ExpressPairsRepository

    init(expressManager: ExpressManager, expressPairsRepository: ExpressPairsRepository) {
        self.expressManager = expressManager
        self.expressPairsRepository = expressPairsRepository
    }

    // MARK: - Token changes (full refresh)

    func sourceTokenChanged(
        pair: ExpressManagerSwappingPair,
        source: SendSwapableToken,
        destination: SendReceiveToken,
        sourceAmount: Decimal?
    ) async throws -> SwapEventResult {
        try await fullRefresh(pair: pair, source: source, destination: destination, sourceAmount: sourceAmount)
    }

    func receiveTokenChanged(
        pair: ExpressManagerSwappingPair,
        source: SendSwapableToken,
        destination: SendReceiveToken,
        sourceAmount: Decimal?
    ) async throws -> SwapEventResult {
        try await fullRefresh(pair: pair, source: source, destination: destination, sourceAmount: sourceAmount)
    }

    // MARK: - Amount changes (re-quote only)

    func sourceAmountChanged(amount: Decimal?) async throws -> SwapEventResult {
        let amountType: ExpressAmountType? = amount.map { .from($0) }
        let result: ExpressManagerUpdatingResult = try await expressManager.update(
            amountType: amountType,
            by: .amountChange
        )

        let amountUpdate: SwapEventResult.AmountUpdate? = result.selected?.getState().quote.map { quote in
            .setComplementary(crypto: quote.expectAmount)
        }
        return SwapEventResult(expressResult: result, amountUpdate: amountUpdate)
    }

    func receiveAmountChanged(amount: Decimal?) async throws -> SwapEventResult {
        // Regular swap is float-only; receive-amount changes still re-quote in `.to` direction
        // but the regular flow doesn't anchor on receive long-term. SwapModel handles direction state.
        let amountType: ExpressAmountType? = amount.map { .to($0) }
        let result: ExpressManagerUpdatingResult = try await expressManager.update(
            amountType: amountType,
            by: .amountChange
        )

        let amountUpdate: SwapEventResult.AmountUpdate? = result.selected?.getState().quote.map { quote in
            .setComplementary(crypto: quote.fromAmount)
        }
        return SwapEventResult(expressResult: result, amountUpdate: amountUpdate)
    }

    // MARK: - CEX-only refreshes

    func destinationAddressChanged() async throws -> SwapEventResult {
        let result: ExpressManagerUpdatingResult = try await expressManager.update(by: .pairChange)
        return SwapEventResult(expressResult: result, amountUpdate: nil)
    }

    func refreshRequested() async throws -> SwapEventResult {
        let result: ExpressManagerUpdatingResult = try await expressManager.update(by: .pairChange)
        return SwapEventResult(expressResult: result, amountUpdate: nil)
    }

    // MARK: - Private

    private func fullRefresh(
        pair: ExpressManagerSwappingPair,
        source: SendSwapableToken,
        destination: SendReceiveToken,
        sourceAmount: Decimal?
    ) async throws -> SwapEventResult {
        if FeatureProvider.isAvailable(.swapPipelineV2) {
            let cachedPairs = await expressPairsRepository.getPairs(from: source.currency)
            let isPairCached = cachedPairs.contains { $0.destination == destination.currency.asCurrency }

            if !isPairCached {
                try await expressPairsRepository.updatePairs(
                    for: source.currency,
                    userWalletInfo: source.userWalletInfo
                )
            }
        }

        let pairResult: ExpressManagerUpdatingResult = try await expressManager.update(pair: pair)

        guard let sourceAmount else {
            return SwapEventResult(expressResult: pairResult, amountUpdate: .clearComplementary)
        }

        let result: ExpressManagerUpdatingResult = try await expressManager.update(
            amountType: .from(sourceAmount),
            by: .pairChange
        )

        let amountUpdate: SwapEventResult.AmountUpdate = result.selected?.getState().quote.map { quote in
            .anchorOnSource(
                source: sourceAmount,
                receive: quote.expectAmount,
                sourceCurrencyId: source.tokenItem.currencyId,
                receiveCurrencyId: destination.tokenItem.currencyId
            )
        } ?? .clearComplementary

        return SwapEventResult(expressResult: result, amountUpdate: amountUpdate)
    }
}
