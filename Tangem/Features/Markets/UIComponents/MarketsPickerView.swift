//
//  MarketsPickerView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets

struct MarketsPickerView: View {
    @Binding var marketPriceIntervalType: MarketsPriceIntervalType

    let options: [MarketsPriceIntervalType]
    let shouldStretchToFill: Bool
    let isDisabled: Bool
    let style: SegmentedPicker<MarketsPriceIntervalType>.Style
    let titleFactory: (MarketsPriceIntervalType) -> String
    let accessibilityIdentifierFactory: ((MarketsPriceIntervalType) -> String)?

    init(
        marketPriceIntervalType: Binding<MarketsPriceIntervalType>,
        options: [MarketsPriceIntervalType],
        shouldStretchToFill: Bool,
        isDisabled: Bool,
        style: SegmentedPicker<MarketsPriceIntervalType>.Style,
        titleFactory: @escaping (MarketsPriceIntervalType) -> String,
        accessibilityIdentifierFactory: ((MarketsPriceIntervalType) -> String)? = nil
    ) {
        _marketPriceIntervalType = marketPriceIntervalType
        self.options = options
        self.shouldStretchToFill = shouldStretchToFill
        self.isDisabled = isDisabled
        self.style = style
        self.titleFactory = titleFactory
        self.accessibilityIdentifierFactory = accessibilityIdentifierFactory
    }

    var body: some View {
        SegmentedPicker(
            selectedOption: $marketPriceIntervalType,
            options: options,
            shouldStretchToFill: shouldStretchToFill,
            isDisabled: isDisabled,
            style: style,
            titleFactory: titleFactory,
            segmentAccessibilityIdentifier: accessibilityIdentifierFactory
        )
    }
}

#Preview {
    struct MarketsPickerPreviewView: View {
        @State private var firstInterval = MarketsPriceIntervalType.day
        @State private var secondInterval = MarketsPriceIntervalType.day
        @State private var thirdInterval = MarketsPriceIntervalType.day

        var body: some View {
            VStack(spacing: 30) {
                MarketsPickerView(
                    marketPriceIntervalType: $firstInterval,
                    options: [.day, .week, .month],
                    shouldStretchToFill: false,
                    isDisabled: false,
                    style: .init(textVerticalPadding: 2),
                    titleFactory: { $0.marketsListId }
                )

                MarketsPickerView(
                    marketPriceIntervalType: $secondInterval,
                    options: MarketsPriceIntervalType.allCases,
                    shouldStretchToFill: false,
                    isDisabled: false,
                    style: .init(textVerticalPadding: 2),
                    titleFactory: { $0.rawValue }
                )

                MarketsPickerView(
                    marketPriceIntervalType: $secondInterval,
                    options: MarketsPriceIntervalType.allCases,
                    shouldStretchToFill: true,
                    isDisabled: false,
                    style: .init(textVerticalPadding: 2),
                    titleFactory: { $0.rawValue }
                )
                .padding(.horizontal, 16)
            }
        }
    }

    return MarketsPickerPreviewView()
        .background(Colors.Background.primary)
}
