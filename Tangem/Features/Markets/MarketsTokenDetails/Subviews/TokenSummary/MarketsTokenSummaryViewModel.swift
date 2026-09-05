//
//  MarketsTokenSummaryViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

@MainActor
final class MarketsTokenSummaryViewModel: ObservableObject {
    @Published private(set) var state: State = .loading

    /// Handed to the sheet on tap so it renders the readings already on screen instead of fetching them again.
    private(set) var indicators: [TokenSummaryIndicator] = []

    private let symbol: String
    private let period: TokenSummaryPeriod
    private let mapper: TokenSummaryIndicatorsMapper
    private let indicatorsProvider: TokenSummaryIndicatorsProvider
    private let onTap: () -> Void

    private var hasLoaded = false

    init(
        symbol: String,
        period: TokenSummaryPeriod = .day,
        mapper: TokenSummaryIndicatorsMapper = TokenSummaryIndicatorsMapper(),
        indicatorsProvider: TokenSummaryIndicatorsProvider = CommonTokenSummaryIndicatorsProvider(),
        onTap: @escaping () -> Void
    ) {
        self.symbol = symbol
        self.period = period
        self.mapper = mapper
        self.indicatorsProvider = indicatorsProvider
        self.onTap = onTap
    }

    /// Loaded once per view model: the card's `task` runs again on every re-appearance, and the sheet
    /// reuses these readings.
    func loadIndicators() async {
        guard !hasLoaded else { return }

        hasLoaded = true

        do {
            let readings = try await indicatorsProvider.loadIndicators(symbol: symbol)

            indicators = readings
            state = mapper.map(readings: readings, timeframe: period.timeframe).score.map(State.loaded) ?? .unavailable
        } catch is CancellationError {
            // Nothing arrived, so let the next appearance ask again instead of latching a verdict.
            hasLoaded = false
        } catch {
            state = .unavailable
        }
    }

    func cardTapped() {
        onTap()
    }
}

// MARK: - State

extension MarketsTokenSummaryViewModel {
    enum State: Equatable {
        case loading
        case loaded(TokenSummaryScore)
        case unavailable
    }
}
