//
//  PolymarketOrderSubmission.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import TangemFoundation
import TangemLocalization
import TangemPolymarket
import TangemPolymarketUI
import TangemUI
import TangemUIUtils

@MainActor
final class PolymarketOrderSubmission {
    private let model: PolymarketOrderModel
    private let placementService: PolymarketOrderPlacementService
    private let now: () -> Date

    init(
        model: PolymarketOrderModel,
        placementService: PolymarketOrderPlacementService,
        now: @escaping () -> Date = Date.init
    ) {
        self.model = model
        self.placementService = placementService
        self.now = now
    }

    func readiness() -> Readiness {
        guard let quote = model.state.quote.quote else { return .unavailable }

        guard model.state.keepsQuote(at: now()) else { return .staleQuote }

        return .ready(quote)
    }

    func submit(quote: PolymarketOrderQuote, marketRow: @escaping () -> PolymarketOrderMarketRow.Model) async -> Outcome {
        do {
            let placement = try await placementService.place(
                quote: quote,
                market: model.market,
                outcome: model.outcome
            )

            guard !placement.isMatchedWithoutFill(side: model.intent.side) else {
                PolymarketLogger.error(
                    "The exchange matched the order and filled no shares",
                    error: PlacementAnomaly.matchedWithoutFill
                )
                return .failed(returningToMain: true)
            }

            return finished(
                with: .init(placement: placement, quotedShares: quote.shares, side: model.intent.side),
                placement: placement,
                quote: quote,
                marketRow: marketRow()
            )
        } catch let error as PolymarketOrderPlacementError {
            return outcome(for: error, quote: quote, marketRow: marketRow())
        } catch is CancellationError {
            return .cancelled
        } catch {
            PolymarketLogger.error("Order placement failed", error: error)
            return .failed(returningToMain: false)
        }
    }
}

// MARK: - Readiness

extension PolymarketOrderSubmission {
    enum Readiness {
        case ready(PolymarketOrderQuote)
        case unavailable
        case staleQuote
    }
}

// MARK: - Outcome

extension PolymarketOrderSubmission {
    enum Outcome {
        case cancelled
        case failed(returningToMain: Bool)
        case finished(PolymarketOrderResultViewModel.State, PolymarketOrderResultViewModel.Content)
    }
}

// MARK: - Alerts

extension PolymarketOrderSubmission {
    static func failureAlert(
        returningToMain: Bool,
        onSupport: @escaping () -> Void,
        onClose: @escaping () -> Void
    ) -> AlertBinder {
        AlertBuilder.makeAlert(
            title: Localization.commonSomethingWentWrong,
            message: Localization.predictionPlaceErrorDescription,
            primaryButton: .default(Text(Localization.commonSupport)) {
                onSupport()

                guard returningToMain else { return }

                onClose()
            },
            secondaryButton: .cancel(Text(Localization.commonClose)) {
                guard returningToMain else { return }

                onClose()
            }
        )
    }

    static func staleQuoteAlert(onAcknowledge: @escaping () -> Void) -> AlertBinder {
        AlertBuilder.makeOkGotItAlert(
            message: Localization.predictionPlacePriceChangedDescription,
            okAction: onAcknowledge
        )
    }
}

// MARK: - Placement errors

private extension PolymarketOrderSubmission {
    func outcome(
        for error: PolymarketOrderPlacementError,
        quote: PolymarketOrderQuote,
        marketRow: PolymarketOrderMarketRow.Model
    ) -> Outcome {
        switch error {
        case .noLiquidity:
            PolymarketLogger.error("The book had nothing to match the order", error: error)
            return finished(with: .noFill, placement: nil, quote: quote, marketRow: marketRow)
        case _ where error.isAmbiguous:
            PolymarketLogger.error("The order was sent and its outcome is unknown", error: error)
            return finished(with: .stillProcessing, placement: nil, quote: quote, marketRow: marketRow)
        case _ where error.isUserCancellation:
            return .cancelled
        default:
            PolymarketLogger.error("Order placement failed", error: error)
            return .failed(returningToMain: false)
        }
    }

    func finished(
        with state: PolymarketOrderResultViewModel.State,
        placement: PolymarketOrderPlacement?,
        quote: PolymarketOrderQuote?,
        marketRow: PolymarketOrderMarketRow.Model
    ) -> Outcome {
        .finished(state, makeResultContent(placement: placement, quote: quote, marketRow: marketRow))
    }
}

// MARK: - Result mapping

private extension PolymarketOrderSubmission {
    func filledMoney(_ placement: PolymarketOrderPlacement?) -> Decimal? {
        placement?.filledMoney(side: model.intent.side)
    }

    func filledShares(_ placement: PolymarketOrderPlacement?) -> Decimal? {
        placement?.filledShares(side: model.intent.side)
    }

    func orderedMoney(quote: PolymarketOrderQuote?) -> Decimal? {
        switch model.intent {
        case .buy: model.state.enteredAmount
        case .sell: quote?.expectedExecutionAmount
        }
    }

    func executionPrice(_ placement: PolymarketOrderPlacement?) -> Decimal? {
        guard let money = filledMoney(placement), let shares = filledShares(placement), shares > 0 else {
            return nil
        }

        return money / shares
    }

    var heldShares: Decimal? {
        guard case .sell(let shares) = model.intent else { return nil }

        return shares
    }

    func makeResultContent(
        placement: PolymarketOrderPlacement?,
        quote: PolymarketOrderQuote?,
        marketRow: PolymarketOrderMarketRow.Model
    ) -> PolymarketOrderResultViewModel.Content {
        .init(
            market: makeResultMarketRow(executionPrice: executionPrice(placement), marketRow: marketRow),
            placedAt: now(),
            orderedAmount: orderedMoney(quote: quote),
            filledAmount: filledMoney(placement),
            tokensBought: filledShares(placement),
            resolutionDate: model.market.endDate,
            side: model.intent.side,
            heldShares: heldShares
        )
    }

    func makeResultMarketRow(
        executionPrice: Decimal?,
        marketRow: PolymarketOrderMarketRow.Model
    ) -> PolymarketOrderMarketRow.Model {
        guard model.intent.side == .sell else { return marketRow }

        guard let executionPrice else {
            return .make(
                market: model.market,
                outcome: model.outcome,
                eventTitle: model.eventTitle,
                isPriceUnavailable: true
            )
        }

        return .make(
            market: model.market,
            outcome: model.outcome,
            eventTitle: model.eventTitle,
            averagePrice: executionPrice,
            entryPrice: model.state.entryPrice
        )
    }
}

// MARK: - PlacementAnomaly

private extension PolymarketOrderSubmission {
    enum PlacementAnomaly: Error {
        case matchedWithoutFill
    }
}

// MARK: - Cancellation

private extension PolymarketOrderPlacementError {
    var isUserCancellation: Bool {
        guard case .notSent(let underlying) = self else { return false }

        if let signing = underlying as? PolymarketSigningError, case .cancelled = signing {
            return true
        }

        return underlying is CancellationError
    }
}
