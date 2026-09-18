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
    let details: PolymarketOrderResultDetailsView.Model?

    private let side: PolymarketOrderSide
    private let indexing: PolymarketOrderIndexing?
    private weak var coordinator: PolymarketOrderResultRoutable?

    private var positionTask: Task<Void, Never>?

    init(
        state: State,
        content: Content,
        indexing: PolymarketOrderIndexing? = nil,
        coordinator: PolymarketOrderResultRoutable?
    ) {
        self.state = state
        side = content.side
        self.indexing = indexing
        self.coordinator = coordinator

        title = Self.makeTitle(state: state, content: content)
        description = Self.makeDescription(state: state, content: content)
        appearance = state.appearance
        glyph = state.glyph
        glyphTint = state.glyphTint
        details = Self.makeDetails(state: state, content: content)

        awaitPosition()
    }

    deinit {
        positionTask?.cancel()
    }

    var actionTitle: String {
        canViewPosition ? Constants.viewPositionTitle : Localization.predictionPlaceResultToMain
    }

    var secondaryActionTitle: String? {
        canViewPosition ? Localization.predictionPlaceResultToMain : nil
    }

    var action: ViewAction {
        canViewPosition ? .viewPositionTapped : .toMainTapped
    }

    var isActionDisabled: Bool {
        canViewPosition && position == nil
    }

    private var isPositionExpected: Bool {
        side == .buy && indexing != nil && (state == .placed || state == .partiallyPlaced)
    }

    private var canViewPosition: Bool {
        isPositionExpected && (isAwaitingPosition || position != nil)
    }

    // MARK: - View actions

    func handleViewAction(_ action: ViewAction) {
        switch action {
        case .toMainTapped:
            coordinator?.returnToMain()
        case .viewPositionTapped:
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
        let executionPrice: Decimal?
        let side: PolymarketOrderSide
        let feeText: String?
    }

    enum ViewAction {
        case toMainTapped
        case viewPositionTapped
    }
}

// MARK: - The position the order created

private extension PolymarketOrderResultViewModel {
    func awaitPosition() {
        guard isPositionExpected, let indexing else { return }

        isAwaitingPosition = true

        positionTask = runTask(in: self) { @MainActor viewModel in
            viewModel.position = await indexing.value
            viewModel.isAwaitingPosition = false
        }
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
            let amount = PolymarketOrderFormatter.enteredAmount(content.filledAmount ?? content.orderedAmount)

            return content.side == .sell
                ? Localization.predictionCloseResultSoldTitle(amount)
                : Localization.predictionPlaceResultPlacedTitle(amount)
        case .partiallyPlaced:
            let filled = PolymarketOrderFormatter.enteredAmount(content.filledAmount)
            let ordered = PolymarketOrderFormatter.enteredAmount(content.orderedAmount)
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

    static func makeDetails(state: State, content: Content) -> PolymarketOrderResultDetailsView.Model? {
        guard state != .stillProcessing else { return nil }

        return .init(
            banner: makeBanner(state: state),
            market: content.market,
            tokensBoughtText: makeTokensBoughtText(state: state, content: content),
            executionPriceText: content.executionPrice.map(PolymarketPriceFormatter.centsText),
            resolutionDateText: content.resolutionDate.map(PolymarketOrderResultFormatter.resolutionDate),
            tokensTitle: content.side == .sell
                ? Constants.tokensSoldTitle
                : Localization.predictionPlaceResultTokensBought,
            fee: (state == .placed ? content.feeText : nil).map {
                .init(currencyCode: PolymarketUtilities.collateralTokenItem.currencySymbol, valueText: $0)
            }
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
        // [REDACTED_TODO_COMMENT]
        static let viewPositionTitle = "View position"
        static let partiallySoldTitle = Localization.predictionCloseResultPartiallySoldTitle
        static let noLiquidityTitle = Localization.predictionCloseResultNoFillTitle
        static let tokensSoldTitle = Localization.predictionCloseResultTokensSold
    }
}
