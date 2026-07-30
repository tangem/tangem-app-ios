//
//  MarketsTokenSummaryViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

final class MarketsTokenSummaryViewModel: ObservableObject {
    @Published private(set) var state: State = .loading

    /// Handed to the sheet on tap so it renders the readings already on screen instead of fetching them again.
    private(set) var indicators: [TokenSummaryIndicator] = []

    /// Nothing to open while the readings are in flight, or when none arrived at all — the sheet would
    /// only repeat the message the card already shows.
    var isTappable: Bool {
        switch state {
        case .loading: false
        case .loaded(let gaugeState): gaugeState != .dataUnavailable
        }
    }

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
    @MainActor
    func loadIndicators() async {
        guard !hasLoaded else { return }

        hasLoaded = true

        do {
            let readings = try await indicatorsProvider.loadIndicators(symbol: symbol)

            indicators = readings
            state = .loaded(mapper.map(readings: readings, timeframe: period.timeframe).gaugeState)
        } catch is CancellationError {
            // Nothing arrived, so let the next appearance ask again instead of latching a verdict.
            hasLoaded = false
        } catch {
            state = .loaded(.dataUnavailable)
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
        case loaded(TokenSummaryGaugeState)
    }
}
