//
//  TokenRowMarketShowcase.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

#if INTERNAL || DEBUG
import SwiftUI
import TangemUI

struct TokenRowMarketShowcase: View {
    @State private var configuration = Configuration()
    @State private var isRowEnabled = true
    @State private var isMasked = false
    @State private var tapCount = 0

    var body: some View {
        DSShowcase("TokenRowMarket") { controls in
            controls.picker("Case", $configuration.contentCase)

            if configuration.contentCase == .price {
                controls.toggle("Rank", $configuration.showRank)
                controls.picker("Price", $configuration.priceState, options: PriceStateOption.allCases, label: \.label)
                controls.picker("Graph", $configuration.graph)
                controls.picker("Price change", $configuration.priceChange)

                if configuration.priceChange != PriceChangeOption.none {
                    controls.toggle("Updating price change", $configuration.isPriceChangeUpdating)
                }

                controls.toggle("Enabled", $isRowEnabled)
                controls.toggle("Overflowing text", $configuration.overflow)
            }

            controls.toggle("Masked balances", $isMasked)
            controls.note("A market price is public data: it must stay visible when balances are masked.")
            controls.readout("Taps", "\(tapCount)")
        } stage: {
            row(configuration, isInteractive: true)
                .disabled(!isRowEnabled)
                .environment(\.isBalanceMasked, isMasked)
        } matrix: {
            DSShowcaseGroup("Content") {
                DSShowcaseMatrix(rows: ContentCase.allCases) { contentCase in
                    matrixRow(Configuration(contentCase: contentCase))
                }
            }

            DSShowcaseGroup("Price × graph") {
                DSShowcaseMatrix(rows: PriceStateOption.allCases, columns: GraphOption.allCases, rowLabel: { $0.label }) { priceState, graph in
                    matrixRow(Configuration(priceState: priceState, graph: graph))
                }
            }

            DSShowcaseGroup("Price change") {
                DSShowcaseMatrix(rows: PriceChangeOption.allCases, columns: [false, true], columnLabel: { $0 ? "updating" : "idle" }) { priceChange, isUpdating in
                    matrixRow(Configuration(priceChange: priceChange, isPriceChangeUpdating: isUpdating))
                }
            }

            DSShowcaseGroup("Rank") {
                DSShowcaseMatrix(rows: [true, false], rowLabel: { $0 ? "with rank" : "no rank" }) { showRank in
                    matrixRow(Configuration(showRank: showRank))
                }
            }

            DSShowcaseGroup("States") {
                DSShowcaseMatrix(rows: RowStateOption.allCases) { state in
                    matrixRow(Configuration(overflow: state == .overflowingText))
                        .disabled(state == .disabled)
                        .environment(\.isBalanceMasked, state == .maskedBalances)
                }
            }
        }
    }

    private func matrixRow(_ configuration: Configuration) -> some View {
        row(configuration, isInteractive: false)
            .frame(width: 343)
    }

    private func row(_ configuration: Configuration, isInteractive: Bool) -> some View {
        TokenRowMarket(content(configuration, isInteractive: isInteractive))
    }

    private func content(_ configuration: Configuration, isInteractive: Bool) -> TokenRowMarket.Content {
        switch configuration.contentCase {
        case .price:
            return TokenRowMarket.Content.price(
                icon: TokenRowShowcase.iconInfo,
                title: configuration.title,
                ticker: configuration.ticker,
                rank: configuration.showRank ? configuration.rank : nil,
                capitalisation: configuration.capitalisation,
                price: priceValue(configuration),
                priceChange: configuration.priceChange.value(isUpdating: configuration.isPriceChangeUpdating),
                graph: configuration.graph.values,
                onTap: isInteractive ? { tapCount += 1 } : {}
            )

        case .shimmer:
            return TokenRowMarket.Content.shimmer
        }
    }

    private func priceValue(_ configuration: Configuration) -> TokenRowValue {
        switch configuration.priceState {
        case .loading:
            return TokenRowValue.loading
        case .updating:
            return TokenRowValue.updating(configuration.price)
        case .loaded:
            return TokenRowValue.loaded(configuration.price)
        }
    }
}

// MARK: - Configuration

private extension TokenRowMarketShowcase {
    typealias PriceChangeOption = TokenRowShowcase.PriceChangeOption

    struct Configuration {
        var contentCase: ContentCase = .price
        var showRank = true
        var priceState: PriceStateOption = .loaded
        var graph: GraphOption = .curve
        var priceChange: PriceChangeOption = .positive
        var isPriceChangeUpdating = false
        var overflow = false

        var title: String { overflow ? "Wrapped Staked Ether Long Name" : "Bitcoin" }
        var ticker: String { overflow ? "WSTETH" : "BTC" }
        var rank: String { overflow ? "1024" : "1" }
        var capitalisation: String { overflow ? "$2,084,120,345,678" : "$2.08T" }
        var price: String { overflow ? "$105,432.18765432" : "$105,432.18" }
    }

    enum ContentCase: Hashable, CaseIterable {
        case price
        case shimmer
    }

    enum PriceStateOption: Hashable, CaseIterable {
        case loading
        case updating
        case loaded

        var label: String {
            switch self {
            case .loading: return "skeleton"
            case .updating: return "shimmer"
            case .loaded: return "loaded"
            }
        }
    }

    enum RowStateOption: Hashable, CaseIterable {
        case overflowingText
        case disabled
        case maskedBalances
    }

    enum GraphOption: Hashable, CaseIterable {
        case curve
        case loading
        case flat
        case twoPoints

        var values: [Double]? {
            switch self {
            case .curve: return [12, 14, 13, 17, 16, 21, 19, 24, 22, 27, 25, 31]
            case .loading: return nil
            case .flat: return Array(repeating: 18, count: 12)
            case .twoPoints: return [12, 31]
            }
        }
    }
}
#endif
