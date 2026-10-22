//
//  PolymarketOrderResultViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import TangemAssets
import TangemFoundation
import TangemLocalization
import TangemPolymarket
import TangemPolymarketUI
import TangemUI

final class PolymarketOrderResultViewModel: ObservableObject, Identifiable {
    @Published private(set) var position: PolymarketPosition?
    @Published private(set) var isAwaitingPosition = false

    let state: State

    let title: String
    let description: String?
    let appearance: StatusScreenAppearance
    let glyphTint: Color?
    let glyph: StatusIcon.Glyph
    @Published private(set) var details: PolymarketOrderResultDetailsView.Model?

    private let content: Content
    private let side: PolymarketOrderSide
    private let indexing: PolymarketOrderIndexing?
    private weak var coordinator: PolymarketOrderResultRoutable?

    private var positionTask: Task<Void, Never>?

    init(
        state: State,
        content: Content,
        indexing: PolymarketOrderIndexing? = nil,
        offersPlacedPosition: Bool = true,
        coordinator: PolymarketOrderResultRoutable?
    ) {
        self.offersPlacedPosition = offersPlacedPosition
        self.state = state
        self.content = content
        side = content.side
        self.indexing = indexing
        self.coordinator = coordinator

        title = Self.makeTitle(state: state, content: content)
        description = Self.makeDescription(state: state, content: content)
        appearance = state.appearance
        glyph = state.glyph
        glyphTint = state.glyphTint
        details = Self.makeDetails(state: state, content: content, market: content.market)

        awaitPosition()
    }

    deinit {
        positionTask?.cancel()
    }

    private let offersPlacedPosition: Bool

    var actionTitle: String {
        if canViewPosition {
            return Constants.viewPositionTitle
        }

        return Localization.commonClose
    }

    var action: ViewAction {
        if canViewPosition {
            return .openPositionDetails
        }

        return .close
    }

    var isActionDisabled: Bool {
        canViewPosition && position == nil
    }

    var hidesFooter: Bool {
        !canViewPosition
    }

    var blocksSwipeDismiss: Bool {
        closesPosition
    }

    var closesPosition: Bool {
        guard side == .sell, state == .placed || state == .partiallyPlaced else { return false }
        guard let heldShares = content.heldShares, let soldShares = content.tokensBought else { return false }

        return heldShares - soldShares < Constants.dustShares
    }

    private var isPositionExpected: Bool {
        offersPlacedPosition && side == .buy && indexing != nil && (state == .placed || state == .partiallyPlaced)
    }

    private var canViewPosition: Bool {
        isPositionExpected && (isAwaitingPosition || position != nil)
    }

    // MARK: - View actions

    func handleViewAction(_ action: ViewAction) {
        switch action {
        case .close:
            coordinator?.closeOrder()
        case .openPositionDetails:
            guard let position else { return }

            coordinator?.openPosition(position)
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
        let side: PolymarketOrderSide
        var heldShares: Decimal?
    }

    enum ViewAction {
        case close
        case openPositionDetails
    }
}

// MARK: - The position the order created

private extension PolymarketOrderResultViewModel {
    func awaitPosition() {
        guard isPositionExpected, let indexing else { return }

        isAwaitingPosition = true
        refreshDetails()

        positionTask = runTask(in: self) { @MainActor viewModel in
            viewModel.position = await indexing.value
            viewModel.isAwaitingPosition = false
            viewModel.refreshDetails()
        }
    }

    func refreshDetails() {
        details = Self.makeDetails(state: state, content: content, market: settledMarketRow)
    }

    var settledMarketRow: PolymarketOrderMarketRow.Model {
        content.market.settling(
            nextPriceText: isAwaitingPosition ? nil : PolymarketPriceFormatter.centsText(position?.avgPrice),
            isLoading: isAwaitingPosition
        )
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

    var glyphTint: Color? {
        switch self {
        case .partiallyPlaced: DesignSystem.Color.iconStatusWarning
        case .placed, .noFill, .stillProcessing: nil
        }
    }
}

// MARK: - Mapping

private extension PolymarketOrderResultViewModel {
    static func makeTitle(state: State, content: Content) -> String {
        switch state {
        case .placed:
            let amount = PolymarketOrderFormatter.money(content.filledAmount)

            return content.side == .sell
                ? Localization.predictionCloseResultSoldTitle(amount)
                : Localization.predictionPlaceResultPlacedTitle(amount)
        case .partiallyPlaced:
            let filled = PolymarketOrderFormatter.money(content.filledAmount)
            let ordered = PolymarketOrderFormatter.money(content.orderedAmount)
            return [
                content.side == .sell ? Constants.partiallySoldTitle : Localization.predictionPlaceResultPartialTitle,
                Localization.predictionPlaceResultPartialAmount(filled, ordered),
            ].joined(separator: "\n")
        case .noFill:
            return content.side == .sell ? Constants.noLiquidityTitle : Localization.predictionPlaceResultNoFillTitle
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

    static func makeDetails(
        state: State,
        content: Content,
        market: PolymarketOrderMarketRow.Model
    ) -> PolymarketOrderResultDetailsView.Model? {
        guard state != .stillProcessing else { return nil }

        return .init(
            banner: makeBanner(state: state),
            market: market,
            tokensBoughtText: makeTokensBoughtText(state: state, content: content),
            resolutionDateText: content.resolutionDate.map(PolymarketOrderResultFormatter.resolutionDate),
            tokensTitle: content.side == .sell
                ? Constants.tokensSoldTitle
                : Localization.predictionPlaceResultTokensBought
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
    init(placement: PolymarketOrderPlacement, quotedShares: Decimal, side: PolymarketOrderSide) {
        guard placement.isMatched, let taking = placement.takingAmount, taking > 0 else {
            self = .stillProcessing
            return
        }

        let filled: Decimal

        switch side {
        case .buy:
            filled = taking
        case .sell:
            guard let making = placement.makingAmount else {
                self = .stillProcessing
                return
            }

            filled = making
        }

        self = filled < quotedShares ? .partiallyPlaced : .placed
    }
}

// MARK: - Constants

private extension PolymarketOrderResultViewModel {
    enum Constants {
        static let dustShares: Decimal = 0.01
        static let viewPositionTitle = Localization.predictionPlaceResultViewPosition
        static let partiallySoldTitle = Localization.predictionCloseResultPartiallySoldTitle
        static let noLiquidityTitle = Localization.predictionCloseResultNoFillTitle
        static let tokensSoldTitle = Localization.predictionCloseResultTokensSold
    }
}
