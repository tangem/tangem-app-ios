//
//  TokenRowMarketShowcase.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUIUtils

public struct TokenRowMarketShowcase: View {
    @State private var contentCase: ContentCase = .price
    @State private var showRank = true
    @State private var priceState: PriceStateOption = .loaded
    @State private var graph: GraphOption = .curve
    @State private var priceChange: PriceChangeOption = .positive
    @State private var isPriceChangeUpdating = false

    @State private var isRowEnabled = true
    @State private var overflow = false
    @State private var isMasked = false
    @State private var isDark = false
    @State private var isRTL = false
    @State private var dynamicTypeIndex = Self.dynamicTypeAllCases.firstIndex(of: .large) ?? 0

    @State private var tapCount = 0

    private static let dynamicTypeAllCases: [DynamicTypeSize] = Array(DynamicTypeSize.allCases)

    public init() {}

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                previewSection

                contentControls

                stateControls

                environmentControls
            }
            .padding()
        }
    }

    // MARK: - Preview

    private var previewSection: some View {
        section(title: "Preview") {
            row
                .background(DesignSystem.Color.bgSecondary, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                .environment(\.isBalanceMasked, isMasked)
                .environment(\.dynamicTypeSize, dynamicTypeSize)
                .environment(\.layoutDirection, isRTL ? .rightToLeft : .leftToRight)
                .environment(\.colorScheme, isDark ? .dark : .light)

            Text("taps: \(tapCount)")
                .font(.caption)
                .monospacedDigit()
                .foregroundStyle(.secondary)
        }
    }

    private var row: some View {
        TokenRowMarket(content)
            .accessibilityIdentifier("TokenRowMarketShowcase")
            .disabled(!isRowEnabled)
    }

    private var content: TokenRowMarket.Content {
        switch contentCase {
        case .price:
            return TokenRowMarket.Content.price(
                icon: TokenRowShowcase.iconInfo,
                title: title,
                ticker: ticker,
                rank: showRank ? rank : nil,
                capitalisation: capitalisation,
                price: priceValue,
                priceChange: priceChange.value(isUpdating: isPriceChangeUpdating),
                graph: graph.values,
                onTap: { tapCount += 1 }
            )

        case .shimmer:
            return TokenRowMarket.Content.shimmer
        }
    }

    private var priceValue: TokenRowValue {
        switch priceState {
        case .loading:
            return TokenRowValue.loading
        case .updating:
            return TokenRowValue.updating(price)
        case .loaded:
            return TokenRowValue.loaded(price)
        }
    }

    // MARK: - Controls

    private var contentControls: some View {
        section(title: "Content") {
            picker(title: "case", cases: ContentCase.allCases, binding: $contentCase)

            if contentCase == .price {
                Toggle("rank", isOn: $showRank)
                picker(title: "price", cases: PriceStateOption.allCases, binding: $priceState)
                picker(title: "graph", cases: GraphOption.allCases, binding: $graph)
                picker(title: "price change", cases: PriceChangeOption.allCases, binding: $priceChange)

                if priceChange != PriceChangeOption.none {
                    Toggle("updating price change", isOn: $isPriceChangeUpdating)
                }
            }
        }
    }

    @ViewBuilder
    private var stateControls: some View {
        if contentCase != .shimmer {
            section(title: "State") {
                Toggle("enabled", isOn: $isRowEnabled)
                Toggle("overflowing text", isOn: $overflow)
            }
        }
    }

    private var environmentControls: some View {
        section(title: "Environment (row only)") {
            Stepper(
                "Dynamic Type: \(String(describing: dynamicTypeSize))",
                value: $dynamicTypeIndex,
                in: 0 ... (Self.dynamicTypeAllCases.count - 1)
            )
            Toggle("masked balances (the price must stay visible)", isOn: $isMasked)
            Toggle("dark theme", isOn: $isDark)
            Toggle("right-to-left", isOn: $isRTL)
        }
    }

    // MARK: - Samples

    private var title: String { overflow ? "Wrapped Staked Ether Long Name" : "Bitcoin" }
    private var ticker: String { overflow ? "WSTETH" : "BTC" }
    private var rank: String { overflow ? "1024" : "1" }
    private var capitalisation: String { overflow ? "$2,084,120,345,678" : "$2.08T" }
    private var price: String { overflow ? "$105,432.18765432" : "$105,432.18" }

    // MARK: - Helpers

    private var dynamicTypeSize: DynamicTypeSize {
        Self.dynamicTypeAllCases[dynamicTypeIndex]
    }

    private func section<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.secondary)
            content()
        }
        .font(.callout)
    }

    private func picker<Value: Hashable & TokenRowShowcaseLabeled>(
        title: String,
        cases: [Value],
        binding: Binding<Value>
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.caption)
            Picker(title, selection: binding) {
                ForEach(cases, id: \.self) { value in
                    Text(value.showcaseLabel).tag(value)
                }
            }
            .pickerStyle(.segmented)
        }
    }
}

// MARK: - Showcase axes

extension TokenRowMarketShowcase {
    typealias PriceChangeOption = TokenRowShowcase.PriceChangeOption

    enum ContentCase: Hashable, CaseIterable, TokenRowShowcaseLabeled {
        case price
        case shimmer

        var showcaseLabel: String {
            switch self {
            case .price: return "price"
            case .shimmer: return "shimmer"
            }
        }
    }

    enum PriceStateOption: Hashable, CaseIterable, TokenRowShowcaseLabeled {
        case loading
        case updating
        case loaded

        var showcaseLabel: String {
            switch self {
            case .loading: return "skeleton"
            case .updating: return "shimmer"
            case .loaded: return "loaded"
            }
        }
    }

    enum GraphOption: Hashable, CaseIterable, TokenRowShowcaseLabeled {
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

        var showcaseLabel: String {
            switch self {
            case .curve: return "curve"
            case .loading: return "loading"
            case .flat: return "flat"
            case .twoPoints: return "2 points"
            }
        }
    }
}
