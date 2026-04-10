//
//  SendWithSwapPairUpdateHandler.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemExpress

/// Pair update handler for the send-via-swap flow.
/// Estimates receive amount on first selection via local rates.
/// Preserves current direction on subsequent pair changes.
final class SendWithSwapPairUpdateHandler: SwapPairUpdateHandler {
    private let expressManager: ExpressManager
    private let balanceConverter = BalanceConverter()

    init(expressManager: ExpressManager) {
        self.expressManager = expressManager
    }

    func handlePairChange(
        pair: ExpressManagerSwappingPair,
        source: SendSwapableToken,
        destination: SendReceiveToken,
        sourceAmount: Decimal?,
        receiveAmount: Decimal?
    ) async throws -> SwapPairUpdateResult {
        // Pre-pair: compute local estimate for first selection
        var estimatedTo: Decimal?
        if receiveAmount == nil,
           let sourceAmount,
           let sourceCurrencyId = source.tokenItem.currencyId,
           let destCurrencyId = destination.tokenItem.currencyId {
            estimatedTo = try? await balanceConverter.convertCryptoToCrypto(
                sourceId: sourceCurrencyId,
                sourceAmount: sourceAmount,
                targetId: destCurrencyId
            )
        }

        // Pair update — populates availableProviders in CommonExpressManager
        let pairResult: ExpressManagerUpdatingResult = try await expressManager.update(pair: pair)

        guard let sourceAmount else {
            return SwapPairUpdateResult(expressResult: pairResult, amountUpdate: nil)
        }

        // First selection — return estimate if available
        guard let receiveAmount else {
            let amountUpdate: SwapPairUpdateResult.AmountUpdate? = estimatedTo.map {
                .setReceiveAmount(crypto: $0, currencyId: destination.tokenItem.currencyId)
            }
            return SwapPairUpdateResult(expressResult: pairResult, amountUpdate: amountUpdate)
        }

        // Resolve direction and fetch quote
        let amountType = await resolveAmountType(
            pairResult: pairResult,
            sourceAmount: sourceAmount,
            receiveAmount: receiveAmount
        )

        let result: ExpressManagerUpdatingResult = try await expressManager.update(
            amountType: amountType,
            by: .pairChange
        )

        let amountUpdate: SwapPairUpdateResult.AmountUpdate? = result.selected?.getState().quote.flatMap {
            switch amountType {
            case .from:
                .setReceiveAmount(crypto: $0.expectAmount, currencyId: destination.tokenItem.currencyId)
            case .to:
                .setSourceAmount(crypto: $0.fromAmount, currencyId: source.tokenItem.currencyId)
            }
        }

        return SwapPairUpdateResult(expressResult: result, amountUpdate: amountUpdate)
    }

    /// Preserves current direction. Falls back to `.from` if provider doesn't support fixed.
    private func resolveAmountType(
        pairResult: ExpressManagerUpdatingResult,
        sourceAmount: Decimal,
        receiveAmount: Decimal
    ) async -> ExpressAmountType {
        switch await expressManager.getAmountType() {
        case .from(let sourceAmount):
            return .from(sourceAmount)

        case .to where pairResult.providers.contains(where: { $0.supportedRateTypes.contains(.fixed) }):
            return .to(receiveAmount)

        case .to, .none:
            return .from(sourceAmount)
        }
    }
}
