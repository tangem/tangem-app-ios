//
//  MarketsPickerView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI

struct MarketsPickerView: View {
    @Binding var marketPriceIntervalType: MarketsPriceIntervalType

    let options: [MarketsPriceIntervalType]
    let shouldStretchToFill: Bool
    let style: SegmentedPicker<MarketsPriceIntervalType>.Style
    let titleFactory: (MarketsPriceIntervalType) -> String
    let accessibilityIdentifierFactory: ((MarketsPriceIntervalType) -> String)?

    init(
        marketPriceIntervalType: Binding<MarketsPriceIntervalType>,
        options: [MarketsPriceIntervalType],
        shouldStretchToFill: Bool,
        style: SegmentedPicker<MarketsPriceIntervalType>.Style,
        titleFactory: @escaping (MarketsPriceIntervalType) -> String,
        accessibilityIdentifierFactory: ((MarketsPriceIntervalType) -> String)? = nil
    ) {
        _marketPriceIntervalType = marketPriceIntervalType
        self.options = options
        self.shouldStretchToFill = shouldStretchToFill
        self.style = style
        self.titleFactory = titleFactory
        self.accessibilityIdentifierFactory = accessibilityIdentifierFactory
    }

    var body: some View {
        MarketsPickerViewRedesign(
            selection: $marketPriceIntervalType,
            data: options,
            titleFactory: titleFactory,
            style: shouldStretchToFill ? .flexible : .fixed
        )
    }
}

private struct MarketsPickerViewRedesign: View {
    typealias Option = MarketsPriceIntervalType

    @Binding private var selection: Item

    private let data: [Item]
    private let titleFactory: (Option) -> String
    private let style: TangemSegmentedPickerStyle

    init(
        selection: Binding<Option>,
        data: [Option],
        titleFactory: @escaping (Option) -> String,
        style: TangemSegmentedPickerStyle,
    ) {
        _selection = Binding(
            get: {
                Item(
                    intervalType: selection.wrappedValue,
                    titleFactory: titleFactory
                )
            },
            set: { value in
                selection.wrappedValue = value.intervalType
            }
        )
        self.data = data.map { Item(intervalType: $0, titleFactory: titleFactory) }
        self.titleFactory = titleFactory
        self.style = style
    }

    var body: some View {
        TangemSegmentedPicker(
            data: data,
            selection: $selection
        )
        .style(style)
        .showSeparators(true)
    }

    struct Item: TangemSegmentedPickerTextProvider {
        let intervalType: MarketsPriceIntervalType
        let titleFactory: (MarketsPriceIntervalType) -> String
        var text: String { titleFactory(intervalType) }

        static func == (lhs: Self, rhs: Self) -> Bool {
            lhs.intervalType == rhs.intervalType
        }

        func hash(into hasher: inout Hasher) {
            hasher.combine(intervalType)
        }
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
                    style: .init(textVerticalPadding: 2),
                    titleFactory: { $0.marketsListId }
                )

                MarketsPickerView(
                    marketPriceIntervalType: $secondInterval,
                    options: MarketsPriceIntervalType.allCases,
                    shouldStretchToFill: false,
                    style: .init(textVerticalPadding: 2),
                    titleFactory: { $0.rawValue }
                )

                MarketsPickerView(
                    marketPriceIntervalType: $secondInterval,
                    options: MarketsPriceIntervalType.allCases,
                    shouldStretchToFill: true,
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
