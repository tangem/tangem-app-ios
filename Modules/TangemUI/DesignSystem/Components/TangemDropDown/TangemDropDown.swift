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

public struct TangemDropDown<Label: View, Items: View>: View, Setupable {
    private let label: Label
    private let items: Items

    fileprivate var accessibilityIdentifierFactory: ((AnyHashable) -> String?)?

    public init(
        @ViewBuilder items: () -> Items,
        @ViewBuilder label: () -> Label
    ) {
        self.items = items()
        self.label = label()
    }

    public var body: some View {
        Menu {
            items
        } label: {
            if #available(iOS 26.0, *) {
                label
                    .fixedSize(horizontal: true, vertical: false)
                    .frame(maxWidth: .infinity, alignment: .topLeading)
            } else {
                label
            }
        }
        .transaction { if !isIOS26Available { $0.animation = nil } }
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .environment(\.tangemDropDownItemAccessibilityIdentifier, accessibilityIdentifierFactory)
    }
}

private var isIOS26Available: Bool {
    if #available(iOS 26.0, *) { return true }
    return false
}

// MARK: - Default label

public struct TangemDropDownDefaultLabel: View {
    @ScaledMetric(relativeTo: .caption) private var iconSize: CGFloat = .unit(.x6)
    @ScaledMetric private var contentHorizontalPadding: CGFloat = .unit(.x2)
    @ScaledMetric private var contentVerticalPadding: CGFloat = .unit(.x2)

    private let text: String

    public init(text: String) {
        self.text = text
    }

    public var body: some View {
        HStack(spacing: .unit(.half)) {
            Text(text)
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
        .transaction { if !isIOS26Available { $0.animation = nil } }
    }
}

// MARK: - Item model

public struct TangemDropDownItem: Identifiable {
    public let id: AnyHashable
    public let text: String
    public let isChecked: Bool?
    public let isEnabled: Bool
    public let action: () -> Void

    public init(
        id: AnyHashable = UUID(),
        text: String,
        isChecked: Bool? = nil,
        isEnabled: Bool = true,
        action: @escaping () -> Void
    ) {
        self.id = id
        self.text = text
        self.isChecked = isChecked
        self.isEnabled = isEnabled
        self.action = action
    }
}

// MARK: - Single-selection convenience

public extension TangemDropDown where Label == TangemDropDownDefaultLabel {
    init<Data>(
        singleSelection: Binding<Data.Element>,
        in data: Data
    ) where Data: RandomAccessCollection,
        Data.Element: TangemDropDownTextProvider,
        Items == TangemDropDownSelectionItems<Data> {
        self.init(
            items: { TangemDropDownSelectionItems(data: data, selection: singleSelection) },
            label: { TangemDropDownDefaultLabel(text: singleSelection.wrappedValue.text) }
        )
    }
}

public struct TangemDropDownSelectionItems<Data>: View
    where Data: RandomAccessCollection, Data.Element: TangemDropDownTextProvider {
    @Environment(\.tangemDropDownItemAccessibilityIdentifier) private var accessibilityIdentifierFactory

    private let data: Data
    @Binding private var selection: Data.Element

    fileprivate init(data: Data, selection: Binding<Data.Element>) {
        self.data = data
        _selection = selection
    }

    public var body: some View {
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
            .accessibilityIdentifier(accessibilityIdentifierFactory?(AnyHashable(item)) ?? "")
        }
    }
}

public extension TangemDropDown {
    func accessibilityIdentifier<Data>(
        factory: @escaping (Data.Element) -> String
    ) -> Self where Items == TangemDropDownSelectionItems<Data> {
        map { copy in
            copy.accessibilityIdentifierFactory = { anyHashable in
                (anyHashable.base as? Data.Element).map(factory)
            }
        }
    }
}

// MARK: - Items convenience

public extension TangemDropDown where Items == TangemDropDownItems {
    init(
        items: [TangemDropDownItem],
        @ViewBuilder label: () -> Label
    ) {
        self.init(
            items: { TangemDropDownItems(items: items) },
            label: label
        )
    }
}

public struct TangemDropDownItems: View {
    private let items: [TangemDropDownItem]

    fileprivate init(items: [TangemDropDownItem]) {
        self.items = items
    }

    public var body: some View {
        ForEach(items) { item in
            Button(action: item.action) {
                Text(item.text)

                if item.isChecked == true {
                    Assets.Checked.disabled.image
                        .resizable()
                }
            }
            .disabled(!item.isEnabled)
        }
    }
}

// MARK: - Environment

private struct TangemDropDownItemAccessibilityIdentifierKey: EnvironmentKey {
    static let defaultValue: ((AnyHashable) -> String?)? = nil
}

private extension EnvironmentValues {
    var tangemDropDownItemAccessibilityIdentifier: ((AnyHashable) -> String?)? {
        get { self[TangemDropDownItemAccessibilityIdentifierKey.self] }
        set { self[TangemDropDownItemAccessibilityIdentifierKey.self] = newValue }
    }
}
