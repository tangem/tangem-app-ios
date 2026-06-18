//
//  TangemTabs.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI

public struct TangemTabs<Data>: View
    where Data: RandomAccessCollection, Data.Element: TangemTabsTextProvider {
    fileprivate typealias Item = Data.Element

    @ScaledMetric private var contentHorizontalPadding: CGFloat
    @ScaledMetric private var contentVerticalPadding: CGFloat
    @ScaledMetric private var spacing: CGFloat

    private let animation: Animation = .spring

    private let data: Data
    @Binding private var selection: Item

    public init(
        data: Data,
        selection: Binding<Data.Element>
    ) {
        self.data = data
        _selection = selection

        _spacing = ScaledMetric(wrappedValue: .unit(.x2))
        _contentHorizontalPadding = ScaledMetric(wrappedValue: .unit(.x3))
        _contentVerticalPadding = ScaledMetric(wrappedValue: .unit(.x2))
    }

    public var body: some View {
        content
            .animation(animation, value: selection)
    }
}

// MARK: - Subviews

private extension TangemTabs {
    var content: some View {
        HStack(spacing: spacing) {
            ForEach(data, id: \.self) { item in
                tab(item)
            }
        }
    }

    func tab(_ item: Item) -> some View {
        Button(action: { selection = item }) {
            itemContent(item)
                .background(
                    backgroundColor(isSelected: isItemSelected(item)),
                    in: .capsule
                )
        }
        .buttonStyle(.plain)
    }

    func itemContent(_ item: Item) -> some View {
        Text(item.text)
            .style(
                Font.Tangem.Body16.semibold,
                color: fontColor(isSelected: isItemSelected(item))
            )
            .padding(.horizontal, contentHorizontalPadding)
            .padding(.vertical, contentVerticalPadding)
    }
}

// MARK: - Calculations

private extension TangemTabs {
    func isItemSelected(_ item: Item) -> Bool {
        item == selection
    }

    func fontColor(isSelected: Bool) -> Color {
        isSelected ? .Tangem.Tabs.textPrimary : .Tangem.Tabs.textSecondary
    }

    func backgroundColor(isSelected: Bool) -> Color {
        isSelected ? .Tangem.Tabs.backgroundPrimary : .Tangem.Tabs.backgroundSecondary
    }
}

// MARK: - TextProvider

public protocol TangemTabsTextProvider: Hashable {
    var text: String { get }
}
