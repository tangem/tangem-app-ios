//
//  AccountIconWithContentView.swift
//  TangemAccounts
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemUIUtils
import TangemAssets

public struct AccountIconWithContentView<Subtitle: View, Trailing: View>: View {
    let iconData: AccountIconView.ViewData
    let name: String
    let subtitle: Subtitle
    let trailing: Trailing

    private var iconSettings: AccountIconView.Settings = .defaultSized

    public init(
        iconData: AccountIconView.ViewData,
        name: String,
        @ViewBuilder subtitle: () -> Subtitle,
        @ViewBuilder trailing: () -> Trailing
    ) {
        self.iconData = iconData
        self.name = name
        self.subtitle = subtitle()
        self.trailing = trailing()
    }

    public var body: some View {
        HStack(spacing: 0) {
            AccountIconView(data: iconData, settings: iconSettings)
                .padding(.trailing, 12)

            contentStack
                .fixedSize(horizontal: true, vertical: false)

            Spacer(minLength: 8)

            trailing
        }
        .contentShape(Rectangle())
    }

    private var contentStack: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(name)
                .style(Fonts.Bold.subheadline, color: Colors.Text.primary1)
                .lineLimit(1)

            subtitle
                .style(Fonts.Regular.caption1, color: Colors.Text.tertiary)
                .lineLimit(1)
        }
    }
}

// MARK: - Setupable protocol conformance

extension AccountIconWithContentView: Setupable {
    public func iconSettings(_ settings: AccountIconView.Settings) -> Self {
        map { $0.iconSettings = settings }
    }
}

// MARK: - Default Empty Trailing

public extension AccountIconWithContentView where Trailing == EmptyView {
    init(
        iconData: AccountIconView.ViewData,
        name: String,
        @ViewBuilder subtitle: () -> Subtitle
    ) {
        self.init(
            iconData: iconData,
            name: name,
            subtitle: subtitle,
            trailing: { EmptyView() }
        )
    }
}

// MARK: - Empty Trailing and Subtitle

public extension AccountIconWithContentView where Subtitle == EmptyView, Trailing == EmptyView {
    init(
        iconData: AccountIconView.ViewData,
        name: String,
    ) {
        self.init(
            iconData: iconData,
            name: name,
            subtitle: { EmptyView() },
            trailing: { EmptyView() }
        )
    }
}
