//
//  TokenRowMarket.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUIUtils

public struct TokenRowMarket: View, Setupable {
    private let content: Content

    var accessibility: Accessibility = .combined(label: nil)

    @Environment(\.isEnabled) private var isEnabled

    @ScaledMetric private var padding: CGFloat = TokenRowMetrics.padding
    @ScaledMetric private var slotSpacing: CGFloat = TokenRowMetrics.slotSpacing
    @ScaledMetric private var lineSpacing: CGFloat = TokenRowMetrics.lineSpacing
    @ScaledMetric private var inlineSpacing: CGFloat = TokenRowMetrics.inlineSpacing
    @ScaledMetric private var minTitleWidth: CGFloat = TokenRowMetrics.minTitleWidth
    @ScaledMetric private var graphWidth: CGFloat = TokenRowMetrics.graphWidth
    @ScaledMetric private var graphHeight: CGFloat = TokenRowMetrics.graphHeight

    public init(_ content: Content) {
        self.content = content
    }

    public var body: some View {
        switch content {
        case .price(
            let icon,
            let title,
            let ticker,
            let rank,
            let capitalisation,
            let price,
            let priceChange,
            let graph,
            let onTap
        ):
            priceRow(
                icon: icon,
                title: title,
                ticker: ticker,
                rank: rank,
                capitalisation: capitalisation,
                price: price,
                priceChange: priceChange,
                graph: graph,
                onTap: onTap
            )

        case .shimmer:
            TokenRowSkeleton(hasGraph: true)
        }
    }

    // MARK: - Price

    private func priceRow(
        icon: TokenIconInfo,
        title: String,
        ticker: String,
        rank: String?,
        capitalisation: String,
        price: TokenRowValue,
        priceChange: TokenRowPriceChange?,
        graph: [Double]?,
        onTap: @escaping () -> Void
    ) -> some View {
        let mainLine = HStack(alignment: .center, spacing: slotSpacing) {
            TokenRowTokenIcon(icon, accessibilityIdentifier: identifiers?.icon)

            // A loading price column has no intrinsic width, so it takes an equal share instead of a fit.
            RowContentLayout(
                contentLead: price.isLoading ? .equal : .end,
                minOppositeWidth: minTitleWidth
            ) {
                titleColumn(title: title, ticker: ticker, rank: rank, capitalisation: capitalisation)
                priceColumn(price: price, priceChange: priceChange)
            }
            .frame(maxWidth: .infinity)

            graphCurve(graph: graph, priceChange: priceChange)
        }

        return PressableRow(
            onTap: onTap,
            label: padded(mainLine).rowAccessibility(accessibilityShape)
        )
    }

    private func titleColumn(
        title: String,
        ticker: String,
        rank: String?,
        capitalisation: String
    ) -> some View {
        VStack(alignment: .leading, spacing: lineSpacing) {
            HStack(alignment: .lastTextBaseline, spacing: inlineSpacing) {
                TokenRowTitleText(title, accessibilityIdentifier: identifiers?.name)

                TokenRowCaptionText(ticker, accessibilityIdentifier: identifiers?.ticker)
                    .layoutPriority(1)
            }

            HStack(alignment: .center, spacing: inlineSpacing) {
                if let rank {
                    rankBadge(rank)
                }

                TokenRowCaptionText(capitalisation, accessibilityIdentifier: identifiers?.capitalisation)
            }
        }
    }

    private func rankBadge(_ rank: String) -> some View {
        Badge(label: rank, accessibilityLabel: nil)
            .size(.x4)
            .variant(.tinted)
            .appearance(.neutral)
            .accessibilityIdentifier(identifiers?.rank)
            .layoutPriority(1)
    }

    private func priceColumn(price: TokenRowValue, priceChange: TokenRowPriceChange?) -> some View {
        VStack(alignment: .trailing, spacing: lineSpacing) {
            priceLine(price)

            if let priceChange {
                UtilPriceChange(value: priceChange.value, direction: priceChange.direction)
                    .updating(priceChange.isUpdating)
                    .accessibilityIdentifier(identifiers?.priceChange)
            }
        }
    }

    @ViewBuilder
    private func priceLine(_ price: TokenRowValue) -> some View {
        switch price {
        case .loading:
            Shimmer()
                .variant(.text(style: .body, alignment: .trailing))

        case .updating(let value):
            priceText(value, isUpdating: true)

        case .loaded(let value):
            priceText(value, isUpdating: false)
        }
    }

    /// Deliberately not `masked(_:)` — a market price is public data, never hidden by `\.isBalanceMasked`.
    private func priceText(_ value: UtilBalance.Value, isUpdating: Bool) -> some View {
        UtilBalance(value)
            .updating(isUpdating)
            .style(DesignSystem.Font.bodyMediumToken, color: DesignSystem.Color.textPrimary)
            .accessibilityIdentifier(identifiers?.price)
    }

    private func graphCurve(graph: [Double]?, priceChange: TokenRowPriceChange?) -> some View {
        UtilGraph(values: graph ?? [])
            .direction(graphDirection(for: priceChange))
            .isLoading(graph == nil)
            .frame(width: graphWidth, height: graphHeight)
    }

    private func graphDirection(for priceChange: TokenRowPriceChange?) -> UtilGraph.Direction {
        switch priceChange?.direction {
        case .positive: .positive
        case .negative: .negative
        case .neutral, nil: .neutral
        }
    }

    // MARK: - Shell

    private func padded(_ content: some View) -> some View {
        content
            .opacity(isEnabled ? 1 : TokenRowMetrics.dimmedOpacity)
            .padding(padding)
    }

    // MARK: - Accessibility

    private var accessibilityShape: RowAccessibility.Shape {
        switch accessibility {
        case .combined(let label): .element(label: label)
        case .leaves: .container
        }
    }

    private var identifiers: AccessibilityIdentifiers? {
        switch accessibility {
        case .combined: nil
        case .leaves(let identifiers): identifiers
        }
    }
}

// MARK: - Content

public extension TokenRowMarket {
    struct AccessibilityIdentifiers: Equatable, Hashable, Sendable {
        public let name: String?
        public let ticker: String?
        public let price: String?
        public let priceChange: String?
        public let capitalisation: String?
        public let rank: String?
        public let icon: String?

        public init(
            name: String? = nil,
            ticker: String? = nil,
            price: String? = nil,
            priceChange: String? = nil,
            capitalisation: String? = nil,
            rank: String? = nil,
            icon: String? = nil
        ) {
            self.name = name
            self.ticker = ticker
            self.price = price
            self.priceChange = priceChange
            self.capitalisation = capitalisation
            self.rank = rank
            self.icon = icon
        }
    }

    enum Content {
        /// A `nil` graph is still loading.
        case price(
            icon: TokenIconInfo,
            title: String,
            ticker: String,
            rank: String?,
            capitalisation: String,
            price: TokenRowValue,
            priceChange: TokenRowPriceChange?,
            graph: [Double]?,
            onTap: () -> Void
        )

        case shimmer
    }

    enum Accessibility: Equatable, Hashable, Sendable {
        case combined(label: String?)
        case leaves(AccessibilityIdentifiers)
    }
}

// MARK: - Setupable

public extension TokenRowMarket {
    func accessibilityLabel(_ label: String?) -> Self {
        map { $0.accessibility = .combined(label: label) }
    }

    func accessibilityIdentifiers(_ identifiers: AccessibilityIdentifiers) -> Self {
        map { $0.accessibility = .leaves(identifiers) }
    }
}
