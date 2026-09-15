//
//  PolymarketOrderResultViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemLocalization
import TangemPolymarket
import TangemPolymarketUI
import TangemUI

final class PolymarketOrderResultViewModel: Identifiable {
    let state: State

    let title: String
    let description: String?
    let appearance: StatusScreenAppearance
    let glyph: StatusIcon.Glyph
    let details: PolymarketOrderResultDetailsView.Model?

    private weak var coordinator: PolymarketOrderResultRoutable?

    init(state: State, content: Content, coordinator: PolymarketOrderResultRoutable?) {
        self.state = state
        self.coordinator = coordinator

        title = Self.makeTitle(state: state, content: content)
        description = Self.makeDescription(state: state, content: content)
        appearance = state.appearance
        glyph = state.glyph
        details = Self.makeDetails(state: state, content: content)
    }

    // MARK: - View actions

    func handleViewAction(_ action: ViewAction) {
        switch action {
        case .toMainTapped:
            coordinator?.closeOrder()
        }
    }
}

// MARK: - State

extension PolymarketOrderResultViewModel {
    enum State {
        case placed
        case partiallyPlaced
        case noFill
        case stillProcessing
    }

    struct Content {
        let market: PolymarketOrderMarketRow.Model
        let placedAt: Date
        let orderedAmount: Decimal?
        let filledAmount: Decimal?
        let tokensBought: Decimal?
        let resolutionDate: Date?
    }

    enum ViewAction {
        case toMainTapped
    }
}

// MARK: - Appearance

private extension PolymarketOrderResultViewModel.State {
    var appearance: StatusScreenAppearance {
        switch self {
        case .placed: .success
        case .partiallyPlaced: .warning
        case .noFill: .error
        case .stillProcessing: .neutral
        }
    }

    var glyph: StatusIcon.Glyph {
        switch self {
        case .placed, .partiallyPlaced: .checkmark
        case .noFill: .heartBroken
        case .stillProcessing: .info
        }
    }
}

// MARK: - Mapping

private extension PolymarketOrderResultViewModel {
    static func makeTitle(state: State, content: Content) -> String {
        switch state {
        case .placed:
            let amount = content.filledAmount ?? content.orderedAmount
            return [
                Localization.predictionPlaceResultSuccessTitle,
                PolymarketOrderFormatter.enteredAmount(amount),
            ].joined(separator: "\n")
        case .partiallyPlaced:
            let filled = PolymarketOrderFormatter.enteredAmount(content.filledAmount)
            let ordered = PolymarketOrderFormatter.enteredAmount(content.orderedAmount)
            return [
                Localization.predictionPlaceResultPartialTitle,
                Localization.predictionPlaceResultPartialAmount(filled, ordered),
            ].joined(separator: "\n")
        case .noFill:
            return Localization.predictionPlaceResultNoFillTitle
        case .stillProcessing:
            return Localization.predictionPlaceDelayedTimeoutTitle
        }
    }

    static func makeDescription(state: State, content: Content) -> String? {
        switch state {
        case .placed, .partiallyPlaced, .noFill:
            PolymarketOrderResultFormatter.placedAt(content.placedAt)
        case .stillProcessing:
            Localization.predictionPlaceDelayedTimeoutDescription
        }
    }

    static func makeDetails(state: State, content: Content) -> PolymarketOrderResultDetailsView.Model? {
        guard state != .stillProcessing else { return nil }

        return .init(
            banner: makeBanner(state: state),
            market: content.market,
            tokensBoughtText: makeTokensBoughtText(state: state, content: content),
            resolutionDateText: content.resolutionDate.map(PolymarketOrderResultFormatter.resolutionDate)
        )
    }

    static func makeBanner(state: State) -> PolymarketOrderResultDetailsView.Banner? {
        switch state {
        case .partiallyPlaced:
            .init(
                title: Localization.predictionPlaceResultPartialBannerTitle,
                description: Localization.predictionPlaceResultPartialBannerDescription,
                style: .partialFill
            )
        case .noFill:
            .init(
                title: Localization.predictionPlaceResultNoFillBannerTitle,
                description: Localization.predictionPlaceResultNoFillBannerDescription,
                style: .noFill
            )
        case .placed, .stillProcessing:
            nil
        }
    }

    static func makeTokensBoughtText(state: State, content: Content) -> String? {
        guard state != .noFill, let tokensBought = content.tokensBought else { return nil }

        return PolymarketOrderFormatter.shares(tokensBought)
    }
}

// MARK: - Reading the exchange's answer

extension PolymarketOrderResultViewModel.State {
    init(placement: PolymarketOrderPlacement, quotedShares: Decimal) {
        guard placement.isMatched, let filled = placement.takingAmount, filled > 0 else {
            self = .stillProcessing
            return
        }

        self = filled < quotedShares ? .partiallyPlaced : .placed
    }
}
