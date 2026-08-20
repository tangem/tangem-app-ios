//
//  MarketsTokenSummaryView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemLocalization
import TangemUI
import TangemUIUtils

struct MarketsTokenSummaryView: View {
    @ObservedObject var viewModel: MarketsTokenSummaryViewModel

    var body: some View {
        Group {
            if viewModel.isTappable {
                SwiftUI.Button(action: viewModel.cardTapped) {
                    card
                }
                .buttonStyle(.plain)
            } else {
                card
            }
        }
        .task { await viewModel.loadIndicators() }
    }

    @ViewBuilder
    private var card: some View {
        switch viewModel.state {
        case .loading:
            MarketsTokenSummaryPlaceholderView()

        case .loaded(let gaugeState):
            VStack(alignment: .leading, spacing: CardLayout.trackSpacing) {
                header(for: gaugeState)

                TokenSummaryTrackView(score: gaugeState.score)
            }
            .cardBackground()
        }
    }

    private func header(for gaugeState: TokenSummaryGaugeState) -> some View {
        VStack(alignment: .leading, spacing: CardLayout.titleSpacing) {
            Text(Localization.tokenSummaryTitle)
                .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textSecondary)

            if let score = gaugeState.score {
                Text(score.outlook.title)
                    .style(DesignSystem.Font.headingSmallToken, color: DesignSystem.Color.textPrimary)
            } else if let message = gaugeState.unavailabilityMessage {
                Text(message)
                    .style(DesignSystem.Font.headingSmallToken, color: DesignSystem.Color.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Placeholder

/// Shown both by the card itself while its indicators load and by the coin page's block skeletons, so the
/// page-wide skeleton and the card's own loading state are the same view in the same place.
struct MarketsTokenSummaryPlaceholderView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: CardLayout.trackSpacing) {
            VStack(alignment: .leading, spacing: CardLayout.titleSpacing) {
                Shimmer()
                    .variant(.custom(height: DesignSystem.Font.captionMediumToken.lineHeight))

                Shimmer()
                    .variant(.custom(height: DesignSystem.Font.headingSmallToken.lineHeight))
            }

            Shimmer()
                .variant(.custom(height: TokenSummaryTrackView.height))
        }
        .cardBackground()
    }
}

// MARK: - Card chrome

private enum CardLayout {
    static let titleSpacing: CGFloat = 4
    static let trackSpacing: CGFloat = 20
    static let padding: CGFloat = 16
    static let radius: CGFloat = 24
}

private extension View {
    func cardBackground() -> some View {
        roundedBackground(with: DesignSystem.Color.bgSecondary, padding: CardLayout.padding, radius: CardLayout.radius)
    }
}

// MARK: - Previews

#Preview {
    VStack(spacing: 16) {
        previewCard(.score)
        previewCard(.outlookUnavailable)
        previewCard(.dataUnavailable)
        previewCard(.pending)
    }
    .padding(16)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(DesignSystem.Color.bgPrimary)
}

private func previewCard(_ readings: PreviewIndicatorsProvider.Readings) -> some View {
    MarketsTokenSummaryView(
        viewModel: .init(symbol: "BTC", indicatorsProvider: PreviewIndicatorsProvider(readings: readings), onTap: {})
    )
}

private struct PreviewIndicatorsProvider: TokenSummaryIndicatorsProvider {
    enum Readings {
        case score
        case outlookUnavailable
        case dataUnavailable
        case pending
    }

    let readings: Readings

    func loadIndicators(symbol: String) async throws -> [TokenSummaryIndicator] {
        switch readings {
        case .score:
            return [
                .init(kind: .galaxyScore, timeframe: .day, title: "Galaxy Score", value: 72, signal: .positive, updatedAt: nil),
                .init(kind: .sentiment, timeframe: .day, title: "Sentiment", value: 4, signal: .positive, updatedAt: nil),
                .init(kind: .rsi, timeframe: .day, title: "RSI", value: 61, signal: .neutral, updatedAt: nil),
                .init(kind: .macd, timeframe: .day, title: "MACD", value: Decimal(string: "145.67"), signal: .positive, updatedAt: nil),
                .init(kind: .maCross, timeframe: .day, title: "MA Cross", value: 50, signal: .positive, updatedAt: nil),
            ]

        case .outlookUnavailable:
            return [.init(kind: .rsi, timeframe: .day, title: "RSI", value: nil, signal: .unavailable, updatedAt: nil)]

        case .dataUnavailable:
            return []

        case .pending:
            try await Task.sleep(for: .seconds(600))
            return []
        }
    }
}
