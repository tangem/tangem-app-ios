//
//  TangemDropDown.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUIUtils

public protocol TangemDropDownTextProvider: Hashable {
    var text: String { get }
}

public struct TangemDropDown<Data>: View, Setupable
    where Data: RandomAccessCollection, Data.Element: TangemDropDownTextProvider {
    fileprivate typealias Item = Data.Element

    @ScaledMetric private var contentHorizontalPadding: CGFloat
    @ScaledMetric private var contentVerticalPadding: CGFloat
    @ScaledMetric(relativeTo: .caption) private var iconSize: CGFloat = .unit(.x6)

    private let data: Data
    @Binding private var selection: Item

    private var accessibilityIdentifierFactory: ((Data.Element) -> String)?

    public init(
        data: Data,
        selection: Binding<Data.Element>
    ) {
        self.data = data
        _selection = selection

        _contentHorizontalPadding = ScaledMetric(wrappedValue: .unit(.x2))
        _contentVerticalPadding = ScaledMetric(wrappedValue: .unit(.x2))
    }

    public var body: some View {
        menu
    }
}

private extension TangemDropDown {
    var menu: some View {
        Menu {
            ForEach(data, id: \.self) { item in
                Button {
                    selection = item
                } label: {
                    Text(item.text)

                    if selection == item {
                        Assets.Checked.disabled.image
                            .resizable()
                    }
                }
                .accessibilityIdentifier(accessibilityIdentifierFactory?(item))
            }
        } label: {
            if #available(iOS 26.0, *) {
                menuLabel
                    .fixedSize(horizontal: true, vertical: false)
                    .frame(maxWidth: .infinity, alignment: .topLeading)
            } else {
                menuLabel
            }
        }
        .transaction { if !isIOS26 { $0.animation = nil } }
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }

    var isIOS26: Bool {
        if #available(iOS 26.0, *) { return true }
        return false
    }

    var menuLabel: some View {
        HStack(spacing: .unit(.half)) {
            Text(selection.text)
                .lineLimit(1)

            Assets.chevronDown24.image
                .resizable()
                .frame(width: iconSize, height: iconSize)
        }
        .style(
            .Tangem.Body16.semibold,
            color: .Tangem.Text.Neutral.primary
        )
        .padding(.horizontal, contentHorizontalPadding)
        .padding(.vertical, contentVerticalPadding)
        .background(
            Color.Tangem.Button.backgroundSecondary,
            in: RoundedRectangle(cornerRadius: .unit(.x4))
        )
        .transaction { if !isIOS26 { $0.animation = nil } }
    }
}

// MARK: - Setupable

public extension TangemDropDown {
    func accessibilityIdentifier(factory: @escaping (Data.Element) -> String) -> Self {
        map { $0.accessibilityIdentifierFactory = factory }
    }
}
